'use client'

import { motion, useScroll, useTransform } from 'framer-motion'
import { useRef, useState } from 'react'
import Link from 'next/link'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { CinematicVideoFrame, GlassCard, Reveal, SectionShell } from '@/components/premium-ui'
import {
  Camera, Network, Cpu, Wrench, BriefcaseBusiness,
  ShieldCheck, BadgeCheck, Sparkles, Award, Users,
  ChevronRight, Star, CheckCircle2, Zap, TrendingUp, Globe
} from 'lucide-react'

/* ─────────────── DATA ─────────────── */
const features = [
  { icon: ShieldCheck, label: '100% Practical Training', color: '#0B4DBA' },
  { icon: Sparkles, label: 'Real Project Internship', color: '#FF6B00' },
  { icon: Zap, label: 'Job Assistance', color: '#0B4DBA' },
  { icon: Users, label: 'Industry Expert Trainers', color: '#FF6B00' },
  { icon: BadgeCheck, label: 'Certificate of Completion', color: '#0B4DBA' },
]

const modules = [
  {
    icon: Camera, color: '#0B4DBA', title: 'CCTV Technology',
    topics: ['CCTV Basics', 'IP & Analog Cameras', 'Installation & Wiring', 'DVR/NVR Setup', 'Mobile Viewing', 'Troubleshooting'],
  },
  {
    icon: Network, color: '#FF6B00', title: 'Networking',
    topics: ['Networking Basics', 'IP Addressing', 'Router Configuration', 'LAN & WiFi Setup', 'Switch Configuration'],
  },
  {
    icon: Cpu, color: '#0B4DBA', title: 'Computer Hardware',
    topics: ['Desktop Assembling', 'Laptop Repair Basics', 'OS Installation', 'Software Installation', 'Virus Removal', 'System Maintenance'],
  },
  {
    icon: Wrench, color: '#FF6B00', title: 'Practical Training',
    topics: ['Real Site Installations', 'Configuration Practice', 'Fault Finding', 'Client Handling', 'Maintenance Work'],
  },
  {
    icon: BriefcaseBusiness, color: '#0B4DBA', title: 'Business Skills',
    topics: ['How to Get Clients', 'Pricing & Quotation', 'Sales & Communication', 'Freelancing Tips', 'Start Your Own Business'],
  },
]

const careers = [
  { icon: Camera, role: 'CCTV Technician', desc: 'Install & maintain surveillance systems', salary: '₹15K–₹30K/mo' },
  { icon: Network, role: 'Network Technician', desc: 'Configure routers, switches & LAN', salary: '₹18K–₹35K/mo' },
  { icon: Cpu, role: 'IT Support Executive', desc: 'Hardware & software troubleshooting', salary: '₹15K–₹28K/mo' },
  { icon: Wrench, role: 'Field Service Engineer', desc: 'On-site installation & client service', salary: '₹20K–₹40K/mo' },
]

const plans = [
  {
    name: 'BASIC PLAN', price: '₹7,999', popular: false,
    features: ['2 Months Classroom Training', 'CCTV Basics & Installation', 'Networking Basics', 'Computer Hardware Basics', 'Practical Lab Sessions', 'Course Completion Certificate', 'Trainer Support During Course', 'Study Materials (PDF)'],
  },
  {
    name: 'JOB READY PLAN', price: '₹14,999', popular: true,
    features: ['Everything in Basic Plan', '1 Month Real Project Internship', 'Advanced CCTV (IP Camera, NVR)', 'Advanced Networking (Router, Switch)', 'Troubleshooting & Maintenance', 'Mobile App Setup & Configuration', 'Soft Skills & Client Handling', 'Job Assistance & Guidance', 'Certificate + Internship Certificate'],
  },
  {
    name: 'PREMIUM PLAN', price: '₹24,999', popular: false,
    features: ['Everything in Job Ready Plan', '2 Months Extended Internship', 'Live Project Experience (On Site)', 'Business & Entrepreneurship Training', 'How to Start Your Own CCTV Business', 'Quotation, Pricing & Marketing', 'Placement Assistance', 'Interview Preparation', 'Premium Certificate', 'Lifetime Guidance & Support'],
  },
]

