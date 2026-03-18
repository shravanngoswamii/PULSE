<template>
  <div>
    <div class="page-header">
      <div>
        <h1 class="emergency-title">Mass Emergency Dispatch</h1>
        <p>Coordinate multi-vehicle response for large-scale incidents</p>
      </div>
      <button class="btn btn-outline" @click="loadAll">Refresh</button>
    </div>

    <!-- Emergency Type Selection -->
    <div class="emergency-type-section">
      <h3 class="section-title">1. Emergency Type</h3>
      <div class="emergency-types-grid">
        <button
          v-for="et in emergencyTypes"
          :key="et.value"
          class="emergency-type-card"
          :class="{ active: selectedType === et.value }"
          @click="selectedType = et.value"
        >
          <span class="et-icon">{{ et.icon }}</span>
          <span class="et-label">{{ et.label }}</span>
        </button>
      </div>
    </div>

    <!-- Location -->
    <div class="card section-card">
      <h3 class="section-title">2. Incident Location</h3>
      <div class="location-row">
        <div class="form-group" style="flex: 1">
          <label>Destination Name</label>
          <input v-model="destination.name" class="form-input" placeholder="e.g. Industrial Zone Block C" />
        </div>
        <div class="form-group" style="width: 160px">
          <label>Latitude</label>
          <input v-model.number="destination.lat" type="number" step="any" class="form-input" />
        </div>
        <div class="form-group" style="width: 160px">
          <label>Longitude</label>
          <input v-model.number="destination.lng" type="number" step="any" class="form-input" />
        </div>
      </div>
      <div class="hospital-picker" v-if="hospitals.length">
        <label class="picker-label">Or pick from hospitals:</label>
        <div class="hospital-chips">
          <button
            v-for="h in hospitals"
            :key="h.id"
            class="btn btn-sm"
            :class="destination.name === h.name ? 'btn-primary' : 'btn-outline'"
            @click="pickHospital(h)"
          >
            {{ h.name }}
          </button>
        </div>
      </div>
    </div>

    <!-- Priority Override -->
    <div class="card section-card">
      <h3 class="section-title">3. Priority Override</h3>
      <div class="priority-row">
        <button
          class="priority-btn"
          :class="{ active: priority === 'critical', critical: priority === 'critical' }"
          @click="priority = 'critical'"
        >
          CRITICAL
        </button>
        <button
          class="priority-btn"
          :class="{ active: priority === 'high', high: priority === 'high' }"
          @click="priority = 'high'"
        >
          HIGH
        </button>
      </div>
    </div>

    <!-- Vehicle Dispatch Grid -->
    <div class="card section-card">
      <h3 class="section-title">
        4. Select Vehicles
        <span class="selected-count" v-if="selectedVehicles.length">
          {{ selectedVehicles.length }} selected
        </span>
      </h3>

      <div class="select-actions">
        <button class="btn btn-sm btn-outline" @click="selectAllStandby">Select All Standby</button>
        <button class="btn btn-sm btn-outline" @click="selectByType('ambulance')">All Ambulances</button>
        <button class="btn btn-sm btn-outline" @click="selectByType('fire')">All Fire</button>
        <button class="btn btn-sm btn-outline" @click="selectByType('police')">All Police</button>
        <button class="btn btn-sm btn-outline" @click="selectedVehicles = []" v-if="selectedVehicles.length">Clear</button>
      </div>

      <div v-for="vtype in vehicleTypeGroups" :key="vtype.type" class="vehicle-group">
        <h4 class="group-header">
          <span class="badge" :class="typeClass(vtype.type)">{{ vtype.type }}</span>
          <span class="group-count">{{ vtype.vehicles.length }} vehicles</span>
        </h4>
        <div class="vehicle-grid">
          <label
            v-for="v in vtype.vehicles"
            :key="v.id"
            class="vehicle-card"
            :class="{
              selected: selectedVehicles.includes(v.id),
              unavailable: v.status !== 'standby'
            }"
          >
            <input
              type="checkbox"
              :value="v.id"
              v-model="selectedVehicles"
              :disabled="v.status !== 'standby'"
              class="vehicle-checkbox"
            />
            <div class="vehicle-info">
              <span class="vehicle-id">{{ v.id }}</span>
              <span class="vehicle-name">{{ v.name }}</span>
              <span class="badge btn-sm" :class="v.status === 'standby' ? 'badge-green' : v.status === 'active' ? 'badge-yellow' : 'badge-gray'">
                {{ v.status }}
              </span>
            </div>
          </label>
        </div>
      </div>

      <p v-if="!vehicles.length" style="text-align: center; padding: 24px; color: var(--text-hint)">
        Loading vehicles...
      </p>
    </div>

    <!-- Dispatch Button -->
    <div class="dispatch-section">
      <button
        class="dispatch-btn"
        :disabled="!canDispatch || dispatching"
        @click="dispatchAll"
      >
        <span v-if="!dispatching">DISPATCH ALL ({{ selectedVehicles.length }} VEHICLES)</span>
        <span v-else>DISPATCHING... {{ dispatchProgress.done }}/{{ dispatchProgress.total }}</span>
      </button>
      <p class="dispatch-hint" v-if="!canDispatch && !dispatching">
        Select an emergency type, set a location, and choose at least one vehicle.
      </p>
    </div>

    <!-- Dispatch Progress -->
    <div v-if="dispatchProgress.total > 0" class="card section-card dispatch-results">
      <h3 class="section-title">Dispatch Results</h3>
      <div class="progress-bar-container">
        <div class="progress-bar" :style="{ width: progressPercent + '%' }"></div>
      </div>
      <p class="progress-text">
        {{ dispatchProgress.done }}/{{ dispatchProgress.total }} dispatched
        <span v-if="dispatchProgress.failed > 0" class="fail-count">
          ({{ dispatchProgress.failed }} failed)
        </span>
      </p>
      <div class="results-list">
        <div
          v-for="r in dispatchResults"
          :key="r.vehicleId"
          class="result-item"
          :class="r.success ? 'result-success' : 'result-fail'"
        >
          <span class="result-vehicle">{{ r.vehicleId }}</span>
          <span v-if="r.success" class="badge badge-green">Dispatched</span>
          <span v-else class="badge badge-red">Failed</span>
          <span v-if="r.missionId" class="result-mission">Mission: {{ r.missionId }}</span>
          <span v-if="r.error" class="result-error">{{ r.error }}</span>
        </div>
      </div>
    </div>

    <!-- Signal Clearance -->
    <div v-if="dispatchResults.length > 0 && dispatchResults.some(r => r.success)" class="card section-card">
      <h3 class="section-title">Signal Clearance</h3>
      <p class="section-desc">Force all nearby intersections to green for emergency corridor.</p>
      <div class="signal-actions">
        <button
          class="btn btn-danger"
          :disabled="clearingSignals"
          @click="clearAllSignals"
        >
          {{ clearingSignals ? 'Clearing Signals...' : 'Force All Intersections GREEN' }}
        </button>
        <span v-if="signalsClearedCount > 0" class="badge badge-green" style="margin-left: 12px">
          {{ signalsClearedCount }} intersections cleared
        </span>
        <span v-if="signalClearErrors > 0" class="badge badge-red" style="margin-left: 8px">
          {{ signalClearErrors }} failed
        </span>
      </div>
    </div>

    <!-- Active Mass Emergency Panel -->
    <div v-if="activeMissions.length > 0" class="card section-card active-panel">
      <h3 class="section-title">
        Active Mass Emergency Missions
        <button class="btn btn-sm btn-outline" style="margin-left: auto" @click="refreshActiveMissions">Refresh</button>
      </h3>
      <div class="card pulse-table-card table-glass">
        <table class="data-table">
          <thead>
            <tr>
              <th>Mission</th>
              <th>Vehicle</th>
              <th>Type</th>
              <th>Priority</th>
              <th>ETA</th>
              <th>Distance</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="m in activeMissions" :key="m.id">
              <td style="font-family: monospace; font-weight: 800; color: var(--primary)">{{ m.id }}</td>
              <td style="font-weight: 600">{{ m.vehicle_name || m.vehicle_id }}</td>
              <td><span class="badge" :class="typeClass(m.vehicle_type)">{{ m.vehicle_type || '-' }}</span></td>
              <td>
                <span class="badge" :class="m.priority === 'critical' ? 'badge-red' : 'badge-yellow'">
                  {{ m.priority }}
                </span>
              </td>
              <td style="font-family: monospace">{{ m.eta_minutes ? m.eta_minutes.toFixed(1) + ' min' : '-' }}</td>
              <td style="font-family: monospace">{{ m.distance_km ? m.distance_km.toFixed(2) + ' km' : '-' }}</td>
              <td>
                <span class="badge" :class="m.status === 'active' ? 'badge-green' : m.status === 'completed' ? 'badge-blue' : 'badge-gray'">
                  {{ m.status }}
                </span>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import api from '../api/client'

