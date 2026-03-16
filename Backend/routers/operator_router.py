import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import User, Mission, Intersection, Alert, Vehicle
from schemas import (
    SystemStateResponse, ActiveMissionDTO, IntersectionOut, IntersectionUpdate,
    MissionOut, AlertOut, AlertCreate, GPSLocation,
)
from auth import require_role
from websocket_manager import manager

router = APIRouter(prefix="/api/operator", tags=["Operator"])


@router.get("/state", response_model=SystemStateResponse)
def get_system_state(
    user: User = Depends(require_role("operator", "admin")),
    db: Session = Depends(get_db),
):
    missions = db.query(Mission).filter(Mission.status == "active").all()
    intersections = db.query(Intersection).all()
    alerts = db.query(Alert).filter(Alert.is_active == True).all()

    active_dtos = []
    for m in missions:
        vehicle = db.query(Vehicle).filter(Vehicle.id == m.vehicle_id).first()
        driver = db.query(User).filter(User.id == m.driver_id).first()
        active_dtos.append(ActiveMissionDTO(
            mission_id=m.id,
            vehicle_id=m.vehicle_id,
            vehicle_type=vehicle.type if vehicle else "unknown",
            vehicle_name=vehicle.name if vehicle else "Unknown",
            driver_name=driver.name if driver else "Unknown",
            incident_type=m.incident_type,
            priority=m.priority,
            current_location=GPSLocation(
                lat=vehicle.current_lat or m.origin_lat or 0,
                lng=vehicle.current_lng or m.origin_lng or 0,
            ),
            destination=GPSLocation(lat=m.destination_lat or 0, lng=m.destination_lng or 0),
            destination_name=m.destination_name or "",
            eta_minutes=m.eta_minutes or 0,
            status=m.status,
        ))

    congested = [i.id for i in intersections if i.congestion_level == "high"]
    signal_states = {i.id: i.signal_mode for i in intersections}

    return SystemStateResponse(
        active_missions=active_dtos,
        intersections=[IntersectionOut.model_validate(i) for i in intersections],
        congested_nodes=congested,
        signal_states=signal_states,
        stats={
            "active_signals": len(intersections),
            "active_emergencies": len(missions),
            "congested_roads": len(congested),
            "avg_delay": int(sum(i.avg_delay_seconds for i in intersections) / max(len(intersections), 1)),
            "active_alerts": len(alerts),
        },
    )


@router.get("/missions", response_model=list[MissionOut])
def get_missions(
    status: str = None,
    user: User = Depends(require_role("operator", "admin")),
    db: Session = Depends(get_db),
):
    q = db.query(Mission)
    if status:
        q = q.filter(Mission.status == status)
    missions = q.order_by(Mission.started_at.desc()).limit(50).all()
    results = []
    for m in missions:
        results.append(MissionOut(
            id=m.id,
            vehicle_id=m.vehicle_id,
            driver_id=m.driver_id,
            incident_type=m.incident_type,
            priority=m.priority,
            status=m.status,
            origin_lat=m.origin_lat,
            origin_lng=m.origin_lng,
            destination_name=m.destination_name,
            destination_lat=m.destination_lat,
            destination_lng=m.destination_lng,
            route_path=m.route_path,
            eta_minutes=m.eta_minutes,
            distance_km=m.distance_km,
            signals_cleared=m.signals_cleared,
            started_at=m.started_at,
            completed_at=m.completed_at,
            vehicle_type=m.vehicle.type if m.vehicle else None,
            vehicle_name=m.vehicle.name if m.vehicle else None,
            driver_name=m.driver.name if m.driver else None,
            current_lat=m.vehicle.current_lat if m.vehicle else None,
            current_lng=m.vehicle.current_lng if m.vehicle else None,
        ))
    return results


