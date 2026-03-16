from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from database import get_db
from models import Edge, Intersection
from schemas import DensityUpdate

router = APIRouter(prefix="/api/edge", tags=["Edge AI"])


@router.post("/density")
def receive_density(payload: DensityUpdate, db: Session = Depends(get_db)):
    """YOLO camera sends traffic density updates."""
    node = payload.node_id
    weight = payload.total_weight
    multiplier = max(1.0, weight / 5.0)

    # Update edges TO this node
    edges = db.query(Edge).filter(Edge.to_id == node).all()
    for e in edges:
        e.current_weight = e.base_travel_time * multiplier

    # Update congestion level on the intersection
    intersection = db.query(Intersection).filter(Intersection.id == node).first()
    if intersection:
        if multiplier > 2.0:
            intersection.congestion_level = "high"
        elif multiplier > 1.3:
            intersection.congestion_level = "moderate"
        else:
            intersection.congestion_level = "low"
        intersection.vehicles_waiting = int(weight)

    db.commit()
    return {"status": "ok", "multiplier": round(multiplier, 2)}
