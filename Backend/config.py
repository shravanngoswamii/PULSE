import os
from dotenv import load_dotenv

# Load .env file from the same directory as this script
load_dotenv()

SECRET_KEY = os.getenv("PULSE_SECRET_KEY", "pulse-hackathon-secret-key-2026")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_HOURS = 72
DATABASE_URL = os.getenv("DATABASE_URL", "sqlite:///./pulse.db")

# Server binding – default to 0.0.0.0 so it's reachable from simulators / devices
HOST = os.getenv("HOST", "0.0.0.0")
PORT = int(os.getenv("PORT", "9000"))

CORS_ORIGINS = [
    "http://localhost:5173",   # Vue dev server
    "http://localhost:3000",
    "http://127.0.0.1:5173",
    "http://10.0.2.2:9000",    # Android emulator → host loopback
    "*",                        # Allow all during development
]
