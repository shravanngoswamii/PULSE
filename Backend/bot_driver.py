#!/usr/bin/env python3
"""
PULSE Bot Driver — Simulates a driver completing a mission for demo purposes.

Usage:
    python bot_driver.py                          # Interactive mode (pick hospital)
    python bot_driver.py --hospital "Bombay"      # Auto-pick hospital by name
    python bot_driver.py --speed fast             # Speed: slow (2s), normal (1s), fast (0.3s)
    python bot_driver.py --loop                   # Auto-restart after completing

Bot uses driver2@pulse.com (Fire Engine Bravo) by default.
"""

import asyncio
import argparse
import httpx
import sys
import time
import math

# ─── Config ─────────────────────────────────────────────────────────────────
API_BASE = "http://localhost:9000/api"
BOT_EMAIL = "driver2@pulse.com"
BOT_PASSWORD = "password123"
BOT_VEHICLE = "FIR-01"

# AITR, Indore — bot starts here
ORIGIN_LAT = 22.820567
ORIGIN_LNG = 75.942712

SPEED_PRESETS = {
    "slow": 2.0,      # 2 seconds per step — very visible on map
    "normal": 1.0,     # 1 second per step
    "fast": 0.3,       # 0.3 seconds per step — quick demo
}


# ─── Helpers ────────────────────────────────────────────────────────────────
def haversine_km(lat1, lon1, lat2, lon2):
    R = 6371
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dp = math.radians(lat2 - lat1)
    dl = math.radians(lon2 - lon1)
    a = math.sin(dp / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dl / 2) ** 2
    return R * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)))


def print_header(text):
    width = 60
    print(f"\n{'━' * width}")
    print(f"  🚑  {text}")
    print(f"{'━' * width}")


def print_step(icon, text, dim=False):
    color = "\033[90m" if dim else ""
    reset = "\033[0m" if dim else ""
    print(f"  {color}{icon}  {text}{reset}")


def progress_bar(current, total, width=30):
    filled = int(width * current / total)
    bar = "█" * filled + "░" * (width - filled)
    pct = int(100 * current / total)
    return f"[{bar}] {pct}%"


# ─── Bot Logic ──────────────────────────────────────────────────────────────
async def login(client: httpx.AsyncClient) -> str:
    """Log in and return JWT token."""
    resp = await client.post(f"{API_BASE}/auth/login", json={
        "email": BOT_EMAIL,
        "password": BOT_PASSWORD,
    })
    if resp.status_code != 200:
        print(f"  ❌  Login failed: {resp.text}")
        sys.exit(1)
    token = resp.json()["token"]
    print_step("🔑", f"Logged in as {BOT_EMAIL}")
    return token


async def get_hospitals(client: httpx.AsyncClient, headers: dict) -> list:
    """Fetch nearby hospitals."""
    resp = await client.get(
        f"{API_BASE}/driver/nearby-hospitals",
        params={"lat": ORIGIN_LAT, "lng": ORIGIN_LNG},
        headers=headers,
    )
    if resp.status_code != 200:
        print(f"  ❌  Failed to fetch hospitals: {resp.text}")
        sys.exit(1)
    return resp.json()


async def start_mission(client: httpx.AsyncClient, headers: dict, hospital: dict, vehicle_id: str) -> dict:
    """Start a mission to the given hospital."""
    resp = await client.post(
        f"{API_BASE}/driver/mission/start",
        json={
            "vehicle_id": vehicle_id,
            "destination_lat": hospital["lat"],
            "destination_lng": hospital["lng"],
            "destination_name": hospital["name"],
            "incident_type": "Medical Emergency",
            "priority": "high",
            "origin_lat": ORIGIN_LAT,
            "origin_lng": ORIGIN_LNG,
        },
        headers=headers,
        timeout=30.0,
    )
    if resp.status_code != 200:
        print(f"  ❌  Failed to start mission: {resp.text}")
        sys.exit(1)
    return resp.json()


async def ping_gps(client: httpx.AsyncClient, headers: dict, mission_id: str, lat: float, lng: float) -> dict:
    """Send a GPS ping."""
    try:
        resp = await client.post(
            f"{API_BASE}/driver/mission/ping",
            json={"mission_id": mission_id, "current_lat": lat, "current_lng": lng},
            headers=headers,
            timeout=15.0,
        )
        if resp.status_code == 200:
            return resp.json()
    except Exception:
        pass
    return {}


async def end_mission(client: httpx.AsyncClient, headers: dict, mission_id: str):
    """End the mission."""
    resp = await client.post(
        f"{API_BASE}/driver/mission/end",
        json={"mission_id": mission_id},
        headers=headers,
    )
    if resp.status_code == 200:
        data = resp.json()
        return data
    else:
        print(f"  ⚠️  End mission response: {resp.status_code}")
        return {}


