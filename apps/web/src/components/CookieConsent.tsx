import { useState, useEffect } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Button } from '@/components/ui/button'
import { Link } from 'react-router-dom'
import { X } from '@phosphor-icons/react'

const GA_TRACKING_ID = import.meta.env.VITE_GA_TRACKING_ID || 'G-S71XEXELEN'

export function CookieConsent() {
  const [isVisible, setIsVisible] = useState(false)

  useEffect(() => {
    // Check if user has already made a choice
    const consent = localStorage.getItem('cookie-consent')

    if (consent === null) {
      // Show banner if no choice made yet
      const timer = setTimeout(() => setIsVisible(true), 1000)
      return () => clearTimeout(timer)
    } else if (consent === 'true') {
      // Initialize GA if previously accepted
      initializeGA()
    }
  }, [])

  const initializeGA = () => {
    // Avoid double initialization
    if (window.dataLayer) return

    const script1 = document.createElement('script')
    script1.async = true
    script1.src = `https://www.googletagmanager.com/gtag/js?id=${GA_TRACKING_ID}`

    const script2 = document.createElement('script')
    script2.innerHTML = `
      window.dataLayer = window.dataLayer || [];
      function gtag(){dataLayer.push(arguments);}
      gtag('js', new Date());
      gtag('config', '${GA_TRACKING_ID}');
    `

    document.head.appendChild(script1)
    document.head.appendChild(script2)
  }

  const handleAccept = () => {
    localStorage.setItem('cookie-consent', 'true')
    initializeGA()
    setIsVisible(false)
  }

  const handleDecline = () => {
    localStorage.setItem('cookie-consent', 'false')
    setIsVisible(false)
  }

  return (
    <AnimatePresence>
      {isVisible && (
        <motion.div
          initial={{ y: 100, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={{ y: 100, opacity: 0 }}
          className="fixed bottom-0 left-0 right-0 z-50 p-4 bg-background/95 backdrop-blur border-t border-border shadow-lg"
        >
          <div className="max-w-7xl mx-auto flex flex-col sm:flex-row items-center justify-between gap-4">
            <div className="flex-1 text-sm text-muted-foreground text-center sm:text-left">
              <p>
                We use cookies to improve your experience and analyze site traffic.
                By clicking "Accept", you agree to our use of cookies as described in our{' '}
                <Link to="/privacy" className="text-primary hover:underline underline-offset-4">
                  Privacy Policy
                </Link>.
              </p>
            </div>
            <div className="flex items-center gap-3">
              <Button variant="outline" size="sm" onClick={handleDecline}>
                Decline
              </Button>
              <Button size="sm" onClick={handleAccept}>
                Accept
              </Button>
              <button
                onClick={handleDecline}
                className="absolute top-2 right-2 sm:hidden text-muted-foreground hover:text-foreground"
                aria-label="Close"
              >
                <X size={16} />
              </button>
            </div>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}

// Add types for window.dataLayer
declare global {
  interface Window {
    dataLayer: any[]
  }
}
