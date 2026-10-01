import path from 'path'
import { fileURLToPath } from 'url'
import { defineConfig } from '@lark-apaas/coding-preset-vite-react'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

export default defineConfig({
  base: './',
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
      '@shared': path.resolve(__dirname, 'shared'),
    },
  },
})
