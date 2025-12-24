import { describe, it, expect, beforeEach, afterEach, vi } from 'vitest';
import { render, screen, waitFor, renderHook, act } from '@testing-library/react';
import { ThemeProvider, useTheme, type Theme } from './ThemeContext';

describe('ThemeContext', () => {
    let mockMatchMedia: ReturnType<typeof vi.fn>;
    let mockAddEventListener: ReturnType<typeof vi.fn>;
    let mockRemoveEventListener: ReturnType<typeof vi.fn>;
    let mockAddListener: ReturnType<typeof vi.fn>;
    let mockRemoveListener: ReturnType<typeof vi.fn>;

    beforeEach(() => {
        // Clear localStorage
        localStorage.clear();

        // Clear document.documentElement.setAttribute calls
        vi.clearAllMocks();

        // Mock matchMedia
        mockAddEventListener = vi.fn();
        mockRemoveEventListener = vi.fn();
        mockAddListener = vi.fn();
        mockRemoveListener = vi.fn();

        mockMatchMedia = vi.fn((query: string) => ({
            matches: query === '(prefers-color-scheme: dark)' ? false : false,
            media: query,
            onchange: null,
            addEventListener: mockAddEventListener,
            removeEventListener: mockRemoveEventListener,
            addListener: mockAddListener,
            removeListener: mockRemoveListener,
            dispatchEvent: vi.fn(),
        }));

        Object.defineProperty(window, 'matchMedia', {
            writable: true,
            value: mockMatchMedia,
        });
    });

    afterEach(() => {
        vi.restoreAllMocks();
    });

    describe('ThemeProvider', () => {
        it('should render children', () => {
            render(
                <ThemeProvider>
                    <div>Test Child</div>
                </ThemeProvider>
            );

            expect(screen.getByText('Test Child')).toBeInTheDocument();
        });

        it('should default to system theme', () => {
            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            expect(result.current.theme).toBe('system');
        });

        it('should load theme from localStorage', async () => {
            localStorage.setItem('theme', 'dark');

            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            await waitFor(() => {
                expect(result.current.theme).toBe('dark');
            });
        });

        it('should ignore invalid theme from localStorage', async () => {
            localStorage.setItem('theme', 'invalid-theme');

            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            await waitFor(() => {
                expect(result.current.theme).toBe('system');
            });
        });

        it('should set theme and save to localStorage', () => {
            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            act(() => {
                result.current.setTheme('dark');
            });

            expect(result.current.theme).toBe('dark');
            expect(localStorage.getItem('theme')).toBe('dark');
        });

        it('should apply light theme to document when theme is light', () => {
            const setAttributeSpy = vi.spyOn(document.documentElement, 'setAttribute');

            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            act(() => {
                result.current.setTheme('light');
            });

            expect(setAttributeSpy).toHaveBeenCalledWith('data-theme', 'light');
        });

        it('should apply dark theme to document when theme is dark', () => {
            const setAttributeSpy = vi.spyOn(document.documentElement, 'setAttribute');

            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            act(() => {
                result.current.setTheme('dark');
            });

            expect(setAttributeSpy).toHaveBeenCalledWith('data-theme', 'dark');
        });

        it('should apply open-source-pro theme to document', () => {
            const setAttributeSpy = vi.spyOn(document.documentElement, 'setAttribute');

            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            act(() => {
                result.current.setTheme('open-source-pro');
            });

            expect(setAttributeSpy).toHaveBeenCalledWith('data-theme', 'open-source-pro');
        });

        it('should resolve system theme to light when prefers-color-scheme is light', () => {
            const setAttributeSpy = vi.spyOn(document.documentElement, 'setAttribute');
            mockMatchMedia.mockReturnValue({
                matches: false, // light mode
                media: '(prefers-color-scheme: dark)',
                addEventListener: mockAddEventListener,
                removeEventListener: mockRemoveEventListener,
                addListener: mockAddListener,
                removeListener: mockRemoveListener,
                dispatchEvent: vi.fn(),
            });

            renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            expect(setAttributeSpy).toHaveBeenCalledWith('data-theme', 'light');
        });

        it('should resolve system theme to dark when prefers-color-scheme is dark', () => {
            const setAttributeSpy = vi.spyOn(document.documentElement, 'setAttribute');
            mockMatchMedia.mockReturnValue({
                matches: true, // dark mode
                media: '(prefers-color-scheme: dark)',
                addEventListener: mockAddEventListener,
                removeEventListener: mockRemoveEventListener,
                addListener: mockAddListener,
                removeListener: mockRemoveListener,
                dispatchEvent: vi.fn(),
            });

            renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            expect(setAttributeSpy).toHaveBeenCalledWith('data-theme', 'dark');
        });

        it('should fallback to light theme when matchMedia is not supported', () => {
            const setAttributeSpy = vi.spyOn(document.documentElement, 'setAttribute');
            Object.defineProperty(window, 'matchMedia', {
                writable: true,
                value: undefined,
            });

            renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            expect(setAttributeSpy).toHaveBeenCalledWith('data-theme', 'light');
        });

        it('should add event listener for system theme changes (modern browsers)', () => {
            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            act(() => {
                result.current.setTheme('system');
            });

            expect(mockAddEventListener).toHaveBeenCalledWith('change', expect.any(Function));
        });

        it('should use legacy addListener for system theme changes (old browsers)', () => {
            mockMatchMedia.mockReturnValue({
                matches: false,
                media: '(prefers-color-scheme: dark)',
                addEventListener: undefined,
                removeEventListener: undefined,
                addListener: mockAddListener,
                removeListener: mockRemoveListener,
                dispatchEvent: vi.fn(),
            });

            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            act(() => {
                result.current.setTheme('system');
            });

            expect(mockAddListener).toHaveBeenCalledWith(expect.any(Function));
        });

        it('should remove event listener when theme changes from system', () => {
            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            act(() => {
                result.current.setTheme('system');
            });

            act(() => {
                result.current.setTheme('light');
            });

            expect(mockRemoveEventListener).toHaveBeenCalled();
        });

        it('should use legacy removeListener when cleaning up (old browsers)', () => {
            mockMatchMedia.mockReturnValue({
                matches: false,
                media: '(prefers-color-scheme: dark)',
                addEventListener: undefined,
                removeEventListener: undefined,
                addListener: mockAddListener,
                removeListener: mockRemoveListener,
                dispatchEvent: vi.fn(),
            });

            const { result, unmount } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            act(() => {
                result.current.setTheme('system');
            });

            unmount();

            expect(mockRemoveListener).toHaveBeenCalled();
        });

        it('should not add listener when theme is not system', () => {
            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            // Clear mocks from initial render (system theme)
            mockAddEventListener.mockClear();
            mockAddListener.mockClear();

            act(() => {
                result.current.setTheme('dark');
            });

            // Should not add new listeners for non-system theme
            expect(mockAddEventListener).not.toHaveBeenCalled();
            expect(mockAddListener).not.toHaveBeenCalled();
        });

        it('should cycle through all theme options', () => {
            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            const themes: Theme[] = ['system', 'light', 'dark', 'open-source-pro'];

            themes.forEach((expectedTheme) => {
                act(() => {
                    result.current.setTheme(expectedTheme);
                });
                expect(result.current.theme).toBe(expectedTheme);
            });
        });
    });

    describe('useTheme hook', () => {
        it('should throw error when used outside ThemeProvider', () => {
            // Suppress console.error for this test
            const consoleError = vi.spyOn(console, 'error').mockImplementation(() => { });

            expect(() => {
                renderHook(() => useTheme());
            }).toThrow('useTheme must be used within a ThemeProvider');

            consoleError.mockRestore();
        });

        it('should return theme context when used within ThemeProvider', () => {
            const { result } = renderHook(() => useTheme(), {
                wrapper: ThemeProvider,
            });

            expect(result.current).toHaveProperty('theme');
            expect(result.current).toHaveProperty('setTheme');
            expect(typeof result.current.setTheme).toBe('function');
        });
    });
});
