# Build Time Investigation

## Problem
Build times have increased significantly in Cloudflare Workers deployment.

## Investigation Plan

### 1. Recent Changes Analysis
- [x] Review recent dependency updates
- [x] Check for new large dependencies added
- [x] Review TypeScript configuration changes
- [x] Check Vite build configuration
- [x] Review Cloudflare build settings

### 2. Potential Causes

#### A. Dependencies
Recent additions that might slow builds:
- Multiple Radix UI components (many packages)
- @github/spark plugin and dependencies
- Large icon libraries (@phosphor-icons/react)
- Tailwind CSS with Vite plugin

#### B. Build Configuration
- `tsc -b --noCheck` in build script - TypeScript build step
- Vite build with multiple plugins:
  - `@vitejs/plugin-react-swc`
  - `@tailwindcss/vite`
  - `@github/spark/spark-vite-plugin`
  - Icon proxy plugin

#### C. Cloudflare Build Settings
- Check if Bun installation is being cached properly
- Verify build command: `bun run build`
- Check if dependencies are being reinstalled on every build

### 3. Baseline Measurements Needed
- Measure local build time: `time bun run build`
- Compare with previous build times (if available)
- Check Cloudflare build logs for timing breakdown

### 4. Optimization Opportunities

#### Potential Optimizations:
1. **TypeScript Check**: Currently using `--noCheck` - verify if full type checking is needed
2. **Dependency Optimization**: Consider if all Radix UI components are needed, or if we can tree-shake better
3. **Build Caching**: Ensure Cloudflare caches `node_modules`/`bun.lock` properly
4. **Vite Optimizations**: Review Vite build settings for optimization flags
5. **Code Splitting**: Ensure proper code splitting for smaller chunks

### 5. Next Steps
- [x] Measure actual build times (local vs Cloudflare)
- [ ] Review Cloudflare build logs for bottlenecks
- [x] Compare dependency sizes before/after recent changes
- [ ] Test build optimizations
- [x] Document findings and recommendations

## Build Script Analysis

Current build command:
```bash
tsc -b --noCheck && vite build
```

This runs:
1. TypeScript build (with `--noCheck` flag - skips type checking)
2. Vite production build

## Dependencies Size Check

Run to check bundle size:
```bash
bun run build
du -sh dist/
```

Check largest dependencies:
```bash
cd apps/web
bun pm ls --size | head -20
```

## Investigation Results

### Baseline Measurements

**Local Build Time:**
- **Total:** ~4 seconds (3.899s real time, 4.645s user time)
- **TypeScript:** ~2 seconds (with `--noCheck`)
- **Vite Build:** ~2 seconds
- **6557 modules transformed**

**Bundle Size:**
- **Total:** 932KB
- **JavaScript:** 544.53 KB (165.57 KB gzipped) - ⚠️ **Exceeds 500KB warning threshold**
- **CSS:** 352.02 KB (66.06 KB gzipped)
- **HTML:** 1.02 KB (0.56 KB gzipped)

### Dependency Analysis

**Total Dependencies:** 79 packages
- **Radix UI Components:** 27 packages (largest single contributor)
- **Icon Libraries:**
  - `@phosphor-icons/react` (1533 icons loaded via proxy plugin)
  - `@heroicons/react`
  - `lucide-react`
- **Large Dependencies:**
  - `d3` (data visualization library - ~250KB)
  - `three` (3D graphics - ~200KB)
  - `recharts` (charting library)
  - `framer-motion` (animation library)

### Identified Issues

#### 1. Bundle Size Warning ⚠️
Vite reports: "Some chunks are larger than 500 kB after minification"
- Main JS bundle is 544.53 KB (exceeds recommended 500KB limit)
- **Impact:** Larger initial load time for users

#### 2. TypeScript Build Step
- Currently using `tsc -b --noCheck` (skips type checking)
- Still requires file parsing and module resolution
- **Potential optimization:** Skip TypeScript build entirely if Vite handles it

#### 3. Icon Proxy Plugin Overhead
- The `@github/spark` icon proxy plugin processes 1533 icons from `@phosphor-icons/react`
- Runs during build: "Checking for exports in directory" (seen twice in logs)
- **Potential optimization:** Pre-build icon index or use direct imports

#### 4. Cloudflare Build Process
- **Install command:** `curl -fsSL https://bun.sh/install | bash && export PATH="$HOME/.bun/bin:$PATH"`
- **Issue:** Bun is installed on every build (not cached)
- **Potential time cost:** 10-30 seconds per build for Bun installation

#### 5. Large Number of Vite Plugins
- 4 active plugins: React SWC, Tailwind, Spark, Icon Proxy
- Each plugin adds processing overhead

### Root Cause Hypothesis

