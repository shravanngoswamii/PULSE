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

## Network Setup (LAN / Physical Devices)

All apps connect to the Backend. A single file controls the IP:

**1. Set your PC's LAN IP in `network.env`:**

```env
API_HOST=192.168.1.42   # ← your PC's Wi-Fi IPv4 (ipconfig)
API_PORT=9000
```

**2. Sync to Flutter apps:**

```powershell
# Windows
.\sync_env.ps1

# Mac/Linux
bash sync_env.sh
```

This writes `PULSE/.env` and `PULSE-CC/.env` with the same IP.

**3. Build APKs and install on phones:**

```bash
cd PULSE && flutter build apk --release
cd PULSE-CC && flutter build apk --release
```

APKs are at `build/app/outputs/flutter-apk/app-release.apk`.

**4. Web apps** are already bound to `0.0.0.0`, so phones on the same Wi-Fi can open them at `http://<YOUR_IP>:5173` (Admin) and `http://<YOUR_IP>:5174` (PULSE-AID).

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
