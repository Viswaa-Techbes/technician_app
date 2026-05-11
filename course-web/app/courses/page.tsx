'use client'

import { motion } from 'framer-motion'
import Link from 'next/link'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { GlassCard, Reveal, SectionShell } from '@/components/premium-ui'
import {
  Camera, Network, Cpu, Wrench, BriefcaseBusiness,
  CheckCircle2, ChevronRight, Clock, Users, Award
} from 'lucide-react'

const modules = [
  {
    icon: Camera, color: '#0B4DBA',
    title: 'CCTV Technology',
    slug: 'cctv-technology',
    badge: 'Core Module',
    duration: '3 Weeks',
    topics: ['CCTV Basics', 'IP & Analog Cameras', 'Installation & Wiring', 'DVR/NVR Setup', 'Mobile Viewing', 'Troubleshooting'],
    desc: 'Master the full stack of CCTV systems — from basic analog cameras to advanced IP camera networks with remote monitoring.',
  },
  {
    icon: Network, color: '#FF6B00',
    title: 'Networking',
    slug: 'networking',
    badge: 'Core Module',
    duration: '2 Weeks',
    topics: ['Networking Basics', 'IP Addressing', 'Router Configuration', 'LAN & WiFi Setup', 'Switch Configuration'],
    desc: 'Learn to design and configure enterprise-grade networks including routers, switches, LAN infrastructure and WiFi systems.',
  },
  {
    icon: Cpu, color: '#0B4DBA',
    title: 'Computer Hardware',
    slug: 'computer-hardware',
    badge: 'Core Module',
    duration: '2 Weeks',
    topics: ['Desktop Assembling', 'Laptop Repair Basics', 'OS Installation', 'Software Installation', 'Virus Removal', 'System Maintenance'],
    desc: 'Hands-on training in assembling, repairing, and maintaining desktop and laptop systems from the ground up.',
  },
  {
    icon: Wrench, color: '#FF6B00',
    title: 'Practical Training',
    badge: 'Field Module',
    duration: '3 Weeks',
    topics: ['Real Site Installations', 'Configuration Practice', 'Fault Finding', 'Client Handling', 'Maintenance Work'],
    desc: 'Real-world field experience. You\'ll work on actual installations, diagnose faults, and handle client communication professionally.',
  },
  {
    icon: BriefcaseBusiness, color: '#0B4DBA',
    title: 'Business Skills',
    badge: 'Career Module',
    duration: '1 Week',
    topics: ['How to Get Clients', 'Pricing & Quotation', 'Sales & Communication', 'Freelancing Tips', 'Start Your Own Business'],
    desc: 'Learn the business side of the trade — from winning your first client to launching your own CCTV installation business.',
  },
]

const highlights = [
  { icon: Clock, label: '2 Months Training', sub: '+ 1 Month Internship' },
  { icon: Users, label: 'Small Batch Size', sub: 'Personalised Attention' },
  { icon: Wrench, label: '100% Practical', sub: 'No Boring Theory Only' },
  { icon: Award, label: 'Certificate', sub: 'Industry Recognized' },
]

