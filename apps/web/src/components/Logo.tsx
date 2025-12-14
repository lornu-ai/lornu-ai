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
// Logo files - supports both PNG (legacy) and SVG variants
import logoPng from '@/assets/logo.png'
import logoSvg from '@/assets/logo.svg'

interface LogoProps {
  className?: string
  onClick?: () => void
  size?: 'sm' | 'md' | 'lg'
  width?: number
  height?: number
  variant?: 'default' | 'svg'
}

const sizeClasses = {
  sm: 'h-6',
  md: 'h-8',
  lg: 'h-12'
}

const logoVariants = {
  default: logoPng,
  svg: logoSvg
}

export function Logo({
  className = '',
  onClick,
  size = 'md',
  width,
  height,
  variant = 'default'
}: LogoProps) {
  const logoSource = logoVariants[variant]

  // Use explicit width/height if provided, otherwise use size classes
  const style = width || height
    ? { width: width ? `${width}px` : undefined, height: height ? `${height}px` : undefined }
    : {}

  const sizeClass = width || height ? '' : sizeClasses[size]

  const content = (
    <img
      src={logoSource}
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
