<template>
  <div class="login-page">
    <div class="login-card window-glass">
      <div class="mac-controls" style="padding: 0; margin-top: -10px; margin-bottom: 24px;">
        <div class="mac-dot red"></div>
        <div class="mac-dot yellow"></div>
        <div class="mac-dot green"></div>
      </div>
      <img src="../assets/green_logo.png" alt="PULSE Logo" class="login-logo" />
      <h1>PULSE</h1>
      <p class="subtitle">System Access</p>

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

<style scoped>
.login-page {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: 100vh;
  background-image:
    linear-gradient(rgba(11, 14, 20, 0.78), rgba(11, 14, 20, 0.72)),
    url('../assets/PULSEbg.png');
  background-position: center;
  background-repeat: no-repeat;
  background-size: cover;
}

:global(body.light-theme) .login-page {
  background-image:
    linear-gradient(rgba(248, 250, 252, 0.82), rgba(248, 250, 252, 0.74)),
    url('../assets/PULSEbg.png');
}

.login-card {
  background: var(--surface);
  padding: 40px;
  border-radius: var(--radius-lg);
  box-shadow: 0 0 30px rgba(0, 0, 0, 0.5), 0 0 0 1px rgba(0, 230, 118, 0.2);
  width: 100%;
  max-width: 400px;
  text-align: center;
}

.login-logo {
  width: 80px;
  height: 80px;
  margin: 0 auto 16px;
  filter: drop-shadow(0 0 10px rgba(0, 230, 118, 0.3));
}

h1 {
  margin-bottom: 4px;
  color: var(--primary);
  text-shadow: 0 0 10px rgba(0, 230, 118, 0.3);
  font-weight: 800;
  letter-spacing: 1px;
}

.subtitle {
  color: var(--text-hint);
  margin-bottom: 30px;
}

</style>