export default function CoursesPage() {
  return (
    <main className="min-h-screen overflow-x-hidden" style={{ background: '#F5F9FF' }}>
      <Header />

      {/* Hero */}
      <section className="relative pt-40 md:pt-48 pb-16 overflow-hidden">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_30%_50%,rgba(11,77,186,0.13),transparent_55%),radial-gradient(ellipse_at_75%_20%,rgba(255,107,0,0.09),transparent_45%)]" />
        <div className="absolute inset-0 bg-[linear-gradient(rgba(11,77,186,0.04)_1px,transparent_1px),linear-gradient(90deg,rgba(11,77,186,0.04)_1px,transparent_1px)] bg-[size:60px_60px]" />
        <div className="container mx-auto px-6 lg:px-8 max-w-7xl relative z-10 text-center">
          <motion.div initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7 }}>
            <p className="text-accent font-bold tracking-widest text-sm uppercase mb-4">5 Comprehensive Modules</p>
            <h1 className="text-5xl md:text-7xl font-black text-primary mb-4 leading-tight">
              Our <span style={{ color: '#FF6B00' }}>Course</span> Program
            </h1>
            <p className="text-xl text-foreground/60 max-w-2xl mx-auto mb-10">
              A job-ready curriculum covering CCTV installation, networking, computer hardware, field training, and business skills.
            </p>
            <Link href="/admission">
              <motion.button
                whileHover={{ scale: 1.05, boxShadow: '0 0 40px rgba(255,107,0,0.45)' }}
                whileTap={{ scale: 0.97 }}
                className="px-10 py-5 rounded-2xl text-lg font-black text-white inline-flex items-center gap-2"
                style={{ background: 'linear-gradient(135deg,#FF6B00,#e65c00)' }}
              >
                Enroll Now <ChevronRight size={20} />
              </motion.button>
            </Link>
          </motion.div>
        </div>
      </section>

      {/* Highlights */}
      <SectionShell>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-5 mb-20">
          {highlights.map(({ icon: Icon, label, sub }, i) => (
            <Reveal key={label} delay={i * 0.1}>
              <motion.div whileHover={{ y: -6 }} className="glass-card rounded-2xl p-6 text-center">
                <div className="w-12 h-12 rounded-xl bg-primary/10 flex items-center justify-center mx-auto mb-3">
                  <Icon size={22} className="text-primary" />
                </div>
                <p className="font-black text-primary">{label}</p>
                <p className="text-sm text-foreground/50 mt-1">{sub}</p>
              </motion.div>
            </Reveal>
          ))}
        </div>

        {/* Module Cards */}
        <Reveal>
          <div className="text-center mb-14">
            <h2 className="text-4xl md:text-5xl font-black text-primary">Course Modules</h2>
            <p className="mt-4 text-lg text-foreground/60">Everything you need to become a job-ready CCTV & IT professional</p>
          </div>
        </Reveal>

        <div className="space-y-8">
          {modules.map(({ icon: Icon, color, title, badge, duration, topics, desc }, i) => (
            <GlassCard key={title} delay={i * 0.1}>
              <div className="p-8">
                <div className="flex flex-col md:flex-row gap-8">
                  {/* Left */}
                  <div className="flex-shrink-0">
                    <motion.div
                      whileHover={{ rotate: 10 }}
                      className="w-20 h-20 rounded-2xl flex items-center justify-center"
                      style={{ background: `${color}12`, border: `2px solid ${color}25` }}
                    >
                      <Icon size={38} style={{ color }} />
                    </motion.div>
                  </div>
                  {/* Content */}
                  <div className="flex-1">
                    <div className="flex flex-wrap items-center gap-3 mb-3">
                      <h3 className="text-2xl font-black text-primary">{title}</h3>
                      <span className="text-xs font-bold px-3 py-1 rounded-full" style={{ background: `${color}12`, color }}>{badge}</span>
                      <span className="text-xs font-semibold text-foreground/50 flex items-center gap-1">
                        <Clock size={11} /> {duration}
                      </span>
                    </div>
                    <p className="text-foreground/60 mb-5">{desc}</p>
                    <div className="flex flex-wrap gap-2 mb-6">
                      {topics.map((t) => (
                        <span key={t} className="flex items-center gap-1.5 text-sm font-semibold px-3 py-1.5 rounded-xl bg-white/80 border border-white/60 text-foreground/70">
                          <CheckCircle2 size={12} style={{ color }} /> {t}
                        </span>
                      ))}
                    </div>
                    {slug && (
                      <Link href={`/courses/${slug}`} className="inline-flex items-center gap-2 font-bold text-sm transition-colors hover:opacity-80" style={{ color }}>
                        View Full Details <ChevronRight size={16} />
                      </Link>
                    )}
                  </div>
                </div>
              </div>
              <div className="absolute inset-0 rounded-[inherit] opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none" style={{ boxShadow: `inset 0 0 0 1.5px ${color}40` }} />
            </GlassCard>
          ))}
        </div>

        {/* CTA */}
        <Reveal delay={0.3}>
          <div className="mt-16 text-center glass-card rounded-3xl p-10">
            <h3 className="text-3xl font-black text-primary mb-3">Ready to Start Learning?</h3>
            <p className="text-foreground/60 mb-8 text-lg">Join the next batch and kickstart your CCTV & IT career in just 3 months.</p>
            <div className="flex flex-wrap justify-center gap-4">
              <Link href="/admission">
                <motion.button
                  whileHover={{ scale: 1.05, boxShadow: '0 0 40px rgba(255,107,0,0.45)' }}
                  whileTap={{ scale: 0.97 }}
                  className="px-8 py-4 rounded-2xl text-white font-black text-base"
                  style={{ background: 'linear-gradient(135deg,#FF6B00,#e65c00)' }}
                >
                  Apply for Admission
                </motion.button>
              </Link>
              <Link href="/enquiry">
                <motion.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.97 }}
                  className="px-8 py-4 rounded-2xl text-primary font-black text-base border-2 border-primary/25 glass-card"
                >
                  Ask a Question
                </motion.button>
              </Link>
            </div>
          </div>
        </Reveal>
      </SectionShell>

      <Footer />
    </main>
  )
}
