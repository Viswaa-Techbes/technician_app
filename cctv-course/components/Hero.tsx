"use client"
import Link from 'next/link'
import { motion } from 'framer-motion'
import FeatureCard from './FeatureCard'

// Simple icons as emoji placeholders – replace with Heroicons if available
const icons = {
  live: '📡',
  demo: '🛠️',
  certificate: '📄',
  experts: '👩‍🏫',
}

export default function Hero() {
  const fadeUp = {
    initial: { opacity: 0, y: 20 },
    animate: { opacity: 1, y: 0 },
    transition: { duration: 0.6 },
  }
  return (
    <section className="relative overflow-hidden bg-gradient-to-b from-slate-900 via-slate-800 to-slate-950 py-16">
      {/* subtle grid background */}
      <div className="absolute inset-0 bg-[url('data:image/svg+xml,%3Csvg width=40 height=40 viewBox=0 0 40 40 xmlns=\'http://www.w3.org/2000/svg\'%3E%3Cpath d=\'M0 0H40V40H0Z\' fill=\'none\'/%3E%3Cpath d=\'M0 0L40 40M40 0L0 40\' stroke=\'%23666\' stroke-width=\'0.5\'/%3E%3C/svg%3E')] pointer-events-none" />
      <div className="container mx-auto px-4 grid md:grid-cols-2 gap-8 items-center relative z-10">
        {/* LEFT */}
        <motion.div {...fadeUp} className="space-y-4">
          <div className="inline-flex items-center gap-2 bg-yellow-400/10 text-yellow-300 px-3 py-1 rounded-full text-sm animate-pulse">LIVE & PRACTICAL</div>
          <h1 className="mt-4 text-4xl md:text-5xl font-extrabold text-white">CCTV MASTERCLASS</h1>
          <p className="mt-3 text-slate-300">Learn. Practice. Build Your Career.</p>
          <p className="mt-4 text-slate-300 max-w-prose">Learn CCTV Installation, IP Networking, NVR Configuration, Mobile Viewing and Troubleshooting through a live practical masterclass.</p>
          <div className="mt-6 flex items-center gap-4">
            <div className="text-sm text-slate-400 line-through">₹999</div>
            <div className="text-3xl font-bold text-yellow-300">₹499</div>
            <div className="ml-3 px-2 py-1 bg-red-600 text-white rounded">SPECIAL LAUNCH OFFER</div>
          </div>
          <Link href="#register">
            <motion.a whileHover={{ scale: 1.02 }} className="inline-block bg-red-600 text-white px-6 py-3 rounded font-semibold shadow-lg hover:shadow-xl transition">REGISTER NOW – ₹499</motion.a>
          </Link>
          {/* Feature cards */}
          <div className="mt-8 grid grid-cols-2 gap-4">
            <FeatureCard icon={() => <span className='text-2xl'>{icons.live}</span>} title="Live Interactive Session" />
            <FeatureCard icon={() => <span className='text-2xl'>{icons.demo}</span>} title="Practical Demonstration" />
            <FeatureCard icon={() => <span className='text-2xl'>{icons.certificate}</span>} title="E‑Certificate" />
            <FeatureCard icon={() => <span className='text-2xl'>{icons.experts}</span>} title="Industry Experts" />
          </div>
        </motion.div>
        {/* RIGHT */}
        <motion.div {...fadeUp} className="flex justify-center">
          <div className="w-full max-w-md h-64 bg-gradient-to-br from-slate-800 to-slate-900 rounded-lg border border-yellow-800 flex items-center justify-center overflow-hidden">
            <img src="/images/poster-preview.jpg" alt="CCTV Masterclass" className="object-cover w-full h-full" />
          </div>
        </motion.div>
      </div>
    </section>
  )
}

