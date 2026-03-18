import { createRouter, createWebHistory } from 'vue-router'

const routes = [
  { path: '/login', name: 'Login', component: () => import('../views/LoginView.vue') },
  { path: '/', name: 'Dashboard', component: () => import('../views/DashboardView.vue'), meta: { auth: true } },
  { path: '/users', name: 'Users', component: () => import('../views/UsersView.vue'), meta: { auth: true } },
  { path: '/vehicles', name: 'Vehicles', component: () => import('../views/VehiclesView.vue'), meta: { auth: true } },
  { path: '/intersections', name: 'Intersections', component: () => import('../views/IntersectionsView.vue'), meta: { auth: true } },
  { path: '/missions', name: 'Missions', component: () => import('../views/MissionsView.vue'), meta: { auth: true } },
  { path: '/alerts', name: 'Alerts', component: () => import('../views/AlertsView.vue'), meta: { auth: true } },
  { path: '/hospitals', name: 'Hospitals', component: () => import('../views/HospitalsView.vue'), meta: { auth: true } },
  { path: '/mass-emergency', name: 'MassEmergency', component: () => import('../views/MassEmergencyView.vue'), meta: { auth: true } },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('pulse_token')
  if (to.meta.auth && !token) {
    next('/login')
  } else if (to.name === 'Login' && token) {
    next('/')
  } else {
    next()
  }
})

export default router
