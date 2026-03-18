# PULSE - Smart City Emergency Traffic Management System

PULSE is an intelligent traffic management system that creates green corridors for emergency vehicles using real-time routing algorithms, signal control, and live GPS tracking.

## Quick Start

### 1. Backend (FastAPI)

```bash
cd Backend
pip install -r requirements.txt
python seed.py          # Creates database with Indore intersections, vehicles, hospitals
python main.py          # Starts server at http://localhost:9000
```

API docs available at: http://localhost:9000/docs

### 2. Admin Dashboard (Vue.js)

```bash
cd Website
npm install
npm run dev             # Starts at http://localhost:5173
```

Login: `admin@pulse.com` / `password123`

### 3. PULSE Driver App (Flutter)

```bash
cd PULSE
flutter pub get
flutter run             # Run on Android emulator or device
```

Login: `driver@pulse.com` / `password123`

### 4. PULSE-CC Command Center (Flutter)

```bash
cd PULSE-CC
flutter pub get
flutter run             # Run on Android emulator or device
```

Login: `operator@pulse.com` / `password123`

## Demo Credentials

| Role       | Email                  | Password    | App           | Assigned Intersections           |
|------------|------------------------|-------------|---------------|----------------------------------|
| Driver     | driver@pulse.com       | password123 | PULSE         | -                                |
| Driver 2   | driver2@pulse.com      | password123 | PULSE         | -                                |
| Driver 3   | driver3@pulse.com      | password123 | PULSE         | -                                |
| Operator 1 | operator@pulse.com     | password123 | PULSE-CC      | Vijay Nagar, Palasia             |
| Operator 2 | operator2@pulse.com    | password123 | PULSE-CC      | Geeta Bhawan, Rajwada            |
| Operator 3 | operator3@pulse.com    | password123 | PULSE-CC      | Sarwate, MG Road                 |
| Operator 4 | operator4@pulse.com    | password123 | PULSE-CC      | Bhanwar Kuwa, Scheme 54          |
| Operator 5 | operator5@pulse.com    | password123 | PULSE-CC      | AB Road, Bombay Hospital         |
| Operator 6 | operator6@pulse.com    | password123 | PULSE-CC      | Rau, Mhow Naka                   |
| Admin      | admin@pulse.com        | password123 | Web Dashboard | -                                |

## System Components

### Backend (Python FastAPI)
- JWT authentication with role-based access control
- SQLite database with SQLAlchemy ORM
- Shortest path algorithms (Dijkstra, A*, SSSP Breakthrough)
- Dynamic graph engine with real-time weight updates
- WebSocket for live updates to operator dashboard
- Nearby hospital search from seeded Indore hospital data
- Signal management (automatic/manual/emergency modes)

### PULSE - Driver App
- Real-time GPS tracking using device location
- Nearby hospital search sorted by distance
- Mission workflow: select hospital, get optimal route, navigate
- Live map with route polyline and current position
- Backend integration for route calculation and GPS pings

### PULSE-CC - Command Center
- Real-time mission monitoring on live map
- Intersection signal control (force green/red, restore automatic)
- Emergency event timeline
- Traffic intelligence analytics
- WebSocket for live vehicle position updates

### Admin Dashboard
- Full CRUD for users, vehicles, intersections, hospitals, alerts
- Mission monitoring with status filters
- System statistics overview
- Role management (driver, operator, admin)

## Tech Stack

| Component    | Technology                                    |
|-------------|-----------------------------------------------|
| Backend     | Python, FastAPI, SQLAlchemy, SQLite, JWT       |
| Driver App  | Flutter, Riverpod, GoRouter, flutter_map, Dio  |
| CC App      | Flutter, Riverpod, GoRouter, flutter_map, Dio  |
| Admin Web   | Vue 3, Vite, Pinia, Vue Router, Axios          |
| Maps        | OpenStreetMap (free, no API key required)       |
| Algorithms  | Dijkstra, A*, Bellman-Ford, Floydd Warshall SSSP Breakthrough  |

## Seed Data (Indore)

The backend seeds with realistic Indore city data:
- 10 major intersections (Vijay Nagar, Palasia, Rajwada, Geeta Bhawan, Bombay Hospital, etc.)
- 24 bidirectional road edges with travel times
- 7 emergency vehicles (3 ambulances, 2 fire engines, 2 police)
- 12 real Indore hospitals with coordinates
- 6 demo users across all roles

## API Endpoints

| Method | Endpoint                              | Role     | Description                    |
|--------|---------------------------------------|----------|--------------------------------|
| POST   | /api/auth/login                       | Any      | Login, returns JWT token       |
| POST   | /api/auth/register                    | Any      | Register new user              |
| GET    | /api/driver/dashboard                 | Driver   | Dashboard data                 |
| GET    | /api/driver/nearby-hospitals          | Driver   | Hospitals sorted by distance   |
| POST   | /api/driver/mission/start             | Driver   | Start emergency mission        |
| POST   | /api/driver/mission/ping              | Driver   | Update GPS, get new route      |
| POST   | /api/driver/mission/end               | Driver   | Complete mission               |
| GET    | /api/operator/state                   | Operator | System overview                |
| GET    | /api/operator/intersections           | Operator | All intersections              |
| POST   | /api/operator/intersections/{id}/force-signal | Operator | Override signal     |
| GET    | /api/admin/stats                      | Admin    | System statistics              |
| CRUD   | /api/admin/users                      | Admin    | User management                |
| CRUD   | /api/admin/vehicles                   | Admin    | Vehicle management             |
| CRUD   | /api/admin/intersections              | Admin    | Intersection management        |

Full API documentation: http://localhost:9000/docs