/* ─────────────── HERO ─────────────── */
function HeroSection() {
  const ref = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start start', 'end start'] })
  const y = useTransform(scrollYProgress, [0, 1], ['0%', '30%'])

  return (
    <section ref={ref} className="relative min-h-screen flex items-center overflow-hidden pt-40 md:pt-48 pb-20" style={{ position: 'relative' }}>
      {/* Animated background */}
      <motion.div style={{ y }} className="absolute inset-0 pointer-events-none">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_20%_50%,rgba(11,77,186,0.18),transparent_55%),radial-gradient(ellipse_at_80%_20%,rgba(255,107,0,0.12),transparent_45%),radial-gradient(ellipse_at_60%_80%,rgba(11,77,186,0.10),transparent_50%)]" />
        <div className="absolute inset-0 bg-[linear-gradient(rgba(11,77,186,0.04)_1px,transparent_1px),linear-gradient(90deg,rgba(11,77,186,0.04)_1px,transparent_1px)] bg-[size:60px_60px]" />
        {/* Floating orbs */}
        {[
          { w: 500, h: 500, x: '-5%', y: '10%', c: 'rgba(11,77,186,0.08)', d: 8 },
          { w: 350, h: 350, x: '70%', y: '-5%', c: 'rgba(255,107,0,0.07)', d: 12 },
          { w: 250, h: 250, x: '85%', y: '55%', c: 'rgba(11,77,186,0.06)', d: 10 },
        ].map((orb, i) => (
          <motion.div
            key={i}
            animate={{ scale: [1, 1.15, 1], opacity: [0.7, 1, 0.7] }}
            transition={{ duration: orb.d, repeat: Infinity, ease: 'easeInOut', delay: i * 2 }}
            className="absolute rounded-full blur-3xl"
            style={{ width: orb.w, height: orb.h, left: orb.x, top: orb.y, background: orb.c }}
          />
        ))}
      </motion.div>

      <div className="container mx-auto px-6 lg:px-8 max-w-7xl relative z-10">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 lg:gap-16 items-center">
          {/* Left */}
          <div className="space-y-8">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20"
            >
              <motion.span animate={{ scale: [1, 1.3, 1] }} transition={{ duration: 2, repeat: Infinity }} className="w-2 h-2 rounded-full bg-accent" />
              <span className="text-sm font-bold text-primary">Admissions Open – Limited Seats</span>
            </motion.div>

            <motion.h1
              initial={{ opacity: 0, y: 40 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.7, delay: 0.1 }}
              className="text-4xl sm:text-5xl md:text-6xl lg:text-7xl font-black leading-tight"
            >
              <span style={{ color: '#0B4DBA' }}>CCTV &</span>{' '}
              <span className="relative inline-block">
                <span style={{ color: '#FF6B00' }}>IT Skill</span>
                <motion.span
                  animate={{ scaleX: [0, 1] }}
                  transition={{ duration: 0.8, delay: 0.9, ease: [0.22, 1, 0.36, 1] }}
                  className="absolute -bottom-1 left-0 right-0 h-1 bg-accent origin-left rounded-full"
                />
              </span>
              <br />
              <span style={{ color: '#0B4DBA' }}>Development</span>
              <br />
              <span style={{ color: '#083B8A' }}>Program</span>
            </motion.h1>

            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6, delay: 0.3 }}>
              <p className="text-xl sm:text-2xl font-bold text-accent mb-4">2 Months Training + 1 Month Internship</p>
              <div className="flex flex-wrap items-center gap-x-3 gap-y-2 text-base sm:text-lg text-foreground/60 font-medium">
                <span>Get Job Ready</span>
                <span className="text-primary/30 hidden sm:inline">•</span>
                <span>Work on Real Projects</span>
                <span className="text-primary/30 hidden sm:inline">•</span>
                <span>Build Skills</span>
                <span className="text-primary/30 hidden sm:inline">•</span>
                <span>Build Your Future</span>
              </div>
            </motion.div>

            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6, delay: 0.45 }} className="flex flex-wrap gap-4">
              <Link href="/admission">
                <motion.button
                  whileHover={{ scale: 1.05, boxShadow: '0 0 40px rgba(255,107,0,0.5)' }}
                  whileTap={{ scale: 0.97 }}
                  className="px-8 py-4 rounded-2xl text-lg font-black text-white flex items-center gap-2"
                  style={{ background: 'linear-gradient(135deg,#FF6B00,#e65c00)' }}
                >
                  Enroll Now <ChevronRight size={20} />
                </motion.button>
              </Link>
              <Link href="/courses">
                <motion.button
                  whileHover={{ scale: 1.05, boxShadow: '0 0 30px rgba(11,77,186,0.3)' }}
                  whileTap={{ scale: 0.97 }}
                  className="px-8 py-4 rounded-2xl text-lg font-bold text-primary border-2 border-primary/30 glass-card flex items-center gap-2"
                >
                  Explore Courses <ChevronRight size={20} />
                </motion.button>
              </Link>
            </motion.div>

            {/* Feature badges */}
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ duration: 0.7, delay: 0.6 }} className="flex flex-wrap gap-3 pt-2">
              {features.map(({ icon: Icon, label, color }, i) => (
                <motion.div
                  key={label}
                  initial={{ opacity: 0, scale: 0.8 }}
                  animate={{ opacity: 1, scale: 1 }}
                  transition={{ delay: 0.65 + i * 0.08 }}
                  whileHover={{ y: -4, boxShadow: `0 8px 30px ${color}25` }}
                  className="glass-card flex items-center gap-2 px-4 py-2 rounded-xl cursor-default"
                >
                  <Icon size={16} style={{ color }} />
                  <span className="text-sm font-semibold text-foreground/80">{label}</span>
                </motion.div>
              ))}
            </motion.div>
          </div>

          {/* Right – Video */}
          <motion.div initial={{ opacity: 0, x: 50 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.9, delay: 0.2 }}>
            <CinematicVideoFrame />
          </motion.div>
        </div>
      </div>
    </section>
  )
}

