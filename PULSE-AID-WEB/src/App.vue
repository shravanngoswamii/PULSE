<script setup>
import { ref, computed, onMounted, onUnmounted, nextTick, watch } from 'vue';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';

// ── State ──────────────────────────────────────────────────────────────────
const screen = ref('phone'); // 'phone' | 'tracking' | 'emergency'
const phone = ref('');
const errorMsg = ref('');
const loading = ref(false);
const trackingData = ref(null);
const pollingTimer = ref(null);
const trackedPhone = ref('');

// Emergency form
const emergencyForm = ref({
  name: '',
  phone: '',
  lat: null,
  lng: null,
  incident_type: 'Medical Emergency',
  description: '',
  severity: 'high',
});
const gpsStatus = ref('');
const emergencyLoading = ref(false);
const emergencyError = ref('');

// Map
let map = null;
let vehicleMarker = null;
let callerMarker = null;
let routePolyline = null;

// ── Helpers ────────────────────────────────────────────────────────────────
const statusLabel = computed(() => {
  if (!trackingData.value) return '';
  const s = trackingData.value.status || trackingData.value.mission_status;
  if (s === 'completed') return 'Completed';
  if (s === 'in_progress' || s === 'active') return 'En Route';
  if (s === 'assigned') return 'Assigned';
  if (s === 'pending') return 'Pending';
  return s || 'Unknown';
});

const statusColor = computed(() => {
  const s = statusLabel.value;
  if (s === 'Assigned') return '#fbbf24';
  if (s === 'En Route') return '#2dd4bf';
  if (s === 'Arriving' || s === 'Completed') return '#34d399';
  return '#94a3b8';
});

const etaDisplay = computed(() => {
  if (!trackingData.value) return '--';
  const eta = trackingData.value.mission_eta;
  if (eta == null) return '--';
  if (eta < 1) return '< 1 min';
  return `${Math.round(eta)} min`;
});

const distanceDisplay = computed(() => {
  if (!trackingData.value) return '--';
  const d = trackingData.value.mission_distance_km;
  if (d == null) return '--';
  return `${d.toFixed(2)} km`;
});

// ── Map Icons ──────────────────────────────────────────────────────────────
const createIcon = (label, gradient) =>
  L.divIcon({
    className: 'pulse-map-icon',
    html: `<div style="
      width:44px;height:44px;border-radius:50%;
      background:${gradient};
      border:3px solid rgba(255,255,255,0.9);
      box-shadow:0 4px 16px rgba(0,0,0,0.4);
      display:flex;align-items:center;justify-content:center;
      font-size:0.7rem;font-weight:800;color:#fff;
      letter-spacing:0.02em;
    ">${label}</div>`,
    iconSize: [44, 44],
    iconAnchor: [22, 22],
  });

const ambulanceIcon = createIcon('AMB', 'radial-gradient(circle at 30% 30%, #fb7185, #dc2626)');
const callerIcon = createIcon('YOU', 'radial-gradient(circle at 30% 30%, #5eead4, #0f766e)');

// ── API Calls ──────────────────────────────────────────────────────────────
async function trackEmergency(phoneNumber) {
  const cleanPhone = phoneNumber.replace(/[\s\-()]/g, '');
  const encoded = encodeURIComponent(cleanPhone);
  const res = await fetch(`/api/emergency/track/${encoded}`);
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.detail || 'No active emergency found for this number');
  }
  return await res.json();
}

async function callEmergency(data) {
  const res = await fetch('/api/emergency/call', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(data),
  });
  if (!res.ok) {
    const body = await res.json().catch(() => ({}));
    throw new Error(body.detail || 'Failed to create emergency call');
  }
  return await res.json();
}

// ── Phone Screen Actions ───────────────────────────────────────────────────
async function submitPhone() {
  const fullPhone = phone.value.startsWith('+') ? phone.value : `+91${phone.value}`;
  if (fullPhone.replace(/\D/g, '').length < 10) {
    errorMsg.value = 'Please enter a valid phone number';
    return;
  }
  loading.value = true;
  errorMsg.value = '';
  try {
    const data = await trackEmergency(fullPhone);
    trackingData.value = data;
    trackedPhone.value = fullPhone;
    screen.value = 'tracking';
    await nextTick();
    initMap();
    startPolling();
  } catch (err) {
    errorMsg.value = err.message;
  } finally {
    loading.value = false;
  }
}

