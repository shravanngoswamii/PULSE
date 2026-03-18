<template>
  <div>
    <div class="page-header">
      <div>
        <h1>Missions</h1>
        <p>View all emergency missions</p>
      </div>
      <button class="btn btn-outline" @click="load">Refresh</button>
    </div>

    <!-- Map showing selected mission route -->
    <div class="card pulse-table-card table-glass" style="margin-bottom: 24px">
      <div class="card-header">
        <h3 style="color: var(--primary); margin: 0">Mission Map</h3>
        <div style="font-size: 12px; color: var(--text-secondary)">
          {{ selectedMission ? `Mission: ${selectedMission.id}` : 'Click a mission row to view on map' }}
        </div>
      </div>
      <div id="mission-map" style="height: 360px; border-radius: 8px; overflow: hidden; border: 1px solid var(--border)"></div>
      <div class="map-legend-inline" style="margin-top: 10px">
        <span class="legend-chip" style="--c: #ff5252">Origin</span>
        <span class="legend-chip" style="--c: #42a5f5">Destination</span>
        <span class="legend-chip" style="--c: #00e676">Vehicle</span>
      </div>
    </div>

    <div class="toolbar">
      <select v-model="statusFilter" class="form-input" style="width: 160px">
        <option value="">All Statuses</option>
        <option value="active">Active</option>
        <option value="completed">Completed</option>
        <option value="cancelled">Cancelled</option>
      </select>
    </div>

    <div class="card pulse-table-card table-glass">
      <table class="data-table">
        <thead>
          <tr>
            <th>Mission ID</th>
            <th>Vehicle</th>
            <th>Driver</th>
            <th>Incident</th>
            <th>Priority</th>
            <th>Destination</th>
            <th>ETA</th>
            <th>Distance</th>
            <th>Status</th>
            <th style="text-align: right">Started</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="m in filtered" :key="m.id" @click="showMission(m)" class="clickable-row" :class="{ 'row-active': selectedMission?.id === m.id }">
            <td style="font-family: monospace; font-size: 13px; font-weight: 800; color: var(--primary)">{{ m.id }}</td>
            <td style="font-weight: 600">{{ m.vehicle_name || m.vehicle_id }}</td>
            <td style="opacity: 0.9">{{ m.driver_name || '-' }}</td>
            <td>{{ m.incident_type }}</td>
            <td><span class="badge" :class="m.priority === 'critical' ? 'badge-red' : m.priority === 'high' ? 'badge-yellow' : 'badge-gray'">{{ m.priority }}</span></td>
            <td>{{ m.destination_name || 'N/A' }}</td>
            <td style="font-family: monospace">{{ m.eta_minutes ? m.eta_minutes + ' min' : '-' }}</td>
            <td style="font-family: monospace">{{ m.distance_km ? m.distance_km + ' km' : '-' }}</td>
            <td><span class="badge" :class="m.status === 'active' ? 'badge-green' : m.status === 'completed' ? 'badge-blue' : 'badge-gray'">{{ m.status }}</span></td>
            <td style="font-size: 12px; text-align: right; opacity: 0.8">{{ formatDate(m.started_at) }}</td>
          </tr>
        </tbody>
      </table>
      <p v-if="!filtered.length" style="text-align: center; padding: 24px; color: var(--text-hint)">No missions found</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, nextTick } from 'vue'
import api from '../api/client'

const missions = ref([])
const statusFilter = ref('')
const selectedMission = ref(null)

let mapInstance = null
let mapMarkers = []

const filtered = computed(() => {
  if (!statusFilter.value) return missions.value
  return missions.value.filter(m => m.status === statusFilter.value)
})

function formatDate(d) {
  if (!d) return '-'
  return new Date(d).toLocaleString()
}

function initMap() {
  const L = window.L
  if (!L || mapInstance) return
  mapInstance = L.map('mission-map', { center: [22.72, 75.86], zoom: 13, zoomControl: true, attributionControl: false })
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { maxZoom: 19, subdomains: 'abcd' }).addTo(mapInstance)
  // Show all active missions as vehicle dots
  showAllActive()
}

