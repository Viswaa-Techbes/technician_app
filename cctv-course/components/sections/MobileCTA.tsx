"use client"
import { useEffect, useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { ArrowRight } from 'lucide-react'

export default function MobileCTA() {
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    const heroEl = document.querySelector('section')
    if (!heroEl) return

    const observer = new IntersectionObserver(
      ([entry]) => setVisible(!entry.isIntersecting),
      { threshold: 0.1 }
    )
    observer.observe(heroEl)
    return () => observer.disconnect()
  }, [])

  const scrollToRegister = () => {
    const el = document.querySelector('#register')
    if (el) {
      const top = el.getBoundingClientRect().top + window.scrollY - 72
      window.scrollTo({ top, behavior: 'smooth' })
    }
  }

  return (
    <AnimatePresence>
      {visible && (
        <motion.div
          key="mobile-cta"
          initial={{ y: 80, opacity: 0 }}
          animate={{ y: 0, opacity: 1 }}
          exit={{ y: 80, opacity: 0 }}
          transition={{ duration: 0.3, ease: 'easeOut' }}
          className="fixed bottom-0 left-0 right-0 z-40 lg:hidden"
          style={{
            background: 'linear-gradient(to top, rgba(5,9,18,0.98) 0%, rgba(5,9,18,0.95) 100%)',
            borderTop: '1px solid rgba(245,200,66,0.2)',
            backdropFilter: 'blur(16px)',
            paddingBottom: 'env(safe-area-inset-bottom, 0px)',
          }}
        >
          <div className="flex items-center justify-between gap-3 px-4 py-3">
            <div>
              <div className="text-white font-bold text-xs tracking-wide uppercase leading-tight">
                CCTV MASTERCLASS
              </div>
              <div className="flex items-baseline gap-2 mt-0.5">
                <span className="text-slate-500 line-through text-xs">₹999</span>
                <span className="text-[#F5C842] font-extrabold text-lg leading-tight">₹499</span>
              </div>
            </div>
            <button
              onClick={scrollToRegister}
              className="btn-red px-5 py-3 rounded-xl text-sm font-extrabold tracking-wide flex-shrink-0 shadow-[0_0_20px_rgba(229,57,53,0.4)]"
            >
              REGISTER NOW
              <ArrowRight size={14} />
            </button>
          </div>
        </motion.div>
      )}
    </AnimatePresence>
  )
}
