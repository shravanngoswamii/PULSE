"""Seed the database with Indore intersections, edges, vehicles, hospitals, and demo users."""
import sys
import os
sys.path.insert(0, os.path.dirname(__file__))

from database import engine, SessionLocal, Base
from models import User, Vehicle, Intersection, Edge, Hospital
from auth import hash_password
from graph_engine import haversine


def seed():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # --- Intersections (Indore, MP) ---
    intersections = [
        Intersection(id="INT-VJY", name="Vijay Nagar Square", district="Vijay Nagar", lat=22.7533, lng=75.8937),
        Intersection(id="INT-PAL", name="Palasia Square", district="Palasia", lat=22.7236, lng=75.8798),
        Intersection(id="INT-GPR", name="Geeta Bhawan Square", district="Geeta Bhawan", lat=22.7196, lng=75.8577),
        Intersection(id="INT-RJW", name="Rajwada Square", district="Rajwada", lat=22.7185, lng=75.8571),
        Intersection(id="INT-SRV", name="Sarwate Bus Stand", district="Sarwate", lat=22.7134, lng=75.8621),
        Intersection(id="INT-MGL", name="MG Road - LIG Square", district="MG Road", lat=22.7271, lng=75.8835),
        Intersection(id="INT-BHW", name="Bhanwar Kuwa Square", district="Bhanwar Kuwa", lat=22.7299, lng=75.8656),
        Intersection(id="INT-SCH", name="Scheme No 54 Square", district="Scheme 54", lat=22.7386, lng=75.8897),
        Intersection(id="INT-ABR", name="AB Road - MR 10 Junction", district="AB Road", lat=22.7453, lng=75.8822),
        Intersection(id="INT-BMB", name="Bombay Hospital Chouraha", district="Ring Road", lat=22.7515, lng=75.8770),
        Intersection(id="INT-RPR", name="Rau-Pithampur Road Junction", district="Rau", lat=22.6654, lng=75.8672),
        Intersection(id="INT-MHW", name="Mhow Naka Square", district="Mhow Naka", lat=22.6963, lng=75.8563),
    ]
    db.add_all(intersections)
    db.flush()

    # --- Edges (bidirectional roads with travel times in seconds) ---
    road_segments = [
        ("INT-VJY", "INT-SCH", 120),   # Vijay Nagar -> Scheme 54
        ("INT-VJY", "INT-ABR", 90),    # Vijay Nagar -> AB Road
        ("INT-VJY", "INT-BMB", 100),   # Vijay Nagar -> Bombay Hospital
        ("INT-SCH", "INT-PAL", 150),   # Scheme 54 -> Palasia
        ("INT-SCH", "INT-MGL", 80),    # Scheme 54 -> MG Road
        ("INT-ABR", "INT-BMB", 60),    # AB Road -> Bombay Hospital
        ("INT-ABR", "INT-BHW", 120),   # AB Road -> Bhanwar Kuwa
        ("INT-PAL", "INT-MGL", 60),    # Palasia -> MG Road
        ("INT-PAL", "INT-GPR", 90),    # Palasia -> Geeta Bhawan
        ("INT-MGL", "INT-BHW", 70),    # MG Road -> Bhanwar Kuwa
        ("INT-BHW", "INT-GPR", 80),    # Bhanwar Kuwa -> Geeta Bhawan
        ("INT-BHW", "INT-RJW", 60),    # Bhanwar Kuwa -> Rajwada
        ("INT-GPR", "INT-RJW", 45),    # Geeta Bhawan -> Rajwada
        ("INT-RJW", "INT-SRV", 50),    # Rajwada -> Sarwate
        ("INT-SRV", "INT-MHW", 120),   # Sarwate -> Mhow Naka
        ("INT-MHW", "INT-RPR", 240),   # Mhow Naka -> Rau
        ("INT-BMB", "INT-BHW", 150),   # Bombay Hospital -> Bhanwar Kuwa
    ]

    imap = {i.id: i for i in intersections}
    for from_id, to_id, base_time in road_segments:
        dist = haversine(imap[from_id].lat, imap[from_id].lng, imap[to_id].lat, imap[to_id].lng)
        db.add(Edge(from_id=from_id, to_id=to_id, base_travel_time=base_time, current_weight=base_time, distance_meters=dist))
        db.add(Edge(from_id=to_id, to_id=from_id, base_travel_time=base_time, current_weight=base_time, distance_meters=dist))

    # --- Vehicles ---
    vehicles = [
        Vehicle(id="AMB-01", type="ambulance", name="Ambulance Alpha", registration="MP-09-AB-1234", current_lat=22.7196, current_lng=75.8577),
        Vehicle(id="AMB-02", type="ambulance", name="Ambulance Bravo", registration="MP-09-AB-5678", current_lat=22.7533, current_lng=75.8937),
        Vehicle(id="AMB-03", type="ambulance", name="Ambulance Charlie", registration="MP-09-AC-9012", current_lat=22.7134, current_lng=75.8621),
        Vehicle(id="FIR-01", type="fire", name="Fire Engine Alpha", registration="MP-09-FE-1001", current_lat=22.7236, current_lng=75.8798),
        Vehicle(id="FIR-02", type="fire", name="Fire Engine Bravo", registration="MP-09-FE-2002", current_lat=22.6963, current_lng=75.8563),
        Vehicle(id="POL-01", type="police", name="Police Patrol Alpha", registration="MP-09-PL-3001", current_lat=22.7271, current_lng=75.8835),
        Vehicle(id="POL-02", type="police", name="Police Patrol Bravo", registration="MP-09-PL-4002", current_lat=22.7453, current_lng=75.8822),
    ]
    db.add_all(vehicles)
    db.flush()

    # --- Users ---
    users = [
        User(name="Rahul Sharma", email="driver@pulse.com", password_hash=hash_password("password123"), role="driver", phone="+91-9876543210", vehicle_id="AMB-01"),
        User(name="Priya Verma", email="driver2@pulse.com", password_hash=hash_password("password123"), role="driver", phone="+91-9876543211", vehicle_id="FIR-01"),
        User(name="Amit Patel", email="driver3@pulse.com", password_hash=hash_password("password123"), role="driver", phone="+91-9876543212", vehicle_id="POL-01"),
        User(id="op-001", name="Suresh Joshi", email="operator@pulse.com", password_hash=hash_password("password123"), role="operator", phone="+91-9876543220"),
        User(id="op-002", name="Neha Gupta", email="operator2@pulse.com", password_hash=hash_password("password123"), role="operator", phone="+91-9876543221"),
        User(id="op-003", name="Vikram Singh", email="operator3@pulse.com", password_hash=hash_password("password123"), role="operator", phone="+91-9876543222"),
        User(id="op-004", name="Anita Rao", email="operator4@pulse.com", password_hash=hash_password("password123"), role="operator", phone="+91-9876543223"),
        User(id="op-005", name="Deepak Mishra", email="operator5@pulse.com", password_hash=hash_password("password123"), role="operator", phone="+91-9876543224"),
        User(id="op-006", name="Kavita Sharma", email="operator6@pulse.com", password_hash=hash_password("password123"), role="operator", phone="+91-9876543225"),
        User(name="Admin", email="admin@pulse.com", password_hash=hash_password("password123"), role="admin", phone="+91-9876543200"),
    ]
    db.add_all(users)
    db.flush()

    # --- Assign operators to intersections ---
    operator_assignments = {
        "INT-VJY": "op-001",  # Suresh Joshi at Vijay Nagar
        "INT-PAL": "op-001",  # Suresh Joshi also covers Palasia
        "INT-GPR": "op-002",  # Neha Gupta at Geeta Bhawan
        "INT-RJW": "op-002",  # Neha Gupta also covers Rajwada
        "INT-SRV": "op-003",  # Vikram Singh at Sarwate
        "INT-MGL": "op-003",  # Vikram Singh also covers MG Road
        "INT-BHW": "op-004",  # Anita Rao at Bhanwar Kuwa
        "INT-SCH": "op-004",  # Anita Rao also covers Scheme 54
        "INT-ABR": "op-005",  # Deepak Mishra at AB Road
        "INT-BMB": "op-005",  # Deepak Mishra also covers Bombay Hospital
        "INT-RPR": "op-006",  # Kavita Sharma at Rau
        "INT-MHW": "op-006",  # Kavita Sharma also covers Mhow Naka
    }
    for iid, oid in operator_assignments.items():
        inter = db.query(Intersection).filter(Intersection.id == iid).first()
        if inter:
            inter.assigned_operator_id = oid

    # --- Hospitals (real Indore hospitals) ---
    hospitals = [
        Hospital(name="MY Hospital (Govt)", lat=22.7175, lng=75.8558, address="MY Hospital Road, Indore", phone="+91-731-2527383"),
        Hospital(name="Bombay Hospital Indore", lat=22.7515, lng=75.8770, address="Ring Road, Indore", phone="+91-731-2581111"),
        Hospital(name="CHL Hospital", lat=22.7380, lng=75.8930, address="AB Road, Scheme 54, Indore", phone="+91-731-2550100"),
        Hospital(name="Choithram Hospital", lat=22.6960, lng=75.8490, address="Manik Bagh Road, Indore", phone="+91-731-2362491"),
        Hospital(name="Medanta Super Speciality Hospital", lat=22.7560, lng=75.9100, address="AB Road, Vijay Nagar, Indore", phone="+91-731-4988888"),
        Hospital(name="SAIMS Hospital", lat=22.6830, lng=75.8640, address="Bhawarkua-Sanwer Road, Indore", phone="+91-731-4233333"),
        Hospital(name="Gokuldas Hospital", lat=22.7200, lng=75.8610, address="511, MG Road, Indore", phone="+91-731-2432222"),
        Hospital(name="Aurobindo Hospital", lat=22.7610, lng=75.9050, address="Sanwer Road, Indore", phone="+91-731-4231800"),
        Hospital(name="Index Medical College Hospital", lat=22.6500, lng=75.8700, address="Nemawar Road, Indore", phone="+91-731-2850100"),
        Hospital(name="Greater Kailash Hospital", lat=22.7310, lng=75.8800, address="LIG Colony, Indore", phone="+91-731-2490300"),
        Hospital(name="Apollo Rajshree Hospital", lat=22.7390, lng=75.8650, address="Opposite High Court, Indore", phone="+91-731-2573333"),
        Hospital(name="Vishesh Hospital", lat=22.7280, lng=75.8570, address="Yeshwant Colony, Indore", phone="+91-731-4066666"),
    ]
    db.add_all(hospitals)

    db.commit()
    db.close()
    print("Database seeded successfully with Indore data!")
    print(f"  {len(intersections)} intersections")
    print(f"  {len(road_segments) * 2} edges (bidirectional)")
    print(f"  {len(vehicles)} vehicles")
    print(f"  {len(users)} users")
    print(f"  {len(hospitals)} hospitals")
    print("\nDemo credentials:")
    print("  Driver:   driver@pulse.com / password123")
    print("  Operator: operator@pulse.com / password123")
    print("  Admin:    admin@pulse.com / password123")


if __name__ == "__main__":
    seed()
