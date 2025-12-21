import { describe, it, expect } from 'vitest'
import { render, screen } from '@testing-library/react'
import { BrowserRouter } from 'react-router-dom'
import { Logo } from './Logo'

describe('Logo Component', () => {
  const renderWithRouter = (ui: React.ReactElement) => {
    return render(<BrowserRouter>{ui}</BrowserRouter>)
  }

  it('renders logo svg with correct aria-label', () => {
    renderWithRouter(<Logo />)
    const logo = screen.getByLabelText('Lornuai Enterprise AI Logo')
    expect(logo).toBeInTheDocument()
  })

  it('applies correct size class for sm size', () => {
    renderWithRouter(<Logo size="sm" />)
    const logo = screen.getByLabelText('Lornuai Enterprise AI Logo')
    expect(logo).toHaveClass('h-6')
  })

  it('applies correct size class for md size (default)', () => {
    renderWithRouter(<Logo />)
    const logo = screen.getByLabelText('Lornuai Enterprise AI Logo')
    expect(logo).toHaveClass('h-8')
  })

  it('applies correct size class for lg size', () => {
    renderWithRouter(<Logo size="lg" />)
    const logo = screen.getByLabelText('Lornuai Enterprise AI Logo')
    expect(logo).toHaveClass('h-12')
  })

  it('applies custom className', () => {
    renderWithRouter(<Logo className="custom-class" />)
    const logo = screen.getByLabelText('Lornuai Enterprise AI Logo')
    expect(logo).toHaveClass('custom-class')
  })

  it('renders with explicit width and height props', () => {
    renderWithRouter(<Logo width={100} height={50} />)
    const logo = screen.getByLabelText('Lornuai Enterprise AI Logo')
    expect(logo).toHaveStyle({ width: '100px', height: '50px' })
  })
})
