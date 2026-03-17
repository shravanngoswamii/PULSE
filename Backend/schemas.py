from pydantic import BaseModel
from typing import List, Dict, Optional
from datetime import datetime


# --- Auth ---
class LoginRequest(BaseModel):
    email: str
    password: str

class RegisterRequest(BaseModel):
    name: str
    email: str
    password: str
    role: str = "driver"
    phone: Optional[str] = None
    vehicle_id: Optional[str] = None

class TokenResponse(BaseModel):
    token: str
    user: "UserOut"

class UserOut(BaseModel):
    id: str
    name: str
    email: str
    role: str
    phone: Optional[str] = None
    vehicle_id: Optional[str] = None
    is_active: bool = True

    class Config:
        from_attributes = True


# --- GPS ---
class GPSLocation(BaseModel):
    lat: float
    lng: float


# --- Vehicle ---
class VehicleOut(BaseModel):
    id: str
    type: str
    name: str
    registration: Optional[str] = None
    status: str
    current_lat: Optional[float] = None
    current_lng: Optional[float] = None

    class Config:
        from_attributes = True

class VehicleCreate(BaseModel):
    id: str
    type: str
    name: str
    registration: Optional[str] = None

class VehicleUpdate(BaseModel):
    name: Optional[str] = None
    type: Optional[str] = None
    registration: Optional[str] = None
    status: Optional[str] = None
    current_lat: Optional[float] = None
    current_lng: Optional[float] = None


# --- Intersection ---
class IntersectionOut(BaseModel):
    id: str
    name: str
    district: str
    lat: float
    lng: float
    signal_mode: str
    current_phase: str
    vehicles_waiting: int
    avg_delay_seconds: int
    congestion_level: str
    assigned_operator_id: Optional[str] = None

    class Config:
        from_attributes = True

class IntersectionCreate(BaseModel):
    id: str
    name: str
    district: str
    lat: float
    lng: float

class IntersectionUpdate(BaseModel):
    name: Optional[str] = None
    district: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    signal_mode: Optional[str] = None
    current_phase: Optional[str] = None
    vehicles_waiting: Optional[int] = None
    avg_delay_seconds: Optional[int] = None
    congestion_level: Optional[str] = None
    assigned_operator_id: Optional[str] = None


# --- Mission ---
class MissionStartRequest(BaseModel):
    vehicle_id: str
    destination_lat: float
    destination_lng: float
    destination_name: str = ""
    incident_type: str = "Medical Emergency"
    priority: str = "high"
    origin_lat: Optional[float] = None
    origin_lng: Optional[float] = None

class RouteResponse(BaseModel):
    mission_id: str
    eta_minutes: float
    distance_km: float
    route_coordinates: List[GPSLocation]
    route_intersections: List[str]
    next_signal_state: str
    signals_on_route: int
    signals_cleared: int = 0

class GPSPing(BaseModel):
    mission_id: str
    current_lat: float
    current_lng: float

class MissionOut(BaseModel):
    id: str
    vehicle_id: str
    driver_id: str
    incident_type: str
    priority: str
    status: str
    origin_lat: Optional[float] = None
    origin_lng: Optional[float] = None
    destination_name: Optional[str] = None
    destination_lat: Optional[float] = None
    destination_lng: Optional[float] = None
    route_path: Optional[str] = None
    eta_minutes: Optional[float] = None
    distance_km: Optional[float] = None
    signals_cleared: int = 0
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None

    # Populated from relationships
    vehicle_type: Optional[str] = None
    vehicle_name: Optional[str] = None
    driver_name: Optional[str] = None
    current_lat: Optional[float] = None
    current_lng: Optional[float] = None

    class Config:
        from_attributes = True

class MissionEndRequest(BaseModel):
    mission_id: str


# --- Alert ---
class AlertOut(BaseModel):
    id: str
    type: str
    severity: str
    title: str
    description: Optional[str] = None
    location: Optional[str] = None
    intersection_id: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None
    is_active: bool
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True

class AlertCreate(BaseModel):
    type: str
    severity: str
    title: str
    description: Optional[str] = None
    location: Optional[str] = None
    intersection_id: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None


# --- Hospital ---
class HospitalOut(BaseModel):
    id: str
    name: str
    lat: float
    lng: float
    address: Optional[str] = None
    phone: Optional[str] = None
    distance_km: Optional[float] = None
    eta_minutes: Optional[float] = None

    class Config:
        from_attributes = True


# --- Dashboard / Operator ---
class DensityUpdate(BaseModel):
    node_id: str
    total_weight: float

class ActiveMissionDTO(BaseModel):
    mission_id: str
    vehicle_id: str
    vehicle_type: str
    vehicle_name: str
    driver_name: str
    incident_type: str
    priority: str
    current_location: GPSLocation
    destination: GPSLocation
    destination_name: str
    eta_minutes: float
    status: str

class SystemStateResponse(BaseModel):
    active_missions: List[ActiveMissionDTO]
    intersections: List[IntersectionOut]
    congested_nodes: List[str]
    signal_states: Dict[str, str]
    stats: Dict[str, int]

class DriverDashboard(BaseModel):
    user: UserOut
    vehicle: Optional[VehicleOut] = None
    active_mission: Optional[MissionOut] = None
    recent_missions: List[MissionOut] = []
    nearby_alerts: List[AlertOut] = []

class AdminStats(BaseModel):
    total_users: int
    total_drivers: int
    total_operators: int
    total_vehicles: int
    total_intersections: int
    active_missions: int
    completed_missions: int
    active_alerts: int


# Fix forward reference
TokenResponse.model_rebuild()
