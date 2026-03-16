<template>
  <div>
    <div class="page-header">
      <div>
        <h1>Vehicles</h1>
        <p>Manage emergency fleet</p>
      </div>
      <button class="btn btn-primary" @click="openCreate">+ Add Vehicle</button>
    </div>

    <div class="toolbar">
      <input v-model="search" class="form-input search-input" placeholder="Search vehicles..." />
      <select v-model="typeFilter" class="form-input" style="width: 160px">
        <option value="">All Types</option>
        <option value="ambulance">Ambulance</option>
        <option value="fire">Fire</option>
        <option value="police">Police</option>
      </select>
    </div>

    <div class="card">
      <table class="data-table">
        <thead>
          <tr>
            <th>ID</th>
            <th>Name</th>
            <th>Type</th>
            <th>Registration</th>
            <th>Status</th>
            <th>Location</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="v in filtered" :key="v.id">
            <td style="font-family: monospace; font-weight: 600">{{ v.id }}</td>
            <td>{{ v.name }}</td>
            <td><span class="badge" :class="typeClass(v.type)">{{ v.type }}</span></td>
            <td>{{ v.registration || '-' }}</td>
            <td><span class="badge" :class="v.status === 'active' ? 'badge-green' : v.status === 'maintenance' ? 'badge-yellow' : 'badge-gray'">{{ v.status }}</span></td>
            <td style="font-size: 12px; color: var(--text-secondary)">{{ v.current_lat ? `${v.current_lat.toFixed(4)}, ${v.current_lng.toFixed(4)}` : 'N/A' }}</td>
            <td>
              <button class="btn btn-outline btn-sm" @click="openEdit(v)">Edit</button>
              <button class="btn btn-danger btn-sm" @click="remove(v)" style="margin-left: 4px">Delete</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
      <div class="modal">
        <h2>{{ editing ? 'Edit Vehicle' : 'Add Vehicle' }}</h2>
        <form @submit.prevent="save">
          <div class="form-group" v-if="!editing">
            <label>Vehicle ID</label>
            <input v-model="form.id" class="form-input" placeholder="e.g. AMB-04" required />
          </div>
          <div class="form-group">
            <label>Name</label>
            <input v-model="form.name" class="form-input" required />
          </div>
          <div class="form-group">
            <label>Type</label>
            <select v-model="form.type" class="form-input">
              <option value="ambulance">Ambulance</option>
              <option value="fire">Fire</option>
              <option value="police">Police</option>
            </select>
          </div>
          <div class="form-group">
            <label>Registration</label>
            <input v-model="form.registration" class="form-input" placeholder="MH-12-XX-1234" />
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
import { ref, computed, onMounted } from 'vue'
import api from '../api/client'

const vehicles = ref([])
const search = ref('')
const typeFilter = ref('')
const showModal = ref(false)
const editing = ref(null)
const form = ref({ id: '', name: '', type: 'ambulance', registration: '' })

const filtered = computed(() => {
  return vehicles.value.filter(v => {
    const q = search.value.toLowerCase()
    const match = !q || v.name.toLowerCase().includes(q) || v.id.toLowerCase().includes(q)
    const matchType = !typeFilter.value || v.type === typeFilter.value
    return match && matchType
  })
})

function typeClass(t) {
  if (t === 'ambulance') return 'badge-green'
  if (t === 'fire') return 'badge-yellow'
  return 'badge-blue'
}

function openCreate() {
  editing.value = null
  form.value = { id: '', name: '', type: 'ambulance', registration: '' }
  showModal.value = true
}

function openEdit(v) {
  editing.value = v.id
  form.value = { name: v.name, type: v.type, registration: v.registration || '' }
  showModal.value = true
}

async function save() {
  try {
    if (editing.value) {
      await api.put(`/admin/vehicles/${editing.value}`, form.value)
    } else {
      await api.post('/admin/vehicles', form.value)
    }
    showModal.value = false
    await load()
  } catch (e) {
    alert(e.response?.data?.detail || 'Error')
  }
}

async function remove(v) {
  if (!confirm(`Delete vehicle "${v.id}"?`)) return
  await api.delete(`/admin/vehicles/${v.id}`)
  await load()
}

async function load() {
  const res = await api.get('/admin/vehicles')
  vehicles.value = res.data
}

onMounted(load)
</script>
