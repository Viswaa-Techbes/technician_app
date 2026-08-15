"use client"
import { motion } from 'framer-motion'
import { ArrowRight } from 'lucide-react'
import ScrollReveal from '../ui/ScrollReveal'

export default function FinalCTA() {
  const scrollToRegister = () => {
    const el = document.querySelector('#register')
    if (el) {
      const top = el.getBoundingClientRect().top + window.scrollY - 72
      window.scrollTo({ top, behavior: 'smooth' })
    }
  }

  return (
    <section className="bg-[#050912] section-pad-sm overflow-hidden">
      <div className="max-w-section mx-auto">
        <ScrollReveal>
          <div
            className="relative rounded-3xl overflow-hidden text-center py-16 px-8"
            style={{ background: 'linear-gradient(135deg, rgba(245,200,66,0.08) 0%, rgba(229,57,53,0.06) 50%, rgba(14,165,233,0.04) 100%)', border: '1px solid rgba(245,200,66,0.15)' }}
          >
            {/* Background grid */}
            <div className="absolute inset-0 tech-grid-bg opacity-60 pointer-events-none" />

            {/* Gold glow top */}
            <div
              className="absolute top-0 left-1/2 -translate-x-1/2 w-64 h-32 pointer-events-none"
              style={{ background: 'radial-gradient(ellipse, rgba(245,200,66,0.15) 0%, transparent 70%)' }}
            />

            <div className="relative z-10">
              <div className="inline-flex items-center gap-2 bg-[#E53935]/12 border border-[#E53935]/25 text-[#EF5350] text-xs font-bold px-4 py-1.5 rounded-full tracking-widest uppercase mb-6">
                <span className="w-1.5 h-1.5 rounded-full bg-[#E53935] animate-pulse inline-block" />
                Limited Seats Available
              </div>

              <h2
                className="font-extrabold text-white leading-tight mb-4"
                style={{ fontSize: 'clamp(1.8rem, 4vw, 3rem)' }}
              >
                READY TO BUILD YOUR CCTV SKILLS?
              </h2>

              <p className="text-slate-400 text-base max-w-lg mx-auto mb-8 leading-relaxed">
                Join the TECHBES CCTV Masterclass. 2 hours of live, practical training that
                will set you apart in the CCTV installation industry.
              </p>

              <div className="flex items-center justify-center gap-4 flex-wrap mb-8">
                <span className="text-slate-500 line-through text-lg">₹999</span>
                <span className="text-[#F5C842] font-extrabold" style={{ fontSize: 'clamp(2rem, 4vw, 3rem)' }}>
                  ₹499 ONLY
                </span>
              </div>

              <motion.button
                whileHover={{ scale: 1.04, boxShadow: '0 0 60px rgba(229,57,53,0.55)' }}
                whileTap={{ scale: 0.97 }}
                onClick={scrollToRegister}
                className="btn-red px-10 py-4 rounded-xl text-base font-extrabold tracking-wide shadow-[0_0_40px_rgba(229,57,53,0.35)] inline-flex items-center gap-2"
              >
                RESERVE MY SEAT
                <ArrowRight size={20} />
              </motion.button>
            </div>
          </div>
        </ScrollReveal>
      </div>
    </section>
  )
}
