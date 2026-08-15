"use client"
import { motion } from 'framer-motion'
import { CheckCircle2, Video, MessageSquare, BookOpen, Layers } from 'lucide-react'
import ScrollReveal from '../ui/ScrollReveal'

const cardFeatures = [
  { icon: Video,         text: 'Live Session'            },
  { icon: Layers,        text: 'Practical Demonstration' },
  { icon: MessageSquare, text: 'Live Doubt Clearance'    },
  { icon: BookOpen,      text: 'Real CCTV Concepts'      },
]

export default function MasterclassOverview() {
  return (
    <section id="overview" className="bg-[#050912] section-pad">
      <div className="max-w-section mx-auto">
        <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">

          {/* LEFT — Text */}
          <ScrollReveal direction="left">
            <div>
              <div className="inline-flex items-center gap-2 mb-5">
                <div className="h-[2px] w-8 bg-[#F5C842]" />
                <span className="text-[#F5C842] text-xs font-bold tracking-[0.2em] uppercase">
                  About the Masterclass
                </span>
              </div>

              <h2 className="font-extrabold text-white leading-tight" style={{ fontSize: 'clamp(1.8rem, 3.5vw, 2.75rem)' }}>
                Learn CCTV.<br />
                Understand Networking.<br />
                <span className="text-gold-gradient">Build Real-World Skills.</span>
              </h2>

              <p className="mt-6 text-slate-400 leading-relaxed text-base">
                The TECHBES CCTV Masterclass is a focused, live, hands-on training session
                designed for anyone who wants to understand and work with modern CCTV security
                systems. From camera fundamentals to real-time NVR configuration and mobile
                remote viewing — every minute is practical.
              </p>

              <p className="mt-4 text-slate-400 leading-relaxed text-base">
                No prior experience is required. If you can follow instructions and use a
                smartphone or laptop, you can take this masterclass.
              </p>

              <div className="mt-8 grid grid-cols-1 sm:grid-cols-2 gap-3">
                {[
                  'CCTV Installation Basics',
                  'IP Camera Configuration',
                  'NVR Setup & Management',
                  'Remote Mobile Viewing',
                  'PoE Networking',
                  'Live Troubleshooting',
                ].map(skill => (
                  <div key={skill} className="flex items-center gap-2.5 text-sm text-slate-300">
                    <CheckCircle2 size={15} className="text-[#F5C842] flex-shrink-0" />
                    {skill}
                  </div>
                ))}
              </div>
            </div>
          </ScrollReveal>

          {/* RIGHT — Card */}
          <ScrollReveal direction="right" delay={0.15}>
            <div className="relative">
              {/* Glow background */}
              <div
                className="absolute -inset-4 rounded-3xl pointer-events-none"
                style={{ background: 'radial-gradient(ellipse at center, rgba(245,200,66,0.06) 0%, transparent 70%)' }}
              />

              <div className="relative card-glass rounded-2xl p-8 card-gold-border glow-gold">
                {/* Header */}
                <div className="text-center pb-6 border-b border-white/[0.07]">
                  <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-[#F5C842]/10 border border-[#F5C842]/20 mb-4">
                    <Video size={28} className="text-[#F5C842]" />
                  </div>
                  <div
                    className="font-extrabold text-[#F5C842] leading-tight"
                    style={{ fontSize: 'clamp(2.5rem, 4vw, 3.5rem)' }}
                  >
                    2 HOURS
                  </div>
                  <div className="text-white font-bold text-lg tracking-widest mt-1 uppercase">
                    Live Masterclass
                  </div>
                  <div className="text-slate-500 text-sm mt-1">
                    Interactive · Practical · Doubt Clearance
                  </div>
                </div>

                {/* Feature list */}
                <div className="mt-6 space-y-4">
                  {cardFeatures.map(({ icon: Icon, text }) => (
                    <div key={text} className="flex items-center gap-4">
                      <div className="w-9 h-9 rounded-xl bg-[#101A2D] border border-white/[0.07] flex items-center justify-center flex-shrink-0">
                        <Icon size={16} className="text-[#F5C842]" />
                      </div>
                      <span className="text-slate-200 font-medium text-sm">{text}</span>
                    </div>
                  ))}
                </div>

                {/* Price badge */}
                <div className="mt-8 bg-[#E53935]/10 border border-[#E53935]/25 rounded-xl p-4 text-center">
                  <div className="text-slate-400 text-xs font-semibold tracking-widest uppercase mb-1">
                    One-Time Registration
                  </div>
                  <div className="flex items-baseline justify-center gap-3">
                    <span className="text-slate-500 line-through text-sm">₹999</span>
                    <span className="text-[#F5C842] font-extrabold text-3xl">₹499</span>
                  </div>
                </div>
              </div>
            </div>
          </ScrollReveal>
        </div>
      </div>
    </section>
  )
}
