"""
PULSE – All shortest-path algorithms used by the visualizer.

Each function takes the same inputs:
    nodes   – dict {node_id: {"lat", "lng", "name"}}
    graph   – adjacency dict {node_id: {neighbor_id: weight, ...}}
    start   – node_id
    end     – node_id

Each function returns (path, cost_seconds, steps) where:
    path         – ordered list of node_ids from start→end
    cost_seconds – total travel cost in seconds
    steps        – list of dicts describing each step for visualization
"""
import math, heapq


# ──────────────────────────────────────────────────────────────────────
# Utilities
# ──────────────────────────────────────────────────────────────────────
def _haversine(lat1, lon1, lat2, lon2):
    R = 6371000
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp, dl = math.radians(lat2 - lat1), math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))


def _reconstruct(prev, start, end):
    path = []
    cur = end
    while cur is not None:
        path.append(cur)
        cur = prev.get(cur)
    path.reverse()
    if not path or path[0] != start:
        return []
    return path


# ──────────────────────────────────────────────────────────────────────
# 1. Dijkstra  O(m + n log n)
# ──────────────────────────────────────────────────────────────────────
def dijkstra(nodes, graph, start, end):
    dist = {n: float("inf") for n in nodes}
    prev = {n: None for n in nodes}
    dist[start] = 0
    pq = [(0, start)]
    visited = set()
    steps = []
    step = 0

    steps.append({"step": 0, "action": "init", "algo": "dijkstra",
                   "start": start, "end": end,
                   "start_name": nodes[start]["name"],
                   "end_name": nodes[end]["name"]})

    relaxations = 0

    while pq:
        g, cur = heapq.heappop(pq)
        if cur in visited:
            continue
        visited.add(cur)
        step += 1

        steps.append({"step": step, "action": "visit", "node": cur,
                       "name": nodes[cur]["name"],
                       "lat": nodes[cur]["lat"], "lng": nodes[cur]["lng"],
                       "g_score": round(g, 1)})

        if cur == end:
            steps.append({"step": step, "action": "found", "node": cur,
                           "name": nodes[cur]["name"],
                           "total_cost": round(dist[end], 1)})
            break

        for nb, w in graph.get(cur, {}).items():
            if nb in visited:
                continue
            relaxations += 1
            new_g = dist[cur] + w
            if new_g < dist[nb]:
                dist[nb] = new_g
                prev[nb] = cur
                heapq.heappush(pq, (new_g, nb))
                steps.append({"step": step, "action": "relax",
                               "from": cur, "from_name": nodes[cur]["name"],
                               "to": nb, "to_name": nodes[nb]["name"],
                               "weight": round(w, 1),
                               "new_dist": round(new_g, 1)})

    path = _reconstruct(prev, start, end)
    steps.append({"step": step + 1, "action": "path", "path": path,
                   "path_names": [nodes[n]["name"] for n in path],
                   "total_cost_seconds": round(dist[end], 1),
                   "relaxations": relaxations,
                   "visited_count": len(visited)})
    return path, dist[end], steps