// --- Emergency types ---
const emergencyTypes = [
  { value: 'major_fire', label: 'Major Fire', icon: '\u{1F525}' },
  { value: 'mass_casualty', label: 'Mass Casualty', icon: '\u{1F6D1}' },
  { value: 'industrial_accident', label: 'Industrial Accident', icon: '\u{26A0}\u{FE0F}' },
  { value: 'natural_disaster', label: 'Natural Disaster', icon: '\u{1F30A}' },
  { value: 'terror_incident', label: 'Terror Incident', icon: '\u{1F6A8}' },
]

const incidentTypeMap = {
  major_fire: 'Major Fire',
  mass_casualty: 'Mass Casualty Event',
  industrial_accident: 'Industrial Accident',
  natural_disaster: 'Natural Disaster',
  terror_incident: 'Terror Incident',
}

// --- State ---
const selectedType = ref('')
const destination = ref({ name: '', lat: null, lng: null })
const priority = ref('critical')
const vehicles = ref([])
const hospitals = ref([])
const intersections = ref([])
const selectedVehicles = ref([])

const dispatching = ref(false)
const dispatchProgress = ref({ done: 0, total: 0, failed: 0 })
const dispatchResults = ref([])
const dispatchedMissionIds = ref([])

const activeMissions = ref([])
const clearingSignals = ref(false)
const signalsClearedCount = ref(0)
const signalClearErrors = ref(0)

