# Epic: Theme Customization & Social Footprint Integration

**Issue**: #96
**Status**: Planning
**Priority**: Medium
**Target Component**: Frontend (React + Tailwind)

---

## Overview

This epic covers implementing a multi-theme engine (Light, Dark, High-Contrast modes) and integrating official Lornu AI social channels (GitHub & YouTube) into the global navigation and footer components.

---

## Epics Breakdown

### Epic 1: Theme Engine Implementation

**Goal**: Enable users to customize the visual appearance of the application with multiple theme options.

**Acceptance Criteria**:
- Users can toggle between Light, Dark, and System themes
- Theme preference persists across sessions via localStorage
- All components respect the active theme
- Color contrast meets WCAG AA standards

#### User Stories

| ID | Story | Priority | Estimate |
|----|-------|----------|----------|
| US-1.1 | As a user, I want to toggle between Light and Dark themes so I can use the app comfortably in different lighting conditions | High | 3 pts |
| US-1.2 | As a user, I want my theme preference to persist when I return to the site so I don't have to reconfigure it each visit | High | 2 pts |
| US-1.3 | As a user, I want the app to respect my system preference by default so the theme matches my OS settings | Medium | 2 pts |
| US-1.4 | As a developer, I want a ThemeContext provider that makes the current theme available throughout the component tree | High | 3 pts |
| US-1.5 | As a user with accessibility needs, I want a high-contrast theme option so I can use the app with visual impairments | Low | 5 pts |

#### Technical Tasks

- [ ] Create `ThemeContext.tsx` with theme state management
- [ ] Implement `ThemeToggle.tsx` component with dropdown/button UI
- [ ] Update `tailwind.config.js` for class-based dark mode
- [ ] Define CSS variables for each theme in `styles/theme.css`
- [ ] Add theme toggle to navbar
- [ ] Write unit tests for ThemeContext (target: 70% coverage)
- [ ] Verify WCAG AA compliance for all themes

---

### Epic 2: Social Links Integration

**Goal**: Provide quick access to Lornu AI community channels from the application.

**Acceptance Criteria**:
- GitHub and YouTube links are visible in footer
- Links open in new tabs with proper security attributes
- Icons are consistent with existing design system
- Mobile-responsive layout

#### User Stories

| ID | Story | Priority | Estimate |
|----|-------|----------|----------|
| US-2.1 | As a community member, I want to quickly access the Lornu AI GitHub organization from the footer so I can contribute to the project | High | 2 pts |
| US-2.2 | As a user, I want to find YouTube tutorials from the footer so I can learn how to use the platform | Medium | 1 pt |
| US-2.3 | As a user, I want social links to open in new tabs so I don't lose my place in the application | High | 1 pt |
| US-2.4 | As a mobile user, I want the footer social links to be easily tappable so I can access them on touch devices | Medium | 2 pts |

#### Technical Tasks

- [ ] Create `SocialLinks.tsx` component
- [ ] Add GitHub and YouTube icons using lucide-react
- [ ] Update Footer component with Community section
- [ ] Ensure all external links have `rel="noopener noreferrer"` and `target="_blank"`
- [ ] Add hover states and transitions
- [ ] Test responsive layout on mobile breakpoints

---

## Definition of Done

- [ ] All user stories implemented and tested
- [ ] Unit test coverage >= 70% for new components
- [ ] E2E smoke tests pass
- [ ] Accessibility audit passes (WCAG AA)
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Deployed to staging for visual regression testing

---

## Dependencies

- **No backend changes required**
- Uses existing `next-themes` package (already installed)
- Uses existing `lucide-react` for icons

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Theme flicker on page load | Medium | Use `next-themes` SSR support or add theme script to document head |
| Inconsistent styling across components | High | Create comprehensive theme variable set before implementation |
| Breaking existing dark mode styles | Medium | Audit current CSS before making changes |

---

## Timeline Estimate

| Phase | Duration |
|-------|----------|
| Epic 1: Theme Engine | 2-3 days |
| Epic 2: Social Links | 1 day |
| Testing & QA | 1 day |
| **Total** | **4-5 days** |

---

## Related Issues

- #96 - Feature Request: Theme Customization & Social Footprint Integration
- #98 - Feature Request: Global Brand Logo Update (related UI work)
