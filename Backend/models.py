import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, Text, ForeignKey
from sqlalchemy.orm import relationship
from database import Base


def gen_uuid():
    return str(uuid.uuid4())


def utcnow():
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String, nullable=False)
    email = Column(String, unique=True, nullable=False, index=True)
    password_hash = Column(String, nullable=False)
    role = Column(String, nullable=False)  # driver, operator, admin
    phone = Column(String, nullable=True)
    vehicle_id = Column(String, ForeignKey("vehicles.id"), nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=utcnow)

    vehicle = relationship("Vehicle", back_populates="assigned_driver", foreign_keys=[vehicle_id])


class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(String, primary_key=True)  # AMB-01, FIR-01, POL-01
    type = Column(String, nullable=False)  # ambulance, fire, police
    name = Column(String, nullable=False)
    registration = Column(String, nullable=True)
    status = Column(String, default="standby")  # standby, active, maintenance
    current_lat = Column(Float, nullable=True)
    current_lng = Column(Float, nullable=True)
    created_at = Column(DateTime, default=utcnow)

    assigned_driver = relationship("User", back_populates="vehicle", foreign_keys=[User.vehicle_id], uselist=False)


class Intersection(Base):
    __tablename__ = "intersections"

    id = Column(String, primary_key=True)
    name = Column(String, nullable=False)
    district = Column(String, nullable=False)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    signal_mode = Column(String, default="automatic")  # automatic, manual, emergency
    current_phase = Column(String, default="green")  # green, red, amber
    vehicles_waiting = Column(Integer, default=0)
    avg_delay_seconds = Column(Integer, default=15)
    congestion_level = Column(String, default="low")  # low, moderate, high
    assigned_operator_id = Column(String, ForeignKey("users.id"), nullable=True)
    created_at = Column(DateTime, default=utcnow)


class Edge(Base):
    __tablename__ = "edges"

    id = Column(Integer, primary_key=True, autoincrement=True)
    from_id = Column(String, ForeignKey("intersections.id"), nullable=False)
    to_id = Column(String, ForeignKey("intersections.id"), nullable=False)
    base_travel_time = Column(Float, nullable=False)  # seconds
    current_weight = Column(Float, nullable=False)  # dynamic, updated by density
    distance_meters = Column(Float, nullable=True)


class Mission(Base):
    __tablename__ = "missions"

    id = Column(String, primary_key=True, default=lambda: f"MSN-{uuid.uuid4().hex[:6].upper()}")
    vehicle_id = Column(String, ForeignKey("vehicles.id"), nullable=False)
    driver_id = Column(String, ForeignKey("users.id"), nullable=False)
    incident_type = Column(String, nullable=False)
    priority = Column(String, nullable=False)  # critical, high, standard
    origin_lat = Column(Float, nullable=True)
    origin_lng = Column(Float, nullable=True)
    destination_name = Column(String, nullable=True)
    destination_lat = Column(Float, nullable=True)
    destination_lng = Column(Float, nullable=True)
    status = Column(String, default="active")  # active, completed, cancelled
    route_path = Column(Text, nullable=True)  # JSON: list of intersection IDs
    eta_minutes = Column(Float, nullable=True)
    distance_km = Column(Float, nullable=True)
    signals_cleared = Column(Integer, default=0)
    started_at = Column(DateTime, default=utcnow)
    completed_at = Column(DateTime, nullable=True)

    vehicle = relationship("Vehicle")
    driver = relationship("User")


class Alert(Base):
    __tablename__ = "alerts"

    id = Column(String, primary_key=True, default=gen_uuid)
    type = Column(String, nullable=False)  # accident, signal_failure, emergency_vehicle, congestion
    severity = Column(String, nullable=False)  # high, medium, low
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    location = Column(String, nullable=True)
    intersection_id = Column(String, ForeignKey("intersections.id"), nullable=True)
    lat = Column(Float, nullable=True)
    lng = Column(Float, nullable=True)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=utcnow)


class Hospital(Base):
    __tablename__ = "hospitals"

    id = Column(String, primary_key=True, default=gen_uuid)
    name = Column(String, nullable=False)
    lat = Column(Float, nullable=False)
    lng = Column(Float, nullable=False)
    address = Column(String, nullable=True)
    phone = Column(String, nullable=True)
