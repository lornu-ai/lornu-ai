# Testing Documentation

## Overview

This project uses **Vitest** for unit and integration testing, along with **React Testing Library** for component testing.

## Running Tests

```bash
# Run tests in watch mode
bun test

# Run tests once
bun test:run

# Run tests with UI
bun test:ui

# Run tests with coverage
bun test:coverage
```

## Test Structure

### Setup Files
- `src/test/setup.ts` - Global test setup, mocks, and configuration
- `vitest.config.ts` - Vitest configuration

### Test Files
Tests are co-located with their source files using the `.test.tsx` extension:

```
src/
  components/
    Logo.tsx
    Logo.test.tsx       # Component tests
    SEOHead.tsx
    SEOHead.test.tsx
  pages/
    Terms.tsx
    Terms.test.tsx      # Page tests
```

## Writing Tests

### Component Tests

```typescript
import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import MyComponent from './MyComponent'

describe('MyComponent', () => {
  const renderWithRouter = (ui: React.ReactElement) => {
    return render(<BrowserRouter>{ui}</BrowserRouter>)
  }

  it('renders correctly', () => {
    renderWithRouter(<MyComponent />)
    expect(screen.getByText(/expected text/i)).toBeInTheDocument()
  })
})
```

### Page Tests with Helmet

```typescript
import { describe, it, expect } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { HelmetProvider } from 'react-helmet-async'
import MyPage from './MyPage'

describe('MyPage', () => {
  const renderPage = () => {
    return render(
      <HelmetProvider>
        <BrowserRouter>
          <MyPage />
        </BrowserRouter>
      </HelmetProvider>
    )
  }

  it('sets correct page title', async () => {
    renderPage()
    await waitFor(() => {
      expect(document.title).toBe('Expected Title')
    })
  })
})
```

## Test Coverage

Current test coverage includes:

- ✅ Logo component (size variants, props)
- ✅ SEOHead component (title handling, meta tags, Open Graph)
- ✅ Terms page (rendering, navigation, SEO)
- ✅ Privacy page (rendering, navigation, SEO)
- ✅ Security page (rendering, navigation, SEO)
- ✅ App routing (basic router setup)

### Coverage Goals
- Aim for >80% code coverage
- 100% coverage for critical paths (SEO, routing)
- All new features must include tests

## Mocked APIs

The test setup includes mocks for:
- `window.matchMedia` - For responsive design tests
- `IntersectionObserver` - For scroll/visibility tests
- `ResizeObserver` - For dynamic sizing tests

## Best Practices

1. **Test User Behavior** - Test what users see and do, not implementation details
2. **Use Semantic Queries** - Prefer `getByRole`, `getByLabelText` over `getByTestId`
3. **Async Operations** - Use `waitFor` for async updates (Helmet, API calls)
4. **Accessibility** - Ensure components are accessible (proper ARIA labels, roles)
5. **Isolation** - Each test should be independent and not affect others

## Troubleshooting

### Tests Timeout
- Increase timeout in `vitest.config.ts`
- Check for missing `await` on async operations

### Element Not Found
- Use `screen.debug()` to see rendered output
- Check if element needs `waitFor` for async rendering
- Verify query method (getByRole vs getByText)

### Mock Not Working
- Ensure mock is defined before import
- Check mock is in `setup.ts` for global mocks
- Use `vi.mock()` for module-level mocks

## Future Enhancements

- [ ] E2E tests with Playwright
- [ ] Visual regression testing
- [ ] Performance testing
- [ ] A11y automated testing
- [ ] Form interaction tests
- [ ] API integration tests
