<template>
  <div v-if="route.name === 'Login'">
    <router-view />
  </div>
  <div v-else class="app-layout">
    <Sidebar />
    <main class="main-content">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import { useRoute } from 'vue-router'
import Sidebar from './components/Sidebar.vue'

const route = useRoute()
</script>
