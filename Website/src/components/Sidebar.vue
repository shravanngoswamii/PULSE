<template>
  <aside class="sidebar">
    <div class="mac-controls">
      <div class="mac-dot red"></div>
      <div class="mac-dot yellow"></div>
      <div class="mac-dot green"></div>
    </div>
    <div class="sidebar-brand">
      <img src="../assets/green_logo.png" alt="PULSE Logo" class="brand-icon-img" />
      <div>
        <div class="brand-name">PULSE</div>
        <div class="brand-sub">Super Admin</div>
      </div>
    </div>

    <nav class="sidebar-nav">
      <router-link v-for="item in navItems" :key="item.path" :to="item.path" class="nav-item" :class="{ active: route.path === item.path }">
        <svg class="nav-icon-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <template v-if="item.icon === 'grid'"><rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/></template>
          <template v-if="item.icon === 'users'"><path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M23 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></template>
          <template v-if="item.icon === 'truck'"><rect x="1" y="3" width="15" height="13"/><polygon points="16 8 20 8 23 11 23 16 16 16 16 8"/><circle cx="5.5" cy="18.5" r="2.5"/><circle cx="18.5" cy="18.5" r="2.5"/></template>
          <template v-if="item.icon === 'signal'"><circle cx="12" cy="5" r="3"/><circle cx="12" cy="12" r="3"/><circle cx="12" cy="19" r="3"/></template>
          <template v-if="item.icon === 'target'"><circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/></template>
          <template v-if="item.icon === 'alert'"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z"/><line x1="12" y1="9" x2="12" y2="13"/><line x1="12" y1="17" x2="12.01" y2="17"/></template>
          <template v-if="item.icon === 'hospital'"><path d="M3 3h18v18H3z"/><path d="M12 7v10"/><path d="M7 12h10"/></template>
          <template v-if="item.icon === 'zap'"><polygon points="13 2 3 14 12 14 11 22 21 10 12 10 13 2"/></template>
        </svg>
        <span>{{ item.label }}</span>
      </router-link>
    </nav>

    <div class="sidebar-footer">
      <button class="theme-toggle-btn" @click="toggleTheme" title="Toggle Theme">
        <svg v-if="!isLightMode" class="nav-icon-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="5"></circle>
          <line x1="12" y1="1" x2="12" y2="3"></line>
          <line x1="12" y1="21" x2="12" y2="23"></line>
          <line x1="4.22" y1="4.22" x2="5.64" y2="5.64"></line>
          <line x1="18.36" y1="18.36" x2="19.78" y2="19.78"></line>
          <line x1="1" y1="12" x2="3" y2="12"></line>
          <line x1="21" y1="12" x2="23" y2="12"></line>
          <line x1="4.22" y1="19.78" x2="5.64" y2="18.36"></line>
          <line x1="18.36" y1="5.64" x2="19.78" y2="4.22"></line>
        </svg>
        <svg v-else class="nav-icon-svg" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
          <path d="M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z"></path>
        </svg>
        <span>{{ isLightMode ? 'Dark Mode' : 'Light Mode' }}</span>
      </button>

      <div class="user-info">
        <div class="user-avatar">{{ user?.name?.[0] || 'A' }}</div>
        <div>
          <div class="user-name">{{ user?.name || 'Admin' }}</div>
          <div class="user-role">{{ user?.role || 'admin' }}</div>
        </div>
      </div>
      <button class="logout-btn" @click="handleLogout">Logout</button>
    </div>
  </aside>
</template>

<script setup>
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'
import { computed, ref, onMounted } from 'vue'

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const user = computed(() => auth.user)

const isLightMode = ref(false)

onMounted(() => {
  isLightMode.value = document.body.classList.contains('light-theme')
})

function toggleTheme() {
  isLightMode.value = !isLightMode.value
  if (isLightMode.value) {
    document.body.classList.add('light-theme')
    localStorage.setItem('theme', 'light')
  } else {
    document.body.classList.remove('light-theme')
    localStorage.setItem('theme', 'dark')
  }
}

const navItems = [
  { path: '/', label: 'Dashboard', icon: 'grid' },
  { path: '/users', label: 'Users', icon: 'users' },
  { path: '/vehicles', label: 'Vehicles', icon: 'truck' },
  { path: '/intersections', label: 'Intersections', icon: 'signal' },
  { path: '/missions', label: 'Missions', icon: 'target' },
  { path: '/alerts', label: 'Alerts', icon: 'alert' },
  { path: '/hospitals', label: 'Hospitals', icon: 'hospital' },
  { path: '/mass-emergency', label: 'Mass Emergency', icon: 'zap' },
]

function handleLogout() {
  auth.logout()
  router.push('/login')
}
</script>

<style scoped>
.sidebar {
  position: fixed;
  left: 0;
  top: 0;
  bottom: 0;
  width: 260px;
  background: var(--sidebar-bg);
  display: flex;
  flex-direction: column;
  z-index: 50;
  border-right: 1px solid var(--border);
}

.sidebar-brand {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 20px;
  border-bottom: 1px solid var(--border);
}

.brand-icon-img {
  width: 40px;
  height: 40px;
  object-fit: contain;
  border-radius: 8px;
}

.brand-name {
  color: var(--text);
  font-weight: 700;
  font-size: 16px;
}

.brand-sub {
  color: var(--sidebar-text);
  font-size: 11px;
}

.sidebar-nav {
  flex: 1;
  padding: 12px 8px;
  overflow-y: auto;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 10px 14px;
  border-radius: 8px;
  color: var(--sidebar-text);
  text-decoration: none;
  font-size: 14px;
  font-weight: 500;
  margin-bottom: 2px;
  transition: all 0.15s;
}

.nav-item:hover {
  background: var(--sidebar-hover);
  color: var(--text);
}

.nav-item.active {
  background: var(--primary-bg);
  color: var(--primary);
  border-left: 3px solid var(--primary);
  border-radius: 4px 8px 8px 4px;
}

.nav-icon-svg {
  width: 18px;
  height: 18px;
  flex-shrink: 0;
}

.sidebar-footer {
  padding: 24px 20px;
  border-top: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.theme-toggle-btn {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 16px;
  width: 100%;
  border-radius: 8px;
  background: transparent;
  color: var(--sidebar-text);
  border: 1px solid var(--border);
  cursor: pointer;
  transition: all 0.2s ease;
  font-family: inherit;
  font-size: 14px;
  font-weight: 500;
}

.theme-toggle-btn:hover {
  background: var(--sidebar-hover);
  color: var(--text);
}
.light-theme .theme-toggle-btn:hover {
  color: var(--text);
  border-color: var(--border);
}

.user-info {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-bottom: 12px;
}

.user-avatar {
  width: 32px;
  height: 32px;
  background: var(--primary-bg);
  border: 1px solid var(--primary);
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  color: var(--primary);
  font-weight: 700;
  font-size: 13px;
}

.user-name {
  color: var(--text);
  font-size: 13px;
  font-weight: 600;
}

.user-role {
  color: var(--sidebar-text);
  font-size: 11px;
  text-transform: capitalize;
}

.logout-btn {
  width: 100%;
  padding: 8px;
  background: var(--sidebar-hover);
  border: 1px solid var(--border);
  border-radius: 8px;
  color: var(--sidebar-text);
  font-size: 13px;
  cursor: pointer;
  transition: all 0.15s;
}

.logout-btn:hover {
  background: rgba(226, 75, 74, 0.2);
  border-color: var(--danger);
  color: var(--danger);
}
</style>
