"use client"
import { motion } from 'framer-motion'
import { CheckCircle2, ArrowRight } from 'lucide-react'
import ScrollReveal from '../ui/ScrollReveal'

const features = [
  '2 Hour Live Session',
  'Practical Demonstration',
  'Industry Expert Instruction',
  'Live Doubt Clearance',
  'E-Certificate on Completion',
  'Learning Resources Included',
]

export default function PricingSection() {
  const scrollToRegister = () => {
    const el = document.querySelector('#register')
    if (el) {
      const top = el.getBoundingClientRect().top + window.scrollY - 72
      window.scrollTo({ top, behavior: 'smooth' })
    }
  }

  return (
    <section className="bg-[#050912] section-pad overflow-hidden">
      <div className="max-w-section mx-auto">

        <ScrollReveal className="text-center mb-12">
          <div className="inline-flex items-center gap-2 mb-4">
            <div className="h-[2px] w-8 bg-[#F5C842]" />
            <span className="text-[#F5C842] text-xs font-bold tracking-[0.2em] uppercase">Pricing</span>
            <div className="h-[2px] w-8 bg-[#F5C842]" />
          </div>
          <h2
            className="font-extrabold text-white leading-tight"
            style={{ fontSize: 'clamp(1.8rem, 3.5vw, 2.75rem)' }}
          >
            SIMPLE, ONE-TIME PRICING
          </h2>
        </ScrollReveal>

        <ScrollReveal delay={0.1}>
          <div className="max-w-lg mx-auto relative">
            {/* Outer glow */}
            <div
              className="absolute -inset-4 rounded-3xl pointer-events-none"
              style={{ background: 'radial-gradient(ellipse at center, rgba(245,200,66,0.1) 0%, transparent 70%)' }}
            />

            <div className="relative rounded-3xl overflow-hidden" style={{ border: '1px solid rgba(245,200,66,0.3)' }}>
              {/* Header */}
              <div
                className="px-8 pt-8 pb-6 text-center"
                style={{ background: 'linear-gradient(135deg, rgba(245,200,66,0.08) 0%, rgba(10,16,32,1) 60%)' }}
              >
                {/* Launch badge */}
                <div className="inline-flex items-center gap-2 bg-[#E53935]/15 border border-[#E53935]/30 text-[#EF5350] text-xs font-bold px-4 py-1.5 rounded-full tracking-widest uppercase mb-5">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#E53935] animate-pulse inline-block" />
                  Special Launch Offer
                </div>

                <div className="text-slate-400 font-semibold text-sm tracking-widest uppercase mb-2">
                  TECHBES CCTV Masterclass
                </div>

                {/* Price */}
                <div className="flex items-baseline justify-center gap-4 my-4">
                  <span className="text-slate-500 line-through text-2xl">₹999</span>
                  <span
                    className="text-[#F5C842] font-extrabold leading-none"
                    style={{ fontSize: 'clamp(3.5rem, 7vw, 5rem)' }}
                  >
                    ₹499
                  </span>
                </div>
                <div className="text-slate-400 text-sm">One-Time Registration · No Hidden Fees</div>
              </div>

              {/* Divider */}
              <div className="h-[1px] bg-gradient-to-r from-transparent via-[#F5C842]/25 to-transparent" />

              {/* Features */}
              <div className="bg-[#0A1020] px-8 py-7">
                <div className="space-y-3 mb-7">
                  {features.map(f => (
                    <div key={f} className="flex items-center gap-3">
                      <div className="w-5 h-5 rounded-full bg-[#F5C842]/15 flex items-center justify-center flex-shrink-0">
                        <CheckCircle2 size={13} className="text-[#F5C842]" />
                      </div>
                      <span className="text-slate-300 text-sm font-medium">{f}</span>
                    </div>
                  ))}
                </div>

                {/* CTA */}
                <motion.button
                  whileHover={{ scale: 1.02, boxShadow: '0 0 40px rgba(229,57,53,0.5)' }}
                  whileTap={{ scale: 0.97 }}
                  onClick={scrollToRegister}
                  className="w-full btn-red py-4 rounded-xl text-base font-extrabold tracking-wide shadow-[0_0_30px_rgba(229,57,53,0.3)]"
                >
                  RESERVE MY SEAT — ₹499
                  <ArrowRight size={18} />
                </motion.button>

                {/* Urgency */}
                <div className="mt-4 text-center">
                  <span className="text-[#E53935] text-xs font-bold tracking-widest uppercase animate-pulse">
                    ⚡ Limited Seats Available
                  </span>
                </div>
              </div>
            </div>
          </div>
        </ScrollReveal>
      </div>
    </section>
  )
}
