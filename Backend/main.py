from contextlib import asynccontextmanager
from pathlib import Path
from fastapi import FastAPI, WebSocket, WebSocketDisconnect, Depends
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import FileResponse
from sqlalchemy.orm import Session
from config import CORS_ORIGINS, HOST, PORT
from database import engine, Base, get_db
from models import Edge, Intersection
from routers import auth_router, driver_router, operator_router, admin_router, edge_router
from websocket_manager import manager


@asynccontextmanager
async def lifespan(app):
    Base.metadata.create_all(bind=engine)
    yield


app = FastAPI(title="PULSE V2I Core Engine", version="2.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router.router)
app.include_router(driver_router.router)
app.include_router(operator_router.router)
app.include_router(admin_router.router)
app.include_router(edge_router.router)

# Serve static files
static_dir = Path(__file__).parent / "static"
if static_dir.exists():
    app.mount("/static", StaticFiles(directory=str(static_dir)), name="static")


@app.get("/")
def root():
    return {"status": "PULSE V2I Core Engine running", "version": "2.0", "visualizer": "/visualizer"}


@app.get("/api/health")
def health():
    return {"status": "ok"}


@app.get("/visualizer")
def visualizer_page():
    """Serve the algorithm visualizer page."""
    return FileResponse(str(static_dir / "visualizer.html"))


@app.get("/api/visualizer/graph")
def get_graph_data(db: Session = Depends(get_db)):
    """Return the full graph (nodes + edges) for the visualizer."""
    intersections = db.query(Intersection).all()
    edges_db = db.query(Edge).all()

    nodes = {i.id: {"lat": i.lat, "lng": i.lng, "name": i.name, "district": i.district} for i in intersections}
    edge_list = [{"from_id": e.from_id, "to_id": e.to_id, "weight": e.current_weight, "base": e.base_travel_time, "distance_m": e.distance_meters} for e in edges_db]

    return {"nodes": nodes, "edges": edge_list}


@app.get("/api/visualizer/compare")
def compare_algorithms(
    origin_lat: float, origin_lng: float,
    dest_lat: float, dest_lng: float,
    db: Session = Depends(get_db),
):
    """Run all 5 shortest-path algorithms on the same graph & endpoints."""
    from algorithms import run_all
    from routing_service import load_graph, snap_to_node

    nodes, graph = load_graph(db)
    start = snap_to_node(origin_lat, origin_lng, nodes)
    end = snap_to_node(dest_lat, dest_lng, nodes)

    if not start or not end:
        return {"error": "Could not snap to graph nodes"}
    if start == end:
        return {"error": "Origin and destination snap to the same intersection"}

    results = run_all(nodes, graph, start, end)
    return {
        "start": start, "end": end,
        "start_name": nodes[start]["name"],
        "end_name": nodes[end]["name"],
        "results": results,
    }


# --- WebSocket Endpoints ---

@app.websocket("/ws/operator")
async def ws_operator(websocket: WebSocket):
    await manager.connect(websocket, "operator")
    try:
        while True:
            data = await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, "operator")


@app.websocket("/ws/operator/{operator_id}")
async def ws_operator_personal(websocket: WebSocket, operator_id: str):
    """Per-operator WebSocket for intersection-specific alerts."""
    room = f"operator_{operator_id}"
    await manager.connect(websocket, room)
    await manager.connect(websocket, "operator")
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, room)
        manager.disconnect(websocket, "operator")


@app.websocket("/ws/driver/{mission_id}")
async def ws_driver(websocket: WebSocket, mission_id: str):
    room = f"driver_{mission_id}"
    await manager.connect(websocket, room)
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, room)


@app.websocket("/ws/admin")
async def ws_admin(websocket: WebSocket):
    await manager.connect(websocket, "admin")
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, "admin")


@app.websocket("/ws/visualizer")
async def ws_visualizer(websocket: WebSocket):
    """WebSocket for the live algorithm visualizer page."""
    await manager.connect(websocket, "visualizer")
    try:
        while True:
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket, "visualizer")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host=HOST, port=PORT, reload=True)