// ── Polling for live updates ───────────────────────────────────────────────
function startPolling() {
  stopPolling();
  pollingTimer.value = setInterval(async () => {
    try {
      const data = await trackEmergency(trackedPhone.value);
      trackingData.value = data;
      updateMap();
    } catch {
      // Keep showing last known data
    }
  }, 3000);
}

function stopPolling() {
  if (pollingTimer.value) {
    clearInterval(pollingTimer.value);
    pollingTimer.value = null;
  }
}

// ── Map ────────────────────────────────────────────────────────────────────
function initMap() {
  if (map) {
    map.remove();
    map = null;
  }
  vehicleMarker = null;
  callerMarker = null;
  routePolyline = null;

  const d = trackingData.value;
  if (!d) return;

  const center = [d.caller_lat || 22.72, d.caller_lng || 75.86];

  map = L.map('tracking-map', { zoomControl: false, attributionControl: false }).setView(center, 14);
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; OSM &copy; CARTO',
  }).addTo(map);

  // Caller marker
  callerMarker = L.marker(center, { icon: callerIcon }).addTo(map);
  callerMarker.bindPopup('Your Location');

  // Vehicle marker
  if (d.vehicle_lat && d.vehicle_lng) {
    vehicleMarker = L.marker([d.vehicle_lat, d.vehicle_lng], { icon: ambulanceIcon }).addTo(map);
    vehicleMarker.bindPopup('Ambulance');
  }

  // Route polyline
  if (d.road_coordinates && d.road_coordinates.length > 1) {
    const latlngs = d.road_coordinates.map((c) => [c.lat, c.lng]);
    routePolyline = L.polyline(latlngs, {
      color: '#2dd4bf',
      weight: 5,
      opacity: 0.85,
    }).addTo(map);
  }

  // Fit bounds
  fitMapBounds();
}

function updateMap() {
  const d = trackingData.value;
  if (!d || !map) return;

  // Update vehicle position
  if (d.vehicle_lat && d.vehicle_lng) {
    if (vehicleMarker) {
      vehicleMarker.setLatLng([d.vehicle_lat, d.vehicle_lng]);
    } else {
      vehicleMarker = L.marker([d.vehicle_lat, d.vehicle_lng], { icon: ambulanceIcon }).addTo(map);
      vehicleMarker.bindPopup('Ambulance');
    }
  }

  // Update caller marker
  if (d.caller_lat && d.caller_lng && callerMarker) {
    callerMarker.setLatLng([d.caller_lat, d.caller_lng]);
  }

  // Update route
  if (d.road_coordinates && d.road_coordinates.length > 1) {
    const latlngs = d.road_coordinates.map((c) => [c.lat, c.lng]);
    if (routePolyline) {
      routePolyline.setLatLngs(latlngs);
    } else {
      routePolyline = L.polyline(latlngs, {
        color: '#2dd4bf',
        weight: 5,
        opacity: 0.85,
      }).addTo(map);
    }
  }
}

function fitMapBounds() {
  if (!map) return;
  const markers = [];
  if (callerMarker) markers.push(callerMarker);
  if (vehicleMarker) markers.push(vehicleMarker);
  if (markers.length > 1) {
    const group = L.featureGroup(markers);
    map.fitBounds(group.getBounds(), { padding: [60, 60] });
  } else if (routePolyline) {
    map.fitBounds(routePolyline.getBounds(), { padding: [60, 60] });
  }
}

// ── Share Location ─────────────────────────────────────────────────────────
function shareMyLocation() {
  if (!navigator.geolocation) return;
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      const { latitude, longitude } = pos.coords;
      if (callerMarker && map) {
        callerMarker.setLatLng([latitude, longitude]);
        fitMapBounds();
      }
    },
    () => {},
    { enableHighAccuracy: true, timeout: 8000, maximumAge: 0 }
  );
}

// ── Emergency Form ─────────────────────────────────────────────────────────
function goToEmergency() {
  screen.value = 'emergency';
  detectLocation();
}