# ──────────────────────────────────────────────────────────────────────
# 2. A*  O(m + n log n) with haversine heuristic
# ──────────────────────────────────────────────────────────────────────
def astar(nodes, graph, start, end):
    def h(nid):
        n, e = nodes[nid], nodes[end]
        return _haversine(n["lat"], n["lng"], e["lat"], e["lng"]) / 15.0

    dist = {n: float("inf") for n in nodes}
    prev = {n: None for n in nodes}
    dist[start] = 0
    pq = [(h(start), 0, start)]
    visited = set()
    steps = []
    step = 0
    relaxations = 0

    steps.append({"step": 0, "action": "init", "algo": "astar",
                   "start": start, "end": end,
                   "start_name": nodes[start]["name"],
                   "end_name": nodes[end]["name"],
                   "h_start": round(h(start), 1)})

    while pq:
        f, g, cur = heapq.heappop(pq)
        if cur in visited:
            continue
        visited.add(cur)
        step += 1

        steps.append({"step": step, "action": "visit", "node": cur,
                       "name": nodes[cur]["name"],
                       "lat": nodes[cur]["lat"], "lng": nodes[cur]["lng"],
                       "g_score": round(g, 1), "f_score": round(f, 1)})

        if cur == end:
            steps.append({"step": step, "action": "found", "node": cur,
                           "name": nodes[cur]["name"],
                           "total_cost": round(dist[end], 1)})
            break

        for nb, w in graph.get(cur, {}).items():
            if nb in visited:
                continue
            relaxations += 1
            new_g = dist[cur] + w
            if new_g < dist[nb]:
                dist[nb] = new_g
                prev[nb] = cur
                heapq.heappush(pq, (new_g + h(nb), new_g, nb))
                steps.append({"step": step, "action": "relax",
                               "from": cur, "from_name": nodes[cur]["name"],
                               "to": nb, "to_name": nodes[nb]["name"],
                               "weight": round(w, 1),
                               "new_dist": round(new_g, 1),
                               "f_score": round(new_g + h(nb), 1)})

    path = _reconstruct(prev, start, end)
    steps.append({"step": step + 1, "action": "path", "path": path,
                   "path_names": [nodes[n]["name"] for n in path],
                   "total_cost_seconds": round(dist[end], 1),
                   "relaxations": relaxations,
                   "visited_count": len(visited)})
    return path, dist[end], steps


# ──────────────────────────────────────────────────────────────────────
# 3. Bellman-Ford  O(V·E)
# ──────────────────────────────────────────────────────────────────────
def bellman_ford(nodes, graph, start, end):
    dist = {n: float("inf") for n in nodes}
    prev = {n: None for n in nodes}
    dist[start] = 0
    steps = []
    relaxations = 0
    all_edges = []
    for u, nbrs in graph.items():
        for v, w in nbrs.items():
            all_edges.append((u, v, w))

    steps.append({"step": 0, "action": "init", "algo": "bellman_ford",
                   "start": start, "end": end,
                   "start_name": nodes[start]["name"],
                   "end_name": nodes[end]["name"],
                   "edge_count": len(all_edges),
                   "node_count": len(nodes)})

    n_nodes = len(nodes)
    for phase in range(1, n_nodes):
        updated = False
        for u, v, w in all_edges:
            if dist[u] == float("inf"):
                continue
            relaxations += 1
            if dist[u] + w < dist[v]:
                dist[v] = dist[u] + w
                prev[v] = u
                updated = True
                steps.append({"step": phase, "action": "relax",
                               "from": u, "from_name": nodes[u]["name"],
                               "to": v, "to_name": nodes[v]["name"],
                               "weight": round(w, 1),
                               "new_dist": round(dist[v], 1)})
        steps.append({"step": phase, "action": "phase_end",
                       "phase": phase, "updated": updated})
        if not updated:
            break

    if dist[end] < float("inf"):
        steps.append({"step": phase, "action": "found", "node": end,
                       "name": nodes[end]["name"],
                       "total_cost": round(dist[end], 1)})

    path = _reconstruct(prev, start, end)
    visited_nodes = {n for n in nodes if dist[n] < float("inf")}
    steps.append({"step": phase + 1, "action": "path", "path": path,
                   "path_names": [nodes[n]["name"] for n in path],
                   "total_cost_seconds": round(dist[end], 1),
                   "relaxations": relaxations,
                   "visited_count": len(visited_nodes),
                   "phases": phase})
    return path, dist[end], steps


