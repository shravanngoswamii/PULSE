"""
Routing service that combines:
1. A* algorithm on our intersection graph (for signal corridor planning)
2. OSRM for actual road-following polylines (for map display)
"""
import httpx
import math
import heapq
from typing import Dict, List, Tuple, Optional
from sqlalchemy.orm import Session
from models import Intersection, Edge
from schemas import GPSLocation


def haversine(lat1, lon1, lat2, lon2) -> float:
    """Distance in meters between two GPS points."""
    R = 6371000
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return R * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)))


def load_graph(db: Session) -> Tuple[dict, dict]:
    """Load nodes and adjacency list from DB."""
    nodes = {}
    for i in db.query(Intersection).all():
        nodes[i.id] = {"lat": i.lat, "lng": i.lng, "name": i.name}

    graph = {nid: {} for nid in nodes}
    for e in db.query(Edge).all():
        if e.from_id in graph:
            graph[e.from_id][e.to_id] = e.current_weight

    return nodes, graph


def snap_to_node(lat: float, lng: float, nodes: dict) -> str:
    """Find closest intersection to a GPS point."""
    closest = None
    min_dist = float("inf")
    for nid, c in nodes.items():
        d = haversine(lat, lng, c["lat"], c["lng"])
        if d < min_dist:
            min_dist = d
            closest = nid
    return closest


def find_intersections_on_route(
    origin_lat: float, origin_lng: float,
    dest_lat: float, dest_lng: float,
    nodes: dict, graph: dict,
) -> Tuple[List[str], List[dict]]:
    """
    A* shortest path through our intersection graph.
    Returns (path_ids, step_log) where step_log records each algorithm step for visualization.
    """
    start = snap_to_node(origin_lat, origin_lng, nodes)
    end = snap_to_node(dest_lat, dest_lng, nodes)

    if start == end:
        return [start], [{"step": 0, "action": "direct", "node": start, "message": "Origin and destination snap to same intersection"}]

    # A* with haversine heuristic
    def heuristic(node_id):
        n = nodes[node_id]
        e = nodes[end]
        return haversine(n["lat"], n["lng"], e["lat"], e["lng"]) / 15.0  # ~15 m/s avg speed -> seconds

    dist = {n: float("inf") for n in nodes}
    prev = {n: None for n in nodes}
    dist[start] = 0
    pq = [(heuristic(start), 0, start)]
    visited = set()
    steps = []
    step_num = 0

    steps.append({
        "step": step_num, "action": "init",
        "start": start, "end": end,
        "start_name": nodes[start]["name"],
        "end_name": nodes[end]["name"],
    })

    while pq:
        f_score, g_score, current = heapq.heappop(pq)
        if current in visited:
            continue
        visited.add(current)
        step_num += 1

        steps.append({
            "step": step_num, "action": "visit",
            "node": current, "name": nodes[current]["name"],
            "lat": nodes[current]["lat"], "lng": nodes[current]["lng"],
            "g_score": round(g_score, 1), "f_score": round(f_score, 1),
            "visited_count": len(visited),
        })

        if current == end:
            steps.append({"step": step_num, "action": "found", "node": current, "name": nodes[current]["name"], "total_cost": round(dist[end], 1)})
            break

        for neighbor, weight in graph.get(current, {}).items():
            if neighbor in visited:
                continue
            new_g = dist[current] + weight
            if new_g < dist[neighbor]:
                dist[neighbor] = new_g
                prev[neighbor] = current
                f = new_g + heuristic(neighbor)
                heapq.heappush(pq, (f, new_g, neighbor))
                steps.append({
                    "step": step_num, "action": "relax",
                    "from": current, "from_name": nodes[current]["name"],
                    "to": neighbor, "to_name": nodes[neighbor]["name"],
                    "weight": round(weight, 1), "new_dist": round(new_g, 1),
                    "f_score": round(f, 1),
                })

    # Reconstruct path
    path = []
    curr = end
    while curr:
        path.append(curr)
        curr = prev[curr]
    path.reverse()

    if path[0] != start:
        return [start, end], steps  # No path found, fallback

    steps.append({
        "step": step_num + 1, "action": "path",
        "path": path,
        "path_names": [nodes[n]["name"] for n in path],
        "total_cost_seconds": round(dist[end], 1),
    })

    return path, steps


async def get_osrm_route(
    origin_lat: float, origin_lng: float,
    dest_lat: float, dest_lng: float,
    waypoints: List[dict] = None,
) -> Tuple[List[GPSLocation], float, float]:
    """
    Get actual road-following route from OSRM (free, no API key).
    Returns (route_coordinates, distance_km, duration_minutes).
    """
    # Build coordinates string: origin;waypoint1;waypoint2;...;destination
    coords_parts = [f"{origin_lng},{origin_lat}"]
    if waypoints:
        for wp in waypoints:
            coords_parts.append(f"{wp['lng']},{wp['lat']}")
    coords_parts.append(f"{dest_lng},{dest_lat}")
    coords_str = ";".join(coords_parts)

    url = f"https://router.project-osrm.org/route/v1/driving/{coords_str}?overview=full&geometries=geojson"

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(url)
            data = resp.json()

        if data.get("code") != "Ok" or not data.get("routes"):
            return _fallback_route(origin_lat, origin_lng, dest_lat, dest_lng, waypoints), 0, 0

        route = data["routes"][0]
        geometry = route["geometry"]["coordinates"]  # [[lng, lat], ...]
        distance_km = route["distance"] / 1000.0
        duration_min = route["duration"] / 60.0

        route_coords = [GPSLocation(lat=coord[1], lng=coord[0]) for coord in geometry]
        return route_coords, round(distance_km, 2), round(duration_min, 1)

    except Exception:
        return _fallback_route(origin_lat, origin_lng, dest_lat, dest_lng, waypoints), 0, 0


def _fallback_route(origin_lat, origin_lng, dest_lat, dest_lng, waypoints) -> List[GPSLocation]:
    """Straight-line fallback if OSRM is unavailable."""
    coords = [GPSLocation(lat=origin_lat, lng=origin_lng)]
    if waypoints:
        for wp in waypoints:
            coords.append(GPSLocation(lat=wp["lat"], lng=wp["lng"]))
    coords.append(GPSLocation(lat=dest_lat, lng=dest_lng))
    return coords