async def run_bot(hospital_filter=None, speed="normal", loop=False, email=BOT_EMAIL, vehicle=BOT_VEHICLE):
    """Main bot execution."""
    step_delay = SPEED_PRESETS.get(speed, 1.0)
    bot_email = email
    bot_vehicle = vehicle

    async with httpx.AsyncClient(timeout=30.0) as client:
        # 1. Login
        print_header("PULSE Bot Driver Starting")
        resp = await client.post(f"{API_BASE}/auth/login", json={
            "email": bot_email,
            "password": BOT_PASSWORD,
        })
        if resp.status_code != 200:
            print(f"  ❌  Login failed: {resp.text}")
            sys.exit(1)
        token = resp.json()["token"]
        print_step("🔑", f"Logged in as {bot_email}")
        headers = {"Authorization": f"Bearer {token}"}

        while True:
            # 2. Fetch hospitals
            print_step("🏥", "Fetching nearby hospitals...")
            hospitals = await get_hospitals(client, headers)

            if not hospitals:
                print_step("❌", "No hospitals found!")
                return

            # 3. Pick hospital
            selected = None
            if hospital_filter:
                for h in hospitals:
                    if hospital_filter.lower() in h["name"].lower():
                        selected = h
                        break
                if not selected:
                    print_step("❌", f"No hospital matching '{hospital_filter}'")
                    print("  Available hospitals:")
                    for i, h in enumerate(hospitals):
                        print(f"    {i+1}. {h['name']} ({h.get('distance_km', '?')} km)")
                    return
            else:
                print("\n  Available hospitals:")
                for i, h in enumerate(hospitals[:10]):
                    dist = h.get("distance_km", "?")
                    print(f"    {i+1}. {h['name']} ({dist} km)")
                print()
                try:
                    choice = int(input("  Pick hospital number: ")) - 1
                    selected = hospitals[choice]
                except (ValueError, IndexError):
                    print("  Invalid choice. Using first hospital.")
                    selected = hospitals[0]

            dist_km = haversine_km(ORIGIN_LAT, ORIGIN_LNG, selected["lat"], selected["lng"])
            print_step("📍", f"Destination: {selected['name']} ({dist_km:.1f} km away)")

            # 4. Start mission
            print_step("🚀", "Starting mission...")
            mission_data = await start_mission(client, headers, selected, bot_vehicle)
            mission_id = mission_data["mission_id"]
            print_step("✅", f"Mission {mission_id} started!")
            print_step("📊", f"Distance: {mission_data.get('distance_km', '?')} km | ETA: {mission_data.get('eta_minutes', '?')} min | Signals: {mission_data.get('signals_on_route', '?')}")

            # 5. Extract route coordinates
            route_coords = mission_data.get("route_coordinates", [])
            if not route_coords:
                print_step("⚠️", "No route coordinates — using straight line")
                route_coords = [
                    {"lat": ORIGIN_LAT, "lng": ORIGIN_LNG},
                    {"lat": selected["lat"], "lng": selected["lng"]},
                ]

            # Subsample route if too many points (keep every Nth point for smooth travel)
            total_points = len(route_coords)
            if total_points > 200:
                # Keep ~100 points for a smooth but not-too-slow simulation
                step_size = max(1, total_points // 100)
                route_coords = route_coords[::step_size]
                # Always include the last point
                if route_coords[-1] != mission_data.get("route_coordinates", [])[-1]:
                    route_coords.append(mission_data["route_coordinates"][-1])

            total_steps = len(route_coords)
            print_step("🗺️ ", f"Route: {total_points} points → {total_steps} steps (speed: {speed})")

            # 6. Drive along route
            print_header(f"Driving to {selected['name']}")
            start_time = time.time()

            last_eta, last_dist, last_signals = "?", "?", 0
            ping_every = 5  # Only ping every Nth step to avoid OSRM rate limiting

            for i, coord in enumerate(route_coords):
                lat = coord["lat"] if isinstance(coord, dict) else coord[0]
                lng = coord["lng"] if isinstance(coord, dict) else coord[1]

                # Send GPS ping every Nth step (and always first + last)
                if i % ping_every == 0 or i == total_steps - 1:
                    ping_resp = await ping_gps(client, headers, mission_id, lat, lng)
                    last_eta = ping_resp.get("eta_minutes", last_eta)
                    last_dist = ping_resp.get("distance_km", last_dist)
                    last_signals = ping_resp.get("signals_cleared", last_signals)

                # Display progress
                bar = progress_bar(i + 1, total_steps)
                sys.stdout.write(f"\r  🚗  {bar}  ETA: {last_eta} min | Dist: {last_dist} km | Signals: {last_signals}  ")
                sys.stdout.flush()

                # Wait between steps
                await asyncio.sleep(step_delay)

            print()  # newline after progress bar

            # 7. End mission
            elapsed = round(time.time() - start_time, 1)
            print_step("🏁", f"Arrived at destination! (drove {elapsed}s)")
            result = await end_mission(client, headers, mission_id)
            if result:
                print_step("✅", f"Mission completed!")
                print_step("📊", f"Distance: {result.get('distance_km', '?')} km | Duration: {result.get('duration_minutes', '?')} min | Signals cleared: {result.get('signals_cleared', '?')}")

            if not loop:
                print_header("Bot Driver Finished")
                break
            else:
                print_step("🔄", "Restarting in 5 seconds...")
                await asyncio.sleep(5)


# ─── CLI ────────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(description="PULSE Bot Driver — simulate a mission")
    parser.add_argument("--hospital", type=str, default=None, help="Hospital name filter (partial match)")
    parser.add_argument("--speed", type=str, default="normal", choices=["slow", "normal", "fast"], help="Driving speed")
    parser.add_argument("--loop", action="store_true", help="Loop continuously")
    parser.add_argument("--email", type=str, default=BOT_EMAIL, help="Bot user email")
    parser.add_argument("--vehicle", type=str, default=BOT_VEHICLE, help="Vehicle ID")
    args = parser.parse_args()

    asyncio.run(run_bot(
        hospital_filter=args.hospital,
        speed=args.speed,
        loop=args.loop,
        email=args.email,
        vehicle=args.vehicle,
    ))


if __name__ == "__main__":
    main()