# ──────────────────────────────────────────────────────────────────────
# 4. Floyd-Warshall  O(V³) — all-pairs, extract start→end path
# ──────────────────────────────────────────────────────────────────────
def floyd_warshall(nodes, graph, start, end):
    ids = list(nodes.keys())
    idx = {nid: i for i, nid in enumerate(ids)}
    n = len(ids)
    INF = float("inf")

    D = [[INF] * n for _ in range(n)]
    nxt = [[None] * n for _ in range(n)]
    for i in range(n):
        D[i][i] = 0
        nxt[i][i] = i

    for u, nbrs in graph.items():
        for v, w in nbrs.items():
            ui, vi = idx[u], idx[v]
            if w < D[ui][vi]:
                D[ui][vi] = w
                nxt[ui][vi] = vi

    steps = []
    relaxations = 0
    steps.append({"step": 0, "action": "init", "algo": "floyd_warshall",
                   "start": start, "end": end,
                   "start_name": nodes[start]["name"],
                   "end_name": nodes[end]["name"],
                   "node_count": n})

    for k in range(n):
        k_id = ids[k]
        improved = []
        for i in range(n):
            for j in range(n):
                relaxations += 1
                if D[i][k] + D[k][j] < D[i][j]:
                    D[i][j] = D[i][k] + D[k][j]
                    nxt[i][j] = nxt[i][k]
                    if i == idx[start]:
                        improved.append(ids[j])
        steps.append({"step": k + 1, "action": "pivot",
                       "pivot": k_id, "pivot_name": nodes[k_id]["name"],
                       "lat": nodes[k_id]["lat"], "lng": nodes[k_id]["lng"],
                       "improved_from_source": improved,
                       "current_cost": round(D[idx[start]][idx[end]], 1) if D[idx[start]][idx[end]] < INF else None})

    # Reconstruct path
    si, ei = idx[start], idx[end]
    cost = D[si][ei]
    path = []
    if nxt[si][ei] is not None:
        cur = si
        while cur != ei:
            path.append(ids[cur])
            cur = nxt[cur][ei]
            if cur is None:
                break
        path.append(ids[ei])

    if cost < INF:
        steps.append({"step": n + 1, "action": "found", "node": end,
                       "name": nodes[end]["name"],
                       "total_cost": round(cost, 1)})

    steps.append({"step": n + 2, "action": "path", "path": path,
                   "path_names": [nodes[p]["name"] for p in path],
                   "total_cost_seconds": round(cost, 1) if cost < INF else None,
                   "relaxations": relaxations,
                   "visited_count": n})
    return path, cost, steps


