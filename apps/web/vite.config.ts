import tailwindcss from "@tailwindcss/vite";
import react from "@vitejs/plugin-react-swc";
import { defineConfig, PluginOption } from "vite";
import svgr from "vite-plugin-svgr";

import sparkPlugin from "@github/spark/spark-vite-plugin";
import createIconImportProxy from "@github/spark/vitePhosphorIconProxyPlugin";
import { resolve } from 'path'

const projectRoot = process.env.PROJECT_ROOT || import.meta.dirname

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    react(),
    svgr(),
    tailwindcss(),
    // DO NOT REMOVE
    createIconImportProxy() as PluginOption,
    sparkPlugin() as PluginOption,
    {
      name: 'force-port',
      config: () => ({
        server: {
          port: 5174,
          strictPort: true,
          proxy: {
            '/api': 'http://127.0.0.1:8080',
          },
        },
      }),
    }
  ],
  resolve: {
    alias: {
      '@': resolve(projectRoot, 'src')
    }
  },
  build: {
    // Optimize build performance and output
    target: 'es2020', // Match TypeScript target for broader browser compatibility
    sourcemap: false, // Disable sourcemaps in production (faster builds, smaller output)
    // Note: minify: 'esbuild' and cssCodeSplit: true are already defaults in Vite 5+
    rollupOptions: {
      output: {
        manualChunks: (id) => {
          if (id.includes('node_modules')) {
            // Group React core, ecosystem dependencies, and Radix UI together to ensure context sharing
            if (
              id.includes('/react/') ||
              id.includes('/react-dom/') ||
              id.includes('/react-is/') ||
              id.includes('/scheduler/') ||
              id.includes('react-router') ||
              id.includes('react-helmet-async') ||
              id.includes('react-error-boundary') ||
              id.includes('react-hook-form') ||
              id.includes('next-themes') ||
              id.includes('sonner') ||
              id.includes('vaul') ||
              id.includes('cmdk') ||
              id.includes('embla-carousel-react') ||
              id.includes('@radix-ui')
            ) {
              return 'vendor-react';
            }
            // Icon libraries
            if (id.includes('@phosphor-icons') || id.includes('@heroicons') || id.includes('lucide-react')) {
              return 'vendor-icons';
            }
            // Animation library
            if (id.includes('framer-motion')) {
              return 'vendor-animations';
            }
            // Chart libraries
            if (id.includes('recharts')) {
              return 'vendor-charts';
            }
            // Other vendor libraries (non-React)
            return 'vendor-misc';
          }
        }
      }
    },
    chunkSizeWarningLimit: 500,
  },
});