function detectLocation() {
  if (!navigator.geolocation) {
    gpsStatus.value = 'Geolocation not supported';
    return;
  }
  gpsStatus.value = 'Detecting your location...';
  navigator.geolocation.getCurrentPosition(
    (pos) => {
      emergencyForm.value.lat = pos.coords.latitude;
      emergencyForm.value.lng = pos.coords.longitude;
      gpsStatus.value = `Location detected: ${pos.coords.latitude.toFixed(5)}, ${pos.coords.longitude.toFixed(5)}`;
    },
    () => {
      gpsStatus.value = 'Could not detect location. Enter manually below.';
    },
    { enableHighAccuracy: true, timeout: 10000, maximumAge: 0 }
  );
}

async function submitEmergency() {
  const f = emergencyForm.value;
  if (!f.phone || f.phone.replace(/\D/g, '').length < 10) {
    emergencyError.value = 'Please enter a valid phone number';
    return;
  }
  if (!f.lat || !f.lng) {
    emergencyError.value = 'Location is required. Please allow GPS or enter coordinates manually.';
    return;
  }

  emergencyLoading.value = true;
  emergencyError.value = '';
  try {
    const fullPhone = f.phone.startsWith('+') ? f.phone : `+91${f.phone}`;
    const data = await callEmergency({
      caller_name: f.name || 'Unknown',
      caller_phone: fullPhone,
      caller_lat: parseFloat(f.lat),
      caller_lng: parseFloat(f.lng),
      incident_type: f.incident_type,
      severity: f.severity,
      description: f.description,
    });
    trackingData.value = data;
    trackedPhone.value = fullPhone;
    screen.value = 'tracking';
    await nextTick();
    initMap();
    startPolling();
  } catch (err) {
    emergencyError.value = err.message;
  } finally {
    emergencyLoading.value = false;
  }
}

// ── Back navigation ────────────────────────────────────────────────────────
function goBack() {
  stopPolling();
  if (map) {
    map.remove();
    map = null;
  }
  vehicleMarker = null;
  callerMarker = null;
  routePolyline = null;
  trackingData.value = null;
  errorMsg.value = '';
  screen.value = 'phone';
}

// ── Lifecycle ──────────────────────────────────────────────────────────────
onUnmounted(() => {
  stopPolling();
  if (map) {
    map.remove();
    map = null;
  }
});
</script>