/* ─────────────── COURSE MODULES ─────────────── */
function CoursesSection() {
  return (
    <SectionShell>
      <Reveal>
        <div className="text-center mb-16">
          <p className="text-accent font-bold tracking-widest text-sm uppercase mb-3">What You Will Learn</p>
          <h2 className="text-4xl md:text-5xl font-black text-primary">Course Modules</h2>
          <p className="mt-4 text-lg text-foreground/60 max-w-2xl mx-auto">5 comprehensive modules covering every aspect of CCTV installation and IT skills</p>
        </div>
      </Reveal>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-5 gap-6">
        {modules.map(({ icon: Icon, color, title, topics }, i) => (
          <GlassCard key={title} delay={i * 0.1}>
            <div className="p-6 space-y-4">
              <motion.div
                whileHover={{ rotate: 15 }}
                className="w-14 h-14 rounded-2xl flex items-center justify-center"
                style={{ background: `${color}15`, border: `1.5px solid ${color}30` }}
              >
                <Icon size={26} style={{ color }} />
              </motion.div>
              <h3 className="text-lg font-black text-primary">{title}</h3>
              <ul className="space-y-2">
                {topics.map((t) => (
                  <li key={t} className="flex items-center gap-2 text-sm text-foreground/70">
                    <CheckCircle2 size={13} style={{ color, flexShrink: 0 }} />
                    {t}
                  </li>
                ))}
              </ul>
            </div>
            {/* Glow border on hover */}
            <div
              className="absolute inset-0 rounded-[inherit] opacity-0 group-hover:opacity-100 transition-opacity duration-500 pointer-events-none"
              style={{ boxShadow: `inset 0 0 0 1.5px ${color}50, 0 0 30px ${color}15` }}
            />
          </GlassCard>
        ))}
      </div>
    </SectionShell>
  )
}

