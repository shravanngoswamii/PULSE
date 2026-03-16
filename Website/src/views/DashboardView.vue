<template>
  <div>
    <div class="page-header">
      <div>
        <h1>Dashboard</h1>
        <p>System overview and statistics</p>
      </div>
      <button class="btn btn-outline" @click="loadStats">Refresh</button>
    </div>

    <div class="stats-grid">
      <div class="stat-card">
        <div class="label">Total Drivers</div>
        <div class="value">{{ stats.total_drivers }}</div>
        <div class="sub">Registered drivers</div>
      </div>
      <div class="stat-card">
        <div class="label">Vehicles</div>
        <div class="value">{{ stats.total_vehicles }}</div>
        <div class="sub">Fleet size</div>
      </div>
      <div class="stat-card">
        <div class="label">Intersections</div>
        <div class="value">{{ stats.total_intersections }}</div>
        <div class="sub">Managed nodes</div>
      </div>
      <div class="stat-card">
        <div class="label">Active Missions</div>
        <div class="value" style="color: var(--primary)">{{ stats.active_missions }}</div>
        <div class="sub">In progress now</div>
      </div>
      <div class="stat-card">
        <div class="label">Completed</div>
        <div class="value">{{ stats.completed_missions }}</div>
        <div class="sub">Total missions done</div>
      </div>
      <div class="stat-card">
        <div class="label">Active Alerts</div>
        <div class="value" :style="{ color: stats.active_alerts > 0 ? 'var(--danger)' : 'var(--text)' }">{{ stats.active_alerts }}</div>
        <div class="sub">Requires attention</div>
      </div>
      <div class="stat-card">
        <div class="label">Operators</div>
        <div class="value">{{ stats.total_operators }}</div>
        <div class="sub">Traffic operators</div>
      </div>
      <div class="stat-card">
        <div class="label">Total Users</div>
        <div class="value">{{ stats.total_users }}</div>
        <div class="sub">All roles</div>
      </div>
    </div>

    <div class="card">
      <h3 style="margin-bottom: 16px">Recent Missions</h3>
      <table class="data-table" v-if="missions.length">
        <thead>
          <tr>
            <th>Mission ID</th>
            <th>Vehicle</th>
            <th>Type</th>
            <th>Priority</th>
            <th>Destination</th>
            <th>Status</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="m in missions" :key="m.id">
            <td style="font-family: monospace; font-size: 13px">{{ m.id }}</td>
            <td>{{ m.vehicle_name || m.vehicle_id }}</td>
            <td>{{ m.incident_type }}</td>
            <td><span class="badge" :class="priorityClass(m.priority)">{{ m.priority }}</span></td>
            <td>{{ m.destination_name || 'N/A' }}</td>
            <td><span class="badge" :class="statusClass(m.status)">{{ m.status }}</span></td>
          </tr>
        </tbody>
      </table>
      <p v-else style="color: var(--text-hint); text-align: center; padding: 24px">No missions yet</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../api/client'

const stats = ref({
  total_users: 0, total_drivers: 0, total_operators: 0,
  total_vehicles: 0, total_intersections: 0,
  active_missions: 0, completed_missions: 0, active_alerts: 0,
})
const missions = ref([])

function priorityClass(p) {
  if (p === 'critical') return 'badge-red'
  if (p === 'high') return 'badge-yellow'
  return 'badge-gray'
}

function statusClass(s) {
  if (s === 'active') return 'badge-green'
  if (s === 'completed') return 'badge-blue'
  return 'badge-gray'
}

async function loadStats() {
  try {
    const [s, m] = await Promise.all([
      api.get('/admin/stats'),
      api.get('/admin/missions'),
    ])
    stats.value = s.data
    missions.value = m.data.slice(0, 10)
  } catch (e) {
    console.error('Failed to load dashboard', e)
  }
}

onMounted(loadStats)
</script>
