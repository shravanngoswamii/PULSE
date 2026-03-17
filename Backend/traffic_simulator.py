"""
PULSE Traffic Simulator – generates realistic traffic density patterns.
Runs as asyncio background task, updates edge weights, broadcasts via WebSocket.
"""
import asyncio, random, math, time
from datetime import datetime, timezone

PROFILES = {
    "rush_hour": {"base": 18, "var": 8, "desc": "Heavy rush hour traffic"},
    "normal":    {"base": 8,  "var": 5, "desc": "Normal daytime traffic"},
    "light":     {"base": 3,  "var": 2, "desc": "Light night-time traffic"},
    "accident":  {"base": 6,  "var": 3, "hotspot": 30, "desc": "Accident causing localized congestion"},
}


class TrafficSimulator:
    def __init__(self):
        self.running = False
        self.profile = "normal"
        self.densities = {}       # node_id -> float
        self.vehicle_counts = {}  # node_id -> {car, motorcycle, bus, truck}
        self.hotspot = None       # node_id with accident
        self.interval = 3.0
        self._task = None

    async def start(self, db_factory, ws_manager, profile="normal"):
        self.running = True
        self.profile = profile
        self._task = asyncio.create_task(self._loop(db_factory, ws_manager))
        print(f"🚦 Traffic simulator started [{profile}]")

    async def stop(self):
        self.running = False
        if self._task:
            self._task.cancel()
            self._task = None
        print("🚦 Traffic simulator stopped")

    def set_profile(self, profile):
        if profile in PROFILES:
            self.profile = profile

    def set_hotspot(self, node_id):
        self.hotspot = node_id

    def get_status(self):
        return {
            "running": self.running, "profile": self.profile,
            "profile_desc": PROFILES.get(self.profile, {}).get("desc", ""),
            "hotspot": self.hotspot,
            "node_count": len(self.densities),
            "densities": {k: round(v, 1) for k, v in self.densities.items()},
            "vehicle_counts": self.vehicle_counts,
        }

    async def _loop(self, db_factory, ws_manager):
        while self.running:
            try:
                db = db_factory()
                try:
                    await self._tick(db, ws_manager)
                finally:
                    db.close()
            except asyncio.CancelledError:
                break
            except Exception as e:
                print(f"Simulator error: {e}")
            await asyncio.sleep(self.interval)

    async def _tick(self, db, ws_manager):
        from models import Intersection, Edge
        from routing_service import invalidate_graph_cache

        intersections = db.query(Intersection).all()
        if not intersections:
            return

        p = PROFILES.get(self.profile, PROFILES["normal"])
        updates = []

        for inter in intersections:
            old = self.densities.get(inter.id, p["base"])

            if self.hotspot == inter.id:
                target = p.get("hotspot", 28)
            else:
                # Slow oscillation + noise for realism
                phase = hash(inter.id) % 100  # Unique phase per node
                osc = math.sin(time.time() / 45 + phase) * p["var"] * 0.4
                target = p["base"] + osc + random.gauss(0, p["var"] * 0.3)

            # Smooth transition
            density = old * 0.65 + target * 0.35 + random.gauss(0, 0.5)
            density = max(0, min(40, density))
            self.densities[inter.id] = density

            d_int = max(0, int(density))
            counts = {
                "car": max(0, int(d_int * 0.5 + random.gauss(0, 1.5))),
                "motorcycle": max(0, int(d_int * 0.3 + random.gauss(0, 1))),
                "bus": max(0, int(d_int * 0.1 + random.gauss(0, 0.5))),
                "truck": max(0, int(d_int * 0.1 + random.gauss(0, 0.5))),
            }
            self.vehicle_counts[inter.id] = counts
            total_v = sum(counts.values())

            congestion = "high" if density > 15 else "moderate" if density > 7 else "low"
            inter.congestion_level = congestion
            inter.vehicles_waiting = total_v

            multiplier = max(1.0, density / 5.0)
            for e in db.query(Edge).filter(Edge.to_id == inter.id).all():
                e.current_weight = e.base_travel_time * multiplier

            updates.append({
                "node_id": inter.id, "name": inter.name,
                "density": round(density, 1), "congestion": congestion,
                "vehicles": total_v, "counts": counts,
                "multiplier": round(multiplier, 2),
                "lat": inter.lat, "lng": inter.lng,
            })

        db.commit()
        invalidate_graph_cache()

        if ws_manager:
            await ws_manager.broadcast("visualizer", {
                "event": "traffic_update", "profile": self.profile,
                "updates": updates,
                "timestamp": datetime.now(timezone.utc).isoformat(),
            })


simulator = TrafficSimulator()
