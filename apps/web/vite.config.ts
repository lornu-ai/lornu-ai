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
            // Icon libraries - check before generic 'react' to avoid incorrect matching
            if (id.includes('@phosphor-icons') || id.includes('@heroicons') || id.includes('lucide-react')) {
              return 'vendor-icons';
            }
            // Radix UI components - group all together
            if (id.includes('@radix-ui')) {
              return 'vendor-radix-ui';
            }
            // Chart libraries (lazy load if not used on initial page)
            if (id.includes('recharts')) {
              return 'vendor-charts';
            }
            // Animation library (framer-motion)
            if (id.includes('framer-motion')) {
              return 'vendor-animations';
            }
            // React core libraries and all React-dependent packages
            // Include all react-* packages to ensure React is available when needed
            if (
              id.includes('node_modules/react/') ||
              id.includes('node_modules/react-dom/') ||
              id.includes('node_modules/react-router') ||
              id.includes('node_modules/react-') ||
              id.includes('node_modules/next-themes') || // Uses React
              id.includes('node_modules/sonner') || // Uses React
              id.includes('node_modules/cmdk') || // Uses React
              id.includes('node_modules/embla-carousel-react') // Uses React
            ) {
              return 'vendor-react';
            }
            // Other vendor libraries
            return 'vendor-misc';
          }
        }
      }
    },
    chunkSizeWarningLimit: 600, // TODO: Temporarily increased while optimizing. Revisit and reduce to 500 (default) or lower once bundle optimizations are complete.
  },
});
