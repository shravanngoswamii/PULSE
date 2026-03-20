# PULSE — Smart City Emergency Traffic Management

Real-time green corridor system for emergency vehicles using shortest-path algorithms, signal control, and live GPS tracking.

## Apps

| App | Type | Tech | Port | Purpose |
|-----|------|------|------|---------|
| **Backend** | FastAPI server | Python, SQLAlchemy, SQLite | 9000 | REST API + WebSocket |
| **PULSE** | Mobile (Flutter) | Riverpod, flutter_map, Dio | — | Driver / Ambulance app |
| **PULSE-CC** | Mobile (Flutter) | Riverpod, flutter_map, Dio | — | Command Center / Operator app |
| **Admin-Website** | Web (Vue 3) | Vite, Pinia, Axios | 5173 | Admin dashboard |
| **PULSE-AID-WEB** | Web (Vue 3) | Vite | 5174 | Public emergency caller portal |

## Network Setup

All apps connect to the Backend. Edit `network.env` once:

**Option A — Cloud (Render, Railway, etc.):**

```env
API_BASE_URL=https://your-app.onrender.com
```

**Option B — Local LAN:**

```env
# API_BASE_URL=
API_HOST=192.168.1.42   # your machine's Wi-Fi IPv4
API_PORT=9000
```

Then sync to Flutter apps:

```powershell
# Windows
.\sync_env.ps1

# Mac/Linux
bash sync_env.sh
```

For web apps running locally against a remote backend, create `.env` in each web app directory:

```env
VITE_API_BASE_URL=https://your-app.onrender.com
```

**Build APKs:**

```bash
cd PULSE && flutter build apk --release
cd PULSE-CC && flutter build apk --release
```

APKs at `build/app/outputs/flutter-apk/app-release.apk`.

**Web apps** are bound to `0.0.0.0`. On LAN: `http://<IP>:5173` (Admin), `http://<IP>:5174` (PULSE-AID).

## Quick Start

```bash
# 1. Backend
cd Backend
pip install -r requirements.txt
python seed.py
python main.py

# 2. Admin Website
cd Admin-Website
npm install && npm run dev

# 3. PULSE-AID-WEB
cd PULSE-AID-WEB
npm install && npm run dev

# 4. Flutter apps (for dev, or build APKs as above)
cd PULSE && flutter pub get && flutter run
cd PULSE-CC && flutter pub get && flutter run
```

## Demo Credentials

| Role | Email | Password | App |
|------|-------|----------|-----|
| Driver | driver@pulse.com | password123 | PULSE |
| Operator | operator@pulse.com | password123 | PULSE-CC |
| Admin | admin@pulse.com | password123 | Admin-Website |

Additional drivers: `driver2@pulse.com`, `driver3@pulse.com`
Additional operators: `operator2@pulse.com` through `operator6@pulse.com`

## API Docs

`http://localhost:9000/docs`

## Mac Support

Find your Mac's LAN IP:

```sh
ipconfig getifaddr en0
```

```sh
cd Backend
pip install -r requirements.txt
python seed.py
python main.py   # Listens on 0.0.0.0:9000
```