let refreshInterval = null

// --- Computed ---
const standbyVehicles = computed(() => vehicles.value.filter(v => v.status === 'standby'))

const vehicleTypeGroups = computed(() => {
  const types = ['ambulance', 'fire', 'police']
  return types
    .map(t => ({
      type: t,
      vehicles: vehicles.value.filter(v => v.type === t),
    }))
    .filter(g => g.vehicles.length > 0)
})

const canDispatch = computed(() => {
  return (
    selectedType.value &&
    destination.value.lat !== null &&
    destination.value.lng !== null &&
    destination.value.name &&
    selectedVehicles.value.length > 0
  )
})

const progressPercent = computed(() => {
  if (!dispatchProgress.value.total) return 0
  return Math.round((dispatchProgress.value.done / dispatchProgress.value.total) * 100)
})

// --- Helpers ---
function typeClass(t) {
  if (t === 'ambulance') return 'badge-green'
  if (t === 'fire') return 'badge-yellow'
  return 'badge-blue'
}

function pickHospital(h) {
  destination.value.name = h.name
  destination.value.lat = h.lat
  destination.value.lng = h.lng
}

function selectAllStandby() {
  selectedVehicles.value = standbyVehicles.value.map(v => v.id)
}

function selectByType(type) {
  const ids = vehicles.value
    .filter(v => v.type === type && v.status === 'standby')
    .map(v => v.id)
  const current = new Set(selectedVehicles.value)
  ids.forEach(id => current.add(id))
  selectedVehicles.value = Array.from(current)
}

