<template>
  <div class="login-page">
    <div class="login-card">
      <h1>PULSE</h1>
      <p class="subtitle">Super Admin Dashboard</p>

      <div v-if="error" class="login-error">{{ error }}</div>

      <form @submit.prevent="handleLogin">
        <div class="form-group">
          <label>Email</label>
          <input v-model="email" type="email" class="form-input" placeholder="admin@pulse.com" required />
        </div>
        <div class="form-group">
          <label>Password</label>
          <input v-model="password" type="password" class="form-input" placeholder="Enter password" required />
        </div>
        <button type="submit" class="btn btn-primary" :disabled="loading">
          {{ loading ? 'Signing in...' : 'Sign In' }}
        </button>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useAuthStore } from '../stores/auth'

const router = useRouter()
const auth = useAuthStore()

const email = ref('admin@pulse.com')
const password = ref('password123')
const error = ref('')
const loading = ref(false)

async function handleLogin() {
  error.value = ''
  loading.value = true
  try {
    const data = await auth.login(email.value, password.value)
    if (data.user.role !== 'admin') {
      error.value = 'Access denied. Admin role required.'
      auth.logout()
      return
    }
    router.push('/')
  } catch (e) {
    error.value = e.response?.data?.detail || 'Login failed'
  } finally {
    loading.value = false
  }
}
</script>
