"use client"
import { motion } from 'framer-motion'
import { GraduationCap, Wrench, Zap, Network, UserCheck, Store } from 'lucide-react'
import ScrollReveal from '../ui/ScrollReveal'

const audience = [
  { icon: GraduationCap, label: 'ITI / Diploma Students',       desc: 'Build job-ready skills right after your course.' },
  { icon: Wrench,         label: 'CCTV Technicians',             desc: 'Add IP camera expertise to your skill set.' },
  { icon: Zap,            label: 'Electricians',                 desc: 'Expand into the security installation market.' },
  { icon: Network,        label: 'Networking Technicians',       desc: 'Apply your networking knowledge to CCTV.' },
  { icon: UserCheck,      label: 'Job Seekers & Freshers',       desc: 'Start your technology career with practical skills.' },
  { icon: Store,          label: 'Aspiring Business Owners',     desc: 'Learn to offer CCTV installation services.' },
]

export default function AudienceSection() {
  return (
    <section id="audience" className="bg-[#0A1020] section-pad">
      <div className="max-w-section mx-auto">

        {/* Heading */}
        <ScrollReveal className="text-center mb-14">
          <div className="inline-flex items-center gap-2 mb-4">
            <div className="h-[2px] w-8 bg-[#E53935]" />
            <span className="text-[#E53935] text-xs font-bold tracking-[0.2em] uppercase">Who Is This For</span>
            <div className="h-[2px] w-8 bg-[#E53935]" />
          </div>
          <h2
            className="font-extrabold text-white leading-tight"
            style={{ fontSize: 'clamp(1.8rem, 3.5vw, 2.75rem)' }}
          >
            WHO SHOULD JOIN?
          </h2>
          <p className="mt-3 text-slate-400 text-base max-w-xl mx-auto">
            This masterclass is designed for a wide range of learners — anyone ready to build practical CCTV skills.
          </p>
        </ScrollReveal>

        {/* Cards */}
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {audience.map((item, i) => {
            const Icon = item.icon
            return (
              <motion.div
                key={item.label}
                initial={{ opacity: 0, y: 28 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-60px' }}
                transition={{ duration: 0.5, delay: i * 0.08 }}
                whileHover={{ y: -5, transition: { duration: 0.18 } }}
                className="group card-glass rounded-2xl p-6 border border-white/[0.06] hover:border-[#E53935]/30 transition-all duration-300 cursor-default"
              >
                <div className="w-12 h-12 rounded-2xl bg-[#E53935]/10 border border-[#E53935]/20 flex items-center justify-center mb-4 group-hover:bg-[#E53935]/18 transition-colors duration-300">
                  <Icon size={22} className="text-[#E53935]" />
                </div>
                <h3 className="font-extrabold text-white text-sm tracking-wide uppercase mb-2">
                  {item.label}
                </h3>
                <p className="text-slate-400 text-sm leading-relaxed">{item.desc}</p>
              </motion.div>
            )
          })}
        </div>

        {/* Big statement */}
        <ScrollReveal delay={0.3} className="mt-14">
          <div
            className="rounded-2xl p-8 text-center relative overflow-hidden"
            style={{ background: 'linear-gradient(135deg, rgba(245,200,66,0.06) 0%, rgba(229,57,53,0.04) 100%)', border: '1px solid rgba(245,200,66,0.15)' }}
          >
            <div className="absolute inset-0 tech-grid-bg opacity-50 pointer-events-none" />
            <p
              className="relative font-extrabold text-white leading-tight"
              style={{ fontSize: 'clamp(1.4rem, 3vw, 2rem)' }}
            >
              NO PRIOR EXPERIENCE REQUIRED.
            </p>
            <p className="relative mt-2 text-slate-400 text-base">
              If you can use a smartphone or laptop, you can join this masterclass.
            </p>
          </div>
        </ScrollReveal>
      </div>
    </section>
  )
}
