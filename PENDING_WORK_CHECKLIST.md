# PULSE — Hackathon Pending Work Checklist

> Last updated: 2026-03-16
> Two apps: **PULSE** (EV driver app) and **PULSE-CC** (Traffic Authority command center)

---

## BACKEND (Highest Priority — Nothing Works Without This)

### Core Infrastructure
- [ ] Set up backend project (recommended: Python FastAPI or Node.js)
- [ ] Define REST API contracts for both apps (OpenAPI/Swagger spec)
- [ ] Set up WebSocket server for real-time push to both apps
- [ ] Set up PostgreSQL (or SQLite for demo) with PostGIS extension for geo queries
- [ ] Implement JWT authentication endpoint (`POST /auth/login`)
- [ ] Implement token refresh and logout endpoints
- [ ] Set up MQTT broker (Mosquitto) OR replace with pure WebSocket

### Traffic Graph Engine
- [ ] Build road/intersection graph data model (nodes = intersections, edges = road segments)
- [ ] Load mock city graph data (can use OpenStreetMap extract or hand-crafted JSON)
- [ ] Implement edge weight function: `cost = base_travel_time × (1 + congestion_factor) + signal_wait`
- [ ] Implement dynamic weight update API when traffic conditions change

### Routing Algorithms
- [ ] Implement **A\*** algorithm for single emergency vehicle routing
  - [ ] Use GPS coordinates as heuristic (Euclidean/Haversine distance)
  - [ ] Support dynamic edge weight updates mid-route
  - [ ] Return full path with turn-by-turn waypoints
- [ ] Implement **Floyd-Warshall** for precomputed intersection distance matrix
  - [ ] Run offline/on-demand for city subgraph (major intersections only)
  - [ ] Store matrix in cache (Redis or in-memory dict)
  - [ ] Use matrix for instant corridor planning in PULSE-CC
- [ ] Implement route re-computation trigger (when traffic changes significantly)

### Emergency Corridor Logic (AI/ML Problem)
- [ ] Implement Green Corridor algorithm:
  - [ ] Given vehicle position + destination, compute optimal path via A*
  - [ ] For each intersection on the path, schedule signal phase override
  - [ ] Signal override timing: compute ETA to each intersection, pre-clear N seconds before arrival
- [ ] Implement traffic disruption minimization:
  - [ ] Calculate cross-traffic wait time impact
  - [ ] Choose corridor that minimizes total city-wide delay
- [ ] Implement corridor release: restore normal signal timing after vehicle passes
- [ ] Expose `POST /corridor/create` and `DELETE /corridor/{id}` endpoints

### Mission Management
- [ ] `POST /missions` — create new emergency mission (vehicle + destination)
- [ ] `GET /missions/{id}` — get mission status + current route
- [ ] `PATCH /missions/{id}` — update mission (reroute, status change)
- [ ] `GET /missions/active` — list all active missions
- [ ] WebSocket push: broadcast mission updates to PULSE-CC dashboard

### Intersection Control
- [ ] `GET /intersections` — list all intersections with current signal state
- [ ] `GET /intersections/{id}` — get single intersection details
- [ ] `PATCH /intersections/{id}/signal` — manual override from PULSE-CC
- [ ] WebSocket push: broadcast signal state changes in real-time

### Vehicle Tracking
- [ ] `POST /vehicles/{id}/location` — EV app posts GPS position every N seconds
- [ ] WebSocket push: broadcast vehicle position to PULSE-CC live map
- [ ] Implement ETA recalculation on each location update

### Alerts
- [ ] `GET /alerts` — fetch active traffic alerts
- [ ] `POST /alerts` — create new alert (from PULSE-CC or auto-detected)
- [ ] WebSocket push: new alerts broadcast to both apps

### Simulation (for demo)
- [ ] Build city simulation engine:
  - [ ] Random vehicle generation with congestion modeling
  - [ ] Simulate signal cycles at each intersection
  - [ ] Inject simulated emergency vehicle
- [ ] `POST /simulation/start` — start simulation with config
- [ ] `POST /simulation/stop` — stop simulation
- [ ] `GET /simulation/state` — get current simulation snapshot
- [ ] WebSocket push: simulation state updates at ~1Hz

