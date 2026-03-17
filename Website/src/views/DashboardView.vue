<template>
  <div class="dashboard-wrapper">
    <div class="page-header pulse-header">
      <div class="header-brand">
        <img src="../assets/green_logo.png" alt="PULSE" class="pulse-logo-large" />
        <div>
          <h1 class="glow-text">PULSE Command Center</h1>
          <p>Predictive Urban Lane Synchronization Ecosystem</p>
        </div>
      </div>
      <button class="btn btn-outline glow-btn" @click="loadStats">
        <svg viewBox="0 0 24 24" fill="none" class="icon-sm" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <polyline points="23 4 23 10 17 10"></polyline>
          <path d="M20.49 15a9 9 0 1 1-2.12-9.36L23 10"></path>
        </svg>
        Sync Data
      </button>
    </div>

    <div class="pulse-bento-grid">
      <!-- Top Row: High Priority -->
      <div class="bento-card hero-card mission-card">
        <div class="card-bg-effect circuit-bg"></div>
        <div class="bento-content">
          <div class="bento-header">
            <div class="icon-wrapper primary-glow">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></svg>
            </div>
            <span class="pulse-badge">LIVE TRACKING</span>
          </div>
          <div class="bento-body">
            <div class="value-large text-primary-glow">{{ stats.active_missions }}</div>
            <div class="bento-label">Active Missions</div>
          </div>
          <div class="bento-footer">
            <div class="trend text-primary">↑ {{ stats.completed_missions }} Completed all time</div>
          </div>
        </div>
      </div>

      <div class="bento-card hero-card alert-card">
        <div class="card-bg-effect pulse-warn" v-if="stats.active_alerts > 0"></div>
        <div class="bento-content">
          <div class="bento-header">
            <div class="icon-wrapper danger-glow">
              <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></svg>
            </div>
            <span class="pulse-badge danger" v-if="stats.active_alerts > 0">ATTENTION</span>
            <span class="pulse-badge outline" v-else>CLEAR</span>
          </div>
          <div class="bento-body">
            <div class="value-large" :class="stats.active_alerts > 0 ? 'text-danger-glow' : 'text-hint'">{{ stats.active_alerts }}</div>
            <div class="bento-label" :class="stats.active_alerts > 0 ? 'text-danger' : ''">Active Alerts</div>
          </div>
          <div class="bento-footer">
            <div class="sub" style="color: var(--text-hint); font-size: 13px;">System monitoring active</div>
          </div>
        </div>
      </div>

      <!-- Second Row: Infrastructure -->
      <div class="side-grid">
        <div class="bento-card standard-card">
          <div class="bento-header-inline">
            <div class="bento-label">Fleet Size</div>
            <svg class="icon-sm text-hint" style="color: var(--text-hint)" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="1" y="3" width="15" height="13"/><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></svg>
          </div>
          <div class="value-medium">{{ stats.total_vehicles }}</div>
          <div class="progress-bar"><div class="fill primary" style="width: 75%"></div></div>
          <div class="sub" style="color: var(--text-action); font-size: 12px; color: var(--text-secondary)">Total registered vehicles</div>
        </div>

        <div class="bento-card standard-card">
          <div class="bento-header-inline">
            <div class="bento-label">Managed Nodes</div>
            <svg class="icon-sm text-hint" style="color: var(--text-hint)" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="12" cy="5" r="3"/><circle cx="12" cy="12" r="3"/><circle cx="12" cy="19" r="3"/></svg>
          </div>
          <div class="value-medium">{{ stats.total_intersections }}</div>
          <div class="progress-bar"><div class="fill blue" style="width: 100%"></div></div>
          <div class="sub" style="color: var(--text-secondary); font-size: 12px;">Synchronized intersections</div>
        </div>
        
        <div class="bento-card standard-card">
          <div class="bento-header-inline">
            <div class="bento-label">Personnel</div>
            <svg class="icon-sm text-hint" style="color: var(--text-hint)" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/></svg>
          </div>
          <div class="value-medium">{{ stats.total_drivers + stats.total_operators }}</div>
          <div class="metrics-row">
            <div class="metric"><span class="dot green"></span> {{ stats.total_drivers }} Drv</div>
            <div class="metric" style="margin-left: 12px;"><span class="dot blue"></span> {{ stats.total_operators }} Ops</div>
          </div>
        </div>

        <div class="bento-card standard-card">
          <div class="bento-header-inline">
            <div class="bento-label">System Users</div>
            <svg class="icon-sm text-hint" style="color: var(--text-hint)" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="3" width="18" height="18" rx="2" ry="2"/><line x1="3" y1="9" x2="21" y2="9"/><line x1="9" y1="21" x2="9" y2="9"/></svg>
          </div>
          <div class="value-medium">{{ stats.total_users }}</div>
          <div class="sub" style="color: var(--text-secondary); font-size: 12px;">All active accounts</div>
        </div>
      </div>
    </div>

    <div class="card pulse-table-card table-glass">
      <div class="card-header">
        <h3 class="glow-text">Live Mission Feed</h3>
        <div class="live-indicator">
          <span class="pulse-dot"></span> Live
        </div>
      </div>
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

