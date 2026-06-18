import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// 支持通过环境变量配置端口，默认 8080/5173
const backendPort = process.env.VITE_BACKEND_PORT || '8080'
const frontendPort = parseInt(process.env.VITE_FRONTEND_PORT || '5173', 10)

export default defineConfig({
  plugins: [react()],
  server: {
    port: frontendPort,
    proxy: {
      '/api': {
        target: `http://localhost:${backendPort}`,
        changeOrigin: true,
        rewrite: (path) => `/guilin-news${path}`
      }
    }
  }
})
