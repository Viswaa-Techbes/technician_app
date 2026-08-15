"use client"
import Image from 'next/image'
import { motion } from 'framer-motion'
import ScrollReveal from '../ui/ScrollReveal'

const steps = [
  { num: '01', title: 'Connect the Camera',          desc: 'Physical cabling, PoE connection and power.' },
  { num: '02', title: 'Configure the Network',        desc: 'Assign IP addresses, subnet and gateway.' },
  { num: '03', title: 'Add Camera to NVR',            desc: 'Auto-search, manual add and channel binding.' },
  { num: '04', title: 'Enable Mobile Viewing',         desc: 'DDNS / P2P setup, app config, remote access.' },
  { num: '05', title: 'Troubleshoot Common Issues',   desc: 'Offline cameras, no image, network errors.' },
]

export default function PracticalSection() {
  return (
    <section id="practical" className="bg-[#101A2D] section-pad overflow-hidden">
      <div className="max-w-section mx-auto">

        {/* Heading */}
        <ScrollReveal className="text-center mb-14">
          <div className="inline-flex items-center gap-2 mb-4">
            <div className="h-[2px] w-8 bg-[#E53935]" />
            <span className="text-[#E53935] text-xs font-bold tracking-[0.2em] uppercase">Live Demo</span>
            <div className="h-[2px] w-8 bg-[#E53935]" />
          </div>
          <h2
            className="font-extrabold text-white leading-tight"
            style={{ fontSize: 'clamp(1.8rem, 3.5vw, 2.75rem)' }}
          >
            NOT JUST THEORY.
            <br />
            <span className="text-gold-gradient">SEE HOW A REAL CCTV SYSTEM WORKS.</span>
          </h2>
          <p className="mt-4 text-slate-400 text-base max-w-xl mx-auto">
            Watch live as our expert builds and configures a complete CCTV system from scratch —
            every single step, in real time.
          </p>
        </ScrollReveal>

        <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">

          {/* LEFT — Image */}
          <ScrollReveal direction="left">
            <div className="relative">
              <div
                className="absolute -inset-6 rounded-3xl pointer-events-none"
                style={{ background: 'radial-gradient(ellipse at center, rgba(14,165,233,0.08) 0%, transparent 70%)' }}
              />
              <div className="relative rounded-2xl overflow-hidden border border-white/[0.07]">
                <Image
                  src="/images/poster-preview.jpg"
                  alt="Live CCTV practical demonstration"
                  width={580}
                  height={420}
                  className="w-full h-auto object-cover"
                />
                {/* Overlay with label */}
                <div className="absolute inset-0 bg-gradient-to-t from-[#101A2D]/90 via-transparent to-transparent" />
                <div className="absolute bottom-5 left-5 right-5">
                  <div className="inline-flex items-center gap-2 bg-[#E53935] text-white text-xs font-extrabold px-4 py-2 rounded-full tracking-widest uppercase">
                    <span className="w-2 h-2 rounded-full bg-white animate-pulse inline-block" />
                    Live Practical Demo
                  </div>
                </div>
              </div>
            </div>
          </ScrollReveal>

          {/* RIGHT — Steps */}
          <ScrollReveal direction="right" delay={0.15}>
            <div className="space-y-1">
              {steps.map((step, i) => (
                <motion.div
                  key={step.num}
                  initial={{ opacity: 0, x: 24 }}
                  whileInView={{ opacity: 1, x: 0 }}
                  viewport={{ once: true, margin: '-40px' }}
                  transition={{ duration: 0.5, delay: i * 0.1 }}
                  className="group flex gap-5 p-5 rounded-xl hover:bg-white/[0.03] transition-colors cursor-default"
                >
                  {/* Step number circle + connecting line */}
                  <div className="flex flex-col items-center">
                    <div
                      className="w-10 h-10 rounded-full flex items-center justify-center flex-shrink-0 font-extrabold text-sm transition-all duration-200 group-hover:scale-110"
                      style={{
                        background: 'rgba(14,165,233,0.12)',
                        border: '1px solid rgba(14,165,233,0.3)',
                        color: '#0EA5E9',
                      }}
                    >
                      {step.num}
                    </div>
                    {i < steps.length - 1 && (
                      <div className="w-[1px] flex-1 mt-2 bg-gradient-to-b from-[#0EA5E9]/30 to-transparent min-h-[24px]" />
                    )}
                  </div>

                  {/* Content */}
                  <div className="pb-4">
                    <h3 className="font-bold text-white text-base mb-1 group-hover:text-[#F5C842] transition-colors">
                      {step.title}
                    </h3>
                    <p className="text-slate-400 text-sm leading-relaxed">{step.desc}</p>
                  </div>
                </motion.div>
              ))}
            </div>
          </ScrollReveal>
        </div>
      </div>
    </section>
  )
}