<style scoped>
.dashboard-wrapper {
  position: relative;
}

.pulse-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 32px;
}

.header-brand {
  display: flex;
  align-items: center;
  gap: 20px;
}

.pulse-logo-large {
  width: 64px;
  height: 64px;
  object-fit: contain;
  filter: drop-shadow(0 0 10px var(--primary-light));
}

.glow-text {
  color: var(--primary);
  text-shadow: 0 0 20px rgba(0, 230, 118, 0.4);
  font-weight: 800;
  letter-spacing: 0.5px;
}

.text-primary-glow {
  color: var(--primary) !important;
  text-shadow: 0 0 15px rgba(0, 230, 118, 0.5);
}

.text-danger-glow {
  color: var(--danger) !important;
  text-shadow: 0 0 15px rgba(255, 82, 82, 0.5);
}

.border-glow {
  border: 1px solid rgba(0, 230, 118, 0.3) !important;
  box-shadow: 0 0 20px rgba(0, 230, 118, 0.1) !important;
}

.border-danger {
  border: 1px solid rgba(255, 82, 82, 0.3) !important;
}

.text-danger {
  color: var(--danger) !important;
}

.text-primary {
  color: var(--primary) !important;
}

.glow-btn {
  display: flex;
  align-items: center;
  gap: 8px;
  border-color: var(--primary);
  color: var(--primary);
  background: var(--primary-bg);
  transition: all 0.3s ease;
}

.glow-btn:hover {
  background: var(--primary);
  color: #000;
  box-shadow: 0 0 15px var(--primary-light);
}

.icon-sm {
  width: 16px;
  height: 16px;
}

.pulse-table-card {
  position: relative;
  overflow: hidden;
  border-top: none;
}

.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 20px;
}

.live-indicator {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--danger);
  font-weight: 600;
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 1px;
}

.pulse-dot {
  width: 8px;
  height: 8px;
  background: var(--danger);
  border-radius: 50%;
  animation: pulse 1.5s infinite;
}

@keyframes pulse {
  0% { transform: scale(1); opacity: 1; box-shadow: 0 0 0 0 rgba(255, 82, 82, 0.7); }
  70% { transform: scale(1.1); opacity: 0.8; box-shadow: 0 0 0 8px rgba(255, 82, 82, 0); }
  100% { transform: scale(1); opacity: 1; box-shadow: 0 0 0 0 rgba(255, 82, 82, 0); }
}

/* Bento Grid System */
.pulse-bento-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
  margin-bottom: 36px;
}

.side-grid {
  grid-column: 1 / -1;
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 24px;
}

.bento-card {
  background: var(--glass-surface);
  backdrop-filter: blur(12px);
  border: 1px solid var(--border);
  border-radius: var(--radius-lg);
  position: relative;
  overflow: hidden;
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
}

.bento-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg);
  border-color: var(--glass-border);
}

.hero-card {
  padding: 30px;
  min-height: 200px;
  display: flex;
  flex-direction: column;
}

.hero-card.mission-card {
  border-color: rgba(0, 230, 118, 0.2);
  box-shadow: 0 8px 32px rgba(0, 230, 118, 0.05);
}

.hero-card.alert-card {
  border-color: rgba(255, 82, 82, 0.2);
  box-shadow: 0 8px 32px rgba(255, 82, 82, 0.05);
}

