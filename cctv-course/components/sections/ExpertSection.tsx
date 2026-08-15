"use client"
import { motion } from 'framer-motion'
import { CheckCircle2, Briefcase, Star, Users } from 'lucide-react'
import ScrollReveal from '../ui/ScrollReveal'

const highlights = [
  'Practical Industry Knowledge',
  'Real-World Project Experience',
  'Live Step-by-Step Demonstration',
  'Open Q&A & Doubt Clearance',
  'Hands-on CCTV & NVR Expertise',
]

const stats = [
  { value: '10+',   label: 'Years Experience' },
  { value: '500+',  label: 'Systems Installed' },
  { value: '1000+', label: 'Students Trained'  },
]

export default function ExpertSection() {
  return (
    <section className="bg-[#050912] section-pad overflow-hidden">
      <div className="max-w-section mx-auto">

        {/* Section label */}
        <ScrollReveal className="text-center mb-14">
          <div className="inline-flex items-center gap-2 mb-4">
            <div className="h-[2px] w-8 bg-[#F5C842]" />
            <span className="text-[#F5C842] text-xs font-bold tracking-[0.2em] uppercase">
              Your Instructor
            </span>
            <div className="h-[2px] w-8 bg-[#F5C842]" />
          </div>
          <h2
            className="font-extrabold text-white leading-tight"
            style={{ fontSize: 'clamp(1.8rem, 3.5vw, 2.75rem)' }}
          >
            LEARN FROM INDUSTRY EXPERTS
          </h2>
          <p className="mt-3 text-slate-400 text-base max-w-xl mx-auto">
            Learn from people who work with real CCTV systems — not just theory.
          </p>
        </ScrollReveal>

        <div className="grid lg:grid-cols-2 gap-12 lg:gap-16 items-center">

          {/* LEFT — Expert card */}
          <ScrollReveal direction="left">
            <div className="relative">
              <div
                className="absolute -inset-4 rounded-3xl pointer-events-none"
                style={{ background: 'radial-gradient(ellipse at center, rgba(245,200,66,0.07) 0%, transparent 70%)' }}
              />

              <div className="relative card-glass rounded-3xl p-8 card-gold-border overflow-hidden">
                {/* Header */}
                <div className="flex items-start gap-5 mb-8">
                  {/* Avatar placeholder */}
                  <div className="relative flex-shrink-0">
                    <div
                      className="w-20 h-20 rounded-2xl flex items-center justify-center font-extrabold text-2xl text-[#F5C842]"
                      style={{ background: 'rgba(245,200,66,0.1)', border: '2px solid rgba(245,200,66,0.3)' }}
                    >
                      TB
                    </div>
                    <div className="absolute -bottom-1 -right-1 w-6 h-6 rounded-full bg-green-500 border-2 border-[#0A1020] flex items-center justify-center">
                      <div className="w-2 h-2 rounded-full bg-white" />
                    </div>
                  </div>

                  <div>
                    <div className="flex items-center gap-2 mb-1">
                      <h3 className="font-extrabold text-white text-xl">TECHBES Expert</h3>
                    </div>
                    <div className="text-[#F5C842] text-sm font-semibold">CCTV & IP Networking Specialist</div>
                    <div className="flex items-center gap-1.5 mt-2">
                      {[...Array(5)].map((_, i) => (
                        <Star key={i} size={12} className="text-[#F5C842] fill-[#F5C842]" />
                      ))}
                      <span className="text-slate-400 text-xs ml-1">Verified Expert</span>
                    </div>
                  </div>
                </div>

                {/* Stats */}
                <div className="grid grid-cols-3 gap-4 mb-8 p-4 rounded-xl bg-white/[0.03] border border-white/[0.05]">
                  {stats.map(stat => (
                    <div key={stat.label} className="text-center">
                      <div className="text-[#F5C842] font-extrabold text-xl">{stat.value}</div>
                      <div className="text-slate-400 text-xs mt-0.5">{stat.label}</div>
                    </div>
                  ))}
                </div>

                {/* Highlights */}
                <div className="space-y-3">
                  {highlights.map(h => (
                    <div key={h} className="flex items-center gap-3">
                      <div className="w-7 h-7 rounded-lg bg-[#F5C842]/10 flex items-center justify-center flex-shrink-0">
                        <CheckCircle2 size={14} className="text-[#F5C842]" />
                      </div>
                      <span className="text-slate-300 text-sm font-medium">{h}</span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </ScrollReveal>

          {/* RIGHT — Quote / description */}
          <ScrollReveal direction="right" delay={0.15}>
            <div className="space-y-8">
              <div className="relative pl-6 border-l-2 border-[#F5C842]">
                <p className="text-slate-300 text-lg leading-relaxed italic">
                  "Real skills come from real practice. In this masterclass, every concept is
                  demonstrated live — from the first cable connection to remote mobile viewing."
                </p>
                <div className="mt-3 text-[#F5C842] font-semibold text-sm">— TECHBES Expert Instructor</div>
              </div>

              <div className="space-y-4">
                {[
                  {
                    icon: Briefcase,
                    title: 'Industry Background',
                    desc: 'Over 10 years designing and installing CCTV, access control and networking systems for real clients.',
                  },
                  {
                    icon: Users,
                    title: 'Training Experience',
                    desc: 'Trained hundreds of technicians, freshers and entrepreneurs to work confidently with CCTV systems.',
                  },
                ].map(({ icon: Icon, title, desc }) => (
                  <div key={title} className="flex gap-4">
                    <div className="w-10 h-10 rounded-xl bg-[#101A2D] border border-white/[0.07] flex items-center justify-center flex-shrink-0 mt-0.5">
                      <Icon size={18} className="text-[#F5C842]" />
                    </div>
                    <div>
                      <div className="font-bold text-white text-sm mb-1">{title}</div>
                      <p className="text-slate-400 text-sm leading-relaxed">{desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </ScrollReveal>
        </div>
      </div>
    </section>
  )
}
