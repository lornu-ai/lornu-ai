import '@testing-library/jest-dom'
import { cleanup } from '@testing-library/react'
import { afterEach, vi } from 'vitest'

// Cleanup after each test
afterEach(() => {
  cleanup()
})

// Mock window.matchMedia
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: vi.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn(),
  })),
})

// Mock IntersectionObserver
global.IntersectionObserver = class IntersectionObserver {
  constructor(
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    _callback?: IntersectionObserverCallback,
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    _options?: IntersectionObserverInit
  ) {}
  disconnect() {}
  observe() {}
  takeRecords() {
    return []
  }
  unobserve() {}
} as any // eslint-disable-line @typescript-eslint/no-explicit-any

// Mock ResizeObserver
global.ResizeObserver = class ResizeObserver {
  constructor(
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    _callback?: ResizeObserverCallback
  ) {}
  disconnect() {}
  observe() {}
  unobserve() {}
} as any // eslint-disable-line @typescript-eslint/no-explicit-any

// Polyfill localStorage for JSDOM if missing or incomplete
if (typeof window !== 'undefined' && (!('localStorage' in window) || typeof window.localStorage?.getItem !== 'function')) {
  const store = new Map<string, string>()
  window.localStorage = {
    getItem: (key: string) => (store.has(key) ? store.get(key)! : null),
    setItem: (key: string, value: string) => {
      store.set(key, String(value))
    },
    removeItem: (key: string) => {
      store.delete(key)
    },
    clear: () => store.clear(),
    key: (index: number) => Array.from(store.keys())[index] ?? null,
    get length() {
      return store.size
    }
  } as unknown as Storage
}