// --- API ---
async function loadAll() {
  try {
    const [vRes, hRes, iRes] = await Promise.all([
      api.get('/admin/vehicles'),
      api.get('/admin/hospitals'),
      api.get('/admin/intersections'),
    ])
    vehicles.value = vRes.data
    hospitals.value = hRes.data
    intersections.value = iRes.data
  } catch (e) {
    console.error('Failed to load data:', e)
  }
}

async function dispatchAll() {
  if (!canDispatch.value || dispatching.value) return

  dispatching.value = true
  dispatchResults.value = []
  dispatchedMissionIds.value = []
  dispatchProgress.value = { done: 0, total: selectedVehicles.value.length, failed: 0 }

  const vehicleIds = [...selectedVehicles.value]
  const promises = vehicleIds.map(async (vehicleId) => {
    try {
      const res = await api.post('/driver/mission/start', {
        vehicle_id: vehicleId,
        destination_lat: destination.value.lat,
        destination_lng: destination.value.lng,
        destination_name: destination.value.name,
        incident_type: incidentTypeMap[selectedType.value] || selectedType.value,
        priority: priority.value,
        origin_lat: getVehicleOriginLat(vehicleId),
        origin_lng: getVehicleOriginLng(vehicleId),
        auto_drive: true,
      })
      dispatchProgress.value.done++
      const missionId = res.data?.mission_id || res.data?.id || null
      if (missionId) dispatchedMissionIds.value.push(missionId)
      dispatchResults.value.push({ vehicleId, success: true, missionId })
    } catch (e) {
      dispatchProgress.value.done++
      dispatchProgress.value.failed++
      const error = e.response?.data?.detail || e.message || 'Unknown error'
      dispatchResults.value.push({ vehicleId, success: false, error })
    }
  })

  await Promise.all(promises)
  dispatching.value = false

  // Reload vehicles to reflect new statuses
  await loadAll()
  await refreshActiveMissions()

  // Start auto-refresh for active missions
  startMissionRefresh()
}

function getVehicleOriginLat(vehicleId) {
  const v = vehicles.value.find(veh => veh.id === vehicleId)
  return v?.current_lat || null
}

function getVehicleOriginLng(vehicleId) {
  const v = vehicles.value.find(veh => veh.id === vehicleId)
  return v?.current_lng || null
}

async function refreshActiveMissions() {
  if (!dispatchedMissionIds.value.length) return
  try {
    const res = await api.get('/admin/missions')
    activeMissions.value = res.data.filter(
      m => dispatchedMissionIds.value.includes(m.id) || dispatchedMissionIds.value.includes(m.mission_id)
    )
    // If no filter matches (mission_id field name mismatch), show recent active ones
    if (activeMissions.value.length === 0 && dispatchedMissionIds.value.length > 0) {
      activeMissions.value = res.data
        .filter(m => m.status === 'active')
        .slice(0, dispatchedMissionIds.value.length)
    }
  } catch (e) {
    console.error('Failed to refresh missions:', e)
  }
}

function startMissionRefresh() {
  stopMissionRefresh()
  refreshInterval = setInterval(refreshActiveMissions, 5000)
}

function stopMissionRefresh() {
  if (refreshInterval) {
    clearInterval(refreshInterval)
    refreshInterval = null
  }
}

async function clearAllSignals() {
  clearingSignals.value = true
  signalsClearedCount.value = 0
  signalClearErrors.value = 0

  const promises = intersections.value.map(async (intersection) => {
    try {
      await api.post(`/operator/intersections/${intersection.id}/force-signal?phase=green`)
      signalsClearedCount.value++
    } catch {
      signalClearErrors.value++
    }
  })

  await Promise.all(promises)
  clearingSignals.value = false
}

// --- Lifecycle ---
onMounted(loadAll)