The slow build times in Cloudflare are likely caused by:

1. **Bun Installation Overhead** (Primary suspect)
   - Bun is installed fresh on every build via `curl` command
   - No caching of Bun binary between builds
   - Estimated: 10-30 seconds per build

2. **Dependency Installation**
   - 79 packages need to be installed
   - Cloudflare may not be caching `node_modules` effectively
   - Estimated: 5-15 seconds per build

3. **Large Bundle Processing**
   - 6557 modules to transform
   - 544KB JavaScript bundle needs minification/optimization
   - Estimated: 4-8 seconds (matches local build time)

**Total Estimated Cloudflare Build Time: 20-55 seconds**
(If Bun install + dependency install is not cached)

## Recommendations

### Priority 1: Optimize Cloudflare Build Process

#### A. Cache Bun Binary
**Option 1:** Use Cloudflare's pre-installed runtime if available
```bash
# Check if Bun is available in Cloudflare build environment
# If yes, update install command to just verify/use existing Bun
```

**Option 2:** Cache Bun binary between builds
- Store Bun binary in a cached directory
- Check if Bun exists before installing
- Update install command:
```bash
if ! command -v bun &> /dev/null; then
  curl -fsSL https://bun.sh/install | bash
  export PATH="$HOME/.bun/bin:$PATH"
fi
```

#### B. Optimize Dependency Caching
- Ensure `bun.lock` is present and committed
- Cloudflare should cache `node_modules` between builds
- Verify caching is working in Cloudflare build logs

### Priority 2: Optimize Bundle Size

#### A. Code Splitting
Add manual chunking to `vite.config.ts`:
```typescript
export default defineConfig({
  build: {
    rollupOptions: {
      output: {
        manualChunks: {
          'vendor-react': ['react', 'react-dom', 'react-router-dom'],
          'vendor-ui': [
            // Group all Radix UI components
            ...Object.keys(packageJson.dependencies).filter(pkg =>
              pkg.startsWith('@radix-ui/')
            )
          ],
          'vendor-charts': ['d3', 'recharts'],
          'vendor-3d': ['three'],
        }
      }
    }
  }
})
```

#### B. Dynamic Imports for Large Libraries
- Lazy load `d3`, `three`, `recharts` only when needed
- Use React.lazy() for route-based code splitting

#### C. Tree Shaking Optimization
- Verify unused Radix UI components are removed
- Review if all 27 Radix UI packages are actually used
- Consider replacing with lighter alternatives if possible

### Priority 3: Build Configuration Optimizations

#### A. Remove TypeScript Build Step (If Safe)
If Vite handles TypeScript compilation adequately:
```json
"build": "vite build"
```
**Caution:** Test thoroughly - `tsc -b` may be needed for type checking in CI

#### B. Optimize Vite Build Settings
```typescript
export default defineConfig({
  build: {
    target: 'esnext',
    minify: 'esbuild', // Faster than terser
    cssCodeSplit: true,
    sourcemap: false, // Disable in production if not needed
    chunkSizeWarningLimit: 600, // Increase limit temporarily while optimizing
  }
})
```

#### C. Icon Proxy Plugin Optimization
- Consider pre-generating icon exports
- Or switch to direct imports for commonly used icons
- Or use a lighter icon library with tree-shaking

### Priority 4: Dependency Review

#### Review Large Dependencies
- **d3:** Only import needed modules (`d3-selection`, `d3-scale`, etc.)
- **three:** Consider if full library is needed or can use smaller alternatives
- **Radix UI:** Audit if all 27 components are used, remove unused ones

## Implementation Plan

1. **Immediate (Quick Win):**
   - [ ] Update Cloudflare install command to check for existing Bun
   - [ ] Verify dependency caching in Cloudflare logs
   - [ ] Add code splitting configuration

2. **Short-term (1-2 days):**
   - [ ] Implement dynamic imports for large libraries
   - [ ] Review and remove unused Radix UI components
   - [ ] Optimize Vite build settings

3. **Medium-term (1 week):**
   - [ ] Evaluate removing TypeScript build step
   - [ ] Optimize icon loading strategy
   - [ ] Complete dependency audit and optimization

## Monitoring

After implementing optimizations:
- Monitor Cloudflare build logs for timing breakdown
- Compare before/after build times
- Track bundle size changes
- Verify build cache hit rates

## References
- [Vite Build Optimization](https://vitejs.dev/guide/build.html)
- [Cloudflare Workers Build Configuration](https://developers.cloudflare.com/workers/ci-cd/builds/git-integration/)
- [TypeScript Project References](https://www.typescriptlang.org/docs/handbook/project-references.html)
- [Vite Manual Chunks](https://rollupjs.org/configuration-options/#output-manualchunks)
