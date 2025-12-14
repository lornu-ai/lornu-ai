/**
 * Logo Component
 *
 * Displays the LornuAI logo image with entry animation.
 *
 * - If the `onClick` prop is provided, renders the logo inside an animated button (`motion.button`), making it interactive.
 * - If `onClick` is not provided, renders the logo inside an animated div (`motion.div`), making it non-interactive.
 * - Uses Framer Motion for fade-in and slide-in animation on mount.
 *
 * Props:
 * @param {string} [className] - Additional CSS classes to apply to the logo image.
 * @param {() => void} [onClick] - If provided, makes the logo clickable and renders it as a button.
 * @param {'sm' | 'md' | 'lg'} [size='md'] - Sets the logo height size.
 *
 * Accessibility:
 * - When rendered as a button, includes `aria-label="LornuAI Home"`.
 */

import { motion } from 'framer-motion'
// Logo file must exist at @/assets/logo.png - no fallback behavior
// If the file is missing, the build will fail, ensuring the logo is always present
import logo from '@/assets/logo.png'

interface LogoProps {
  className?: string
  onClick?: () => void
  size?: 'sm' | 'md' | 'lg'
}

const sizeClasses = {
  sm: 'h-6',
  md: 'h-8',
  lg: 'h-12'
}

export function Logo({ className = '', onClick, size = 'md' }: LogoProps) {
  const content = (
    <img 
      src={logo} 
      alt="Lornuai Enterprise AI Logo" 
      className={`${sizeClasses[size]} w-auto ${className}`}
    />
  )

  if (onClick) {
    return (
      <motion.button
        onClick={onClick}
        initial={{ opacity: 0, x: -20 }}
        animate={{ opacity: 1, x: 0 }}
        className="flex items-center hover:opacity-80 transition-opacity"
        aria-label="LornuAI Home"
      >
        {content}
      </motion.button>
    )
  }

  return (
    <motion.div
      initial={{ opacity: 0, x: -20 }}
      animate={{ opacity: 1, x: 0 }}
      className="flex items-center"
    >
      {content}
    </motion.div>
  )
}