.bento-content {
  position: relative;
  z-index: 2;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.bento-header {
  display: flex;
  justify-content: space-between;
  align-items: flex-start;
  margin-bottom: auto;
}

.bento-header-inline {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
}

.icon-wrapper {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.icon-wrapper.primary-glow {
  background: rgba(0, 230, 118, 0.1);
  color: var(--primary);
  border: 1px solid rgba(0, 230, 118, 0.2);
  box-shadow: 0 0 15px rgba(0, 230, 118, 0.2);
}

.icon-wrapper.danger-glow {
  background: rgba(255, 82, 82, 0.1);
  color: var(--danger);
  border: 1px solid rgba(255, 82, 82, 0.2);
  box-shadow: 0 0 15px rgba(255, 82, 82, 0.2);
}

.icon-wrapper svg {
  width: 24px;
  height: 24px;
}

.pulse-badge {
  padding: 4px 10px;
  border-radius: 20px;
  font-size: 10px;
  font-weight: 700;
  letter-spacing: 1px;
  background: var(--primary-bg);
  color: var(--primary);
  border: 1px solid rgba(0, 230, 118, 0.3);
  display: flex;
  align-items: center;
  gap: 6px;
}

.pulse-badge::before {
  content: '';
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: currentColor;
  animation: pulse-op 1.5s infinite alternate;
}

.pulse-badge.danger {
  background: rgba(255, 82, 82, 0.1);
  color: var(--danger);
  border-color: rgba(255, 82, 82, 0.3);
}

.pulse-badge.outline {
  background: transparent;
  color: var(--text-hint);
  border-color: var(--border);
}
.pulse-badge.outline::before { display: none; }

.bento-body {
  margin-top: 24px;
}

.value-large {
  font-size: 56px;
  font-weight: 800;
  line-height: 1;
  letter-spacing: -1.5px;
  margin-bottom: 8px;
}

.value-medium {
  font-size: 36px;
  font-weight: 800;
  color: var(--text);
  line-height: 1.1;
  margin-bottom: 12px;
}

.bento-label {
  font-size: 13px;
  text-transform: uppercase;
  letter-spacing: 1.5px;
  font-weight: 600;
  color: var(--text-secondary);
}

.bento-footer {
  margin-top: 20px;
  padding-top: 16px;
  border-top: 1px solid var(--border);
}

.trend {
  font-size: 13px;
  font-weight: 600;
}

.standard-card {
  padding: 24px;
}

.progress-bar {
  height: 4px;
  background: var(--glass-border);
  border-radius: 4px;
  margin-bottom: 12px;
  overflow: hidden;
}

.progress-bar .fill {
  height: 100%;
  border-radius: 4px;
}

.progress-bar .fill.primary { background: var(--primary); box-shadow: 0 0 10px var(--primary); }
.progress-bar .fill.blue { background: var(--blue); box-shadow: 0 0 10px var(--blue); }

.metrics-row {
  display: flex;
  gap: 12px;
  margin-top: 12px;
}

.metric {
  font-size: 12px;
  color: var(--text-secondary);
  display: flex;
  align-items: center;
  gap: 4px;
  font-weight: 600;
}

.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
}
.dot.green { background: var(--primary); box-shadow: 0 0 8px var(--primary); }
.dot.blue { background: var(--blue); box-shadow: 0 0 8px var(--blue); }

/* Decorative Backgrounds */
.card-bg-effect {
  position: absolute;
  top: 0; left: 0; right: 0; bottom: 0;
  z-index: 1;
  pointer-events: none;
}

.circuit-bg {
  background-image: radial-gradient(circle at 100% 0%, rgba(0, 230, 118, 0.15) 0%, transparent 60%),
                    linear-gradient(rgba(0, 230, 118, 0.02) 1px, transparent 1px),
                    linear-gradient(90deg, rgba(0, 230, 118, 0.02) 1px, transparent 1px);
  background-size: 100% 100%, 20px 20px, 20px 20px;
  opacity: 0.8;
}

.pulse-warn {
  background: radial-gradient(circle at 100% 100%, rgba(255, 82, 82, 0.15) 0%, transparent 60%);
  animation: pulse-op 2s infinite alternate;
}

@keyframes pulse-op {
  0% { opacity: 0.5; }
  100% { opacity: 1; }
}

@media (max-width: 1400px) {
  .side-grid { grid-template-columns: repeat(2, 1fr); }
}
</style>