---

## PULSE App (Emergency Vehicle Driver)

### Navigation Screen
- [ ] Integrate Google Maps / Mapbox SDK
- [ ] Display real-time vehicle position on map
- [ ] Draw computed route polyline on map
- [ ] Show turn-by-turn navigation instructions
- [ ] Display ETA and distance remaining
- [ ] Show signal status ahead (green corridor indicators)

### Mission Flow
- [ ] Connect mission creation to backend `POST /missions`
- [ ] Implement mission accept/start/complete flow
- [ ] Show active mission details (incident type, destination, priority)
- [ ] Handle mission cancellation

### Real-time Updates
- [ ] Connect WebSocket client to backend
- [ ] Listen for route update events → re-draw route on map
- [ ] Listen for alert events → show alert banner
- [ ] Post GPS location to backend every 3-5 seconds

### Dashboard Screen
- [ ] Connect to `GET /missions/active` for active mission summary
- [ ] Show vehicle status (on duty / off duty)
- [ ] Show current traffic conditions summary

### Auth Flow
- [ ] Connect login screen to `POST /auth/login`
- [ ] Store JWT in secure storage (already has SecureStorage)
- [ ] Implement token refresh on 401 response
- [ ] Implement logout (clear token + redirect)

---

## PULSE-CC App (Traffic Authority Command Center)

### Live Map Screen
- [ ] Render city intersection graph on Google Maps
- [ ] Show all active emergency vehicles as moving markers
- [ ] Highlight active green corridors on map
- [ ] Show real-time traffic density heatmap (use mock data)
- [ ] Tap on intersection → show signal state + manual control option

### Dashboard Screen
- [ ] Connect `active_mission_tile` widget to real backend data
- [ ] Connect `system_status_card` to real intersection/vehicle counts
- [ ] Connect `traffic_analytics_card` to real traffic data
- [ ] Show `live_map_preview` as a mini embedded map

### Emergency Monitor Screen
- [ ] Connect to WebSocket for live mission updates
- [ ] Show event timeline with real timestamps
- [ ] Implement incident detail view (junction clearance status per intersection)
- [ ] Connect alert feed to `GET /alerts`

### Intersection Control Screen
- [ ] List all intersections from `GET /intersections`
- [ ] Show current signal phase and timing
- [ ] Implement manual override via `PATCH /intersections/{id}/signal`
- [ ] Show override confirmation + countdown

### Intelligence Screen
- [ ] Show city stats grid (total vehicles, active missions, avg delay)
- [ ] Show district map view with traffic density
- [ ] Implement analytics charts (congestion over time, mission response times)

### Simulation Screen
- [ ] Connect start/stop buttons to `POST /simulation/start` and `POST /simulation/stop`
- [ ] Show live simulation state (vehicle positions, signal states)
- [ ] Allow adjusting simulation parameters (vehicle count, congestion level)

### Auth Flow
- [ ] Connect login screen to backend auth
- [ ] Store JWT + authority role in secure storage
- [ ] Role-based access (admin vs. operator)

---

## Integration & Polish

- [ ] Error handling: show proper error UI when backend is unreachable
- [ ] Loading states: all API calls show loading indicators
- [ ] Offline mode: graceful degradation when no network
- [ ] Test both apps on Android emulator end-to-end
- [ ] Prepare demo script: simulate an ambulance mission from dispatch to hospital
- [ ] Record demo video or prepare live demo for judges

---

## Demo Data / Mock Setup (if no real backend time)

- [ ] Create static mock JSON files for all API responses
- [ ] Use mock WebSocket or periodic setState() to simulate real-time updates
- [ ] Hardcode a city graph with ~20-30 intersections for demo
- [ ] Prepare 2-3 scripted scenarios: ambulance, fire truck, police chase

---

## Nice-to-Have (Only if time permits)

- [ ] Push notifications for new mission assignments (FCM)
- [ ] Voice navigation in PULSE EV app (TTS)
- [ ] Historical analytics in PULSE-CC (past mission logs)
- [ ] Multi-vehicle coordination (handle 2 simultaneous emergency vehicles)
- [ ] ML-based congestion prediction using mock historical data
