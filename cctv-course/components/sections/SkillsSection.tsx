"use client"
import { motion } from 'framer-motion'
import { ArrowRight } from 'lucide-react'
import ScrollReveal from '../ui/ScrollReveal'

const progression = [
  { step: 'LEARN',      desc: 'Understand how CCTV systems are designed and configured.',   color: '#F5C842' },
  { step: 'PRACTICE',   desc: 'Follow along with live demonstrations on real hardware.',       color: '#0EA5E9' },
  { step: 'UNDERSTAND', desc: 'Connect theory to real-world scenarios and outcomes.',          color: '#A855F7' },
  { step: 'APPLY',      desc: 'Use your new skills on the job or in your own business.',       color: '#22C55E' },
]

const skillTags = [
  'CCTV Installation',
  'IP Camera Configuration',
  'NVR Setup & Management',
  'PoE Networking',
  'Remote Mobile Viewing',
  'Basic Troubleshooting',
  'Site Planning',
  'Cable & Hardware',
]

export default function SkillsSection() {
  return (
    <section className="bg-[#101A2D] section-pad overflow-hidden">
      <div className="max-w-section mx-auto">

        <ScrollReveal className="text-center mb-16">
          <div className="inline-flex items-center gap-2 mb-4">
            <div className="h-[2px] w-8 bg-[#22C55E]" />
            <span className="text-[#22C55E] text-xs font-bold tracking-[0.2em] uppercase">Career Skills</span>
            <div className="h-[2px] w-8 bg-[#22C55E]" />
          </div>
          <h2
            className="font-extrabold text-white leading-tight"
            style={{ fontSize: 'clamp(1.8rem, 3.5vw, 2.75rem)' }}
          >
            SKILLS YOU CAN START USING
            <br />
            <span className="text-gold-gradient">IN THE REAL WORLD</span>
          </h2>
          <p className="mt-3 text-slate-400 text-base max-w-xl mx-auto">
            Everything taught in this masterclass is immediately applicable — no waiting, no fluff.
          </p>
        </ScrollReveal>

        {/* Progression flow */}
        <div className="flex flex-col sm:flex-row items-center justify-center gap-2 sm:gap-0 mb-16">
          {progression.map((item, i) => (
            <div key={item.step} className="flex flex-col sm:flex-row items-center">
              <motion.div
                initial={{ opacity: 0, scale: 0.85 }}
                whileInView={{ opacity: 1, scale: 1 }}
                viewport={{ once: true }}
                transition={{ duration: 0.5, delay: i * 0.15 }}
                className="flex flex-col items-center text-center px-5 py-6 rounded-2xl card-glass border border-white/[0.06] min-w-[160px] hover:border-white/[0.14] transition-colors group"
                style={{ '--accent': item.color } as React.CSSProperties}
              >
                <div
                  className="w-12 h-12 rounded-full flex items-center justify-center mb-3 font-extrabold text-lg"
                  style={{ background: `${item.color}14`, border: `2px solid ${item.color}30`, color: item.color }}
                >
                  {String(i + 1).padStart(2, '0')}
                </div>
                <div className="font-extrabold tracking-widest text-sm" style={{ color: item.color }}>
                  {item.step}
                </div>
                <p className="text-slate-400 text-xs leading-relaxed mt-2 max-w-[130px]">
                  {item.desc}
                </p>
              </motion.div>

              {/* Arrow connector */}
              {i < progression.length - 1 && (
                <div className="flex items-center justify-center my-2 sm:my-0 sm:mx-1">
                  <ArrowRight size={16} className="text-slate-600 rotate-90 sm:rotate-0" />
                </div>
              )}
            </div>
          ))}
        </div>

        {/* Skill tags */}
        <ScrollReveal delay={0.2}>
          <div className="text-center">
            <p className="text-slate-500 text-xs font-bold tracking-[0.2em] uppercase mb-5">
              Skills Covered in This Masterclass
            </p>
            <div className="flex flex-wrap justify-center gap-3">
              {skillTags.map((tag, i) => (
                <motion.div
                  key={tag}
                  initial={{ opacity: 0, y: 10 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true }}
                  transition={{ delay: i * 0.06 }}
                  className="px-4 py-2 rounded-full text-sm font-semibold text-slate-300 border border-white/[0.1] bg-white/[0.03] hover:border-[#F5C842]/30 hover:text-[#F5C842] transition-all cursor-default"
                >
                  {tag}
                </motion.div>
              ))}
            </div>
          </div>
        </ScrollReveal>
      </div>
    </section>
  )
}
