from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from database import get_db
from models import User
from schemas import LoginRequest, RegisterRequest, TokenResponse, UserOut
from auth import hash_password, verify_password, create_token, get_current_user

router = APIRouter(prefix="/api/auth", tags=["Auth"])


@router.post("/login", response_model=TokenResponse)
def login(req: LoginRequest, db: Session = Depends(get_db)):
    user = db.query(User).filter(User.email == req.email).first()
    if not user or not verify_password(req.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    if not user.is_active:
        raise HTTPException(status_code=403, detail="Account disabled")
    token = create_token(user.id, user.role)
    return TokenResponse(token=token, user=UserOut.model_validate(user))


@router.post("/register", response_model=TokenResponse)
def register(req: RegisterRequest, db: Session = Depends(get_db)):
    if db.query(User).filter(User.email == req.email).first():
        raise HTTPException(status_code=409, detail="Email already registered")
    user = User(
        name=req.name,
        email=req.email,
        password_hash=hash_password(req.password),
        role=req.role,
        phone=req.phone,
        vehicle_id=req.vehicle_id,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    token = create_token(user.id, user.role)
    return TokenResponse(token=token, user=UserOut.model_validate(user))


@router.get("/me", response_model=UserOut)
def get_me(user: User = Depends(get_current_user)):
    return UserOut.model_validate(user)
