<template>
  <div>
    <div class="page-header">
      <div>
        <h1>Hospitals</h1>
        <p>Emergency hospital locations for routing</p>
      </div>
      <button class="btn btn-primary" @click="openCreate">+ Add Hospital</button>
    </div>

    <!-- Map -->
    <div class="card pulse-table-card table-glass" style="margin-bottom: 24px">
      <div class="card-header">
        <h3 style="color: var(--primary); margin: 0">Hospital Locations</h3>
        <div style="font-size: 12px; color: var(--text-secondary)">Click a row to locate on map</div>
      </div>
      <div id="hospital-map" style="height: 360px; border-radius: 8px; overflow: hidden; border: 1px solid var(--border)"></div>
    </div>

    <!-- Table -->
    <div class="card pulse-table-card table-glass">
      <table class="data-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Address</th>
            <th>Coordinates</th>
            <th>Phone</th>
            <th style="text-align: right;">Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="h in hospitals" :key="h.id" @click="flyTo(h)" class="clickable-row" :class="{ 'row-active': selectedId === h.id }">
            <td style="font-weight: 600; color: var(--primary)">
              <div style="display: flex; align-items: center; gap: 8px;">
                <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 3h18v18H3z"/><path d="M12 7v10"/><path d="M7 12h10"/></svg>
                {{ h.name }}
              </div>
            </td>
            <td style="opacity: 0.9">{{ h.address || '-' }}</td>
            <td style="font-size: 13px; color: var(--text-secondary); font-family: monospace;">{{ h.lat.toFixed(4) }}, {{ h.lng.toFixed(4) }}</td>
            <td style="opacity: 0.9">{{ h.phone || '-' }}</td>
            <td style="text-align: right;" @click.stop>
              <button class="btn btn-danger btn-sm action-btn" @click="remove(h)">
                <svg viewBox="0 0 24 24" width="14" height="14" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><polyline points="3 6 5 6 21 6"></polyline><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path><line x1="10" y1="11" x2="10" y2="17"></line><line x1="14" y1="11" x2="14" y2="17"></line></svg>
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
      <div class="modal">
        <h2>Add Hospital</h2>
        <form @submit.prevent="save">
          <div class="form-group">
            <label>Name</label>
            <input v-model="form.name" class="form-input" required />
          </div>
          <div class="form-group">
            <label>Address</label>
            <input v-model="form.address" class="form-input" />
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
          <div class="form-group">
            <label>Phone</label>
            <input v-model="form.phone" class="form-input" />
          </div>
          <div class="modal-actions">
            <button type="button" class="btn btn-outline" @click="showModal = false">Cancel</button>
            <button type="submit" class="btn btn-primary">Create</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, nextTick } from 'vue'
import api from '../api/client'

const hospitals = ref([])
const showModal = ref(false)
const selectedId = ref(null)
const form = ref({ name: '', address: '', lat: 22.72, lng: 75.86, phone: '' })

let mapInstance = null
const markers = {}

function openCreate() {
  form.value = { name: '', address: '', lat: 22.72, lng: 75.86, phone: '' }
  showModal.value = true
}

function flyTo(h) {
  selectedId.value = h.id
  if (mapInstance && h.lat && h.lng) {
    mapInstance.flyTo([h.lat, h.lng], 16, { duration: 0.8 })
    if (markers[h.id]) markers[h.id].openPopup()
  }
}

function initMap() {
  const L = window.L
  if (!L || mapInstance) return
  mapInstance = L.map('hospital-map', { center: [22.72, 75.86], zoom: 13, zoomControl: true, attributionControl: false })
  L.tileLayer('https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png', { maxZoom: 19, subdomains: 'abcd' }).addTo(mapInstance)
  addMarkers()
}

function addMarkers() {
  const L = window.L
  if (!L || !mapInstance) return
  Object.values(markers).forEach(m => mapInstance.removeLayer(m))
  hospitals.value.forEach(h => {
    if (!h.lat || !h.lng) return
    const icon = L.divIcon({
      className: 'hospital-marker',
      html: `<div style="width:24px;height:24px;display:flex;align-items:center;justify-content:center;background:#EF4444;border-radius:6px;color:#fff;font-weight:900;font-size:14px;box-shadow:0 0 10px rgba(239,68,68,0.5);border:2px solid rgba(255,255,255,0.3)">+</div>`,
      iconSize: [24, 24], iconAnchor: [12, 12],
    })
    const m = L.marker([h.lat, h.lng], { icon }).addTo(mapInstance)
    m.bindPopup(`<div style="font-family:Inter,sans-serif;font-size:12px"><strong>${h.name}</strong><br/>${h.address || ''}<br/>${h.phone || ''}</div>`)
    markers[h.id] = m
  })
  if (hospitals.value.length > 0) {
    const bounds = hospitals.value.filter(h => h.lat && h.lng).map(h => [h.lat, h.lng])
    if (bounds.length) mapInstance.fitBounds(bounds, { padding: [30, 30], maxZoom: 14 })
  }
}

async function save() {
  try {
    await api.post('/admin/hospitals', form.value)
    showModal.value = false
    await load()
  } catch (e) { alert(e.response?.data?.detail || 'Error') }
}

async function remove(h) {
  if (!confirm(`Delete "${h.name}"?`)) return
  await api.delete(`/admin/hospitals/${h.id}`)
  await load()
}

async function load() {
  const res = await api.get('/admin/hospitals')
  hospitals.value = res.data
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
</style>
