/**
 * Logo Component
 *
 * Displays the LornuAI logo image with entry animation.
 *
 * - If the `onClick` prop is provided, renders the logo inside an animated button (`motion.button`), making it interactive.
 * - If `onClick` is not provided, renders the logo inside an animated div (`motion.div`), making it non-interactive.
 * - Uses Framer Motion for fade-in and slide-in animation on mount.
 * - Supports testing three SVG variants via the `variant` prop.
 *
 * Props:
 * @param {string} [className] - Additional CSS classes to apply to the logo image.
 * @param {() => void} [onClick] - If provided, makes the logo clickable and renders it as a button.
 * @param {'sm' | 'md' | 'lg'} [size='md'] - Sets the logo height size (used when width/height not provided).
 * @param {number} [width] - Explicit width in pixels (overrides size prop).
 * @param {number} [height] - Explicit height in pixels (overrides size prop).
 * @param {'option1' | 'option2' | 'option3'} [variant='option1'] - Which SVG logo variant to use for testing.
 *
 * Accessibility:
 * - When rendered as a button, includes `aria-label="LornuAI Home"`.
 */

import { motion } from 'framer-motion'
// Logo SVG files for testing three options
// Files must exist at @/assets/logo.svg, logo2.svg, logo3.svg
// If any file is missing, the build will fail, ensuring all logo options are present
import logoOption1 from '@/assets/logo.svg'
import logoOption2 from '@/assets/logo2.svg'
import logoOption3 from '@/assets/logo3.svg'

interface LogoProps {
  className?: string
  onClick?: () => void
  size?: 'sm' | 'md' | 'lg'
  width?: number
  height?: number
  variant?: 'option1' | 'option2' | 'option3'
}

const sizeClasses = {
  sm: 'h-6',
  md: 'h-8',
  lg: 'h-12'
}

const logoVariants = {
  option1: logoOption1,
  option2: logoOption2,
  option3: logoOption3
}

export function Logo({
  className = '',
  onClick,
  size = 'md',
  width,
  height,
  variant = 'option2'  // Temporarily defaulting to option2 (logo2.svg) for live testing
}: LogoProps) {
  const logo = logoVariants[variant]

  // Use explicit width/height if provided, otherwise use size classes
  const style = width || height
    ? { width: width ? `${width}px` : undefined, height: height ? `${height}px` : undefined }
    : {}

  const sizeClass = width || height ? '' : sizeClasses[size]

  const content = (
    <img
      src={logo}
      alt="Lornuai Enterprise AI Logo"
      className={`${sizeClass} w-auto ${className}`}
      style={style}
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
