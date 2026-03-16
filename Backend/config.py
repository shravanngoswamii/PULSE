import os

SECRET_KEY = os.getenv("PULSE_SECRET_KEY", "pulse-hackathon-secret-key-2026")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_HOURS = 72
DATABASE_URL = "sqlite:///./pulse.db"

CORS_ORIGINS = [
    "http://localhost:5173",   # Vue dev server
    "http://localhost:3000",
    "http://127.0.0.1:5173",
    "http://10.0.2.2:8000",    # Android emulator
    "*",
]
