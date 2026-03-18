<script setup>
import { computed, nextTick, onMounted, onUnmounted, ref } from 'vue';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import {
  Ambulance,
  BadgeAlert,
  CarFront,
  Clock3,
  MapPin,
  MessageSquareText,
  Navigation,
  Route,
  ShieldCheck,
  UserRound
} from 'lucide-vue-next';

const DEMO_ROUTE = [
  { lat: 12.9716, lng: 77.5946 },
  { lat: 12.9721, lng: 77.5957 },
  { lat: 12.9727, lng: 77.5971 },
  { lat: 12.9735, lng: 77.5988 },
  { lat: 12.9748, lng: 77.6004 },
  { lat: 12.9763, lng: 77.6021 },
  { lat: 12.9778, lng: 77.6033 },
  { lat: 12.9794, lng: 77.6048 },
  { lat: 12.9809, lng: 77.6062 },
  { lat: 12.9823, lng: 77.6076 },
  { lat: 12.9835, lng: 77.6089 }
];

const FALLBACK_PATIENT_LOCATION = { lat: 12.9844, lng: 77.6097 };
const VEHICLE_SPEED_KMH = 34;
const TRACKING_ID_PARAM_KEYS = ['tracking', 'mission', 'trackingId'];

const mapStatus = ref('Preparing live patient view...');
const demoModeReason = ref('');
const currentRouteIndex = ref(0);
const etaMinutes = ref(0);
const distanceRemainingKm = ref(0);
const patientLocation = ref(null);
const patientShareState = ref('idle');
const patientShareMessage = ref('Tap the action below to alert the ambulance team that you are moving closer.');
const driverInboxMessage = ref('No patient message has been sent yet.');
const lastUpdatedAt = ref(new Date());

let map = null;
let ambulanceMarker = null;
let destinationMarker = null;
let patientMarker = null;
let routePolyline = null;
let patientGuidePolyline = null;
let simulationTimer = null;

const trackingIdFromUrl = (() => {
  const params = new URLSearchParams(window.location.search);
  for (const key of TRACKING_ID_PARAM_KEYS) {
    const value = params.get(key);
    if (value) {
      return value;
    }
  }
  return null;
})();

if (trackingIdFromUrl && trackingIdFromUrl !== 'DEMO-TRACK-4821') {
  demoModeReason.value = `Tracking ID ${trackingIdFromUrl} is not connected right now. Showing a guided demo mission instead.`;
} else if (!trackingIdFromUrl) {
  demoModeReason.value = 'No tracking ID was provided. Showing a guided demo mission for usability testing.';
}

const missionData = ref({
  trackingId: trackingIdFromUrl || 'DEMO-TRACK-4821',
  driverName: 'Rohit Kumar',
  driverPhone: '+91 98765 12045',
  vehicleName: 'ALS Ambulance',
  vehicleNumber: 'KA 03 MX 2147',
  hospitalName: 'Prayatna Emergency Response Unit',
  routeName: 'Richmond Circle to Langford Road pickup',
  status: 'Driver en route to patient',
  patientName: 'Patient pickup',
  priority: 'High',
  route: DEMO_ROUTE
});

const ambulancePosition = computed(() => missionData.value.route[currentRouteIndex.value]);
const destinationPosition = computed(() => missionData.value.route[missionData.value.route.length - 1]);

const statusPill = computed(() => {
  if (patientShareState.value === 'shared') {
    return 'Patient moving toward ambulance';
  }
  return missionData.value.status;
});

const progressPercent = computed(() => {
  const maxIndex = missionData.value.route.length - 1;
  if (maxIndex <= 0) {
    return 0;
  }
  return Math.min(100, Math.round((currentRouteIndex.value / maxIndex) * 100));
});

const lastUpdatedLabel = computed(() => {
  const seconds = Math.max(0, Math.round((Date.now() - lastUpdatedAt.value.getTime()) / 1000));
  if (seconds < 5) {
    return 'updated just now';
  }
  return `updated ${seconds}s ago`;
});

const formatCoordinate = (value) => value.toFixed(5);

const toRadians = (value) => (value * Math.PI) / 180;

const calculateDistanceKm = (start, end) => {
  const earthRadiusKm = 6371;
  const latDiff = toRadians(end.lat - start.lat);
  const lngDiff = toRadians(end.lng - start.lng);
  const startLat = toRadians(start.lat);
  const endLat = toRadians(end.lat);

  const haversine =
    Math.sin(latDiff / 2) * Math.sin(latDiff / 2) +
    Math.sin(lngDiff / 2) * Math.sin(lngDiff / 2) * Math.cos(startLat) * Math.cos(endLat);

  const angularDistance = 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));
  return earthRadiusKm * angularDistance;
};