<template>
  <div class="app-shell">
    <!-- ─── HEADER ──────────────────────────────────────────────── -->
    <header class="topbar glass-panel">
      <div class="brand-row">
        <img src="/logo.png" alt="Pulse Aid" class="brand-logo" />
        <div>
          <h1 class="gradient-text">PULSE AID</h1>
          <p class="subtext">Emergency Ambulance Tracking</p>
        </div>
      </div>
      <div v-if="screen === 'tracking' && trackingData" class="status-cluster">
        <div class="tracking-chip" :style="{ background: `${statusColor}22`, color: statusColor }">
          <span class="live-dot" :style="{ background: statusColor }"></span>
          <span>{{ statusLabel }}</span>
        </div>
      </div>
    </header>

    <!-- ═══════════════════════════════════════════════════════════
         SCREEN 1: PHONE ENTRY
         ═══════════════════════════════════════════════════════════ -->
    <main v-if="screen === 'phone'" class="center-screen">
      <section class="phone-card glass-panel">
        <div class="phone-card-inner">
          <div class="icon-circle">
            <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#2dd4bf" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
              <path d="M9 11a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"/>
              <path d="M17.657 16.657l-4.243 4.243a2 2 0 0 1 -2.827 0l-4.244 -4.243a8 8 0 1 1 11.314 0z"/>
            </svg>
          </div>
          <h2>Track Your Ambulance</h2>
          <p class="helper">Enter your phone number to see real-time ambulance location</p>

          <div class="input-row">
            <span class="country-code">+91</span>
            <input
              v-model="phone"
              type="tel"
              placeholder="Enter phone number"
              class="phone-input"
              maxlength="15"
              @keyup.enter="submitPhone"
            />
          </div>

          <button class="primary-button" :disabled="loading" @click="submitPhone">
            <span v-if="loading" class="spinner"></span>
            <span v-else>Track My Ambulance</span>
          </button>

          <p v-if="errorMsg" class="error-text">{{ errorMsg }}</p>

          <div class="divider">
            <span>OR</span>
          </div>

          <button class="secondary-button" @click="goToEmergency">
            Call Emergency
          </button>
        </div>
      </section>
    </main>

    <!-- ═══════════════════════════════════════════════════════════
         SCREEN 2: LIVE TRACKING
         ═══════════════════════════════════════════════════════════ -->
    <main v-else-if="screen === 'tracking'" class="tracking-layout">
      <section class="info-panel">
        <!-- Back button -->
        <button class="back-btn" @click="goBack">&larr; Back</button>

        <!-- ETA + Distance -->
        <article class="metrics-row glass-panel">
          <div class="metric">
            <label>ETA</label>
            <strong>{{ etaDisplay }}</strong>
          </div>
          <div class="metric-divider"></div>
          <div class="metric">
            <label>Distance</label>
            <strong>{{ distanceDisplay }}</strong>
          </div>
          <div class="metric-divider"></div>
          <div class="metric">
            <label>Status</label>
            <strong :style="{ color: statusColor }">{{ statusLabel }}</strong>
          </div>
        </article>

        <!-- Driver & Vehicle Info -->
        <article v-if="trackingData" class="details-card glass-panel">
          <h3>Driver &amp; Vehicle</h3>
          <div class="detail-grid">
            <div class="detail-item" v-if="trackingData.driver_name">
              <label>Driver</label>
              <strong>{{ trackingData.driver_name }}</strong>
              <p v-if="trackingData.driver_phone">{{ trackingData.driver_phone }}</p>
            </div>
            <div class="detail-item" v-if="trackingData.vehicle_name">
              <label>Vehicle</label>
              <strong>{{ trackingData.vehicle_name }}</strong>
              <p v-if="trackingData.vehicle_type">{{ trackingData.vehicle_type }}</p>
            </div>
            <div class="detail-item" v-if="trackingData.incident_type">
              <label>Incident</label>
              <strong>{{ trackingData.incident_type }}</strong>
              <p>Severity: {{ trackingData.severity || 'high' }}</p>
            </div>
          </div>
        </article>

        <!-- Vehicle Coordinates -->
        <article v-if="trackingData && trackingData.vehicle_lat" class="coords-card glass-panel">
          <label>Vehicle Position</label>
          <p>{{ trackingData.vehicle_lat?.toFixed(5) }}, {{ trackingData.vehicle_lng?.toFixed(5) }}</p>
        </article>

        <!-- Share location -->
        <button class="secondary-button share-btn" @click="shareMyLocation">
          Share My Location
        </button>
      </section>

      <section class="map-container glass-panel">
        <div id="tracking-map"></div>
        <div class="map-legend">
          <div class="legend-item">
            <span class="legend-dot" style="background:#dc2626"></span>
            <span>Ambulance</span>
          </div>
          <div class="legend-item">
            <span class="legend-dot" style="background:#0f766e"></span>
            <span>Your Location</span>
          </div>
          <div class="legend-item">
            <span class="legend-dot" style="background:#2dd4bf"></span>
            <span>Route</span>
          </div>
        </div>
      </section>
    </main>

    <!-- ═══════════════════════════════════════════════════════════
         SCREEN 3: EMERGENCY CALL FORM
         ═══════════════════════════════════════════════════════════ -->
    <main v-else-if="screen === 'emergency'" class="center-screen">
      <section class="emergency-card glass-panel">
        <button class="back-btn" @click="screen = 'phone'">&larr; Back</button>
        <h2>Call Emergency</h2>
        <p class="helper">Fill in your details to dispatch an ambulance to your location</p>

        <div class="form-group">
          <label>Your Name</label>
          <input v-model="emergencyForm.name" type="text" placeholder="Full name" class="form-input" />
        </div>

        <div class="form-group">
          <label>Phone Number</label>
          <div class="input-row">
            <span class="country-code">+91</span>
            <input v-model="emergencyForm.phone" type="tel" placeholder="Phone number" class="phone-input" maxlength="15" />
          </div>
        </div>

        <div class="form-group">
          <label>Location</label>
          <p class="gps-status">{{ gpsStatus }}</p>
          <div class="coords-row">
            <input v-model="emergencyForm.lat" type="number" step="any" placeholder="Latitude" class="form-input coord-input" />
            <input v-model="emergencyForm.lng" type="number" step="any" placeholder="Longitude" class="form-input coord-input" />
          </div>
          <button class="text-btn" @click="detectLocation">Re-detect GPS</button>
        </div>

        <div class="form-group">
          <label>Incident Type</label>
          <select v-model="emergencyForm.incident_type" class="form-input">
            <option>Medical Emergency</option>
            <option>Accident</option>
            <option>Fire</option>
            <option>Police</option>
          </select>
        </div>

        <div class="form-group">
          <label>Description</label>
          <textarea v-model="emergencyForm.description" rows="3" placeholder="Describe the situation..." class="form-input form-textarea"></textarea>
        </div>

        <button class="emergency-button" :disabled="emergencyLoading" @click="submitEmergency">
          <span v-if="emergencyLoading" class="spinner"></span>
          <span v-else>CALL EMERGENCY</span>
        </button>

        <p v-if="emergencyError" class="error-text">{{ emergencyError }}</p>
      </section>
    </main>
  </div>
