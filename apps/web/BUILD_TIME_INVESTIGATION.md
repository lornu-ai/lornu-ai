# Build Time Investigation

## Problem
Build times have increased significantly in Cloudflare Workers deployment.

## Investigation Plan

### 1. Recent Changes Analysis
- [ ] Review recent dependency updates
- [ ] Check for new large dependencies added
- [ ] Review TypeScript configuration changes
- [ ] Check Vite build configuration
- [ ] Review Cloudflare build settings

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
- [ ] Measure actual build times (local vs Cloudflare)
- [ ] Review Cloudflare build logs for bottlenecks
- [ ] Compare dependency sizes before/after recent changes
- [ ] Test build optimizations
- [ ] Document findings and recommendations

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

## References
- [Vite Build Optimization](https://vitejs.dev/guide/build.html)
- [Cloudflare Workers Build Configuration](https://developers.cloudflare.com/workers/ci-cd/builds/git-integration/)
- [TypeScript Project References](https://www.typescriptlang.org/docs/handbook/project-references.html)
