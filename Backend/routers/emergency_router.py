import json
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from database import get_db
from models import EmergencyCall, Vehicle, User, Mission, Intersection
from schemas import EmergencyCallCreate
from routing_service import haversine
from websocket_manager import manager
from auth import get_current_user, require_role

router = APIRouter(prefix="/api/emergency", tags=["Emergency"])


def _enrich_call(call: EmergencyCall, db: Session) -> dict:
    """Build enriched dict with vehicle/driver/mission/road details."""
    vehicle = db.query(Vehicle).filter(Vehicle.id == call.assigned_vehicle_id).first() if call.assigned_vehicle_id else None
    driver = db.query(User).filter(User.id == call.assigned_driver_id).first() if call.assigned_driver_id else None
    mission = db.query(Mission).filter(Mission.id == call.assigned_mission_id).first() if call.assigned_mission_id else None

    road_coordinates = None
    if mission and mission.road_coordinates_json:
        try:
            road_coordinates = json.loads(mission.road_coordinates_json)
        except Exception:
            pass

    return {
        "id": call.id,
        "caller_name": call.caller_name,
        "caller_phone": call.caller_phone,
        "caller_lat": call.caller_lat,
        "caller_lng": call.caller_lng,
        "incident_type": call.incident_type,
        "severity": call.severity,
        "description": call.description or "",
        "status": call.status,
        "assigned_vehicle_id": call.assigned_vehicle_id,
        "assigned_driver_id": call.assigned_driver_id,
        "assigned_mission_id": call.assigned_mission_id,
        "created_at": call.created_at.isoformat() if call.created_at else None,
        "vehicle_name": vehicle.name if vehicle else None,
        "driver_name": driver.name if driver else None,
        "driver_phone": driver.phone if driver else None,
        "vehicle_type": vehicle.type if vehicle else None,
        "vehicle_lat": vehicle.current_lat if vehicle else None,
        "vehicle_lng": vehicle.current_lng if vehicle else None,
        "mission_eta": mission.eta_minutes if mission else None,
        "mission_distance_km": mission.distance_km if mission else None,
        "mission_status": mission.status if mission else None,
        "road_coordinates": road_coordinates,
    }


@router.post("/call")
async def create_emergency_call(req: EmergencyCallCreate, db: Session = Depends(get_db)):
    """Patient calls emergency. No auth required.
    Finds nearest available vehicle and assigns it."""

    # Find nearest standby ambulance
    standby_vehicles = db.query(Vehicle).filter(Vehicle.status == "standby").all()
    if not standby_vehicles:
        # Try any vehicle type
        standby_vehicles = db.query(Vehicle).all()

    best_vehicle = None
    best_dist = float('inf')
    for v in standby_vehicles:
        if v.status != "standby":
            continue
        if v.current_lat and v.current_lng:
            d = haversine(req.caller_lat, req.caller_lng, v.current_lat, v.current_lng)
            if d < best_dist:
                best_dist = d
                best_vehicle = v

    # Fallback: pick first standby vehicle even without coordinates
    if not best_vehicle:
        for v in standby_vehicles:
            if v.status == "standby":
                best_vehicle = v
                break

    if not best_vehicle:
        raise HTTPException(status_code=503, detail="No vehicles available")

    # Find the driver assigned to this vehicle
    driver = db.query(User).filter(User.vehicle_id == best_vehicle.id, User.role == "driver").first()

    call = EmergencyCall(
        caller_name=req.caller_name,
        caller_phone=req.caller_phone,
        caller_lat=req.caller_lat,
        caller_lng=req.caller_lng,
        incident_type=req.incident_type,
        severity=req.severity,
        description=req.description,
        status="assigned",
        assigned_vehicle_id=best_vehicle.id,
        assigned_driver_id=driver.id if driver else None,
    )
    db.add(call)
    db.commit()
    db.refresh(call)

    # Broadcast to operators via WebSocket
    await manager.broadcast("operator", {
        "event": "emergency_dispatch",
        "call_id": call.id,
        "caller_name": req.caller_name,
        "caller_phone": req.caller_phone,
        "caller_lat": req.caller_lat,
        "caller_lng": req.caller_lng,
        "incident_type": req.incident_type,
        "severity": req.severity,
        "assigned_vehicle_id": best_vehicle.id,
        "assigned_driver_id": driver.id if driver else None,
    })

    # Broadcast to ALL drivers so any logged-in driver receives the dispatch
    # (important for demo: only one driver may be logged in)
    all_drivers = db.query(User).filter(User.role == "driver").all()
    for d in all_drivers:
        await manager.broadcast(f"driver_{d.id}", {
            "event": "incoming_dispatch",
            "call_id": call.id,
            "caller_name": req.caller_name,
            "caller_phone": req.caller_phone,
            "caller_lat": req.caller_lat,
            "caller_lng": req.caller_lng,
            "incident_type": req.incident_type,
            "severity": req.severity,
            "description": req.description,
            "assigned_vehicle_id": best_vehicle.id,
        })

    return _enrich_call(call, db)


