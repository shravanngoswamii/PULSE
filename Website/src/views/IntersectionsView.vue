<template>
  <div>
    <div class="page-header">
      <div>
        <h1>Intersections</h1>
        <p>Manage traffic intersections and signals</p>
      </div>
      <button class="btn btn-primary" @click="openCreate">+ Add Intersection</button>
    </div>

    <div class="card">
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
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="i in intersections" :key="i.id">
            <td style="font-family: monospace">{{ i.id }}</td>
            <td style="font-weight: 600">{{ i.name }}</td>
            <td>{{ i.district }}</td>
            <td style="font-size: 12px; color: var(--text-secondary)">{{ i.lat.toFixed(4) }}, {{ i.lng.toFixed(4) }}</td>
            <td><span class="badge" :class="modeClass(i.signal_mode)">{{ i.signal_mode }}</span></td>
            <td><span class="badge" :class="phaseClass(i.current_phase)">{{ i.current_phase }}</span></td>
            <td><span class="badge" :class="congestionClass(i.congestion_level)">{{ i.congestion_level }}</span></td>
            <td>
              <button class="btn btn-outline btn-sm" @click="openEdit(i)">Edit</button>
              <button class="btn btn-danger btn-sm" @click="remove(i)" style="margin-left: 4px">Delete</button>
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
import { ref, onMounted } from 'vue'
import api from '../api/client'

const intersections = ref([])
const showModal = ref(false)
const editing = ref(null)
const form = ref({ id: '', name: '', district: '', lat: 18.52, lng: 73.86 })

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

function openCreate() {
  editing.value = null
  form.value = { id: '', name: '', district: '', lat: 18.52, lng: 73.86 }
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
  } catch (e) {
    alert(e.response?.data?.detail || 'Error')
  }
}

async function remove(i) {
  if (!confirm(`Delete intersection "${i.name}"?`)) return
  await api.delete(`/admin/intersections/${i.id}`)
  await load()
}

async function load() {
  const res = await api.get('/admin/intersections')
  intersections.value = res.data
}

onMounted(load)
</script>
