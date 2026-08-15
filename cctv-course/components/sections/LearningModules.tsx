"use client"
import { motion } from 'framer-motion'
import { Camera, Network, Settings, Smartphone, AlertTriangle, Briefcase } from 'lucide-react'
import ScrollReveal from '../ui/ScrollReveal'

const modules = [
  {
    number: '01',
    icon: Camera,
    title: 'CCTV Basics',
    color: '#F5C842',
    points: ['Analog vs IP Cameras', 'Camera Types & Lenses', 'DVR vs NVR Systems'],
  },
  {
    number: '02',
    icon: Network,
    title: 'IP CCTV & PoE',
    color: '#0EA5E9',
    points: ['IP Camera Setup', 'PoE Switch Configuration', 'Basic Networking'],
  },
  {
    number: '03',
    icon: Settings,
    title: 'Live Configuration',
    color: '#A855F7',
    points: ['IP Address Setup', 'NVR Configuration', 'Camera Live Feed'],
  },
  {
    number: '04',
    icon: Smartphone,
    title: 'Mobile Viewing',
    color: '#22C55E',
    points: ['App Setup & DDNS', 'Remote Access Config', 'Real-time Monitoring'],
  },
  {
    number: '05',
    icon: AlertTriangle,
    title: 'Troubleshooting',
    color: '#F97316',
    points: ['Common Camera Issues', 'Network Diagnostics', 'NVR Fault Resolution'],
  },
  {
    number: '06',
    icon: Briefcase,
    title: 'Real Project',
    color: '#E53935',
    points: ['Site Planning', 'Cable & Hardware', 'Full System Commissioning'],
  },
]

export default function LearningModules() {
  return (
    <section id="learn" className="bg-[#0A1020] section-pad">
      <div className="max-w-section mx-auto">

        {/* Heading */}
        <ScrollReveal className="text-center mb-14">
          <div className="inline-flex items-center gap-2 mb-4">
            <div className="h-[2px] w-8 bg-[#F5C842]" />
            <span className="text-[#F5C842] text-xs font-bold tracking-[0.2em] uppercase">Curriculum</span>
            <div className="h-[2px] w-8 bg-[#F5C842]" />
          </div>
          <h2
            className="font-extrabold text-white leading-tight"
            style={{ fontSize: 'clamp(1.8rem, 3.5vw, 2.75rem)' }}
          >
            WHAT YOU'LL LEARN
          </h2>
          <p className="mt-3 text-slate-400 text-base max-w-xl mx-auto">
            From CCTV fundamentals to real-world IP camera configuration and live system walkthrough.
          </p>
        </ScrollReveal>

        {/* 6-card grid */}
        <div className="grid sm:grid-cols-2 lg:grid-cols-3 gap-5">
          {modules.map((mod, i) => {
            const Icon = mod.icon
            return (
              <motion.div
                key={mod.title}
                initial={{ opacity: 0, y: 32 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true, margin: '-60px' }}
                transition={{ duration: 0.55, delay: i * 0.08 }}
                whileHover={{ y: -6, transition: { duration: 0.2 } }}
                className="group relative card-glass rounded-2xl p-6 border border-white/[0.06] hover:border-white/[0.14] transition-all duration-300 cursor-default overflow-hidden"
              >
                {/* Hover glow */}
                <div
                  className="absolute inset-0 rounded-2xl opacity-0 group-hover:opacity-100 transition-opacity duration-300 pointer-events-none"
                  style={{ background: `radial-gradient(ellipse at top left, ${mod.color}08 0%, transparent 70%)` }}
                />

                {/* Number + Icon row */}
                <div className="flex items-start justify-between mb-5">
                  <span
                    className="font-extrabold text-5xl leading-none select-none"
                    style={{ color: `${mod.color}18` }}
                  >
                    {mod.number}
                  </span>
                  <div
                    className="w-11 h-11 rounded-xl flex items-center justify-center flex-shrink-0"
                    style={{ background: `${mod.color}14`, border: `1px solid ${mod.color}25` }}
                  >
                    <Icon size={20} style={{ color: mod.color }} />
                  </div>
                </div>

                {/* Title */}
                <h3
                  className="font-extrabold text-white text-base tracking-wide mb-3 uppercase"
                  style={{ letterSpacing: '0.05em' }}
                >
                  {mod.title}
                </h3>

                {/* Points */}
                <ul className="space-y-1.5">
                  {mod.points.map(p => (
                    <li key={p} className="flex items-start gap-2 text-sm text-slate-400">
                      <span
                        className="w-1.5 h-1.5 rounded-full mt-1.5 flex-shrink-0"
                        style={{ background: mod.color }}
                      />
                      {p}
                    </li>
                  ))}
                </ul>

                {/* Bottom accent line */}
                <div
                  className="absolute bottom-0 left-0 right-0 h-[2px] opacity-0 group-hover:opacity-100 transition-opacity duration-300"
                  style={{ background: `linear-gradient(to right, transparent, ${mod.color}60, transparent)` }}
                />
              </motion.div>
            )
          })}
        </div>
      </div>
    </section>
  )
}
