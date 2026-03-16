from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import User, Vehicle, Intersection, Edge, Mission, Alert, Hospital
from schemas import (
    UserOut, RegisterRequest, VehicleOut, VehicleCreate, VehicleUpdate,
    IntersectionOut, IntersectionCreate, IntersectionUpdate,
    MissionOut, AlertOut, AlertCreate, HospitalOut, AdminStats,
)
from auth import require_role, hash_password

router = APIRouter(prefix="/api/admin", tags=["Admin"])


# --- Stats ---
@router.get("/stats", response_model=AdminStats)
def get_stats(user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    return AdminStats(
        total_users=db.query(User).count(),
        total_drivers=db.query(User).filter(User.role == "driver").count(),
        total_operators=db.query(User).filter(User.role == "operator").count(),
        total_vehicles=db.query(Vehicle).count(),
        total_intersections=db.query(Intersection).count(),
        active_missions=db.query(Mission).filter(Mission.status == "active").count(),
        completed_missions=db.query(Mission).filter(Mission.status == "completed").count(),
        active_alerts=db.query(Alert).filter(Alert.is_active == True).count(),
    )


# --- Users CRUD ---
@router.get("/users", response_model=list[UserOut])
def list_users(user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    return [UserOut.model_validate(u) for u in db.query(User).order_by(User.created_at.desc()).all()]


@router.post("/users", response_model=UserOut)
def create_user(req: RegisterRequest, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == req.email).first():
        raise HTTPException(status_code=409, detail="Email exists")
    u = User(name=req.name, email=req.email, password_hash=hash_password(req.password), role=req.role, phone=req.phone, vehicle_id=req.vehicle_id)
    db.add(u)
    db.commit()
    db.refresh(u)
    return UserOut.model_validate(u)


@router.get("/users/{uid}", response_model=UserOut)
def get_user(uid: str, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    u = db.query(User).filter(User.id == uid).first()
    if not u:
        raise HTTPException(status_code=404, detail="User not found")
    return UserOut.model_validate(u)


@router.put("/users/{uid}", response_model=UserOut)
def update_user(uid: str, req: dict, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    u = db.query(User).filter(User.id == uid).first()
    if not u:
        raise HTTPException(status_code=404, detail="User not found")
    for k, v in req.items():
        if k == "password":
            u.password_hash = hash_password(v)
        elif hasattr(u, k) and k != "id":
            setattr(u, k, v)
    db.commit()
    db.refresh(u)
    return UserOut.model_validate(u)


@router.delete("/users/{uid}")
def delete_user(uid: str, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    u = db.query(User).filter(User.id == uid).first()
    if not u:
        raise HTTPException(status_code=404, detail="User not found")
    db.delete(u)
    db.commit()
    return {"status": "deleted"}


# --- Vehicles CRUD ---
@router.get("/vehicles", response_model=list[VehicleOut])
def list_vehicles(user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    return [VehicleOut.model_validate(v) for v in db.query(Vehicle).all()]


@router.post("/vehicles", response_model=VehicleOut)
def create_vehicle(req: VehicleCreate, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    if db.query(Vehicle).filter(Vehicle.id == req.id).first():
        raise HTTPException(status_code=409, detail="Vehicle ID exists")
    v = Vehicle(**req.model_dump())
    db.add(v)
    db.commit()
    db.refresh(v)
    return VehicleOut.model_validate(v)


@router.get("/vehicles/{vid}", response_model=VehicleOut)
def get_vehicle(vid: str, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    v = db.query(Vehicle).filter(Vehicle.id == vid).first()
    if not v:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return VehicleOut.model_validate(v)


@router.put("/vehicles/{vid}", response_model=VehicleOut)
def update_vehicle(vid: str, req: VehicleUpdate, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    v = db.query(Vehicle).filter(Vehicle.id == vid).first()
    if not v:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    for k, val in req.model_dump(exclude_unset=True).items():
        setattr(v, k, val)
    db.commit()
    db.refresh(v)
    return VehicleOut.model_validate(v)


@router.delete("/vehicles/{vid}")
def delete_vehicle(vid: str, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    v = db.query(Vehicle).filter(Vehicle.id == vid).first()
    if not v:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    db.delete(v)
    db.commit()
    return {"status": "deleted"}


# --- Intersections CRUD ---
@router.get("/intersections", response_model=list[IntersectionOut])
def list_intersections(user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    return [IntersectionOut.model_validate(i) for i in db.query(Intersection).all()]


@router.post("/intersections", response_model=IntersectionOut)
def create_intersection(req: IntersectionCreate, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    i = Intersection(**req.model_dump())
    db.add(i)
    db.commit()
    db.refresh(i)
    return IntersectionOut.model_validate(i)


@router.get("/intersections/{iid}", response_model=IntersectionOut)
def get_intersection(iid: str, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    i = db.query(Intersection).filter(Intersection.id == iid).first()
    if not i:
        raise HTTPException(status_code=404, detail="Intersection not found")
    return IntersectionOut.model_validate(i)


@router.put("/intersections/{iid}", response_model=IntersectionOut)
def update_intersection(iid: str, req: IntersectionUpdate, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    i = db.query(Intersection).filter(Intersection.id == iid).first()
    if not i:
        raise HTTPException(status_code=404, detail="Intersection not found")
    for k, val in req.model_dump(exclude_unset=True).items():
        setattr(i, k, val)
    db.commit()
    db.refresh(i)
    return IntersectionOut.model_validate(i)


@router.delete("/intersections/{iid}")
def delete_intersection(iid: str, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    # Delete related edges first
    db.query(Edge).filter((Edge.from_id == iid) | (Edge.to_id == iid)).delete()
    i = db.query(Intersection).filter(Intersection.id == iid).first()
    if not i:
        raise HTTPException(status_code=404, detail="Intersection not found")
    db.delete(i)
    db.commit()
    return {"status": "deleted"}


# --- Missions (read-only for admin) ---
@router.get("/missions", response_model=list[MissionOut])
def list_missions(status: str = None, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    q = db.query(Mission)
    if status:
        q = q.filter(Mission.status == status)
    missions = q.order_by(Mission.started_at.desc()).limit(100).all()
    return [MissionOut(
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
    ) for m in missions]


@router.get("/missions/{mid}", response_model=MissionOut)
def get_mission(mid: str, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    m = db.query(Mission).filter(Mission.id == mid).first()
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
    )


# --- Alerts CRUD ---
@router.get("/alerts", response_model=list[AlertOut])
def list_alerts(user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    return [AlertOut.model_validate(a) for a in db.query(Alert).order_by(Alert.created_at.desc()).all()]


@router.post("/alerts", response_model=AlertOut)
def create_alert(req: AlertCreate, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    a = Alert(**req.model_dump())
    db.add(a)
    db.commit()
    db.refresh(a)
    return AlertOut.model_validate(a)


@router.delete("/alerts/{aid}")
def delete_alert(aid: str, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    a = db.query(Alert).filter(Alert.id == aid).first()
    if not a:
        raise HTTPException(status_code=404, detail="Alert not found")
    db.delete(a)
    db.commit()
    return {"status": "deleted"}


# --- Hospitals CRUD ---
@router.get("/hospitals", response_model=list[HospitalOut])
def list_hospitals(user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    return [HospitalOut.model_validate(h) for h in db.query(Hospital).all()]


@router.post("/hospitals", response_model=HospitalOut)
def create_hospital(req: dict, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    h = Hospital(name=req["name"], lat=req["lat"], lng=req["lng"], address=req.get("address"), phone=req.get("phone"))
    db.add(h)
    db.commit()
    db.refresh(h)
    return HospitalOut.model_validate(h)


@router.delete("/hospitals/{hid}")
def delete_hospital(hid: str, user: User = Depends(require_role("admin")), db: Session = Depends(get_db)):
    h = db.query(Hospital).filter(Hospital.id == hid).first()
    if not h:
        raise HTTPException(status_code=404, detail="Hospital not found")
    db.delete(h)
    db.commit()
    return {"status": "deleted"}