@router.get("/missions/{mission_id}", response_model=MissionOut)
def get_mission(
    mission_id: str,
    user: User = Depends(require_role("operator", "admin")),
    db: Session = Depends(get_db),
):
    m = db.query(Mission).filter(Mission.id == mission_id).first()
    if not m:
        raise HTTPException(status_code=404, detail="Mission not found")
    return MissionOut(
        id=m.id, vehicle_id=m.vehicle_id, driver_id=m.driver_id,
        incident_type=m.incident_type, priority=m.priority, status=m.status,
        origin_lat=m.origin_lat, origin_lng=m.origin_lng,
        destination_name=m.destination_name,
        destination_lat=m.destination_lat, destination_lng=m.destination_lng,
        route_path=m.route_path, eta_minutes=m.eta_minutes,
        distance_km=m.distance_km, signals_cleared=m.signals_cleared,
        started_at=m.started_at, completed_at=m.completed_at,
        vehicle_type=m.vehicle.type if m.vehicle else None,
        vehicle_name=m.vehicle.name if m.vehicle else None,
        driver_name=m.driver.name if m.driver else None,
        current_lat=m.vehicle.current_lat if m.vehicle else None,
        current_lng=m.vehicle.current_lng if m.vehicle else None,
    )


@router.get("/intersections", response_model=list[IntersectionOut])
def get_intersections(
    user: User = Depends(require_role("operator", "admin")),
    db: Session = Depends(get_db),
):
    return [IntersectionOut.model_validate(i) for i in db.query(Intersection).all()]


@router.get("/intersections/{iid}", response_model=IntersectionOut)
def get_intersection(
    iid: str,
    user: User = Depends(require_role("operator", "admin")),
    db: Session = Depends(get_db),
):
    i = db.query(Intersection).filter(Intersection.id == iid).first()
    if not i:
        raise HTTPException(status_code=404, detail="Intersection not found")
    return IntersectionOut.model_validate(i)


@router.post("/intersections/{iid}/force-signal")
async def force_signal(
    iid: str,
    phase: str = "green",
    user: User = Depends(require_role("operator", "admin")),
    db: Session = Depends(get_db),
):
    i = db.query(Intersection).filter(Intersection.id == iid).first()
    if not i:
        raise HTTPException(status_code=404, detail="Intersection not found")
    i.signal_mode = "manual"
    i.current_phase = phase
    db.commit()

    await manager.broadcast("operator", {
        "event": "signal_change",
        "intersection_id": iid,
        "phase": phase,
        "mode": "manual",
    })
    return {"status": "ok", "intersection_id": iid, "phase": phase}


@router.post("/intersections/{iid}/restore")
async def restore_auto(
    iid: str,
    user: User = Depends(require_role("operator", "admin")),
    db: Session = Depends(get_db),
):
    i = db.query(Intersection).filter(Intersection.id == iid).first()
    if not i:
        raise HTTPException(status_code=404, detail="Intersection not found")
    i.signal_mode = "automatic"
    i.current_phase = "green"
    db.commit()

    await manager.broadcast("operator", {
        "event": "signal_change",
        "intersection_id": iid,
        "phase": "green",
        "mode": "automatic",
    })
    return {"status": "ok", "intersection_id": iid, "mode": "automatic"}


@router.get("/alerts", response_model=list[AlertOut])
def get_alerts(
    user: User = Depends(require_role("operator", "admin")),
    db: Session = Depends(get_db),
):
    return [AlertOut.model_validate(a) for a in db.query(Alert).filter(Alert.is_active == True).order_by(Alert.created_at.desc()).all()]


@router.post("/alerts", response_model=AlertOut)
async def create_alert(
    req: AlertCreate,
    user: User = Depends(require_role("operator", "admin")),
    db: Session = Depends(get_db),
):
    alert = Alert(**req.model_dump())
    db.add(alert)
    db.commit()
    db.refresh(alert)

    await manager.broadcast("operator", {
        "event": "alert_new",
        "alert_id": alert.id,
        "title": alert.title,
    })
    return AlertOut.model_validate(alert)


@router.post("/alerts/{alert_id}/clear")
async def clear_alert(
    alert_id: str,
    user: User = Depends(require_role("operator", "admin")),
    db: Session = Depends(get_db),
):
    a = db.query(Alert).filter(Alert.id == alert_id).first()
    if not a:
        raise HTTPException(status_code=404, detail="Alert not found")
    a.is_active = False
    db.commit()
    return {"status": "cleared"}