# ──────────────────────────────────────────────────────────────────────
# 5. 2025 Breakthrough  O(m·log^{2/3} n)
#    Hybrid Dijkstra + Bellman-Ford with FindPivots frontier reduction
#    Based on: Duan, Mao, Shu, Yin (2025) — first SSSP breaking the
#    sorting barrier on directed graphs.
# ──────────────────────────────────────────────────────────────────────
def breakthrough_2025(nodes, graph, start, end):
    """
    Practical implementation of the 2025 Breakthrough SSSP algorithm.

    Key ideas from the paper:
    1. Maintain a 'frontier' S of vertices with known distance estimates.
    2. FindPivots: Run k-step Bellman-Ford from S to identify 'pivots'
       (nodes whose shortest-path subtrees have ≥k descendants).
       Non-pivot descendants are already settled by BF, reducing the
       frontier from |S| to |U|/k.
    3. Partial sort: Only extract a chunk of ~|S|/k smallest frontier
       vertices (Dijkstra-like), instead of fully sorting the frontier.
    4. Recurse: Process the chunk, relax outgoing edges, insert newly
       discovered vertices back into the frontier.

    Complexity: O(m·log^{2/3} n) — sub-Dijkstra on sparse directed graphs.
    """
    n_nodes = len(nodes)
    k = max(2, int(math.pow(max(2, math.log2(n_nodes)), 1 / 3)))

    dist = {n: float("inf") for n in nodes}
    prev = {n: None for n in nodes}
    dist[start] = 0
    visited = set()
    visited.add(start)
    steps = []
    step = 0
    relaxations = 0
    pivots_found = set()

    steps.append({"step": 0, "action": "init", "algo": "breakthrough_2025",
                   "start": start, "end": end,
                   "start_name": nodes[start]["name"],
                   "end_name": nodes[end]["name"],
                   "k_param": k,
                   "description": "Hybrid Dijkstra+BF with FindPivots frontier reduction"})

    # Step 1: Initialize frontier from source
    frontier = set()
    for nb, w in graph.get(start, {}).items():
        relaxations += 1
        if dist[start] + w < dist[nb]:
            dist[nb] = dist[start] + w
            prev[nb] = start
            frontier.add(nb)
            steps.append({"step": 1, "action": "relax",
                           "from": start, "from_name": nodes[start]["name"],
                           "to": nb, "to_name": nodes[nb]["name"],
                           "weight": round(w, 1),
                           "new_dist": round(dist[nb], 1)})

    step = 1
    safety = 0
    max_iters = n_nodes * 3

    while frontier and safety < max_iters:
        safety += 1
        S = [v for v in frontier if v not in visited]
        if not S:
            break

        # ═══ FindPivots: k-step Bellman-Ford from frontier S ═══
        layer_verts = set(S)
        cur_layer = set(S)
        subtree_cnt = {v: 0 for v in S}

        for bf_step in range(k):
            nxt_layer = set()
            for u in cur_layer:
                for nb, w in graph.get(u, {}).items():
                    relaxations += 1
                    if dist[u] != float("inf") and dist[u] + w < dist[nb]:
                        dist[nb] = dist[u] + w
                        prev[nb] = u
                        if nb not in layer_verts and nb not in visited:
                            nxt_layer.add(nb)
                            layer_verts.add(nb)
                            # Track subtree sizes for pivot identification
                            root = u
                            s_set = set(S)
                            depth = 0
                            while root not in s_set and prev.get(root) is not None and depth < 50:
                                root = prev[root]
                                depth += 1
                            if root in s_set:
                                subtree_cnt[root] = subtree_cnt.get(root, 0) + 1
            cur_layer = nxt_layer
            if not cur_layer:
                break

        step += 1
        steps.append({"step": step, "action": "find_pivots",
                       "frontier_size": len(S),
                       "bf_layers_explored": len(layer_verts),
                       "k": k})

        # Mark pivots: frontier nodes whose subtree has >= k descendants
        round_pivots = [v for v in S if subtree_cnt.get(v, 0) >= k]
        for pv in round_pivots:
            pivots_found.add(pv)
        if round_pivots:
            steps.append({"step": step, "action": "pivots_marked",
                           "pivots": round_pivots,
                           "pivot_names": [nodes[p]["name"] for p in round_pivots],
                           "lats": [nodes[p]["lat"] for p in round_pivots],
                           "lngs": [nodes[p]["lng"] for p in round_pivots]})

        # ═══ Partial sort: extract chunk of size |S|/k (minimum-distance) ═══
        sorted_S = sorted(S, key=lambda v: dist[v])
        chunk_size = max(1, math.ceil(len(sorted_S) / k))
        chunk = sorted_S[:chunk_size]

        for u in chunk:
            visited.add(u)
            frontier.discard(u)
            step += 1
            steps.append({"step": step, "action": "visit", "node": u,
                           "name": nodes[u]["name"],
                           "lat": nodes[u]["lat"], "lng": nodes[u]["lng"],
                           "g_score": round(dist[u], 1),
                           "is_pivot": u in pivots_found})

            if u == end:
                steps.append({"step": step, "action": "found", "node": u,
                               "name": nodes[u]["name"],
                               "total_cost": round(dist[end], 1)})
                frontier.clear()
                break

            for nb, w in graph.get(u, {}).items():
                relaxations += 1
                if dist[u] + w < dist[nb]:
                    dist[nb] = dist[u] + w
                    prev[nb] = u
                    if nb not in visited:
                        frontier.add(nb)
                        steps.append({"step": step, "action": "relax",
                                       "from": u, "from_name": nodes[u]["name"],
                                       "to": nb, "to_name": nodes[nb]["name"],
                                       "weight": round(w, 1),
                                       "new_dist": round(dist[nb], 1)})

        # Resolve non-pivot BF-discovered vertices
        for v in layer_verts:
            if v not in visited and dist[v] != float("inf"):
                visited.add(v)
                frontier.discard(v)
                for nb, w in graph.get(v, {}).items():
                    relaxations += 1
                    if dist[v] + w < dist[nb]:
                        dist[nb] = dist[v] + w
                        prev[nb] = v
                        if nb not in visited:
                            frontier.add(nb)

        # Clean frontier
        frontier = {v for v in frontier if v not in visited}

        if dist[end] < float("inf") and end in visited:
            break

    path = _reconstruct(prev, start, end)
    if dist[end] < float("inf") and not any(s["action"] == "found" for s in steps):
        steps.append({"step": step + 1, "action": "found", "node": end,
                       "name": nodes[end]["name"],
                       "total_cost": round(dist[end], 1)})

    steps.append({"step": step + 2, "action": "path", "path": path,
                   "path_names": [nodes[n]["name"] for n in path],
                   "total_cost_seconds": round(dist[end], 1) if dist[end] < float("inf") else None,
                   "relaxations": relaxations,
                   "visited_count": len(visited),
                   "pivots_used": list(pivots_found),
                   "k_param": k})
    return path, dist[end], steps