const remainingDistanceFromIndex = (startIndex) => {
  let total = 0;

  for (let index = startIndex; index < missionData.value.route.length - 1; index += 1) {
    total += calculateDistanceKm(missionData.value.route[index], missionData.value.route[index + 1]);
  }

  return total;
};

const updateMetrics = () => {
  distanceRemainingKm.value = remainingDistanceFromIndex(currentRouteIndex.value);
  etaMinutes.value = Math.max(1, Math.round((distanceRemainingKm.value / VEHICLE_SPEED_KMH) * 60));
  lastUpdatedAt.value = new Date();
};

const createLabeledIcon = (label, className) =>
  L.divIcon({
    className: `map-badge ${className}`,
    html: `<span>${label}</span>`,
    iconSize: [54, 54],
    iconAnchor: [27, 27]
  });

const ambulanceIcon = createLabeledIcon('AMB', 'map-badge-ambulance');
const destinationIcon = createLabeledIcon('YOU', 'map-badge-destination');
const patientIcon = createLabeledIcon('PAT', 'map-badge-patient');

const updatePatientGuide = () => {
  if (!map || !patientLocation.value || !ambulancePosition.value) {
    return;
  }

  const line = [
    [patientLocation.value.lat, patientLocation.value.lng],
    [ambulancePosition.value.lat, ambulancePosition.value.lng]
  ];

  if (patientGuidePolyline) {
    patientGuidePolyline.setLatLngs(line);
  } else {
    patientGuidePolyline = L.polyline(line, {
      color: '#fbbf24',
      weight: 3,
      opacity: 0.9,
      dashArray: '7 9'
    }).addTo(map);
  }
};

const updateAmbulanceLocation = () => {
  if (!map || !ambulanceMarker || !ambulancePosition.value) {
    return;
  }

  ambulanceMarker.setLatLng([ambulancePosition.value.lat, ambulancePosition.value.lng]);
  updateMetrics();
  updatePatientGuide();
};

const startSimulation = () => {
  updateMetrics();

  simulationTimer = window.setInterval(() => {
    if (currentRouteIndex.value >= missionData.value.route.length - 1) {
      missionData.value.status = 'Ambulance has reached your pickup point';
      mapStatus.value = 'Ambulance reached destination. Demo mission complete.';
      window.clearInterval(simulationTimer);
      simulationTimer = null;
      return;
    }

    currentRouteIndex.value += 1;
    missionData.value.status = patientShareState.value === 'shared'
      ? 'Driver coordinating with patient live location'
      : 'Ambulance is actively approaching the pickup point';
    mapStatus.value = 'Ambulance location updated from demo simulator.';
    updateAmbulanceLocation();
  }, 2800);
};

const initMap = async () => {
  await nextTick();

  const route = missionData.value.route.map((point) => [point.lat, point.lng]);
  map = L.map('map', { zoomControl: false, attributionControl: true }).setView(route[0], 14);

  L.tileLayer('https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png', {
    attribution: '&copy; OpenStreetMap contributors &copy; CARTO'
  }).addTo(map);

  routePolyline = L.polyline(route, {
    color: '#2dd4bf',
    weight: 6,
    opacity: 0.95
  }).addTo(map);

  ambulanceMarker = L.marker(route[0], { icon: ambulanceIcon }).addTo(map);
  destinationMarker = L.marker(route[route.length - 1], { icon: destinationIcon }).addTo(map);

  ambulanceMarker.bindPopup('Ambulance live position');
  destinationMarker.bindPopup('Patient pickup zone');

  map.fitBounds(routePolyline.getBounds(), { padding: [60, 60] });
  updateMetrics();
};

const applyPatientLocation = (location, sourceLabel) => {
  patientLocation.value = location;
  patientShareState.value = 'shared';
  patientShareMessage.value = `Your location was shared with the ambulance team using ${sourceLabel}. Stay visible and keep your phone nearby.`;
  driverInboxMessage.value = `Patient is closing toward the ambulance. Shared coordinates: ${formatCoordinate(location.lat)}, ${formatCoordinate(location.lng)}.`;
  missionData.value.status = 'Driver coordinating with patient live location';
  mapStatus.value = 'Patient location shared with driver demo console.';

  if (patientMarker) {
    patientMarker.setLatLng([location.lat, location.lng]);
  } else if (map) {
    patientMarker = L.marker([location.lat, location.lng], { icon: patientIcon }).addTo(map);
    patientMarker.bindPopup('Patient shared position');
  }

  updatePatientGuide();

  if (map && ambulanceMarker && patientMarker) {
    const group = L.featureGroup([ambulanceMarker, destinationMarker, patientMarker]);
    map.fitBounds(group.getBounds(), { padding: [80, 80] });
  }
};

