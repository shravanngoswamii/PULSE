<template>
  <div>
    <div class="page-header">
      <div>
        <h1>Alerts</h1>
        <p>Manage traffic alerts and incidents</p>
      </div>
      <button class="btn btn-primary" @click="openCreate">+ Create Alert</button>
    </div>

    <div class="card">
      <table class="data-table">
        <thead>
          <tr>
            <th>Title</th>
            <th>Type</th>
            <th>Severity</th>
            <th>Location</th>
            <th>Status</th>
            <th>Created</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="a in alerts" :key="a.id">
            <td style="font-weight: 600">{{ a.title }}</td>
            <td><span class="badge badge-gray">{{ a.type }}</span></td>
            <td><span class="badge" :class="a.severity === 'high' ? 'badge-red' : a.severity === 'medium' ? 'badge-yellow' : 'badge-green'">{{ a.severity }}</span></td>
            <td>{{ a.location || 'N/A' }}</td>
            <td><span class="badge" :class="a.is_active ? 'badge-red' : 'badge-gray'">{{ a.is_active ? 'Active' : 'Cleared' }}</span></td>
            <td style="font-size: 12px">{{ formatDate(a.created_at) }}</td>
            <td>
              <button class="btn btn-danger btn-sm" @click="remove(a)">Delete</button>
            </td>
          </tr>
        </tbody>
      </table>
      <p v-if="!alerts.length" style="text-align: center; padding: 24px; color: var(--text-hint)">No alerts</p>
    </div>

    <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
      <div class="modal">
        <h2>Create Alert</h2>
        <form @submit.prevent="save">
          <div class="form-group">
            <label>Title</label>
            <input v-model="form.title" class="form-input" required />
          </div>
          <div class="form-group">
            <label>Type</label>
            <select v-model="form.type" class="form-input">
              <option value="accident">Accident</option>
              <option value="signal_failure">Signal Failure</option>
              <option value="congestion">Congestion</option>
              <option value="emergency_vehicle">Emergency Vehicle</option>
            </select>
          </div>
          <div class="form-group">
            <label>Severity</label>
            <select v-model="form.severity" class="form-input">
              <option value="high">High</option>
              <option value="medium">Medium</option>
              <option value="low">Low</option>
            </select>
          </div>
          <div class="form-group">
            <label>Location</label>
            <input v-model="form.location" class="form-input" />
          </div>
          <div class="form-group">
            <label>Description</label>
            <textarea v-model="form.description" class="form-input" rows="3"></textarea>
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

const alerts = ref([])
const showModal = ref(false)
const form = ref({ title: '', type: 'accident', severity: 'medium', location: '', description: '' })

function formatDate(d) {
  if (!d) return '-'
  return new Date(d).toLocaleString()
}

function openCreate() {
  form.value = { title: '', type: 'accident', severity: 'medium', location: '', description: '' }
  showModal.value = true
}

async function save() {
  try {
    await api.post('/admin/alerts', form.value)
    showModal.value = false
    await load()
  } catch (e) {
    alert(e.response?.data?.detail || 'Error')
  }
}

async function remove(a) {
  if (!confirm(`Delete alert "${a.title}"?`)) return
  await api.delete(`/admin/alerts/${a.id}`)
  await load()
}

async function load() {
  const res = await api.get('/admin/alerts')
  alerts.value = res.data
}

onMounted(load)
</script>
