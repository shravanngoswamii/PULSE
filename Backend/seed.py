"""Seed the database – uses real OpenStreetMap intersections (with curated fallback)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))

from database import engine, SessionLocal, Base
from models import User, Vehicle, Intersection, Edge, Hospital
from auth import hash_password
from graph_engine import haversine


# ── Curated fallback: 30 real Indore intersections ──────────────────
FALLBACK_INTERSECTIONS = [
    ("INT-001", "Vijay Nagar Square", "Vijay Nagar", 22.7533, 75.8937),
    ("INT-002", "Palasia Square", "Palasia", 22.7236, 75.8798),
    ("INT-003", "Geeta Bhawan Square", "Geeta Bhawan", 22.7196, 75.8577),
    ("INT-004", "Rajwada Square", "Rajwada", 22.7185, 75.8571),
    ("INT-005", "Sarwate Bus Stand", "Sarwate", 22.7134, 75.8621),
    ("INT-006", "MG Road Junction", "MG Road", 22.7271, 75.8835),
    ("INT-007", "Bhanwar Kuwa Square", "Bhanwar Kuwa", 22.7299, 75.8656),
    ("INT-008", "Scheme 54 Square", "Scheme 54", 22.7386, 75.8897),
    ("INT-009", "AB Road – MR10 Junction", "AB Road", 22.7453, 75.8822),
    ("INT-010", "Bombay Hospital Chouraha", "Ring Road", 22.7515, 75.8770),
    ("INT-011", "Rau–Pithampur Rd Junction", "Rau", 22.6654, 75.8672),
    ("INT-012", "Mhow Naka Square", "Mhow Naka", 22.6963, 75.8563),
    ("INT-013", "Sapna Sangeeta Road", "Sapna Sangeeta", 22.7267, 75.8892),
    ("INT-014", "Race Course Road", "Race Course", 22.7281, 75.8755),
    ("INT-015", "Navlakha Square", "Navlakha", 22.7244, 75.8708),
    ("INT-016", "GPO Square", "GPO", 22.7192, 75.8623),
    ("INT-017", "High Court Chouraha", "High Court", 22.7355, 75.8655),
    ("INT-018", "Tejaji Nagar Square", "Tejaji Nagar", 22.7485, 75.9010),
    ("INT-019", "LIG Square", "LIG Colony", 22.7295, 75.8825),
    ("INT-020", "Panchsheel Nagar", "Panchsheel", 22.7570, 75.8900),
    ("INT-021", "Bhawarkuan Square", "Bhawarkuan", 22.7120, 75.8680),
    ("INT-022", "MR9 Road Junction", "MR9", 22.7400, 75.9050),
    ("INT-023", "Annapurna Road Junction", "Annapurna", 22.7310, 75.8530),
    ("INT-024", "Mahalaxmi Nagar", "Mahalaxmi", 22.7333, 75.8975),
    ("INT-025", "Sudama Nagar Chouraha", "Sudama Nagar", 22.7105, 75.8530),
    ("INT-026", "Silicon City Junction", "Silicon City", 22.7580, 75.9100),
    ("INT-027", "Nandlalpura Square", "Nandlalpura", 22.7148, 75.8700),
    ("INT-028", "Old Palasia Crossing", "Old Palasia", 22.7220, 75.8755),
    ("INT-029", "Laxmi Bai Nagar", "Laxmi Bai Nagar", 22.7055, 75.8580),
    ("INT-030", "Ring Road–AB Road Flyover", "Ring Road", 22.7490, 75.8850),
]

FALLBACK_EDGES = [
    ("INT-001", "INT-008", 120), ("INT-001", "INT-009", 90), ("INT-001", "INT-010", 100),
    ("INT-001", "INT-018", 130), ("INT-001", "INT-020", 110),
    ("INT-008", "INT-002", 150), ("INT-008", "INT-006", 80), ("INT-008", "INT-024", 90),
    ("INT-008", "INT-022", 100),
    ("INT-009", "INT-010", 60), ("INT-009", "INT-007", 120), ("INT-009", "INT-030", 50),
    ("INT-002", "INT-006", 60), ("INT-002", "INT-003", 90), ("INT-002", "INT-013", 55),
    ("INT-002", "INT-028", 40),
    ("INT-006", "INT-007", 70), ("INT-006", "INT-019", 30), ("INT-006", "INT-014", 50),
    ("INT-006", "INT-013", 45),
    ("INT-007", "INT-003", 80), ("INT-007", "INT-004", 60), ("INT-007", "INT-017", 70),
    ("INT-007", "INT-015", 55), ("INT-007", "INT-014", 60),
    ("INT-003", "INT-004", 45), ("INT-003", "INT-016", 40),
    ("INT-004", "INT-005", 50), ("INT-004", "INT-016", 35),
    ("INT-005", "INT-012", 120), ("INT-005", "INT-021", 50), ("INT-005", "INT-027", 40),
    ("INT-005", "INT-025", 55), ("INT-005", "INT-029", 60),
    ("INT-012", "INT-011", 240), ("INT-012", "INT-029", 100),
    ("INT-010", "INT-007", 150), ("INT-010", "INT-030", 40), ("INT-010", "INT-020", 90),
    ("INT-013", "INT-019", 40),
    ("INT-014", "INT-015", 50), ("INT-014", "INT-028", 45),
    ("INT-015", "INT-016", 55), ("INT-015", "INT-023", 70),
    ("INT-016", "INT-021", 50),
    ("INT-017", "INT-009", 85), ("INT-017", "INT-023", 65),
    ("INT-018", "INT-022", 80), ("INT-018", "INT-026", 120),
    ("INT-020", "INT-026", 100), ("INT-020", "INT-030", 60),
    ("INT-021", "INT-027", 45), ("INT-021", "INT-025", 50),
    ("INT-022", "INT-024", 70),
    ("INT-023", "INT-003", 85),
    ("INT-024", "INT-013", 80),
    ("INT-027", "INT-028", 55),
    ("INT-028", "INT-003", 70),
]


def seed():
    Base.metadata.drop_all(bind=engine)
    Base.metadata.create_all(bind=engine)
    db = SessionLocal()

    # ── Try OSM first, fall back to curated ─────────────────────────
    osm_nodes, osm_edges = {}, []
    try:
        from osm_graph import load_graph
        osm_nodes, osm_edges = load_graph()
    except Exception as e:
        print(f"OSM graph unavailable: {e}")

    if osm_nodes and len(osm_nodes) >= 5:
        print(f"Using OSM intersections: {len(osm_nodes)} nodes, {len(osm_edges)} edges")
        for nid, info in osm_nodes.items():
            db.add(Intersection(
                id=f"OSM-{nid}", name=info["name"],
                district=info.get("district", "Indore"),
                lat=info["lat"], lng=info["lng"],
            ))
        db.flush()
        for e in osm_edges:
            from_id, to_id = f"OSM-{e['from']}", f"OSM-{e['to']}"
            db.add(Edge(
                from_id=from_id, to_id=to_id,
                base_travel_time=e["time_s"], current_weight=e["time_s"],
                distance_meters=e["dist_m"],
            ))
    else:
        print("Using curated Indore intersections (30 nodes)")
        for iid, name, district, lat, lng in FALLBACK_INTERSECTIONS:
            db.add(Intersection(id=iid, name=name, district=district, lat=lat, lng=lng))
        db.flush()
        imap = {i[0]: i for i in FALLBACK_INTERSECTIONS}
        for from_id, to_id, base_time in FALLBACK_EDGES:
            f, t = imap[from_id], imap[to_id]
            dist = haversine(f[3], f[4], t[3], t[4])
            db.add(Edge(from_id=from_id, to_id=to_id,
                        base_travel_time=base_time, current_weight=base_time,
                        distance_meters=dist))
            db.add(Edge(from_id=to_id, to_id=from_id,
                        base_travel_time=base_time, current_weight=base_time,
                        distance_meters=dist))

    # ── Vehicles ────────────────────────────────────────────────────
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

    # ── Users ───────────────────────────────────────────────────────
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

    # Assign operators round-robin to intersections
    operators = ["op-001", "op-002", "op-003", "op-004", "op-005", "op-006"]
    all_ints = db.query(Intersection).all()
    for i, inter in enumerate(all_ints):
        inter.assigned_operator_id = operators[i % len(operators)]

    # ── Hospitals ───────────────────────────────────────────────────
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

    n_ints = len(osm_nodes) if osm_nodes else len(FALLBACK_INTERSECTIONS)
    print(f"\n✓ Database seeded successfully!")
    print(f"  {n_ints} intersections ({'OSM' if osm_nodes else 'curated'})")
    print(f"  {len(vehicles)} vehicles | {len(users)} users | {len(hospitals)} hospitals")
    print(f"\nDemo: driver@pulse.com / password123")


if __name__ == "__main__":
    seed()