const sendClosingTowardsYou = async () => {
  if (patientShareState.value === 'sharing') {
    return;
  }

  patientShareState.value = 'sharing';
  patientShareMessage.value = 'Getting your location and notifying the ambulance driver...';

  if (!navigator.geolocation) {
    applyPatientLocation(FALLBACK_PATIENT_LOCATION, 'demo fallback');
    return;
  }

  navigator.geolocation.getCurrentPosition(
    (position) => {
      applyPatientLocation(
        {
          lat: position.coords.latitude,
          lng: position.coords.longitude
        },
        'live browser GPS'
      );
    },
    () => {
      applyPatientLocation(FALLBACK_PATIENT_LOCATION, 'demo fallback');
    },
    {
      enableHighAccuracy: true,
      timeout: 5000,
      maximumAge: 0
    }
  );
};

onMounted(async () => {
  await initMap();
  startSimulation();
});

onUnmounted(() => {
  if (simulationTimer) {
    window.clearInterval(simulationTimer);
  }

  if (map) {
    map.remove();
    map = null;
  }
});
</script>

<template>
  <div class="app-shell">
    <header class="topbar glass-panel">
      <div>
        <p class="eyebrow">Patient tracking view</p>
        <div class="brand-row">
          <img src="/logo.png" alt="Pulse Aid" class="brand-logo" />
          <div>
            <h1>PULSE AID</h1>
            <p class="subtext">Ambulance tracking and patient coordination demo</p>
          </div>
        </div>
      </div>

      <div class="status-cluster">
        <div class="tracking-chip">
          <span class="live-dot"></span>
          <span>{{ statusPill }}</span>
        </div>
        <p class="tracking-id">Tracking ID: {{ missionData.trackingId }}</p>
      </div>
    </header>

    <main class="layout-grid">
      <section class="left-rail">
        <article class="hero-card glass-panel">
          <div class="hero-copy">
            <p class="section-label">Emergency response</p>
            <h2>Ambulance is on the way to you</h2>
            <p>
              This page is now running in demo mode with in-browser data so you can test the patient-side
              experience without a backend connection.
            </p>
          </div>
          <div v-if="demoModeReason" class="demo-banner">
            <BadgeAlert :size="18" />
            <span>{{ demoModeReason }}</span>
          </div>
        </article>

        <article class="details-card glass-panel">
          <div class="card-header">
            <h3>Driver and vehicle</h3>
            <span class="helper-text">{{ lastUpdatedLabel }}</span>
          </div>

          <div class="detail-grid">
            <div class="detail-item">
              <UserRound :size="18" />
              <div>
                <label>Driver</label>
                <strong>{{ missionData.driverName }}</strong>
                <p>{{ missionData.driverPhone }}</p>
              </div>
            </div>

            <div class="detail-item">
              <CarFront :size="18" />
              <div>
                <label>Vehicle</label>
                <strong>{{ missionData.vehicleName }}</strong>
                <p>{{ missionData.vehicleNumber }}</p>
              </div>
            </div>

            <div class="detail-item">
              <Route :size="18" />
              <div>
                <label>Route</label>
                <strong>{{ missionData.routeName }}</strong>
                <p>{{ missionData.hospitalName }}</p>
              </div>
            </div>

            <div class="detail-item">
              <ShieldCheck :size="18" />
              <div>
                <label>Priority</label>
                <strong>{{ missionData.priority }}</strong>
                <p>PULSE guidance active for the corridor</p>
              </div>
            </div>
          </div>
        </article>

        <article class="metrics-card glass-panel">
          <div class="metric">
            <Clock3 :size="18" />
            <div>
              <label>ETA</label>
              <strong>{{ etaMinutes }} min</strong>
            </div>
          </div>

          <div class="metric">
            <Navigation :size="18" />
            <div>
              <label>Distance left</label>
              <strong>{{ distanceRemainingKm.toFixed(2) }} km</strong>
            </div>
          </div>

          <div class="metric">
            <Ambulance :size="18" />
            <div>
              <label>Progress</label>
              <strong>{{ progressPercent }}%</strong>
            </div>
          </div>
        </article>

        <article class="patient-action-card glass-panel">
          <div class="card-header">
            <h3>Patient action</h3>
            <span class="helper-text">Two-way coordination</span>
          </div>

          <p class="action-copy">
            If you are moving toward the ambulance, notify the driver. Your location will be shared on this demo map.
          </p>

          <button class="primary-button" type="button" @click="sendClosingTowardsYou">
            <MessageSquareText :size="18" />
            <span>CLOSING TOWARDS YOU</span>
          </button>

          <p class="share-message">{{ patientShareMessage }}</p>

          <div class="driver-inbox">
            <label>Driver receives</label>
            <p>{{ driverInboxMessage }}</p>
          </div>

          <div v-if="patientLocation" class="patient-coordinates">
            <MapPin :size="16" />
            <span>
              Shared patient position: {{ formatCoordinate(patientLocation.lat) }},
              {{ formatCoordinate(patientLocation.lng) }}
            </span>
          </div>
        </article>
      </section>

      <section class="map-panel glass-panel">
        <div class="map-header">
          <div>
            <p class="section-label">Live route</p>
            <h3>Ambulance and patient coordination map</h3>
          </div>
          <p class="map-status">{{ mapStatus }}</p>
        </div>

        <div id="map"></div>

        <div class="map-footer">
          <div class="legend-item">
            <span class="legend-swatch ambulance"></span>
            <span>Ambulance</span>
          </div>
          <div class="legend-item">
            <span class="legend-swatch destination"></span>
            <span>Pickup point</span>
          </div>
          <div class="legend-item">
            <span class="legend-swatch patient"></span>
            <span>Patient shared location</span>
          </div>
        </div>
      </section>
    </main>
  </div>
