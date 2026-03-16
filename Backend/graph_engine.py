import math
from sqlalchemy.orm import Session
from schemas import GPSLocation


def haversine(lat1, lon1, lat2, lon2):
    """Distance in meters between two GPS points."""
    R = 6371000
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return R * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)))


def load_graph(db: Session) -> tuple[dict, dict]:
    """Load nodes and graph from DB. Returns (nodes_dict, graph_dict)."""
    from models import Intersection, Edge

    nodes = {}
    for i in db.query(Intersection).all():
        nodes[i.id] = {"lat": i.lat, "lng": i.lng, "name": i.name}

    graph = {nid: {} for nid in nodes}
    for e in db.query(Edge).all():
        if e.from_id in graph:
            graph[e.from_id][e.to_id] = e.current_weight

    return nodes, graph


def snap_to_node(lat: float, lng: float, nodes: dict) -> str:
    """Finds the closest intersection to a GPS coordinate."""
    closest = None
    min_dist = float("inf")
    for nid, coords in nodes.items():
        d = haversine(lat, lng, coords["lat"], coords["lng"])
        if d < min_dist:
            min_dist = d
            closest = nid
    return closest


def path_to_coordinates(path: list, nodes: dict) -> list[GPSLocation]:
    """Converts intersection ID path to GPS coordinates."""
    return [GPSLocation(lat=nodes[n]["lat"], lng=nodes[n]["lng"]) for n in path if n in nodes]


def calculate_eta(path: list, graph: dict) -> float:
    """Calculate ETA in minutes for a path through the graph."""
    if len(path) < 2:
        return 0.0
    total = sum(graph.get(path[i], {}).get(path[i + 1], 0) for i in range(len(path) - 1))
    return round(total / 60.0, 1)


def calculate_distance_km(path: list, nodes: dict) -> float:
    """Calculate total distance in km for a path."""
    if len(path) < 2:
        return 0.0
    total = 0.0
    for i in range(len(path) - 1):
        if path[i] in nodes and path[i + 1] in nodes:
            n1, n2 = nodes[path[i]], nodes[path[i + 1]]
            total += haversine(n1["lat"], n1["lng"], n2["lat"], n2["lng"])
    return round(total / 1000.0, 2)