/* ─────────────── CAREER ─────────────── */
function CareerSection() {
  return (
    <SectionShell className="bg-[linear-gradient(135deg,#061f4f,#0B4DBA)]">
      <Reveal>
        <div className="text-center mb-16">
          <p className="text-accent font-bold tracking-widest text-sm uppercase mb-3">After Training</p>
          <h2 className="text-4xl md:text-5xl font-black text-white">Build a Secure Career</h2>
          <p className="mt-4 text-xl font-bold text-accent">High Demand | Good Salary | Bright Future</p>
        </div>
      </Reveal>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {careers.map(({ icon: Icon, role, desc, salary }, i) => (
          <GlassCard key={role} delay={i * 0.12}>
            <div className="p-6 space-y-4 bg-white/5 backdrop-blur-xl rounded-2xl border border-white/15">
              <div className="w-14 h-14 rounded-2xl bg-accent/20 flex items-center justify-center border border-accent/30">
                <Icon size={26} className="text-accent" />
              </div>
              <h3 className="text-xl font-black text-white">{role}</h3>
              <p className="text-white/60 text-sm">{desc}</p>
              <div className="flex items-center gap-2 pt-2">
                <TrendingUp size={16} className="text-green-400" />
                <span className="text-green-400 font-bold text-sm">{salary}</span>
              </div>
            </div>
          </GlassCard>
        ))}
      </div>
    </SectionShell>
  )
}

/* ─────────────── PRICING ─────────────── */
function PricingSection() {
  return (
    <SectionShell>
      <Reveal>
        <div className="text-center mb-16">
          <p className="text-accent font-bold tracking-widest text-sm uppercase mb-3">Transparent Pricing</p>
          <h2 className="text-4xl md:text-5xl font-black text-primary">Choose Your Plan</h2>
          <p className="mt-4 text-lg text-foreground/60">Invest in your future with the right plan</p>
        </div>
      </Reveal>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-8 lg:gap-12 items-center">
        {plans.map(({ name, price, popular, features: fs }, i) => (
          <Reveal key={name} delay={i * 0.15}>
            <motion.div
              whileHover={{ y: -12 }}
              transition={{ type: 'spring', stiffness: 220, damping: 20 }}
              className={`relative rounded-3xl p-8 flex flex-col gap-6 overflow-hidden ${
                popular
                  ? 'bg-gradient-to-b from-[#0B4DBA] to-[#083B8A] text-white shadow-[0_0_60px_rgba(255,107,0,0.35)]'
                  : 'glass-card'
              } ${popular ? 'scale-105 md:scale-110 z-10' : ''}`}
            >
              {popular && (
                <>
                  {/* Pulse border */}
                  <motion.div
                    animate={{ opacity: [0.5, 1, 0.5] }}
                    transition={{ duration: 2, repeat: Infinity }}
                    className="absolute inset-0 rounded-3xl border-2 border-accent pointer-events-none"
                  />
                  <motion.div
                    initial={{ scale: 0.8, opacity: 0 }}
                    animate={{ scale: 1, opacity: 1 }}
                    className="absolute top-4 right-4 bg-accent text-white text-xs font-black px-3 py-1 rounded-full flex items-center gap-1"
                  >
                    <Star size={11} fill="white" /> Most Popular
                  </motion.div>
                </>
              )}
              <div>
                <p className={`text-sm font-black tracking-widest uppercase mb-2 ${popular ? 'text-accent' : 'text-foreground/50'}`}>{name}</p>
                <p className={`text-5xl font-black ${popular ? 'text-white' : 'text-primary'}`}>{price}</p>
              </div>
              <ul className="space-y-3 flex-1">
                {fs.map((f) => (
                  <li key={f} className="flex items-start gap-3 text-sm">
                    <CheckCircle2 size={16} className={`mt-0.5 flex-shrink-0 ${popular ? 'text-accent' : 'text-primary'}`} />
                    <span className={popular ? 'text-white/85' : 'text-foreground/70'}>{f}</span>
                  </li>
                ))}
              </ul>
              <Link href="/admission" className="mt-2">
                <motion.button
                  whileHover={{ scale: 1.04 }}
                  whileTap={{ scale: 0.97 }}
                  className={`w-full py-4 rounded-2xl font-black text-base transition-all duration-300 ${
                    popular
                      ? 'bg-accent text-white shadow-[0_0_30px_rgba(255,107,0,0.4)] hover:shadow-[0_0_50px_rgba(255,107,0,0.6)]'
                      : 'bg-primary text-white hover:shadow-[0_8px_30px_rgba(11,77,186,0.35)]'
                  }`}
                >
                  Get Started
                </motion.button>
              </Link>
            </motion.div>
          </Reveal>
        ))}
      </div>
    </SectionShell>
  )
}

