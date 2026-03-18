<template>
  <div>
    <div class="page-header">
      <div>
        <h1>Intersections</h1>
        <p>Manage traffic intersections and signals</p>
      </div>
      <button class="btn btn-primary" @click="openCreate">+ Add Intersection</button>
    </div>

    <!-- Map -->
    <div class="card pulse-table-card table-glass" style="margin-bottom: 24px">
      <div class="card-header">
        <h3 style="color: var(--primary); margin: 0">Signal Network Map</h3>
        <div class="map-legend-inline">
          <span class="legend-chip" style="--c: #ff5252">Emergency</span>
          <span class="legend-chip" style="--c: #ffd740">Manual</span>
          <span class="legend-chip" style="--c: #00e676">Automatic</span>
        </div>
      </div>
      <div id="signal-map" style="height: 380px; border-radius: 8px; overflow: hidden; border: 1px solid var(--border)"></div>
    </div>

    <div class="card pulse-table-card table-glass">
      <table class="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>District</th>
            <th>Coordinates</th>
            <th>Signal Mode</th>
            <th>Phase</th>
            <th>Congestion</th>
            <th style="text-align: right;">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="i in intersections" :key="i.id" @click="flyTo(i)" class="clickable-row" :class="{ 'row-active': selectedId === i.id }">
            <td style="font-family: monospace; font-weight: 800; color: var(--primary)">{{ i.id }}</td>
            <td style="font-weight: 600">{{ i.name }}</td>
            <td style="opacity: 0.9">{{ i.district }}</td>
            <td style="font-size: 13px; color: var(--text-secondary); font-family: monospace;">{{ i.lat.toFixed(4) }}, {{ i.lng.toFixed(4) }}</td>
            <td><span class="badge" :class="modeClass(i.signal_mode)">{{ i.signal_mode }}</span></td>
            <td><span class="badge" :class="phaseClass(i.current_phase)">{{ i.current_phase }}</span></td>
            <td><span class="badge" :class="congestionClass(i.congestion_level)">{{ i.congestion_level }}</span></td>
            <td style="text-align: right;" @click.stop>
              <button class="btn btn-outline btn-sm action-btn" @click="openEdit(i)">
                <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path></svg>
              </button>
              <button class="btn btn-danger btn-sm action-btn" @click="remove(i)" style="margin-left: 6px">
                <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
      <div class="modal">
        <h2>{{ editing ? 'Edit Intersection' : 'Add Intersection' }}</h2>
        <form @submit.prevent="save">
          <div class="form-group" v-if="!editing">
            <label>ID</label>
            <input v-model="form.id" class="form-input" placeholder="INT-XXX" required />
          </div>
          <div class="form-group">
            <label>Name</label>
            <input v-model="form.name" class="form-input" required />
          </div>
          <div class="form-group">
            <label>District</label>
            <input v-model="form.district" class="form-input" required />
          </div>
          <div style="display: flex; gap: 12px">
            <div class="form-group" style="flex: 1">
              <label>Latitude</label>
              <input v-model.number="form.lat" type="number" step="any" class="form-input" required />
            </div>
            <div class="form-group" style="flex: 1">
              <label>Longitude</label>
              <input v-model.number="form.lng" type="number" step="any" class="form-input" required />
            </div>
          </div>
          <div class="modal-actions">
            <button type="button" class="btn btn-outline" @click="showModal = false">Cancel</button>
            <button type="submit" class="btn btn-primary">{{ editing ? 'Update' : 'Create' }}</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import api from '../api/client'

const intersections = ref([])
const showModal = ref(false)
const editing = ref(null)
const selectedId = ref(null)
const form = ref({ id: '', name: '', district: '', lat: 22.7196, lng: 75.8577 })

let mapInstance = null
const markers = {}

function signalColor(mode) {
  if (mode === 'emergency') return '#ff5252'
  if (mode === 'manual') return '#ffd740'
  return '#00e676'
}

function modeClass(m) {
  if (m === 'emergency') return 'badge-red'
  if (m === 'manual') return 'badge-yellow'
  return 'badge-green'
}
function phaseClass(p) {
  if (p === 'green') return 'badge-green'
  if (p === 'red') return 'badge-red'
  return 'badge-yellow'
}
function congestionClass(c) {
  if (c === 'high') return 'badge-red'
  if (c === 'moderate') return 'badge-yellow'
  return 'badge-green'
}

function flyTo(i) {
  selectedId.value = i.id
  if (mapInstance && i.lat && i.lng) {
    mapInstance.flyTo([i.lat, i.lng], 17, { duration: 0.8 })
    if (markers[i.id]) markers[i.id].openPopup()
  }
}

function initMap() {
  const L = window.L
  if (!L || mapInstance) return
  mapInstance = L.map('signal-map', { center: [22.72, 75.86], zoom: 13, zoomControl: true, attributionControl: false })
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { maxZoom: 19, subdomains: 'abcd' }).addTo(mapInstance)
  addMarkers()
}

function addMarkers() {
  const L = window.L
  if (!L || !mapInstance) return
  Object.values(markers).forEach(m => mapInstance.removeLayer(m))
  const bounds = []
  intersections.value.forEach(ix => {
    if (!ix.lat || !ix.lng) return
    const color = signalColor(ix.signal_mode)
    const m = L.circleMarker([ix.lat, ix.lng], {
      radius: 8, fillColor: color, color: 'rgba(255,255,255,0.4)', weight: 2, fillOpacity: 0.9,
    }).addTo(mapInstance)
    m.bindPopup(`<div style="font-family:Inter,sans-serif;font-size:12px"><strong>${ix.name}</strong><br/>District: ${ix.district}<br/>Mode: <span style="color:${color};font-weight:700">${ix.signal_mode}</span><br/>Phase: ${ix.current_phase}<br/>Congestion: ${ix.congestion_level}</div>`)
    markers[ix.id] = m
    bounds.push([ix.lat, ix.lng])
  })
  if (bounds.length > 1) mapInstance.fitBounds(bounds, { padding: [30, 30], maxZoom: 14 })
}

function openCreate() {
  editing.value = null
  form.value = { id: '', name: '', district: '', lat: 22.7196, lng: 75.8577 }
  showModal.value = true
}

function openEdit(i) {
  editing.value = i.id
  form.value = { name: i.name, district: i.district, lat: i.lat, lng: i.lng }
  showModal.value = true
}

async function save() {
  try {
    if (editing.value) {
      await api.put(`/admin/intersections/${editing.value}`, form.value)
    } else {
      await api.post('/admin/intersections', form.value)
    }
    showModal.value = false
    await load()
  } catch (e) { alert(e.response?.data?.detail || 'Error') }
}

async function remove(i) {
  if (!confirm(`Delete intersection "${i.name}"?`)) return
  await api.delete(`/admin/intersections/${i.id}`)
  await load()
}

async function load() {
  const res = await api.get('/admin/intersections')
  intersections.value = res.data
  await nextTick()
  addMarkers()
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
.map-legend-inline { display: flex; gap: 10px; }
.legend-chip {
  display: flex; align-items: center; gap: 6px;
  font-size: 11px; color: var(--text-secondary); font-weight: 500;
}
.legend-chip::before {
  content: ''; width: 10px; height: 10px; border-radius: 50%;
  background: var(--c); box-shadow: 0 0 8px var(--c);
}
</style>