</template>

<style scoped>
/* ─── Shell ──────────────────────────────────────────────────────────────── */
.app-shell {
  min-height: 100vh;
  padding: 16px;
  background:
    radial-gradient(circle at top left, rgba(45, 212, 191, 0.15), transparent 30%),
    radial-gradient(circle at bottom right, rgba(14, 165, 233, 0.15), transparent 32%),
    linear-gradient(160deg, #07111a 0%, #0b1622 42%, #111827 100%);
}

.glass-panel {
  background: rgba(9, 17, 28, 0.78);
  border: 1px solid rgba(148, 163, 184, 0.14);
  box-shadow: 0 16px 48px rgba(2, 6, 23, 0.3);
  backdrop-filter: blur(14px);
  border-radius: 20px;
}

/* ─── Header ─────────────────────────────────────────────────────────────── */
.topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 16px 20px;
  margin-bottom: 16px;
}

.brand-row {
  display: flex;
  align-items: center;
  gap: 12px;
}

.brand-logo {
  width: 44px;
  height: 44px;
  object-fit: contain;
}

.brand-row h1 {
  margin: 0;
  font-size: 1.35rem;
  letter-spacing: 0.08em;
}

.subtext {
  color: #94a3b8;
  font-size: 0.82rem;
  margin-top: 2px;
}

.status-cluster {
  display: flex;
  align-items: center;
}

.tracking-chip {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  padding: 8px 14px;
  border-radius: 999px;
  font-weight: 600;
  font-size: 0.88rem;
}

.live-dot {
  width: 9px;
  height: 9px;
  border-radius: 50%;
  animation: pulse-dot 1.6s infinite;
}

@keyframes pulse-dot {
  0% { box-shadow: 0 0 0 0 rgba(45, 212, 191, 0.6); }
  70% { box-shadow: 0 0 0 10px rgba(45, 212, 191, 0); }
  100% { box-shadow: 0 0 0 0 rgba(45, 212, 191, 0); }
}

/* ─── Center Screen (Phone / Emergency) ──────────────────────────────────── */
.center-screen {
  display: flex;
  justify-content: center;
  align-items: flex-start;
  padding-top: 4vh;
}

.phone-card,
.emergency-card {
  width: 100%;
  max-width: 420px;
  padding: 32px 28px;
}

.phone-card-inner {
  text-align: center;
}

.icon-circle {
  width: 64px;
  height: 64px;
  margin: 0 auto 16px;
  border-radius: 50%;
  background: rgba(45, 212, 191, 0.12);
  display: flex;
  align-items: center;
  justify-content: center;
}

.phone-card h2,
.emergency-card h2 {
  margin: 0 0 8px;
  font-size: 1.4rem;
}

.helper {
  color: #94a3b8;
  font-size: 0.9rem;
  margin-bottom: 24px;
  line-height: 1.4;
}

/* ─── Input Row ──────────────────────────────────────────────────────────── */
.input-row {
  display: flex;
  align-items: center;
  border: 1px solid rgba(148, 163, 184, 0.2);
  border-radius: 14px;
  background: rgba(15, 23, 42, 0.6);
  overflow: hidden;
}

.country-code {
  padding: 0 14px;
  color: #94a3b8;
  font-weight: 600;
  font-size: 0.95rem;
  white-space: nowrap;
  border-right: 1px solid rgba(148, 163, 184, 0.15);
}

