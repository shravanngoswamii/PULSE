<template>
  <div>
    <div class="page-header">
      <div>
        <h1>Missions</h1>
        <p>View all emergency missions</p>
      </div>
      <button class="btn btn-outline" @click="load">Refresh</button>
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
          <tr v-for="m in filtered" :key="m.id">
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
import { ref, computed, onMounted } from 'vue'
import api from '../api/client'

const missions = ref([])
const statusFilter = ref('')

const filtered = computed(() => {
  if (!statusFilter.value) return missions.value
  return missions.value.filter(m => m.status === statusFilter.value)
})

function formatDate(d) {
  if (!d) return '-'
  return new Date(d).toLocaleString()
}

async function load() {
  const res = await api.get('/admin/missions')
  missions.value = res.data
}

onMounted(load)
</script>
