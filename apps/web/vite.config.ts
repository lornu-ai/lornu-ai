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
      config: () => ({ server: { port: 5174, strictPort: true } }),
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
          // Vendor chunks for better caching and code splitting
          if (id.includes('node_modules')) {
            // React core + ecosystem packages that depend on React context
            // MUST be in the same chunk to ensure React is available when deps initialize
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
              id.includes('embla-carousel-react')
            ) {
              return 'vendor-react';
            }
            // Icon libraries
            if (id.includes('@phosphor-icons') || id.includes('@heroicons') || id.includes('lucide-react')) {
              return 'vendor-icons';
            }
            // Radix UI components
            if (id.includes('@radix-ui')) {
              return 'vendor-radix-ui';
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
    chunkSizeWarningLimit: 600, // TODO: Temporarily increased while optimizing. Revisit and reduce to 500 (default) or lower once bundle optimizations are complete.
  },
});