.phone-input {
  flex: 1;
  background: none;
  border: none;
  outline: none;
  color: #f8fafc;
  padding: 14px 16px;
  font-size: 1rem;
  font-family: inherit;
}

.phone-input::placeholder {
  color: #475569;
}

/* ─── Buttons ────────────────────────────────────────────────────────────── */
.primary-button {
  margin-top: 18px;
  width: 100%;
  border: none;
  border-radius: 14px;
  background: linear-gradient(135deg, #14b8a6, #0ea5e9);
  color: white;
  padding: 15px 18px;
  font-weight: 700;
  font-size: 1rem;
  letter-spacing: 0.03em;
  cursor: pointer;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
  box-shadow: 0 8px 24px rgba(20, 184, 166, 0.25);
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  font-family: inherit;
}

.primary-button:hover:not(:disabled) {
  transform: translateY(-1px);
}

.primary-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.secondary-button {
  margin-top: 0;
  width: 100%;
  border: 1px solid rgba(148, 163, 184, 0.2);
  border-radius: 14px;
  background: rgba(15, 23, 42, 0.5);
  color: #e2e8f0;
  padding: 14px 18px;
  font-weight: 600;
  font-size: 0.95rem;
  cursor: pointer;
  transition: background 0.15s ease;
  font-family: inherit;
}

.secondary-button:hover {
  background: rgba(30, 41, 59, 0.7);
}

.emergency-button {
  margin-top: 24px;
  width: 100%;
  border: none;
  border-radius: 14px;
  background: linear-gradient(135deg, #ef4444, #dc2626);
  color: white;
  padding: 16px 18px;
  font-weight: 800;
  font-size: 1.05rem;
  letter-spacing: 0.06em;
  cursor: pointer;
  box-shadow: 0 8px 24px rgba(239, 68, 68, 0.3);
  transition: transform 0.15s ease;
  font-family: inherit;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
}

.emergency-button:hover:not(:disabled) {
  transform: translateY(-1px);
}

.emergency-button:disabled {
  opacity: 0.6;
  cursor: not-allowed;
}

.text-btn {
  background: none;
  border: none;
  color: #2dd4bf;
  font-size: 0.85rem;
  cursor: pointer;
  padding: 4px 0;
  font-family: inherit;
  text-decoration: underline;
  text-underline-offset: 3px;
}

.back-btn {
  background: none;
  border: none;
  color: #94a3b8;
  font-size: 0.9rem;
  cursor: pointer;
  padding: 4px 0;
  margin-bottom: 14px;
  font-family: inherit;
}

.back-btn:hover {
  color: #e2e8f0;
}

/* ─── Divider ────────────────────────────────────────────────────────────── */
.divider {
  display: flex;
  align-items: center;
  gap: 14px;
  margin: 22px 0;
  color: #475569;
  font-size: 0.82rem;
  text-transform: uppercase;
  letter-spacing: 0.08em;
}

.divider::before,
.divider::after {
  content: '';
  flex: 1;
  height: 1px;
  background: rgba(148, 163, 184, 0.15);
}

/* ─── Error / Spinner ────────────────────────────────────────────────────── */
.error-text {
  color: #fb7185;
  margin-top: 14px;
  font-size: 0.9rem;
}

.spinner {
  width: 20px;
  height: 20px;
  border: 3px solid rgba(255, 255, 255, 0.25);
  border-top-color: #fff;
  border-radius: 50%;
  animation: spin 0.7s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

/* ─── Tracking Layout ────────────────────────────────────────────────────── */
.tracking-layout {
  display: grid;
  grid-template-columns: 340px minmax(0, 1fr);
  gap: 16px;
  min-height: calc(100vh - 110px);
}

.info-panel {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

/* ─── Metrics Row ────────────────────────────────────────────────────────── */
.metrics-row {
  display: flex;
  align-items: center;
  padding: 0;
  overflow: hidden;
}

.metric {
  flex: 1;
  padding: 16px 14px;
  text-align: center;
}

.metric label {
  text-transform: uppercase;
  letter-spacing: 0.08em;
  font-size: 0.7rem;
  color: #94a3b8;
  display: block;
  margin-bottom: 4px;
}

.metric strong {
  font-size: 1.05rem;
  display: block;
}

.metric-divider {
  width: 1px;
  height: 36px;
  background: rgba(148, 163, 184, 0.15);
}

/* ─── Details Card ───────────────────────────────────────────────────────── */
.details-card {
  padding: 18px;
}

.details-card h3 {
  margin: 0 0 14px;
  font-size: 0.95rem;
  color: #e2e8f0;
}

.detail-grid {
  display: grid;
  gap: 14px;
}

.detail-item label {
  text-transform: uppercase;
  letter-spacing: 0.06em;
  font-size: 0.68rem;
  color: #94a3b8;
  display: block;
}

.detail-item strong {
  display: block;
  margin-top: 2px;
  font-size: 0.95rem;
}

.detail-item p {
  color: #94a3b8;
  font-size: 0.85rem;
  margin-top: 2px;
}

/* ─── Coords Card ────────────────────────────────────────────────────────── */
.coords-card {
  padding: 14px 18px;
}

.coords-card label {
  text-transform: uppercase;
  letter-spacing: 0.06em;
  font-size: 0.68rem;
  color: #94a3b8;
  display: block;
  margin-bottom: 4px;
}

.coords-card p {
  color: #e2e8f0;
  font-size: 0.9rem;
  font-family: monospace;
}

.share-btn {
  margin-top: auto;
}

/* ─── Map Container ──────────────────────────────────────────────────────── */
.map-container {
  padding: 12px;
  display: flex;
  flex-direction: column;
  min-height: 0;
}

#tracking-map {
  flex: 1;
  min-height: 500px;
  border-radius: 16px;
  overflow: hidden;
  background: #0f172a;
}

.map-legend {
  display: flex;
  gap: 18px;
  padding: 12px 6px 4px;
}

.legend-item {
  display: flex;
  align-items: center;
  gap: 6px;
  font-size: 0.82rem;
  color: #94a3b8;
}

.legend-dot {
  width: 10px;
  height: 10px;
  border-radius: 50%;
}

/* ─── Form ───────────────────────────────────────────────────────────────── */
.form-group {
  margin-bottom: 16px;
  text-align: left;
}

.form-group label {
  display: block;
  font-size: 0.82rem;
  color: #94a3b8;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  margin-bottom: 6px;
}

.form-input {
  width: 100%;
  background: rgba(15, 23, 42, 0.6);
  border: 1px solid rgba(148, 163, 184, 0.2);
  border-radius: 12px;
  color: #f8fafc;
  padding: 12px 14px;
  font-size: 0.95rem;
  font-family: inherit;
  outline: none;
  transition: border-color 0.15s;
}

.form-input:focus {
  border-color: rgba(45, 212, 191, 0.5);
}

.form-input::placeholder {
  color: #475569;
}

.form-textarea {
  resize: vertical;
  min-height: 70px;
}

select.form-input {
  appearance: none;
  -webkit-appearance: none;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='12' height='12' fill='%2394a3b8' viewBox='0 0 16 16'%3E%3Cpath d='M8 11L3 6h10z'/%3E%3C/svg%3E");
  background-repeat: no-repeat;
  background-position: right 14px center;
  padding-right: 36px;
}

select.form-input option {
  background: #0f172a;
  color: #f8fafc;
}

.coords-row {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px;
}

.gps-status {
  font-size: 0.82rem;
  color: #2dd4bf;
  margin-bottom: 8px;
}

/* ─── Leaflet fix for dark icons ─────────────────────────────────────────── */
:deep(.pulse-map-icon) {
  background: none !important;
  border: none !important;
}

/* ─── Responsive ─────────────────────────────────────────────────────────── */
@media (max-width: 860px) {
  .tracking-layout {
    grid-template-columns: 1fr;
  }

  .info-panel {
    order: 2;
  }

  .map-container {
    order: 1;
    min-height: 400px;
  }

  #tracking-map {
    min-height: 350px;
  }
}

@media (max-width: 480px) {
  .app-shell {
    padding: 10px;
  }

  .topbar {
    flex-direction: column;
    align-items: flex-start;
    gap: 10px;
    padding: 14px 16px;
  }

  .phone-card,
  .emergency-card {
    padding: 24px 20px;
  }

  .metrics-row {
    flex-direction: column;
  }

  .metric-divider {
    width: 80%;
    height: 1px;
  }

  #tracking-map {
    min-height: 280px;
  }
}
</style>
