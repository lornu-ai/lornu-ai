import { useSyncExternalStore } from "react"

const MOBILE_BREAKPOINT = 768

export function useIsMobile() {
  const subscribe = (callback: () => void) => {
    if (typeof window === "undefined") {
      return () => {}
    }
    const mql = window.matchMedia(`(max-width: ${MOBILE_BREAKPOINT - 1}px)`)
    const onChange = () => callback()
    mql.addEventListener("change", onChange)
    return () => mql.removeEventListener("change", onChange)
  }

  const getSnapshot = () => {
    if (typeof window === "undefined") {
      return false
    }
    return window.innerWidth < MOBILE_BREAKPOINT
  }

  return useSyncExternalStore(subscribe, getSnapshot, () => false)
}
