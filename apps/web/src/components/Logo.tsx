/**
 * Logo Component
 * 
 * Displays the LornuAI logo image. Falls back to text if logo file is not available.
 * 
 * TODO: Once logo.svg or logo.png is added to src/assets/, uncomment the import
 * and replace the fallback text with the image.
 */

import { motion } from 'framer-motion'

interface LogoProps {
  className?: string
  onClick?: () => void
  size?: 'sm' | 'md' | 'lg'
}

// TODO: Uncomment once logo file is added to src/assets/
// import logo from '@/assets/logo.svg'
// OR
// import logo from '@/assets/logo.png'

const sizeClasses = {
  sm: 'h-6',
  md: 'h-8',
  lg: 'h-12'
}

export function Logo({ className = '', onClick, size = 'md' }: LogoProps) {
  // TODO: Uncomment logo import above once logo file is added
  const logo: string | undefined = undefined

  const content = logo ? (
    <img 
      src={logo} 
      alt="Lornuai Enterprise AI Logo" 
      className={`${sizeClasses[size]} w-auto ${className}`}
    />
  ) : (
    <span className={`text-2xl font-bold gradient-text ${className}`}>
      LornuAI
    </span>
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