onUnmounted(stopMissionRefresh)
</script>

<style scoped>
/* Emergency title with red accent */
.emergency-title {
  color: var(--danger) !important;
  text-shadow: 0 0 15px rgba(255, 82, 82, 0.4) !important;
}

/* Section titles */
.section-title {
  font-size: 14px;
  font-weight: 700;
  color: var(--text);
  text-transform: uppercase;
  letter-spacing: 0.8px;
  margin-bottom: 16px;
  display: flex;
  align-items: center;
  gap: 10px;
}

.section-desc {
  font-size: 13px;
  color: var(--text-secondary);
  margin-bottom: 16px;
}

.section-card {
  margin-bottom: 20px;
}

/* Emergency Type Cards */
.emergency-type-section {
  margin-bottom: 20px;
}

.emergency-types-grid {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  gap: 12px;
}

.emergency-type-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 20px 12px;
  background: var(--glass-surface);
  border: 2px solid var(--border);
  border-radius: var(--radius-lg);
  cursor: pointer;
  transition: all 0.2s ease;
  font-family: inherit;
  color: var(--text);
}

.emergency-type-card:hover {
  border-color: var(--danger);
  background: var(--danger-light);
}

.emergency-type-card.active {
  border-color: var(--danger);
  background: var(--danger-light);
  box-shadow: 0 0 20px rgba(255, 82, 82, 0.25), inset 0 0 20px rgba(255, 82, 82, 0.05);
}

.et-icon {
  font-size: 28px;
}

.et-label {
  font-size: 12px;
  font-weight: 700;
  text-transform: uppercase;
  letter-spacing: 0.5px;
  text-align: center;
}

/* Location */
.location-row {
  display: flex;
  gap: 12px;
  align-items: flex-start;
}

.hospital-picker {
  margin-top: 12px;
}

.picker-label {
  font-size: 12px;
  font-weight: 600;
  color: var(--text-hint);
  margin-bottom: 8px;
  display: block;
}

.hospital-chips {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

/* Priority */
.priority-row {
  display: flex;
  gap: 12px;
}

.priority-btn {
  padding: 12px 32px;
  border-radius: var(--radius);
  font-size: 14px;
  font-weight: 800;
  letter-spacing: 1px;
  border: 2px solid var(--border);
  background: var(--glass-surface);
  color: var(--text);
  cursor: pointer;
  transition: all 0.2s ease;
  font-family: inherit;
}

.priority-btn:hover {
  border-color: var(--text-secondary);
}

.priority-btn.active.critical {
  border-color: var(--danger);
  background: var(--danger-light);
  color: var(--danger);
  box-shadow: 0 0 15px rgba(255, 82, 82, 0.2);
}

.priority-btn.active.high {
  border-color: var(--warning);
  background: var(--warning-light);
  color: var(--warning);
  box-shadow: 0 0 15px rgba(255, 215, 64, 0.2);
}

/* Vehicle selection */
.select-actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  margin-bottom: 16px;
}

.selected-count {
  font-size: 12px;
  font-weight: 600;
  color: var(--danger);
  background: var(--danger-light);
  padding: 2px 10px;
  border-radius: 100px;
}

.vehicle-group {
  margin-bottom: 16px;
}

.group-header {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 10px;
  font-size: 13px;
  font-weight: 600;
}

.group-count {
  font-size: 12px;
  color: var(--text-hint);
  font-weight: 500;
}

.vehicle-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 10px;
}

.vehicle-card {
  display: flex;
  align-items: flex-start;
  gap: 10px;
  padding: 14px;
  background: var(--glass-surface);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  cursor: pointer;
  transition: all 0.15s ease;
}

.vehicle-card:hover {
  border-color: var(--primary);
}

.vehicle-card.selected {
  border-color: var(--danger);
  background: var(--danger-light);
  box-shadow: 0 0 10px rgba(255, 82, 82, 0.15);
}

