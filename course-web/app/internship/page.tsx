'use client'

import { motion } from 'framer-motion'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { GlassCard, Reveal, SectionShell } from '@/components/premium-ui'
import { Camera, Network, Award, Wrench, CheckCircle2, Zap, Users, Globe } from 'lucide-react'
import Link from 'next/link'

const internshipModules = [
  {
    icon: Camera, color: '#0B4DBA', title: 'Live CCTV Installation',
    desc: 'Work on real-site camera installations at homes, offices, and commercial premises. Learn cable routing, camera positioning, and DVR/NVR configuration.',
    highlights: ['IP & Analog Camera Setup', 'DVR/NVR Configuration', 'Mobile App Integration', 'Real Client Sites'],
  },
  {
    icon: Network, color: '#FF6B00', title: 'Networking Practice',
    desc: 'Configure routers, switches, and set up full LAN and WiFi networks at actual project sites alongside experienced engineers.',
    highlights: ['Router & Switch Config', 'LAN Setup', 'WiFi Optimization', 'IP Addressing'],
  },
  {
    icon: Wrench, color: '#0B4DBA', title: 'Field Training & Service',
    desc: 'Accompany senior technicians on field calls, practice fault finding, maintenance, and client-facing professional communication.',
    highlights: ['Fault Diagnosis', 'Maintenance Rounds', 'Client Handling', 'Report Writing'],
  },
  {
    icon: Globe, color: '#FF6B00', title: 'Real Project Experience',
    desc: 'End-to-end project execution from survey to delivery. Build your own professional portfolio with documented real projects.',
    highlights: ['Project Planning', 'Site Survey', 'Full Execution', 'Portfolio Building'],
  },
]

const internshipStats = [
  { value: '1 Month', label: 'Duration', icon: Zap },
  { value: '100%', label: 'Hands-On', icon: Wrench },
  { value: 'Real', label: 'Project Sites', icon: Globe },
  { value: 'Expert', label: 'Mentors', icon: Users },
]

export default function InternshipPage() {
  return (
    <main className="min-h-screen overflow-x-hidden" style={{ background: '#F5F9FF' }}>
      <Header />

      {/* Hero */}
      <section className="relative min-h-[60vh] flex items-center overflow-hidden pt-40 md:pt-48 pb-16">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_30%_50%,rgba(11,77,186,0.15),transparent_55%),radial-gradient(ellipse_at_75%_30%,rgba(255,107,0,0.10),transparent_45%)]" />
        <div className="absolute inset-0 bg-[linear-gradient(rgba(11,77,186,0.04)_1px,transparent_1px),linear-gradient(90deg,rgba(11,77,186,0.04)_1px,transparent_1px)] bg-[size:60px_60px]" />
        <div className="container mx-auto px-6 lg:px-8 max-w-7xl relative z-10">
          <motion.div
            initial={{ opacity: 0, y: 40 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.8, ease: [0.22, 1, 0.36, 1] }}
            className="text-center max-w-4xl mx-auto"
          >
            <p className="text-accent font-bold tracking-widest text-sm uppercase mb-4">1 Month Program</p>
            <h1 className="text-5xl md:text-7xl font-black text-primary mb-6 leading-tight">
              Real World <span style={{ color: '#FF6B00' }}>Internship</span>
            </h1>
            <p className="text-xl text-foreground/60 max-w-2xl mx-auto mb-10">
              Bridge the gap between classroom and career with hands-on field training on actual installation projects.
            </p>
            <Link href="/admission">
              <motion.button
                whileHover={{ scale: 1.05, boxShadow: '0 0 40px rgba(255,107,0,0.45)' }}
                whileTap={{ scale: 0.97 }}
                className="px-10 py-5 rounded-2xl text-lg font-black text-white"
                style={{ background: 'linear-gradient(135deg,#FF6B00,#e65c00)' }}
              >
                Apply for Internship →
              </motion.button>
            </Link>
          </motion.div>
        </div>
      </section>

      {/* Stats */}
      <SectionShell>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-6 mb-20">
          {internshipStats.map(({ value, label, icon: Icon }, i) => (
            <Reveal key={label} delay={i * 0.1}>
              <motion.div whileHover={{ y: -8 }} className="glass-card rounded-3xl p-8 text-center">
                <div className="w-14 h-14 rounded-2xl bg-primary/10 flex items-center justify-center mx-auto mb-4">
                  <Icon size={26} className="text-primary" />
                </div>
                <p className="text-4xl font-black text-primary">{value}</p>
                <p className="text-foreground/60 font-semibold mt-1">{label}</p>
              </motion.div>
            </Reveal>
          ))}
        </div>

        {/* Modules */}
        <Reveal>
          <div className="text-center mb-14">
            <h2 className="text-4xl md:text-5xl font-black text-primary">What You Will Do</h2>
            <p className="mt-4 text-lg text-foreground/60">Every day is hands-on — no theory, pure field experience</p>
          </div>
        </Reveal>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
          {internshipModules.map(({ icon: Icon, color, title, desc, highlights }, i) => (
            <GlassCard key={title} delay={i * 0.12}>
              <div className="p-8 space-y-5">
                <motion.div whileHover={{ rotate: 15 }} className="w-16 h-16 rounded-2xl flex items-center justify-center" style={{ background: `${color}15`, border: `1.5px solid ${color}30` }}>
                  <Icon size={30} style={{ color }} />
                </motion.div>
                <h3 className="text-2xl font-black text-primary">{title}</h3>
                <p className="text-foreground/60">{desc}</p>
                <div className="flex flex-wrap gap-2">
                  {highlights.map((h) => (
                    <span key={h} className="flex items-center gap-1.5 text-xs font-bold px-3 py-1.5 rounded-full" style={{ background: `${color}10`, color }}>
                      <CheckCircle2 size={11} /> {h}
                    </span>
                  ))}
                </div>
              </div>
            </GlassCard>
          ))}
        </div>
      </SectionShell>

      {/* Certificate */}
      <SectionShell className="bg-[linear-gradient(135deg,#061f4f,#0B4DBA)]">
        <Reveal>
          <div className="text-center">
            <motion.div
              whileHover={{ scale: 1.05 }}
              className="inline-block mb-8"
            >
              <div className="w-24 h-24 rounded-3xl bg-accent/20 border-2 border-accent/40 flex items-center justify-center mx-auto">
                <Award size={48} className="text-accent" />
              </div>
            </motion.div>
            <h2 className="text-4xl md:text-5xl font-black text-white mb-6">Internship Certificate</h2>
            <p className="text-xl text-white/70 max-w-2xl mx-auto mb-10">
              Upon successful completion of your internship, you'll receive an official TECHBES Internship Certificate recognized by industry employers.
            </p>
            <div className="flex flex-wrap justify-center gap-4">
              {['Industry Recognized', 'Digitally Verified', 'LinkedIn Ready', 'Project Listed'].map((item) => (
                <span key={item} className="flex items-center gap-2 text-sm font-bold px-5 py-3 rounded-2xl bg-white/10 text-white border border-white/20">
                  <CheckCircle2 size={14} className="text-accent" /> {item}
                </span>
              ))}
            </div>
          </div>
        </Reveal>
      </SectionShell>

      <Footer />
    </main>
  )
}
