"use client"
import { motion, Variants } from 'framer-motion'
import { ReactNode } from 'react'

interface ScrollRevealProps {
  children: ReactNode
  delay?: number
  direction?: 'up' | 'left' | 'right' | 'none'
  className?: string
}

const variants: Record<string, Variants> = {
  up: {
    hidden:  { opacity: 0, y: 36 },
    visible: { opacity: 1, y: 0  },
  },
  left: {
    hidden:  { opacity: 0, x: -40 },
    visible: { opacity: 1, x: 0  },
  },
  right: {
    hidden:  { opacity: 0, x: 40 },
    visible: { opacity: 1, x: 0  },
  },
  none: {
    hidden:  { opacity: 0 },
    visible: { opacity: 1 },
  },
}

export default function ScrollReveal({
  children,
  delay = 0,
  direction = 'up',
  className = '',
}: ScrollRevealProps) {
  return (
    <motion.div
      initial="hidden"
      whileInView="visible"
      viewport={{ once: true, margin: '-80px' }}
      transition={{ duration: 0.65, delay, ease: [0.25, 0.46, 0.45, 0.94] }}
      variants={variants[direction]}
      className={className}
    >
      {children}
    </motion.div>
  )
}
