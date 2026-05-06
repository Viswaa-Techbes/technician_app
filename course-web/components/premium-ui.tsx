'use client'

import { motion, useMotionValue, useSpring } from 'framer-motion'
import type { ReactNode } from 'react'
import {
  BadgeCheck,
  BriefcaseBusiness,
  Camera,
  CircleDollarSign,
  Cpu,
  MonitorCog,
  Network,
  RadioTower,
  ShieldCheck,
  Sparkles,
  Wrench,
} from 'lucide-react'

export const MotionDiv = motion.div
export const MotionSection = motion.section

export function MouseGlow() {
  const x = useMotionValue(0)
  const y = useMotionValue(0)
  const springX = useSpring(x, { stiffness: 80, damping: 24, mass: 0.4 })
  const springY = useSpring(y, { stiffness: 80, damping: 24, mass: 0.4 })

  return (
    <motion.div
      aria-hidden="true"
      className="pointer-events-none fixed inset-0 z-0 opacity-70"
      onMouseMove={(event) => {
        x.set(event.clientX)
        y.set(event.clientY)
      }}
    >
      <motion.div
        className="absolute h-72 w-72 rounded-full bg-[radial-gradient(circle,rgba(255,107,0,0.16),rgba(11,77,186,0.08)_45%,transparent_70%)] blur-2xl"
        style={{ x: springX, y: springY, translateX: '-50%', translateY: '-50%' }}
      />
    </motion.div>
  )
}

export function Reveal({
  children,
  className = '',
  delay = 0,
}: {
  children: ReactNode
  className?: string
  delay?: number
}) {
  return (
    <motion.div
      initial={{ opacity: 0, y: 34, filter: 'blur(10px)' }}
      whileInView={{ opacity: 1, y: 0, filter: 'blur(0px)' }}
      viewport={{ once: true, margin: '-80px' }}
      transition={{ duration: 0.75, ease: [0.22, 1, 0.36, 1], delay }}
      className={className}
    >
      {children}
    </motion.div>
  )
}

export function SectionShell({
  children,
  className = '',
}: {
  children: ReactNode
  className?: string
}) {
  return (
    <section className={`relative overflow-hidden px-4 py-24 md:py-36 ${className}`}>
      <div className="pointer-events-none absolute inset-0 bg-[linear-gradient(rgba(11,77,186,0.04)_1px,transparent_1px),linear-gradient(90deg,rgba(11,77,186,0.04)_1px,transparent_1px)] bg-[size:48px_48px]" />
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_18%_22%,rgba(11,77,186,0.10),transparent_34%),radial-gradient(circle_at_80%_14%,rgba(255,107,0,0.08),transparent_30%)]" />
      <div className="relative z-10 container mx-auto">{children}</div>
    </section>
  )
}

export function GlassCard({
  children,
  className = '',
  delay = 0,
}: {
  children: ReactNode
  className?: string
  delay?: number
}) {
  return (
    <Reveal delay={delay}>
      <motion.div
        whileHover={{ y: -10, scale: 1.015 }}
        transition={{ type: 'spring', stiffness: 260, damping: 20 }}
        className={`relative group rounded-2xl overflow-hidden glass-card ${className}`}
      >
        {children}
      </motion.div>
    </Reveal>
  )
}

export function PremiumButton({
  children,
  className = '',
}: {
  children: ReactNode
  className?: string
}) {
  return (
    <motion.span
      whileHover={{ scale: 1.04 }}
      whileTap={{ scale: 0.98 }}
      className={`inline-flex ${className}`}
    >
      {children}
    </motion.span>
  )
}

export const featureIcons = [ShieldCheck, RadioTower, BriefcaseBusiness, Sparkles, BadgeCheck]
export const moduleIcons = [Camera, Network, Cpu, Wrench, BriefcaseBusiness]
export const pricingIcons = [MonitorCog, Sparkles, CircleDollarSign]

export function CinematicVideoFrame() {
  const floatingItems = [
    { Icon: Camera, className: 'left-0 top-10', delay: 0 },
    { Icon: Network, className: 'right-2 top-20', delay: 0.25 },
    { Icon: RadioTower, className: 'left-8 bottom-10', delay: 0.5 },
  ]

  return (
    <motion.div
      initial={{ opacity: 0, x: 42, rotateY: -8 }}
      animate={{ opacity: 1, x: 0, rotateY: 0 }}
      transition={{ duration: 0.9, ease: [0.22, 1, 0.36, 1] }}
      className="relative min-h-[430px]"
    >
      {/* Glow orb behind the frame */}
      <div className="absolute inset-6 rounded-[2rem] bg-[conic-gradient(from_140deg,rgba(11,77,186,0.45),rgba(255,107,0,0.38),rgba(11,77,186,0.45))] blur-3xl opacity-70" />

      {/* Floating video frame */}
      <motion.div
        animate={{ y: [0, -14, 0], rotate: [0, 0.7, 0] }}
        transition={{ duration: 6, repeat: Infinity, ease: 'easeInOut' }}
        className="relative overflow-hidden rounded-[2rem] border border-white/50 bg-white/25 p-3 shadow-[0_35px_90px_rgba(8,59,138,0.24)] backdrop-blur-2xl"
      >
        <div className="relative aspect-video overflow-hidden rounded-[1.5rem] bg-[#061f4f]">
          {/* Video element — plays the real promo */}
          <video
            className="absolute inset-0 h-full w-full object-cover"
            autoPlay
            muted
            loop
            playsInline
            src="/promo.mp4"
            aria-label="TECHBES Promo Video"
          />
          {/* Subtle gradient overlay on top of video */}
          <div className="absolute inset-0 bg-[linear-gradient(to_bottom,rgba(11,77,186,0.08),transparent_40%,rgba(8,59,138,0.18))] pointer-events-none" />
          {/* Corner badge */}
          <div className="absolute top-3 left-3 bg-black/40 backdrop-blur-sm text-white text-xs font-bold px-3 py-1.5 rounded-full flex items-center gap-1.5">
            <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
            LIVE TRAINING
          </div>
        </div>
      </motion.div>

      {/* Floating icons */}
      {floatingItems.map(({ Icon, className, delay }) => (
        <motion.div
          key={className}
          animate={{ y: [0, -16, 0], x: [0, 8, 0] }}
          transition={{ duration: 5, repeat: Infinity, ease: 'easeInOut', delay }}
          className={`absolute hidden rounded-2xl border border-white/50 bg-white/40 p-4 text-[#0B4DBA] shadow-xl backdrop-blur-xl md:block ${className}`}
        >
          <Icon className="h-6 w-6" />
        </motion.div>
      ))}

      {/* Animated dashed line */}
      <svg className="absolute inset-x-6 bottom-16 hidden h-28 text-[#0B4DBA]/25 md:block" viewBox="0 0 500 120" fill="none">
        <motion.path
          d="M5 80 C120 5 190 125 290 45 C360 -10 420 30 495 8"
          stroke="currentColor"
          strokeWidth="2"
          strokeDasharray="8 10"
          initial={{ pathLength: 0 }}
          animate={{ pathLength: 1 }}
          transition={{ duration: 3, repeat: Infinity, repeatType: 'reverse', ease: 'easeInOut' }}
        />
      </svg>
    </motion.div>
  )
}
