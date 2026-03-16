<template>
  <div>
    <div class="page-header">
      <div>
        <h1>Users</h1>
        <p>Manage drivers, operators, and admins</p>
      </div>
      <button class="btn btn-primary" @click="openCreate">+ Add User</button>
    </div>

    <div class="toolbar">
      <input v-model="search" class="form-input search-input" placeholder="Search by name or email..." />
      <select v-model="roleFilter" class="form-input" style="width: 160px">
        <option value="">All Roles</option>
        <option value="driver">Driver</option>
        <option value="operator">Operator</option>
        <option value="admin">Admin</option>
      </select>
    </div>

    <div class="card">
      <table class="data-table">
        <thead>
          <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Role</th>
            <th>Vehicle</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="u in filtered" :key="u.id">
            <td style="font-weight: 600">{{ u.name }}</td>
            <td>{{ u.email }}</td>
            <td><span class="badge" :class="roleClass(u.role)">{{ u.role }}</span></td>
            <td>{{ u.vehicle_id || '-' }}</td>
            <td><span class="badge" :class="u.is_active ? 'badge-green' : 'badge-red'">{{ u.is_active ? 'Active' : 'Disabled' }}</span></td>
            <td>
              <button class="btn btn-outline btn-sm" @click="openEdit(u)">Edit</button>
              <button class="btn btn-danger btn-sm" @click="remove(u)" style="margin-left: 4px">Delete</button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Modal -->
    <div v-if="showModal" class="modal-overlay" @click.self="showModal = false">
      <div class="modal">
        <h2>{{ editing ? 'Edit User' : 'Create User' }}</h2>
        <form @submit.prevent="save">
          <div class="form-group">
            <label>Name</label>
            <input v-model="form.name" class="form-input" required />
          </div>
          <div class="form-group">
            <label>Email</label>
            <input v-model="form.email" type="email" class="form-input" required />
          </div>
          <div class="form-group" v-if="!editing">
            <label>Password</label>
            <input v-model="form.password" type="password" class="form-input" required />
          </div>
          <div class="form-group">
            <label>Role</label>
            <select v-model="form.role" class="form-input">
              <option value="driver">Driver</option>
              <option value="operator">Operator</option>
              <option value="admin">Admin</option>
            </select>
          </div>
          <div class="form-group">
            <label>Vehicle ID (for drivers)</label>
            <input v-model="form.vehicle_id" class="form-input" placeholder="e.g. AMB-01" />
          </div>
          <div class="form-group">
            <label>Phone</label>
            <input v-model="form.phone" class="form-input" placeholder="+91-..." />
          </div>
          <div class="modal-actions">
            <button type="button" class="btn btn-outline" @click="showModal = false">Cancel</button>
            <button type="submit" class="btn btn-primary">{{ editing ? 'Update' : 'Create' }}</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import api from '../api/client'

const users = ref([])
const search = ref('')
const roleFilter = ref('')
const showModal = ref(false)
const editing = ref(null)
const form = ref({ name: '', email: '', password: '', role: 'driver', vehicle_id: '', phone: '' })

const filtered = computed(() => {
  return users.value.filter(u => {
    const q = search.value.toLowerCase()
    const matchSearch = !q || u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q)
    const matchRole = !roleFilter.value || u.role === roleFilter.value
    return matchSearch && matchRole
  })
})

function roleClass(r) {
  if (r === 'admin') return 'badge-red'
  if (r === 'operator') return 'badge-blue'
  return 'badge-green'
}

function openCreate() {
  editing.value = null
  form.value = { name: '', email: '', password: '', role: 'driver', vehicle_id: '', phone: '' }
  showModal.value = true
}

function openEdit(u) {
  editing.value = u.id
  form.value = { name: u.name, email: u.email, role: u.role, vehicle_id: u.vehicle_id || '', phone: u.phone || '' }
  showModal.value = true
}

async function save() {
  try {
    if (editing.value) {
      await api.put(`/admin/users/${editing.value}`, form.value)
    } else {
      await api.post('/admin/users', form.value)
    }
    showModal.value = false
    await load()
  } catch (e) {
    alert(e.response?.data?.detail || 'Error saving user')
  }
}

async function remove(u) {
  if (!confirm(`Delete user "${u.name}"?`)) return
  await api.delete(`/admin/users/${u.id}`)
  await load()
}

async function load() {
  const res = await api.get('/admin/users')
  users.value = res.data
}

onMounted(load)
</script>