</template>

<style scoped>
.app-shell {
  min-height: 100vh;
  padding: 24px;
  background:
    radial-gradient(circle at top left, rgba(45, 212, 191, 0.18), transparent 28%),
    radial-gradient(circle at bottom right, rgba(14, 165, 233, 0.2), transparent 30%),
    linear-gradient(160deg, #07111a 0%, #0b1622 42%, #111827 100%);
}

.topbar,
.left-rail,
.map-panel {
  position: relative;
  z-index: 1;
}

.glass-panel {
  background: rgba(9, 17, 28, 0.78);
  border: 1px solid rgba(148, 163, 184, 0.16);
  box-shadow: 0 20px 60px rgba(2, 6, 23, 0.32);
  backdrop-filter: blur(16px);
}

.topbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 24px;
  padding: 20px 24px;
  border-radius: 24px;
  margin-bottom: 20px;
}

.eyebrow,
.section-label,
.helper-text,
.detail-item label,
.metric label,
.driver-inbox label {
  text-transform: uppercase;
  letter-spacing: 0.08em;
  font-size: 0.72rem;
  color: #93a4b8;
}

.brand-row {
  display: flex;
  align-items: center;
  gap: 16px;
}

.brand-logo {
  width: 52px;
  height: 52px;
  object-fit: contain;
}

.brand-row h1 {
  margin: 0;
  font-size: 1.5rem;
  letter-spacing: 0.08em;
}

.subtext {
  margin-top: 4px;
  color: #c2d0dd;
}

.status-cluster {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 10px;
}

.tracking-chip {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 10px 14px;
  border-radius: 999px;
  background: rgba(15, 118, 110, 0.22);
  color: #ccfbf1;
  font-weight: 600;
}

.live-dot {
  width: 10px;
  height: 10px;
  border-radius: 999px;
  background: #5eead4;
  box-shadow: 0 0 0 0 rgba(94, 234, 212, 0.7);
  animation: pulse-dot 1.6s infinite;
}

.tracking-id {
  color: #c7d5e0;
  font-size: 0.95rem;
}

.layout-grid {
  display: grid;
  grid-template-columns: 420px minmax(0, 1fr);
  gap: 20px;
  min-height: calc(100vh - 140px);
}

.left-rail {
  display: grid;
  grid-template-rows: auto auto auto 1fr;
  gap: 16px;
}

.hero-card,
.details-card,
.metrics-card,
.patient-action-card,
.map-panel {
  border-radius: 24px;
}

.hero-card,
.details-card,
.patient-action-card {
  padding: 22px;
}

.hero-copy h2,
.map-header h3,
.card-header h3 {
  margin: 6px 0 10px;
}

.hero-copy p,
.action-copy,
.share-message,
.driver-inbox p,
.detail-item p,
.map-status {
  color: #c6d4df;
  line-height: 1.5;
}