@router.get("/track/{phone}")
def track_by_phone(phone: str, db: Session = Depends(get_db)):
    """Patient tracks their ambulance by phone number. No auth required."""
    # Normalize: strip spaces, dashes, parens
    phone_clean = phone.strip().replace(" ", "").replace("-", "").replace("(", "").replace(")", "")

    # Try exact match first
    call = (
        db.query(EmergencyCall)
        .filter(EmergencyCall.caller_phone == phone_clean, EmergencyCall.status != "cancelled")
        .order_by(EmergencyCall.created_at.desc())
        .first()
    )

    # Try fuzzy match (without country code prefix)
    if not call:
        bare = phone_clean.lstrip("+")
        if bare.startswith("91") and len(bare) > 10:
            bare = bare[2:]
        all_active = (
            db.query(EmergencyCall)
            .filter(EmergencyCall.status != "cancelled")
            .order_by(EmergencyCall.created_at.desc())
            .limit(100)
            .all()
        )
        for c in all_active:
            stored = c.caller_phone.replace(" ", "").replace("-", "").lstrip("+")
            if stored.startswith("91") and len(stored) > 10:
                stored = stored[2:]
            if stored == bare:
                call = c
                break

    if not call:
        raise HTTPException(status_code=404, detail="No active emergency found for this number")

    return _enrich_call(call, db)


@router.get("/pending")
def get_pending_dispatches(
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Get pending dispatches for any driver. Only shows 'assigned' calls
    (not yet accepted). Once accepted, status moves to 'in_progress'."""
    calls = (
        db.query(EmergencyCall)
        .filter(
            EmergencyCall.status == "assigned",
        )
        .order_by(EmergencyCall.created_at.desc())
        .limit(10)
        .all()
    )
    return [_enrich_call(c, db) for c in calls]


@router.post("/accept/{call_id}")
async def accept_dispatch(
    call_id: str,
    user: User = Depends(get_current_user),
    db: Session = Depends(get_db),
):
    """Driver accepts a dispatch. Updates status and reassigns to this driver."""
    call = db.query(EmergencyCall).filter(EmergencyCall.id == call_id).first()
    if not call:
        raise HTTPException(status_code=404, detail="Emergency call not found")

    call.status = "in_progress"
    # Reassign to the accepting driver and their vehicle
    call.assigned_driver_id = user.id
    if user.vehicle_id:
        call.assigned_vehicle_id = user.vehicle_id
    db.commit()

    await manager.broadcast("operator", {
        "event": "dispatch_accepted",
        "call_id": call_id,
        "driver_id": user.id,
        "driver_name": user.name,
        "vehicle_id": call.assigned_vehicle_id,
    })

    return {"status": "accepted", "call_id": call_id, "caller_lat": call.caller_lat, "caller_lng": call.caller_lng}


@router.post("/complete/{call_id}")
async def complete_dispatch(
    call_id: str,
    db: Session = Depends(get_db),
):
    """Mark emergency call as completed."""
    call = db.query(EmergencyCall).filter(EmergencyCall.id == call_id).first()
    if not call:
        raise HTTPException(status_code=404, detail="Emergency call not found")
    call.status = "completed"
    db.commit()
    return {"status": "completed"}


@router.get("/calls")
def list_calls(
    status: str = None,
    user: User = Depends(require_role("operator", "admin")),
    db: Session = Depends(get_db),
):
    """List all emergency calls. For operators/admins."""
    q = db.query(EmergencyCall).order_by(EmergencyCall.created_at.desc())
    if status:
        q = q.filter(EmergencyCall.status == status)
    return [_enrich_call(c, db) for c in q.limit(50).all()]
