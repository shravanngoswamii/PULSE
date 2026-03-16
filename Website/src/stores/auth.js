import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import api from '../api/client'

export const useAuthStore = defineStore('auth', () => {
  const user = ref(JSON.parse(localStorage.getItem('pulse_user') || 'null'))
  const token = ref(localStorage.getItem('pulse_token') || null)

  const isLoggedIn = computed(() => !!token.value)

  async function login(email, password) {
    const res = await api.post('/auth/login', { email, password })
    token.value = res.data.token
    user.value = res.data.user
    localStorage.setItem('pulse_token', res.data.token)
    localStorage.setItem('pulse_user', JSON.stringify(res.data.user))
    return res.data
  }

  function logout() {
    token.value = null
    user.value = null
    localStorage.removeItem('pulse_token')
    localStorage.removeItem('pulse_user')
  }

  return { user, token, isLoggedIn, login, logout }
})
