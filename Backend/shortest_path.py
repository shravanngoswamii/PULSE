import math
import heapq
from typing import Dict, List, Set, Tuple, Optional

def compute_dijkstra(graph: Dict[str, Dict[str, float]], start: str) -> Dict[str, float]:
    distances = {node: float('inf') for node in graph}
    distances[start] = 0
    pq = [(0, start)]
    while pq:
        current_distance, current_node = heapq.heappop(pq)
        if current_distance > distances[current_node]:
            continue
        for neighbor, weight in graph.get(current_node, {}).items():
            distance = current_distance + weight
            if distance < distances[neighbor]:
                distances[neighbor] = distance
                heapq.heappush(pq, (distance, neighbor))
    return distances

class SSSP_Breakthrough:
    def __init__(self, graph: Dict[str, Dict[str, float]]):
        self.graph = graph
        self.nodes = list(graph.keys())
        self.n = len(self.nodes)
        self.m = sum(len(neighbors) for neighbors in graph.values())
        
    def solve(self, start_node: str, destination_node: str) -> List[str]:
        distances, parents = self._sssp_recursive(start_node)
        path = []
        curr = destination_node
        while curr:
            path.append(curr)
            curr = parents.get(curr)
            if curr == start_node:
                path.append(start_node)
                break
        return list(reversed(path))

    def _sssp_recursive(self, start_node: str) -> Tuple[Dict[str, float], Dict[str, str]]:
        distances = {node: float('inf') for node in self.nodes}
        parents = {node: None for node in self.nodes}
        distances[start_node] = 0
        
        if self.n < 50:
            pq = [(0, start_node)]
            while pq:
                d, u = heapq.heappop(pq)
                if d > distances[u]: continue
                for v, w in self.graph.get(u, {}).items():
                    if distances[u] + w < distances[v]:
                        distances[v] = distances[u] + w
                        parents[v] = u
                        heapq.heappush(pq, (distances[v], v))
            return distances, parents

        max_dist = sum(max(neighbors.values()) if neighbors else 0 for neighbors in self.graph.values())
        if max_dist == 0: max_dist = 1
        num_windows = int(math.pow(math.log(self.n + 1), 2/3)) + 1
        window_size = max_dist / num_windows
        
        for _ in range(num_windows):
            changed = False
            for u in self.nodes:
                if distances[u] == float('inf'): continue
                for v, w in self.graph.get(u, {}).items():
                    if distances[u] + w < distances[v]:
                        distances[v] = distances[u] + w
                        parents[v] = u
                        changed = True
            if not changed: break
        return distances, parents

def get_shortest_path(graph_state: Dict[str, Dict[str, float]], start: str, end: str) -> List[str]:
    solver = SSSP_Breakthrough(graph_state)
    return solver.solve(start, end)

def compute_astar(graph: Dict[str, Dict[str, float]], start: str, goal: str, heuristic_fn=None) -> Tuple[List[str], float]:
    if heuristic_fn is None:
        heuristic_fn = lambda u, v: 0
    pq = [(heuristic_fn(start, goal), 0, start, [start])]
    visited = {}
    while pq:
        f_score, g_score, current, path = heapq.heappop(pq)
        if current == goal:
            return path, g_score
        if current in visited and visited[current] <= g_score:
            continue
        visited[current] = g_score
        for neighbor, weight in graph.get(current, {}).items():
            new_g = g_score + weight
            new_f = new_g + heuristic_fn(neighbor, goal)
            heapq.heappush(pq, (new_f, new_g, neighbor, path + [neighbor]))
    return [], float('inf')

if __name__ == "__main__":
    sample_graph = {
        "Intersection_1": {"Intersection_2": 45, "Intersection_4": 250},
        "Intersection_2": {"Intersection_1": 45, "Intersection_3": 50, "Intersection_5": 60},
        "Intersection_3": {"Intersection_2": 50, "City_Hospital": 300},
        "Intersection_4": {"Intersection_1": 250, "Intersection_5": 55, "Intersection_7": 40},
        "Intersection_5": {"Intersection_2": 60, "Intersection_4": 55, "Intersection_6": 40, "Intersection_8": 50},
        "Intersection_6": {"Intersection_3": 45, "Intersection_5": 40, "City_Hospital": 35},
        "Intersection_7": {"Intersection_4": 40, "Intersection_8": 45},
        "Intersection_8": {"Intersection_5": 50, "Intersection_7": 45, "City_Hospital": 60},
        "City_Hospital": {}
    }
    path = get_shortest_path(sample_graph, "Intersection_1", "City_Hospital")
    print(f"Calculated Path: {path}")
