<template>
  <div class="app-root">
    <div v-if="route.name === 'Login'">
      <router-view />
    </div>
    <div v-else class="app-layout">
      <Sidebar />
      <main class="main-content">
        <div class="watermark"></div>
        <router-view />
      </main>
    </div>
  </div>
</template>

<script setup>
import { useRoute } from 'vue-router'
import Sidebar from './components/Sidebar.vue'

const route = useRoute()
</script>

<style>
.app-root {
  min-height: 100vh;
  background-color: var(--bg);
  background-image: 
    linear-gradient(var(--grid-color, rgba(0, 230, 118, 0.03)) 1px, transparent 1px),
    linear-gradient(90deg, var(--grid-color, rgba(0, 230, 118, 0.03)) 1px, transparent 1px);
  background-size: 30px 30px;
  background-position: center center;
}

.watermark {
  position: fixed;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  width: 500px;
  height: 500px;
  background-image: url('./assets/green_logo.png');
  background-repeat: no-repeat;
  background-position: center;
  background-size: contain;
  opacity: var(--watermark-opacity, 0.02);
  pointer-events: none;
  z-index: 0;
  filter: var(--watermark-filter, grayscale(100%) sepia(100%) hue-rotate(90deg) brightness(1.5));
}

.main-content {
  position: relative;
  z-index: 1;
}
</style>
