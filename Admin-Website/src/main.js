import { createApp } from 'vue'
import { createPinia } from 'pinia'
import App from './App.vue'
import router from './router'
import './assets/style.css'

// Check system preference or saved theme
if (localStorage.getItem('theme') === 'light' || (!localStorage.getItem('theme') && window.matchMedia('(prefers-color-scheme: light)').matches)) {
  document.body.classList.add('light-theme')
  localStorage.setItem('theme', 'light')
} else {
  localStorage.setItem('theme', 'dark')
}

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')
