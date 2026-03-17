import json
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from datetime import datetime, timezone
from database import get_db
from models import User, Vehicle, Mission, Alert, Hospital, Intersection
from schemas import (
    MissionStartRequest, RouteResponse, GPSPing, MissionEndRequest,
    MissionOut, DriverDashboard, UserOut, VehicleOut, AlertOut, HospitalOut,
    GPSLocation,
)
from auth import get_current_user, require_role
from routing_service import load_graph, snap_to_node, find_intersections_on_route, get_osrm_route, haversine
from websocket_manager import manager

router = APIRouter(prefix="/api/driver", tags=["Driver"])

# In-memory store for live mission visualization data (for the visualizer page)
live_missions_viz = {}


def _mission_to_out(m: Mission) -> MissionOut:
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


@router.get("/dashboard", response_model=DriverDashboard)
def get_dashboard(user: User = Depends(require_role("driver")), db: Session = Depends(get_db)):
    vehicle = None
    if user.vehicle_id:
        vehicle = db.query(Vehicle).filter(Vehicle.id == user.vehicle_id).first()

    active = db.query(Mission).filter(Mission.driver_id == user.id, Mission.status == "active").first()
    recent = db.query(Mission).filter(Mission.driver_id == user.id, Mission.status != "active").order_by(Mission.started_at.desc()).limit(5).all()
    alerts = db.query(Alert).filter(Alert.is_active == True).limit(5).all()

    return DriverDashboard(
        user=UserOut.model_validate(user),
        vehicle=VehicleOut.model_validate(vehicle) if vehicle else None,
        active_mission=_mission_to_out(active) if active else None,
        recent_missions=[_mission_to_out(m) for m in recent],
        nearby_alerts=[AlertOut.model_validate(a) for a in alerts],
    )


@router.get("/nearby-hospitals", response_model=list[HospitalOut])
def get_nearby_hospitals(lat: float = Query(...), lng: float = Query(...), db: Session = Depends(get_db), user: User = Depends(require_role("driver"))):
    hospitals = db.query(Hospital).all()
    results = []
    for h in hospitals:
        dist_km = haversine(lat, lng, h.lat, h.lng) / 1000.0
        eta_min = round(dist_km / 0.5, 1)
        results.append(HospitalOut(id=h.id, name=h.name, lat=h.lat, lng=h.lng, address=h.address, phone=h.phone, distance_km=round(dist_km, 2), eta_minutes=eta_min))
    results.sort(key=lambda x: x.distance_km)
    return results[:15]


