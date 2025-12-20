import { lazy, Suspense } from 'react'
import { BrowserRouter as Router, Routes, Route } from 'react-router-dom'
import { HelmetProvider } from 'react-helmet-async'
import Home from '@/pages/Home'
import { CookieConsent } from '@/components/CookieConsent'

// Lazy load non-critical pages for better initial bundle size
const Terms = lazy(() => import('@/pages/Terms'))
const Privacy = lazy(() => import('@/pages/Privacy'))
const Security = lazy(() => import('@/pages/Security'))

// Simple loading fallback for lazy-loaded routes
const PageLoader = () => (
  <div className="flex items-center justify-center min-h-screen" aria-live="polite" aria-label="Loading page">
    <div className="text-muted-foreground">Loading...</div>
  </div>
)

function App() {
  return (
    <HelmetProvider>
      <Router>
        <Routes>
          <Route path="/" element={<Home />} />
          <Route
            path="/terms"
            element={
              <Suspense fallback={<PageLoader />}>
                <Terms />
              </Suspense>
            }
          />
          <Route
            path="/privacy"
            element={
              <Suspense fallback={<PageLoader />}>
                <Privacy />
              </Suspense>
            }
          />
          <Route
            path="/security"
            element={
              <Suspense fallback={<PageLoader />}>
                <Security />
              </Suspense>
            }
          />
        </Routes>
        <CookieConsent />
      </Router>
    </HelmetProvider>
  )
}

export default App
