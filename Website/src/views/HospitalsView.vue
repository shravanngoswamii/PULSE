<template>
  <div>
    <div class="page-header">
      <div>
        <h1>Hospitals</h1>
        <p>Manage hospital locations for emergency routing</p>
      </div>
      <button class="btn btn-primary" @click="openCreate">+ Add Hospital</button>
    </div>

    <div class="card">
      <table class="data-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Address</th>
            <th>Coordinates</th>
            <th>Phone</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="h in hospitals" :key="h.id">
            <td style="font-weight: 600">{{ h.name }}</td>
            <td>{{ h.address || '-' }}</td>
            <td style="font-size: 12px; color: var(--text-secondary)">{{ h.lat.toFixed(4) }}, {{ h.lng.toFixed(4) }}</td>
            <td>{{ h.phone || '-' }}</td>
            <td>
              <button class="btn btn-danger btn-sm" @click="remove(h)">Delete</button>
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
import { ref, onMounted } from 'vue'
import api from '../api/client'

const hospitals = ref([])
const showModal = ref(false)
const form = ref({ name: '', address: '', lat: 18.52, lng: 73.86, phone: '' })

function openCreate() {
  form.value = { name: '', address: '', lat: 18.52, lng: 73.86, phone: '' }
  showModal.value = true
}

async function save() {
  try {
    await api.post('/admin/hospitals', form.value)
    showModal.value = false
    await load()
  } catch (e) {
    alert(e.response?.data?.detail || 'Error')
  }
}

async function remove(h) {
  if (!confirm(`Delete "${h.name}"?`)) return
  await api.delete(`/admin/hospitals/${h.id}`)
  await load()
}

async function load() {
  const res = await api.get('/admin/hospitals')
  hospitals.value = res.data
}

onMounted(load)
</script>