.demo-banner {
  margin-top: 18px;
  display: flex;
  gap: 10px;
  align-items: flex-start;
  padding: 14px 16px;
  border-radius: 18px;
  background: rgba(251, 191, 36, 0.12);
  color: #fde68a;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 10px;
  margin-bottom: 18px;
}

.detail-grid {
  display: grid;
  gap: 16px;
}

.detail-item {
  display: grid;
  grid-template-columns: 18px 1fr;
  gap: 12px;
  align-items: start;
}

.detail-item strong,
.metric strong {
  display: block;
  margin-top: 4px;
  font-size: 1rem;
}

.detail-item p {
  margin-top: 4px;
  font-size: 0.92rem;
}

.metrics-card {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1px;
  padding: 1px;
  background: linear-gradient(135deg, rgba(45, 212, 191, 0.32), rgba(59, 130, 246, 0.16));
}

.metric {
  background: rgba(9, 17, 28, 0.94);
  padding: 20px 18px;
  display: flex;
  gap: 12px;
  align-items: center;
}

.primary-button {
  margin-top: 18px;
  width: 100%;
  border: none;
  border-radius: 18px;
  background: linear-gradient(135deg, #f97316, #fb7185);
  color: white;
  padding: 16px 18px;
  font-weight: 700;
  letter-spacing: 0.04em;
  display: inline-flex;
  gap: 10px;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
  box-shadow: 0 18px 30px rgba(251, 113, 133, 0.22);
}

.primary-button:hover {
  transform: translateY(-1px);
}

.share-message {
  margin-top: 14px;
}

.driver-inbox {
  margin-top: 18px;
  padding: 14px 16px;
  border-radius: 18px;
  background: rgba(15, 23, 42, 0.7);
  border: 1px solid rgba(148, 163, 184, 0.14);
}

.driver-inbox p {
  margin-top: 8px;
}

.patient-coordinates {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  margin-top: 16px;
  color: #f8fafc;
  font-size: 0.93rem;
}

.map-panel {
  padding: 18px;
  display: grid;
  grid-template-rows: auto 1fr auto;
  gap: 14px;
  min-height: 0;
}

.map-header,
.map-footer {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: 16px;
}

#map {
  min-height: 560px;
  height: 100%;
  border-radius: 24px;
  overflow: hidden;
  background: #dbeafe;
}

.legend-item {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  color: #d7e3ec;
  font-size: 0.92rem;
}

.legend-swatch {
  width: 12px;
  height: 12px;
  border-radius: 999px;
}

.legend-swatch.ambulance {
  background: #ef4444;
}

.legend-swatch.destination {
  background: #14b8a6;
}

.legend-swatch.patient {
  background: #f59e0b;
}

:deep(.map-badge) {
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 999px;
  border: 3px solid rgba(255, 255, 255, 0.95);
  box-shadow: 0 10px 22px rgba(15, 23, 42, 0.3);
  font-size: 0.78rem;
  font-weight: 800;
  color: white;
}

:deep(.map-badge span) {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 100%;
  height: 100%;
}

:deep(.map-badge-ambulance) {
  background: radial-gradient(circle at 30% 30%, #fb7185, #dc2626);
}

:deep(.map-badge-destination) {
  background: radial-gradient(circle at 30% 30%, #5eead4, #0f766e);
}

:deep(.map-badge-patient) {
  background: radial-gradient(circle at 30% 30%, #fcd34d, #d97706);
}

@keyframes pulse-dot {
  0% {
    box-shadow: 0 0 0 0 rgba(94, 234, 212, 0.7);
  }

  70% {
    box-shadow: 0 0 0 12px rgba(94, 234, 212, 0);
  }

  100% {
    box-shadow: 0 0 0 0 rgba(94, 234, 212, 0);
  }
}

@media (max-width: 1120px) {
  .layout-grid {
    grid-template-columns: 1fr;
  }

  .left-rail {
    grid-template-rows: auto;
  }

  .map-panel {
    min-height: 720px;
  }
}

@media (max-width: 720px) {
  .app-shell {
    padding: 12px;
  }

  .topbar,
  .hero-card,
  .details-card,
  .patient-action-card,
  .map-panel {
    padding: 16px;
    border-radius: 20px;
  }

  .topbar,
  .map-header,
  .map-footer,
  .card-header {
    flex-direction: column;
    align-items: flex-start;
  }

  .status-cluster {
    align-items: flex-start;
  }

  .metrics-card {
    grid-template-columns: 1fr;
  }

  #map {
    min-height: 420px;
  }
}
</style>
