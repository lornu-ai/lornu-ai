import '@testing-library/jest-dom'
import { cleanup } from '@testing-library/react'
import { afterEach, vi } from 'vitest'

// JSDOM doesn't implement these, so we need to mock them
if (typeof window.URL.createObjectURL === 'undefined') {
  Object.defineProperty(window.URL, 'createObjectURL', { value: () => {} });
}

// Cleanup after each test
afterEach(() => {
  cleanup()
  // Clear localStorage after each test
  localStorage.clear()
})

// Mock localStorage with actual storage implementation
const localStorageMock = (() => {
  let store: Record<string, string> = {}
  return {
    getItem: (key: string) => store[key] || null,
    setItem: (key: string, value: string) => {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      store[key] = value.toString() as any
    },
    removeItem: (key: string) => {
      delete store[key]
    },
    clear: () => {
      store = {}
    },
  }
})()
global.localStorage = localStorageMock as any // eslint-disable-line @typescript-eslint/no-explicit-any

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