.vehicle-card.unavailable {
  opacity: 0.4;
  cursor: not-allowed;
}

.vehicle-card.unavailable:hover {
  border-color: var(--border);
}

.vehicle-checkbox {
  margin-top: 2px;
  accent-color: var(--danger);
  width: 16px;
  height: 16px;
  flex-shrink: 0;
}

.vehicle-info {
  display: flex;
  flex-direction: column;
  gap: 3px;
  min-width: 0;
}

.vehicle-id {
  font-family: monospace;
  font-size: 13px;
  font-weight: 800;
  color: var(--primary);
}

.vehicle-name {
  font-size: 12px;
  font-weight: 600;
  color: var(--text);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* Dispatch Button */
.dispatch-section {
  margin-bottom: 20px;
  text-align: center;
}

.dispatch-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: 18px 60px;
  border-radius: var(--radius-lg);
  font-size: 18px;
  font-weight: 900;
  letter-spacing: 2px;
  text-transform: uppercase;
  font-family: inherit;
  border: 2px solid var(--danger);
  background: var(--danger);
  color: white;
  cursor: pointer;
  transition: all 0.2s ease;
  box-shadow: 0 0 30px rgba(255, 82, 82, 0.3), 0 4px 15px rgba(255, 82, 82, 0.2);
}

.dispatch-btn:hover:not(:disabled) {
  background: #E53935;
  box-shadow: 0 0 50px rgba(255, 82, 82, 0.5), 0 4px 25px rgba(255, 82, 82, 0.35);
  transform: translateY(-2px);
}

.dispatch-btn:disabled {
  opacity: 0.35;
  cursor: not-allowed;
  box-shadow: none;
}

.dispatch-hint {
  font-size: 12px;
  color: var(--text-hint);
  margin-top: 10px;
}

/* Dispatch Results */
.dispatch-results {
  border-color: rgba(255, 82, 82, 0.3);
}

.progress-bar-container {
  width: 100%;
  height: 6px;
  background: var(--border);
  border-radius: 3px;
  overflow: hidden;
  margin-bottom: 10px;
}

.progress-bar {
  height: 100%;
  background: var(--danger);
  border-radius: 3px;
  transition: width 0.3s ease;
  box-shadow: 0 0 8px rgba(255, 82, 82, 0.5);
}

.progress-text {
  font-size: 13px;
  font-weight: 600;
  color: var(--text-secondary);
  margin-bottom: 14px;
}

.fail-count {
  color: var(--danger);
}

.results-list {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.result-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 14px;
  border-radius: var(--radius);
  font-size: 13px;
}

.result-success {
  background: rgba(0, 230, 118, 0.05);
  border: 1px solid rgba(0, 230, 118, 0.15);
}

.result-fail {
  background: rgba(255, 82, 82, 0.05);
  border: 1px solid rgba(255, 82, 82, 0.15);
}

.result-vehicle {
  font-family: monospace;
  font-weight: 700;
  color: var(--text);
  min-width: 80px;
}

.result-mission {
  font-family: monospace;
  font-size: 12px;
  color: var(--text-hint);
}

.result-error {
  font-size: 12px;
  color: var(--danger);
  margin-left: auto;
}

/* Signal Clearance */
.signal-actions {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
}

/* Active Panel */
.active-panel .section-title {
  display: flex;
  align-items: center;
}

.active-panel .table-glass {
  margin-top: 12px;
}

/* Responsive */
@media (max-width: 1000px) {
  .emergency-types-grid {
    grid-template-columns: repeat(3, 1fr);
  }
  .location-row {
    flex-direction: column;
  }
  .location-row .form-group {
    width: 100% !important;
  }
}

@media (max-width: 600px) {
  .emergency-types-grid {
    grid-template-columns: repeat(2, 1fr);
  }
  .vehicle-grid {
    grid-template-columns: 1fr;
  }
  .dispatch-btn {
    padding: 14px 30px;
    font-size: 14px;
  }
}
</style>
