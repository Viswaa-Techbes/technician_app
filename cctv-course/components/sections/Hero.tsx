"use client"
import Image from 'next/image'
import { motion } from 'framer-motion'
import { ArrowRight, CheckCircle2, Clock, Zap, Award, Video } from 'lucide-react'

const floatingCards = [
  { icon: Clock,    label: '2 HOURS',     sublabel: 'LIVE SESSION',  color: '#F5C842', delay: 0,   top: '10%',  left: '-5%'  },
  { icon: Zap,      label: '100%',        sublabel: 'PRACTICAL',     color: '#0EA5E9', delay: 0.4, top: '55%',  right: '-3%' },
  { icon: Award,    label: 'E-CERTIFICATE', sublabel: 'INCLUDED',    color: '#E53935', delay: 0.8, bottom: '12%', left: '5%' },
]

const features = [
  'Online Live Class',
  'Practical Demonstration',
  'E-Certificate Included',
]

export default function Hero() {
  const scrollToRegister = () => {
    const el = document.querySelector('#register')
    if (el) {
      const top = el.getBoundingClientRect().top + window.scrollY - 72
      window.scrollTo({ top, behavior: 'smooth' })
    }
  }

  return (
    <section className="relative min-h-screen flex items-center overflow-hidden bg-[#050912]" style={{ paddingTop: '68px' }}>

      {/* Tech grid background */}
      <div className="absolute inset-0 tech-grid-bg opacity-100 pointer-events-none" />

      {/* Blue radial glow — top right */}
      <div
        className="absolute pointer-events-none"
        style={{
          top: '-10%', right: '-5%',
          width: '55vw', height: '55vw',
          background: 'radial-gradient(circle, rgba(14,165,233,0.08) 0%, transparent 70%)',
        }}
      />

      {/* Gold radial glow — bottom left */}
      <div
        className="absolute pointer-events-none"
        style={{
          bottom: '-5%', left: '-5%',
          width: '45vw', height: '45vw',
          background: 'radial-gradient(circle, rgba(245,200,66,0.06) 0%, transparent 70%)',
        }}
      />

      {/* Red accent dot — center */}
      <div
        className="absolute pointer-events-none animate-pulse-glow"
        style={{
          top: '40%', left: '48%',
          width: '300px', height: '300px',
          background: 'radial-gradient(circle, rgba(229,57,53,0.04) 0%, transparent 70%)',
        }}
      />

      <div className="relative z-10 max-w-section mx-auto w-full px-6 lg:px-10 py-16 lg:py-20">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">

          {/* ─── LEFT COLUMN ─── */}
          <div className="flex flex-col">

            {/* Live badge */}
            <motion.div
              initial={{ opacity: 0, y: -12 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
              className="inline-flex items-center gap-2 self-start mb-6"
            >
              <div className="flex items-center gap-2 bg-[#F5C842]/10 border border-[#F5C842]/30 px-4 py-1.5 rounded-full">
                <span className="inline-block w-2 h-2 rounded-full bg-[#F5C842] animate-pulse" />
                <span className="text-[#F5C842] font-bold text-xs tracking-[0.15em] uppercase">
                  Live &amp; Practical
                </span>
              </div>
            </motion.div>

            {/* Main heading */}
            <motion.div
              initial={{ opacity: 0, y: 24 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.65, delay: 0.1 }}
            >
              <h1 className="font-extrabold leading-none tracking-tight">
                <span
                  className="block text-white"
                  style={{ fontSize: 'clamp(4rem, 9vw, 8rem)', letterSpacing: '-0.02em' }}
                >
                  CCTV
                </span>
                <span
                  className="block text-gold-gradient font-extrabold"
                  style={{ fontSize: 'clamp(2rem, 5vw, 4.5rem)', letterSpacing: '0.08em' }}
                >
                  MASTERCLASS
                </span>
              </h1>
            </motion.div>

            {/* Tagline */}
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.25 }}
              className="mt-5 text-slate-300 text-base font-semibold tracking-widest uppercase"
            >
              Learn. Practice. Build Your Career.
            </motion.p>

            {/* Description */}
            <motion.p
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.35 }}
              className="mt-4 text-slate-400 text-base leading-relaxed max-w-md"
            >
              Learn CCTV Installation, IP Networking, NVR Configuration,
              Mobile Viewing &amp; Troubleshooting through a live, hands-on
              practical masterclass.
            </motion.p>

            {/* Online Live Class info */}
            <motion.div
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.42 }}
              className="mt-4 flex items-start gap-3 bg-[#0EA5E9]/[0.07] border border-[#0EA5E9]/20 rounded-xl px-4 py-3 max-w-md"
            >
              <div className="flex-shrink-0 w-7 h-7 rounded-lg bg-[#0EA5E9]/15 flex items-center justify-center mt-0.5">
                <Video size={14} className="text-[#0EA5E9]" />
              </div>
              <div>
                <div className="text-[#0EA5E9] font-bold text-xs tracking-[0.12em] uppercase mb-0.5">
                  Online Live Class
                </div>
                <div className="text-slate-400 text-xs leading-snug">
                  Attend from anywhere in India. Zoom link will be shared with registered members before the session.
                </div>
              </div>
            </motion.div>

            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.45 }}
              className="mt-7 flex items-end gap-4"
            >
              <div>
                <div className="text-xs text-slate-500 font-semibold tracking-widest uppercase mb-1">
                  Special Launch Offer
                </div>
                <div className="flex items-baseline gap-3">
                  <span className="text-slate-500 line-through text-xl font-medium">₹999</span>
                  <span className="text-[#F5C842] font-extrabold leading-none" style={{ fontSize: 'clamp(2.5rem, 5vw, 3.5rem)' }}>
                    ₹499
                  </span>
                  <span className="text-sm text-slate-400 font-medium">only</span>
                </div>
              </div>
              <div className="mb-2">
                <div className="bg-[#E53935]/15 border border-[#E53935]/30 text-[#EF5350] text-xs font-bold px-3 py-1.5 rounded-lg tracking-wide uppercase">
                  Limited Seats
                </div>
              </div>
            </motion.div>

            {/* CTA Button */}
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.55 }}
              className="mt-6"
            >
              <motion.button
                whileHover={{ scale: 1.03, boxShadow: '0 0 40px rgba(229,57,53,0.5)' }}
                whileTap={{ scale: 0.97 }}
                onClick={scrollToRegister}
                className="btn-red text-base px-8 py-4 rounded-xl font-extrabold tracking-wide shadow-[0_0_30px_rgba(229,57,53,0.3)] w-full sm:w-auto"
              >
                REGISTER NOW — ₹499
                <ArrowRight size={18} className="ml-1" />
              </motion.button>
            </motion.div>

            {/* Feature checks */}
            <motion.div
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6, delay: 0.65 }}
              className="mt-6 flex flex-wrap gap-x-6 gap-y-2"
            >
              {features.map(f => (
                <div key={f} className="flex items-center gap-2 text-sm text-slate-300">
                  <CheckCircle2 size={15} className="text-[#F5C842] flex-shrink-0" />
                  <span>{f}</span>
                </div>
              ))}
            </motion.div>
          </div>

          {/* ─── RIGHT COLUMN ─── */}
          <motion.div
            initial={{ opacity: 0, scale: 0.95, x: 30 }}
            animate={{ opacity: 1, scale: 1, x: 0 }}
            transition={{ duration: 0.8, delay: 0.2, ease: [0.25, 0.46, 0.45, 0.94] }}
            className="relative flex justify-center items-center"
          >
            {/* Glow behind image */}
            <div
              className="absolute inset-0 pointer-events-none"
              style={{
                background: 'radial-gradient(ellipse 70% 60% at 50% 50%, rgba(14,165,233,0.12) 0%, rgba(245,200,66,0.06) 40%, transparent 75%)',
              }}
            />

            {/* Image container — floating animation */}
            <div className="relative animate-float" style={{ width: '100%', maxWidth: '540px' }}>
              <Image
                src="/images/poster-preview.jpg"
                alt="TECHBES CCTV Masterclass"
                width={540}
                height={680}
                className="w-full h-auto object-contain drop-shadow-2xl"
                priority
                style={{
                  filter: 'drop-shadow(0 0 40px rgba(14,165,233,0.2)) drop-shadow(0 0 80px rgba(245,200,66,0.08))',
                }}
              />

              {/* Floating card — top left */}
              <motion.div
                initial={{ opacity: 0, y: -10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.9, duration: 0.5 }}
                className="absolute -top-4 -left-4 lg:-left-8 card-glass card-gold-border rounded-xl px-4 py-3 animate-float-reverse"
                style={{ animationDelay: '1s' }}
              >
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-lg bg-[#F5C842]/15 flex items-center justify-center">
                    <Clock size={16} className="text-[#F5C842]" />
                  </div>
                  <div>
                    <div className="text-white font-extrabold text-sm leading-tight">2 HOURS</div>
                    <div className="text-slate-400 text-[10px] font-semibold tracking-wider uppercase">Live Session</div>
                  </div>
                </div>
              </motion.div>

              {/* Floating card — right middle */}
              <motion.div
                initial={{ opacity: 0, x: 10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 1.1, duration: 0.5 }}
                className="absolute top-1/2 -right-4 lg:-right-10 -translate-y-1/2 card-glass rounded-xl px-4 py-3 animate-float"
                style={{ animationDelay: '2s', borderColor: 'rgba(14,165,233,0.25)', border: '1px solid rgba(14,165,233,0.25)' }}
              >
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-lg bg-[#0EA5E9]/15 flex items-center justify-center">
                    <Zap size={16} className="text-[#0EA5E9]" />
                  </div>
                  <div>
                    <div className="text-white font-extrabold text-sm leading-tight">100%</div>
                    <div className="text-slate-400 text-[10px] font-semibold tracking-wider uppercase">Practical</div>
                  </div>
                </div>
              </motion.div>

              {/* Floating card — bottom left */}
              <motion.div
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 1.3, duration: 0.5 }}
                className="absolute -bottom-4 left-8 card-glass rounded-xl px-4 py-3 animate-float-slow"
                style={{ animationDelay: '3s', borderColor: 'rgba(229,57,53,0.25)', border: '1px solid rgba(229,57,53,0.25)' }}
              >
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-lg bg-[#E53935]/15 flex items-center justify-center">
                    <Award size={16} className="text-[#E53935]" />
                  </div>
                  <div>
                    <div className="text-white font-extrabold text-sm leading-tight">E-CERTIFICATE</div>
                    <div className="text-slate-400 text-[10px] font-semibold tracking-wider uppercase">Included</div>
                  </div>
                </div>
              </motion.div>
            </div>
          </motion.div>
        </div>
      </div>

      {/* Bottom fade */}
      <div
        className="absolute bottom-0 left-0 right-0 h-24 pointer-events-none"
        style={{ background: 'linear-gradient(to bottom, transparent, #050912)' }}
      />
    </section>
  )
}
