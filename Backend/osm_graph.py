"""
PULSE – Real intersection discovery from OpenStreetMap (Overpass API).
Finds road junctions + traffic signals in Indore, builds weighted graph.
"""
import math, json
from pathlib import Path
from collections import Counter

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
CACHE_FILE = Path(__file__).parent / "osm_graph_cache.json"
BBOX = "22.68,75.83,22.84,75.96"  # Indore + AITR campus area
ROAD_SPEEDS = {"trunk": 14, "primary": 12, "secondary": 10, "tertiary": 8,
               "primary_link": 11, "secondary_link": 9, "tertiary_link": 7}


def _haversine(lat1, lon1, lat2, lon2):
    R = 6371000
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = math.radians(lat2 - lat1), math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def fetch_osm_intersections():
    """Fetch road junctions from Overpass API. Returns (nodes_dict, edges_list)."""
    import httpx

    query = f"""
    [out:json][timeout:45];
    way["highway"~"trunk|primary|secondary|tertiary|primary_link|secondary_link|tertiary_link"]({BBOX});
    out body;
    >;
    out skel qt;
    """
    resp = httpx.post(OVERPASS_URL, data={"data": query}, timeout=60)
    resp.raise_for_status()
    data = resp.json()

    node_coords = {}
    ways = []
    for el in data["elements"]:
        if el["type"] == "node":
            node_coords[el["id"]] = {"lat": el["lat"], "lng": el["lon"],
                                      "tags": el.get("tags", {})}
        elif el["type"] == "way":
            tags = el.get("tags", {})
            ways.append({"id": el["id"], "nodes": el["nodes"],
                         "highway": tags.get("highway", "secondary"),
                         "name": tags.get("name", "")})

    # Count how many ways each node belongs to
    node_way_count = Counter()
    node_way_names = {}
    for way in ways:
        for nid in way["nodes"]:
            node_way_count[nid] += 1
            if way["name"]:
                node_way_names.setdefault(nid, set()).add(way["name"])

    # Intersections = nodes on 3+ roads, or traffic signals on 2+ roads
    intersections = {}
    idx = 0
    for nid, count in node_way_count.items():
        if nid not in node_coords:
            continue
        nc = node_coords[nid]
        is_signal = nc["tags"].get("highway") == "traffic_signals"
        is_junction = count >= 3
        is_named = count >= 2 and len(node_way_names.get(nid, set())) >= 2

        if is_signal or is_junction or is_named:
            name = nc["tags"].get("name", "")
            if not name and nid in node_way_names:
                roads = sorted(node_way_names[nid])
                name = f"{roads[0]} × {roads[1]}" if len(roads) >= 2 else f"{roads[0]} Junction"
            if not name:
                name = f"Junction-{idx + 1}"
            intersections[nid] = {
                "lat": nc["lat"], "lng": nc["lng"], "name": name,
                "district": nc["tags"].get("addr:suburb", "Indore"),
                "is_signal": is_signal, "road_count": count,
            }
            idx += 1

    # Build edges between consecutive intersections on same road
    int_ids = set(intersections.keys())
    edges = []
    seen = set()
    for way in ways:
        ints_on_way = [(i, nid) for i, nid in enumerate(way["nodes"]) if nid in int_ids]
        for j in range(len(ints_on_way) - 1):
            idx_a, osm_a = ints_on_way[j]
            idx_b, osm_b = ints_on_way[j + 1]
            pair = tuple(sorted([osm_a, osm_b]))
            if pair in seen:
                continue
            seen.add(pair)
            dist = 0
            for k in range(idx_a, idx_b):
                n1, n2 = way["nodes"][k], way["nodes"][k + 1]
                if n1 in node_coords and n2 in node_coords:
                    c1, c2 = node_coords[n1], node_coords[n2]
                    dist += _haversine(c1["lat"], c1["lng"], c2["lat"], c2["lng"])
            if dist < 30:
                continue
            speed = ROAD_SPEEDS.get(way["highway"], 10)
            travel_time = max(5, dist / speed)
            for f, t in [(osm_a, osm_b), (osm_b, osm_a)]:
                edges.append({"from": f, "to": t, "dist_m": round(dist, 1),
                              "time_s": round(travel_time, 1), "road_type": way["highway"],
                              "road_name": way["name"]})

    connected = set()
    for e in edges:
        connected.add(e["from"])
        connected.add(e["to"])
    intersections = {k: v for k, v in intersections.items() if k in connected}

    # ── Phase 2: Add proximity edges to fix disconnected graph ──
    # OSM roads are split into many short segments, so topology alone
    # misses many obvious connections. Connect nearby intersections.
    all_ids = list(intersections.keys())
    for i in range(len(all_ids)):
        for j in range(i + 1, len(all_ids)):
            a, b = all_ids[i], all_ids[j]
            pair = tuple(sorted([a, b]))
            if pair in seen:
                continue
            na, nb = intersections[a], intersections[b]
            dist = _haversine(na["lat"], na["lng"], nb["lat"], nb["lng"])
            if dist < 500:  # 500m threshold
                seen.add(pair)
                travel_time = max(5, dist / 8)  # ~8 m/s city speed
                for f, t in [(a, b), (b, a)]:
                    edges.append({"from": f, "to": t, "dist_m": round(dist, 1),
                                  "time_s": round(travel_time, 1), "road_type": "tertiary",
                                  "road_name": ""})

    # ── Phase 3: Ensure single connected component ──
    from collections import deque
    adj = {nid: set() for nid in intersections}
    for e in edges:
        if e["from"] in adj and e["to"] in adj:
            adj[e["from"]].add(e["to"])

    def bfs_component(start):
        vis = set()
        q = deque([start])
        while q:
            n = q.popleft()
            if n in vis: continue
            vis.add(n)
            for nb in adj.get(n, []):
                if nb not in vis: q.append(nb)
        return vis

    visited_all = set()
    components = []
    for nid in intersections:
        if nid not in visited_all:
            comp = bfs_component(nid)
            components.append(comp)
            visited_all |= comp
    components.sort(key=len, reverse=True)

    # Connect smaller components to the largest via shortest link
    if len(components) > 1:
        main = components[0]
        for comp in components[1:]:
            best_dist = float("inf")
            best_a, best_b = None, None
            for a in comp:
                na = intersections[a]
                for b in main:
                    nb = intersections[b]
                    d = _haversine(na["lat"], na["lng"], nb["lat"], nb["lng"])
                    if d < best_dist:
                        best_dist = d
                        best_a, best_b = a, b
            if best_a and best_b:
                travel_time = max(5, best_dist / 8)
                for f, t in [(best_a, best_b), (best_b, best_a)]:
                    edges.append({"from": f, "to": t, "dist_m": round(best_dist, 1),
                                  "time_s": round(travel_time, 1), "road_type": "tertiary",
                                  "road_name": ""})
                main |= comp

    print(f"  Graph stitching: {len(components)} components → 1 connected graph")
    return intersections, edges


def load_graph():
    """Load from cache or fetch from OSM."""
    if CACHE_FILE.exists():
        try:
            with open(CACHE_FILE) as f:
                data = json.load(f)
            print(f"✓ Loaded OSM graph cache: {len(data['nodes'])} intersections, {len(data['edges'])} edges")
            return data["nodes"], data["edges"]
        except Exception:
            pass
    try:
        nodes, edges = fetch_osm_intersections()
        if nodes and edges:
            cache = {"nodes": {str(k): v for k, v in nodes.items()}, "edges": edges}
            with open(CACHE_FILE, "w") as f:
                json.dump(cache, f)
            print(f"✓ Fetched from OSM: {len(nodes)} intersections, {len(edges)} edges")
            return cache["nodes"], edges
    except Exception as e:
        print(f"⚠ OSM fetch failed: {e}")
    return {}, []


def clear_cache():
    if CACHE_FILE.exists():
        CACHE_FILE.unlink()
        print("OSM cache cleared")