/* ─────────────── ADMISSION FORM ─────────────── */
function AdmissionForm() {
  const [focused, setFocused] = useState<string | null>(null)
  const [submitted, setSubmitted] = useState(false)

  const fields = [
    { id: 'name', label: 'Full Name', type: 'text', placeholder: 'Your full name' },
    { id: 'phone', label: 'Phone Number', type: 'tel', placeholder: '10-digit mobile number' },
    { id: 'email', label: 'Email Address', type: 'email', placeholder: 'your@email.com' },
  ]

  return (
    <SectionShell>
      <div className="max-w-2xl mx-auto">
        <Reveal>
          <div className="text-center mb-12">
            <p className="text-accent font-bold tracking-widest text-sm uppercase mb-3">Secure Your Seat</p>
            <h2 className="text-4xl md:text-5xl font-black text-primary">Apply for Admission</h2>
            <p className="mt-4 text-lg text-foreground/60">Fill in your details and our team will contact you within 24 hours.</p>
          </div>
        </Reveal>

        <Reveal delay={0.15}>
          <motion.form
            onSubmit={(e) => { e.preventDefault(); setSubmitted(true) }}
            className="glass-form rounded-3xl p-8 md:p-12 space-y-6"
          >
            {fields.map(({ id, label, type, placeholder }) => (
              <div key={id} className="relative">
                <motion.label
                  animate={focused === id ? { y: -28, scale: 0.8, color: '#0B4DBA' } : { y: 0, scale: 1, color: '#083B8A99' }}
                  className="absolute left-4 top-4 font-semibold pointer-events-none origin-left z-10 transition-all"
                >
                  {label}
                </motion.label>
                <input
                  id={id} type={type} placeholder={focused === id ? placeholder : ''}
                  onFocus={() => setFocused(id)} onBlur={() => setFocused(null)}
                  className="w-full px-4 pt-8 pb-3 rounded-2xl bg-white/60 border-2 border-transparent text-foreground font-medium outline-none transition-all duration-300 focus:border-primary focus:bg-white focus:shadow-[0_0_0_4px_rgba(11,77,186,0.1)]"
                />
              </div>
            ))}

            <div className="relative">
              <label className="block text-sm font-bold text-foreground/60 mb-2">Course Interest</label>
              <select className="w-full px-4 py-4 rounded-2xl bg-white/60 border-2 border-transparent text-foreground font-medium outline-none transition-all duration-300 focus:border-primary focus:bg-white">
                <option value="">Select a course</option>
                <option>CCTV Technology</option>
                <option>Networking</option>
                <option>Computer Hardware</option>
                <option>Full Program (All Modules)</option>
              </select>
            </div>

            <div className="relative">
              <label className="block text-sm font-bold text-foreground/60 mb-2">Preferred Plan</label>
              <select className="w-full px-4 py-4 rounded-2xl bg-white/60 border-2 border-transparent text-foreground font-medium outline-none transition-all duration-300 focus:border-primary focus:bg-white">
                <option value="">Select a plan</option>
                <option>Basic Plan – ₹7,999</option>
                <option>Job Ready Plan – ₹14,999</option>
                <option>Premium Plan – ₹24,999</option>
              </select>
            </div>

            {submitted ? (
              <motion.div initial={{ scale: 0.8, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="text-center py-6">
                <div className="text-5xl mb-3">🎉</div>
                <p className="text-xl font-black text-primary">Thank you! We'll contact you shortly.</p>
              </motion.div>
            ) : (
              <motion.button
                type="submit"
                whileHover={{ scale: 1.03, boxShadow: '0 0 50px rgba(255,107,0,0.45)' }}
                whileTap={{ scale: 0.97 }}
                className="w-full py-5 rounded-2xl text-white text-lg font-black"
                style={{ background: 'linear-gradient(135deg,#FF6B00,#e65c00)' }}
              >
                Submit Application →
              </motion.button>
            )}
          </motion.form>
        </Reveal>
      </div>
    </SectionShell>
  )
}

/* ─────────────── PAGE ─────────────── */
export default function HomePage() {
  return (
    <main className="min-h-screen overflow-x-hidden" style={{ background: '#F5F9FF' }}>
      <Header />
      <HeroSection />
      <CoursesSection />
      <CareerSection />
      <PricingSection />
      <AdmissionForm />
      <Footer />
    </main>
  )
}