function showAllActive() {
  const L = window.L
  if (!L || !mapInstance) return
  clearMarkers()
  const bounds = []
  missions.value.forEach(m => {
    if (m.current_lat && m.current_lng && m.status === 'active') {
      const color = '#00e676'
      const mk = L.circleMarker([m.current_lat, m.current_lng], { radius: 8, fillColor: color, color: '#fff', weight: 2, fillOpacity: 0.9 }).addTo(mapInstance)
      mk.bindPopup(`<div style="font-family:Inter,sans-serif;font-size:12px"><strong>${m.vehicle_name || m.vehicle_id}</strong><br/>${m.incident_type} → ${m.destination_name || 'N/A'}</div>`)
      mapMarkers.push(mk)
      bounds.push([m.current_lat, m.current_lng])
    }
  })
  if (bounds.length > 1) mapInstance.fitBounds(bounds, { padding: [30, 30], maxZoom: 14 })
}

function clearMarkers() {
  mapMarkers.forEach(m => mapInstance.removeLayer(m))
  mapMarkers = []
}

function showMission(m) {
  selectedMission.value = m
  const L = window.L
  if (!L || !mapInstance) return
  clearMarkers()
  const bounds = []

  // Origin
  if (m.origin_lat && m.origin_lng) {
    const mk = L.circleMarker([m.origin_lat, m.origin_lng], { radius: 10, fillColor: '#ff5252', color: '#fff', weight: 2, fillOpacity: 0.9 }).addTo(mapInstance)
    mk.bindPopup('Origin').bindTooltip('START', { permanent: true, direction: 'top', offset: [0, -8] })
    mapMarkers.push(mk)
    bounds.push([m.origin_lat, m.origin_lng])
  }

  // Destination
  if (m.destination_lat && m.destination_lng) {
    const mk = L.circleMarker([m.destination_lat, m.destination_lng], { radius: 10, fillColor: '#42a5f5', color: '#fff', weight: 2, fillOpacity: 0.9 }).addTo(mapInstance)
    mk.bindPopup(m.destination_name || 'Destination').bindTooltip(m.destination_name || 'END', { permanent: true, direction: 'top', offset: [0, -8] })
    mapMarkers.push(mk)
    bounds.push([m.destination_lat, m.destination_lng])
  }

  // Vehicle current position
  if (m.current_lat && m.current_lng) {
    const icon = L.divIcon({
      className: '',
      html: `<div style="width:16px;height:16px;background:#00e676;border:3px solid #fff;border-radius:50%;box-shadow:0 0 10px rgba(0,230,118,0.6)"></div>`,
      iconSize: [16, 16], iconAnchor: [8, 8],
    })
    const mk = L.marker([m.current_lat, m.current_lng], { icon }).addTo(mapInstance)
    mk.bindPopup(`${m.vehicle_name || 'Vehicle'}`)
    mapMarkers.push(mk)
    bounds.push([m.current_lat, m.current_lng])
  }

  if (bounds.length > 1) mapInstance.fitBounds(bounds, { padding: [40, 40], maxZoom: 15 })
  else if (bounds.length === 1) mapInstance.flyTo(bounds[0], 15, { duration: 0.8 })
}

async function load() {
  const res = await api.get('/admin/missions')
  missions.value = res.data
}

onMounted(async () => {
  await load()
  await nextTick()
  initMap()
})
</script>

<style scoped>
.clickable-row { cursor: pointer; transition: background 0.15s; }
.clickable-row:hover { background: var(--sidebar-hover) !important; }
.row-active { background: var(--primary-bg) !important; border-left: 3px solid var(--primary); }
.card-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
.map-legend-inline { display: flex; gap: 14px; }
.legend-chip {
  display: flex; align-items: center; gap: 6px;
  font-size: 11px; color: var(--text-secondary); font-weight: 500;
}
.legend-chip::before {
  content: ''; width: 10px; height: 10px; border-radius: 50%;
  background: var(--c); box-shadow: 0 0 8px var(--c);
}
</style>