@router.post("/mission/start", response_model=RouteResponse)
async def start_mission(req: MissionStartRequest, user: User = Depends(require_role("driver")), db: Session = Depends(get_db)):
    vehicle = db.query(Vehicle).filter(Vehicle.id == req.vehicle_id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    nodes, graph = load_graph(db)
    if not nodes:
        raise HTTPException(status_code=500, detail="No intersections configured")

    origin_lat = req.origin_lat or vehicle.current_lat or 22.7196
    origin_lng = req.origin_lng or vehicle.current_lng or 75.8577

    # Step 1: A* on intersection graph to find which intersections to clear
    intersection_path, algo_steps = find_intersections_on_route(
        origin_lat, origin_lng, req.destination_lat, req.destination_lng, nodes, graph
    )

    # Step 2: Get actual road-following route from OSRM (direct, no waypoints)
    road_coords, distance_km, eta_minutes = await get_osrm_route(
        origin_lat, origin_lng, req.destination_lat, req.destination_lng
    )

    # Fallback ETA/distance from graph if OSRM failed
    if distance_km == 0:
        from graph_engine import calculate_eta, calculate_distance_km
        eta_minutes = calculate_eta(intersection_path, graph)
        distance_km = calculate_distance_km(intersection_path, nodes)

    # Create mission
    mission = Mission(
        vehicle_id=req.vehicle_id, driver_id=user.id,
        incident_type=req.incident_type, priority=req.priority,
        origin_lat=origin_lat, origin_lng=origin_lng,
        destination_name=req.destination_name,
        destination_lat=req.destination_lat, destination_lng=req.destination_lng,
        route_path=json.dumps(intersection_path),
        eta_minutes=eta_minutes, distance_km=distance_km,
    )
    db.add(mission)

    vehicle.status = "active"
    vehicle.current_lat = origin_lat
    vehicle.current_lng = origin_lng

    # Set signal modes for intersections on route
    route_details = []
    for iid in intersection_path:
        inter = db.query(Intersection).filter(Intersection.id == iid).first()
        if inter:
            inter.signal_mode = "emergency"
            inter.current_phase = "green"
            route_details.append({
                "id": inter.id, "name": inter.name,
                "lat": inter.lat, "lng": inter.lng,
                "assigned_operator_id": inter.assigned_operator_id,
            })

    db.commit()
    db.refresh(mission)

    # Store visualization data for the live visualizer
    # Include OSRM road coordinates for accurate map rendering
    road_coords_list = [{"lat": c.lat, "lng": c.lng} for c in road_coords]
    live_missions_viz[mission.id] = {
        "mission_id": mission.id,
        "vehicle_id": req.vehicle_id,
        "vehicle_type": vehicle.type,
        "driver_name": user.name,
        "incident_type": req.incident_type,
        "priority": req.priority,
        "origin": {"lat": origin_lat, "lng": origin_lng},
        "destination": {"lat": req.destination_lat, "lng": req.destination_lng, "name": req.destination_name},
        "intersection_path": intersection_path,
        "route_details": route_details,
        "algo_steps": algo_steps,
        "road_coordinates": road_coords_list,
        "distance_km": distance_km,
        "eta_minutes": eta_minutes,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }

    # Broadcast mission + algo steps to visualizer via WebSocket
    await manager.broadcast("visualizer", {
        "event": "new_mission",
        **live_missions_viz[mission.id],
    })

    # Broadcast to operators
    await manager.broadcast("operator", {
        "event": "mission_started",
        "mission_id": mission.id,
        "vehicle_id": req.vehicle_id,
        "vehicle_type": vehicle.type,
        "driver_name": user.name,
        "incident_type": req.incident_type,
        "priority": req.priority,
        "destination_name": req.destination_name,
        "route": intersection_path,
        "route_details": route_details,
        "eta_minutes": eta_minutes,
        "distance_km": distance_km,
    })

    # Notify individual operators
    for detail in route_details:
        if detail.get("assigned_operator_id"):
            await manager.broadcast(f"operator_{detail['assigned_operator_id']}", {
                "event": "intersection_alert",
                "mission_id": mission.id,
                "vehicle_id": req.vehicle_id,
                "vehicle_type": vehicle.type,
                "priority": req.priority,
                "intersection_id": detail["id"],
                "intersection_name": detail["name"],
                "message": f"Emergency {vehicle.type} approaching {detail['name']} - Clear corridor!",
            })

    return RouteResponse(
        mission_id=mission.id,
        eta_minutes=eta_minutes,
        distance_km=distance_km,
        route_coordinates=road_coords,
        route_intersections=intersection_path,
        next_signal_state="PRIMARY",
        signals_on_route=len(intersection_path),
    )


@router.post("/mission/ping", response_model=RouteResponse)
async def ping_gps(ping: GPSPing, user: User = Depends(require_role("driver")), db: Session = Depends(get_db)):
    mission = db.query(Mission).filter(Mission.id == ping.mission_id).first()
    if not mission:
        raise HTTPException(status_code=404, detail="Mission not found")

    # Update vehicle position
    vehicle = db.query(Vehicle).filter(Vehicle.id == mission.vehicle_id).first()
    if vehicle:
        vehicle.current_lat = ping.current_lat
        vehicle.current_lng = ping.current_lng

    # Get OSRM route from current position to destination (runs async)
    road_coords, distance_km, eta_minutes = await get_osrm_route(
        ping.current_lat, ping.current_lng,
        mission.destination_lat, mission.destination_lng,
    )

    # Update signal count using cached graph
    nodes, graph = load_graph(db)
    old_path = json.loads(mission.route_path) if mission.route_path else []

    passed = 0
    for n in old_path:
        if n in nodes:
            d_to_vehicle = haversine(ping.current_lat, ping.current_lng, nodes[n]["lat"], nodes[n]["lng"])
            d_to_origin = haversine(mission.origin_lat, mission.origin_lng, nodes[n]["lat"], nodes[n]["lng"])
            if d_to_vehicle > d_to_origin:
                passed += 1
    mission.signals_cleared = max(mission.signals_cleared, passed)

    # Only use new OSRM route if it's valid (not a straight-line fallback)
    use_new_route = distance_km > 0 and len(road_coords) > 2

    if use_new_route:
        mission.eta_minutes = eta_minutes
        mission.distance_km = distance_km

    db.commit()

    # Broadcast position
    await manager.broadcast("operator", {
        "event": "vehicle_position",
        "mission_id": mission.id, "vehicle_id": mission.vehicle_id,
        "lat": ping.current_lat, "lng": ping.current_lng,
        "eta_minutes": mission.eta_minutes,
    })
    await manager.broadcast("visualizer", {
        "event": "vehicle_moved",
        "mission_id": mission.id,
        "lat": ping.current_lat, "lng": ping.current_lng,
    })

    # If OSRM failed, return coordinates from origin to destination as fallback
    # (use the original mission's OSRM route, not a straight line)
    if not use_new_route:
        viz = live_missions_viz.get(mission.id)
        if viz and viz.get("road_coordinates"):
            road_coords = [GPSLocation(lat=c["lat"], lng=c["lng"]) for c in viz["road_coordinates"]]

    return RouteResponse(
        mission_id=mission.id,
        eta_minutes=mission.eta_minutes or 0,
        distance_km=mission.distance_km or 0,
        route_coordinates=road_coords,
        route_intersections=old_path,
        next_signal_state="PRIMARY",
        signals_on_route=len(old_path),
        signals_cleared=mission.signals_cleared,
    )


@router.post("/mission/end")
async def end_mission(req: MissionEndRequest, user: User = Depends(require_role("driver")), db: Session = Depends(get_db)):
    mission = db.query(Mission).filter(Mission.id == req.mission_id).first()
    if not mission:
        raise HTTPException(status_code=404, detail="Mission not found")

    mission.status = "completed"
    mission.completed_at = datetime.now(timezone.utc)

    vehicle = db.query(Vehicle).filter(Vehicle.id == mission.vehicle_id).first()
    if vehicle:
        vehicle.status = "standby"

    old_path = json.loads(mission.route_path) if mission.route_path else []
    for iid in old_path:
        inter = db.query(Intersection).filter(Intersection.id == iid).first()
        if inter and inter.signal_mode == "emergency":
            inter.signal_mode = "automatic"

    db.commit()

    # Clean up viz data
    live_missions_viz.pop(mission.id, None)

    await manager.broadcast("operator", {"event": "mission_completed", "mission_id": mission.id})
    await manager.broadcast("visualizer", {"event": "mission_completed", "mission_id": mission.id})

    return {
        "status": "completed", "mission_id": mission.id,
        "distance_km": mission.distance_km,
        "signals_cleared": mission.signals_cleared,
        "duration_minutes": round((mission.completed_at - mission.started_at).total_seconds() / 60, 1) if mission.started_at else 0,
    }


@router.get("/missions/history", response_model=list[MissionOut])
def get_mission_history(user: User = Depends(require_role("driver")), db: Session = Depends(get_db)):
    missions = db.query(Mission).filter(Mission.driver_id == user.id).order_by(Mission.started_at.desc()).limit(20).all()
    return [_mission_to_out(m) for m in missions]


# --- Visualizer endpoints ---
@router.get("/viz/missions")
def get_viz_missions():
    """Get all live mission visualization data (no auth needed for demo)."""
    return list(live_missions_viz.values())