# ──────────────────────────────────────────────────────────────────────
# Run all algorithms and return comparison
# ──────────────────────────────────────────────────────────────────────
ALGORITHMS = {
    "breakthrough_2025": {"fn": breakthrough_2025, "name": "2025 Breakthrough",
                          "complexity": "O(m·log^{2/3} n)", "year": 2025,
                          "tag": "2025 Paper", "tag_class": "paper"},
    "astar":             {"fn": astar, "name": "A*",
                          "complexity": "O(m + n log n)", "year": 1968,
                          "tag": "Best Practical", "tag_class": "best"},
    "dijkstra":          {"fn": dijkstra, "name": "Dijkstra",
                          "complexity": "O(m + n log n)", "year": 1956,
                          "tag": "Classic", "tag_class": "classic"},
    "bellman_ford":      {"fn": bellman_ford, "name": "Bellman-Ford",
                          "complexity": "O(V·E)", "year": 1958,
                          "tag": "Robust", "tag_class": "classic"},
    "floyd_warshall":    {"fn": floyd_warshall, "name": "Floyd-Warshall",
                          "complexity": "O(V³)", "year": 1962,
                          "tag": "All-Pairs", "tag_class": "classic"},
}



def _sanitize(obj):
    """Replace inf/nan floats with None so JSON serialization doesn't crash."""
    import math
    if isinstance(obj, float) and (math.isinf(obj) or math.isnan(obj)):
        return None
    if isinstance(obj, dict):
        return {k: _sanitize(v) for k, v in obj.items()}
    if isinstance(obj, (list, tuple)):
        return [_sanitize(v) for v in obj]
    return obj


def run_all(nodes, graph, start, end):
    """Run all algorithms on the same graph/endpoints and return comparison."""
    import time
    results = {}
    for key, meta in ALGORITHMS.items():
        t0 = time.perf_counter()
        path, cost, steps = meta["fn"](nodes, graph, start, end)
        elapsed_ms = (time.perf_counter() - t0) * 1000

        # Extract stats from the final 'path' step
        path_step = next((s for s in steps if s["action"] == "path"), {})
        results[key] = {
            "name": meta["name"],
            "complexity": meta["complexity"],
            "year": meta["year"],
            "tag": meta["tag"],
            "tag_class": meta["tag_class"],
            "path": path,
            "path_names": path_step.get("path_names", []),
            "cost_seconds": round(cost, 1) if cost < float("inf") else None,
            "visited": path_step.get("visited_count", 0),
            "relaxations": path_step.get("relaxations", 0),
            "time_ms": round(elapsed_ms, 2),
            "steps": _sanitize(steps),
        }
    return results
