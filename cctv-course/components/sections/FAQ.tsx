"use client"
import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Plus, Minus } from 'lucide-react'
import ScrollReveal from '../ui/ScrollReveal'

const faqs = [
  {
    q: 'Is prior experience required?',
    a: 'No prior experience is needed. If you can use a smartphone or laptop, you can join. We start from the very basics and build up to practical configuration.',
  },
  {
    q: 'How long is the masterclass?',
    a: 'The masterclass is a focused 2-hour live session packed with practical demonstrations, configuration walkthroughs, and live Q&A.',
  },
  {
    q: 'Is the session live or recorded?',
    a: 'It is a LIVE interactive session. You can ask questions in real time, interact with the instructor, and get your doubts cleared on the spot.',
  },
  {
    q: 'Will I get a certificate?',
    a: 'Yes! Every participant who attends the live session receives an E-Certificate from TECHBES. The certificate includes a QR code for public verification.',
  },
  {
    q: 'What is the registration fee?',
    a: 'The registration fee is ₹499 (special launch offer, originally ₹999). This is a one-time payment with no hidden charges.',
  },
  {
    q: 'Who can join this masterclass?',
    a: 'ITI / Diploma students, CCTV technicians, electricians, networking professionals, freshers, job seekers, and anyone interested in starting a CCTV installation business.',
  },
  {
    q: 'Will there be practical demonstrations?',
    a: 'Absolutely. The entire masterclass is built around live practical demonstrations — from connecting cameras and configuring NVRs to setting up remote mobile viewing.',
  },
]

function FAQItem({ faq, isOpen, onToggle }: { faq: typeof faqs[0]; isOpen: boolean; onToggle: () => void }) {
  return (
    <div
      className={`rounded-xl border transition-all duration-200 overflow-hidden ${
        isOpen
          ? 'border-[#F5C842]/30 bg-[#F5C842]/[0.04]'
          : 'border-white/[0.06] bg-[#0A1020]/60 hover:border-white/[0.12]'
      }`}
    >
      <button
        onClick={onToggle}
        className="w-full flex items-center justify-between gap-4 px-6 py-5 text-left cursor-pointer bg-transparent border-none"
      >
        <span className={`font-semibold text-sm sm:text-base leading-snug transition-colors ${isOpen ? 'text-[#F5C842]' : 'text-white'}`}>
          {faq.q}
        </span>
        <div
          className={`w-7 h-7 rounded-full flex items-center justify-center flex-shrink-0 transition-colors ${
            isOpen ? 'bg-[#F5C842]/20 text-[#F5C842]' : 'bg-white/[0.06] text-slate-400'
          }`}
        >
          {isOpen ? <Minus size={14} /> : <Plus size={14} />}
        </div>
      </button>

      <AnimatePresence initial={false}>
        {isOpen && (
          <motion.div
            key="answer"
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: 'auto', opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{ duration: 0.28, ease: 'easeInOut' }}
            className="overflow-hidden"
          >
            <div className="px-6 pb-5">
              <div className="h-[1px] bg-white/[0.06] mb-4" />
              <p className="text-slate-400 text-sm leading-relaxed">{faq.a}</p>
            </div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  )
}

export default function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(0)

  return (
    <section id="faq" className="bg-[#101A2D] section-pad">
      <div className="max-w-section mx-auto">

        <ScrollReveal className="text-center mb-12">
          <div className="inline-flex items-center gap-2 mb-4">
            <div className="h-[2px] w-8 bg-[#F5C842]" />
            <span className="text-[#F5C842] text-xs font-bold tracking-[0.2em] uppercase">FAQ</span>
            <div className="h-[2px] w-8 bg-[#F5C842]" />
          </div>
          <h2
            className="font-extrabold text-white leading-tight"
            style={{ fontSize: 'clamp(1.8rem, 3.5vw, 2.75rem)' }}
          >
            FREQUENTLY ASKED QUESTIONS
          </h2>
          <p className="mt-3 text-slate-400 text-base max-w-xl mx-auto">
            Everything you need to know about the TECHBES CCTV Masterclass.
          </p>
        </ScrollReveal>

        <div className="max-w-3xl mx-auto space-y-3">
          {faqs.map((faq, i) => (
            <ScrollReveal key={faq.q} delay={i * 0.05}>
              <FAQItem
                faq={faq}
                isOpen={openIndex === i}
                onToggle={() => setOpenIndex(openIndex === i ? null : i)}
              />
            </ScrollReveal>
          ))}
        </div>
      </div>
    </section>
  )
}
