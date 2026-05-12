'use client'

import { motion, useScroll, useTransform } from 'framer-motion'
import { useRef } from 'react'
import Link from 'next/link'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import EarnPopup from '@/components/earn-popup'
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
  { icon: Zap, label: '100% job support', color: '#0B4DBA' },
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
  { icon: Wrench, role: 'Field Service Engineer', desc: 'On-site installation & client service', salary: '₹15K–₹40K/mo' },
]

const plans = [
  {
    name: 'BASIC PLAN', price: '₹7,999', popular: false,
    features: ['2 Months Classroom Training', 'CCTV Basics & Installation', 'Networking Basics', 'Computer Hardware Basics', 'Practical Lab Sessions', 'Course Completion Certificate', 'Trainer Support During Course', 'Study Materials (PDF)'],
  },
  {
    name: 'PREMIUM PLAN', price: '₹24,999', originalPrice: '₹30,000', popular: true,
    features: ['Everything in Job Ready Plan', '2 Months Extended Internship', 'Live Project Experience (On Site)', 'Business & Entrepreneurship Training', 'How to Start Your Own CCTV Business', 'Quotation, Pricing & Marketing', 'Interview Preparation', 'Premium Certificate', 'Guidance & Support', '100% JOB ASSISTANCE'],
  },
  {
    name: 'JOB READY PLAN', price: '₹14,999', popular: false,
    features: ['Everything in Basic Plan', '1 Month Real Project Internship', 'Advanced CCTV (IP Camera, NVR)', 'Advanced Networking (Router, Switch)', 'Troubleshooting & Maintenance', 'Mobile App Setup & Configuration', 'Soft Skills & Client Handling', 'Career Guidance & Support', 'Certificate + Internship Certificate'],
  },
]

/* ─────────────── COMPONENTS ─────────────── */
function JobAssistanceBadge() {
  return (
    <motion.div
      initial={{ scale: 0.5, opacity: 0 }}
      animate={{ 
        scale: [1, 1.05, 1],
        opacity: 1,
        y: [0, -5, 0]
      }}
      transition={{ 
        scale: { duration: 2, repeat: Infinity, ease: "easeInOut" },
        y: { duration: 2.5, repeat: Infinity, ease: "easeInOut" },
        opacity: { duration: 0.5 }
      }}
      className="inline-flex items-center gap-2 px-5 py-2.5 rounded-2xl bg-emerald-500/10 border border-emerald-500/20 shadow-[0_0_25px_rgba(16,185,129,0.1)] group relative overflow-hidden cursor-default"
    >
      {/* GIF-like Shimmer Effect */}
      <motion.div 
        animate={{ x: ['-100%', '200%'] }}
        transition={{ duration: 2, repeat: Infinity, ease: "linear", repeatDelay: 1 }}
        className="absolute inset-0 bg-gradient-to-r from-transparent via-white/30 to-transparent -skew-x-12"
      />
      
      <div className="relative z-10 flex items-center gap-2">
        <div className="flex items-center justify-center w-6 h-6 rounded-full bg-emerald-500 shadow-[0_0_15px_rgba(16,185,129,0.5)]">
          <Zap size={14} className="text-white fill-white" />
        </div>
        <span className="text-base md:text-lg font-black text-emerald-600 tracking-tight flex items-center gap-1.5">
          100% job support
          <motion.span
            animate={{ opacity: [1, 0.5, 1] }}
            transition={{ duration: 1, repeat: Infinity }}
            className="w-1.5 h-1.5 rounded-full bg-emerald-500"
          />
        </span>
      </div>
      
      {/* Decorative pulse */}
      <motion.div
        animate={{ scale: [1, 1.5, 1], opacity: [0.2, 0, 0.2] }}
        transition={{ duration: 2, repeat: Infinity }}
        className="absolute inset-0 bg-emerald-500/20 rounded-[inherit]"
      />
    </motion.div>
  )
}

/* ─────────────── HERO ─────────────── */
function HeroSection() {
  const ref = useRef<HTMLDivElement>(null)
  const { scrollYProgress } = useScroll({ target: ref, offset: ['start start', 'end start'] })
  const y = useTransform(scrollYProgress, [0, 1], ['0%', '30%'])

  return (
    <section ref={ref} className="relative min-h-screen flex items-center overflow-hidden pt-28 md:pt-32 pb-20" style={{ position: 'relative' }}>
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
          <div className="space-y-6">
            <motion.div
              initial={{ opacity: 0, y: 30 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.6 }}
              className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20"
            >
              <motion.span animate={{ scale: [1, 1.3, 1] }} transition={{ duration: 2, repeat: Infinity }} className="w-2 h-2 rounded-full bg-accent" />
              <span className="text-sm font-bold text-primary">Admissions Open – Limited Seats</span>
            </motion.div>

            <h1 className="text-4xl sm:text-5xl md:text-5xl lg:text-5xl xl:text-6xl font-black leading-tight">
              <span className="whitespace-nowrap" style={{ color: '#0B4DBA' }}>CCTV & Networking</span>{' '}
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
            </h1>

            <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.6, delay: 0.3 }}>
              <div className="flex flex-col items-start gap-4 mb-6">
                <p className="text-xl sm:text-2xl font-bold text-accent">2 Months Training + 1 Month Internship</p>
                <JobAssistanceBadge />
              </div>
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
          <motion.div initial={{ opacity: 0, x: 50 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.9, delay: 0.2 }} className="lg:-mt-10">
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
    <SectionShell className="bg-[linear-gradient(135deg,#f8fbff,#e8f1ff)]">
      <Reveal>
        <div className="text-center mb-16">
          <p className="text-accent font-bold tracking-widest text-sm uppercase mb-3">After Training</p>
          <h2 className="text-4xl md:text-5xl font-black text-black">Build a Secure Career</h2>
          <p className="mt-4 text-xl font-bold text-primary">High Demand | Good Salary | Bright Future</p>
        </div>
      </Reveal>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {careers.map(({ icon: Icon, role, desc, salary }, i) => (
          <GlassCard key={role} delay={i * 0.12}>
            <div className="p-6 space-y-4 bg-white rounded-2xl border border-primary/10 shadow-[0_16px_45px_rgba(11,77,186,0.10)]">
              <div className="w-14 h-14 rounded-2xl bg-accent/10 flex items-center justify-center border border-accent/30">
                <Icon size={26} className="text-accent" />
              </div>
              <h3 className="text-xl font-black text-black">{role}</h3>
              <p className="text-foreground/65 text-sm">{desc}</p>
              <div className="flex items-center gap-2 pt-2">
                <TrendingUp size={16} className="text-emerald-600" />
                <span className="text-emerald-600 font-bold text-sm">{salary}</span>
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
        {plans.map((plan, i) => {
          const { name, price, popular, features: fs } = plan;
          return (
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
                <div className="flex flex-wrap items-center gap-2 mb-2">
                  <p className={`text-sm font-black tracking-widest uppercase ${popular ? 'text-accent' : 'text-foreground/50'}`}>{name}</p>
                  {(plan as any).originalPrice && (
                    <motion.span 
                      animate={{ scale: [1, 1.05, 1], opacity: [0.9, 1, 0.9] }}
                      transition={{ duration: 2, repeat: Infinity }}
                      className="text-[9px] font-black bg-emerald-500 text-white px-2 py-0.5 rounded-full shadow-lg shadow-emerald-500/20"
                    >
                      SPECIAL OFFER
                    </motion.span>
                  )}
                </div>
                <div className="flex items-end gap-3 flex-wrap">
                  <p className={`text-5xl md:text-6xl font-black ${popular ? 'text-white' : 'text-primary'}`}>{price}</p>
                  {(plan as any).originalPrice && (
                    <div className="flex flex-col pb-1">
                      <p className={`text-xl font-bold line-through ${popular ? 'text-white/40' : 'text-foreground/30'}`}>{(plan as any).originalPrice}</p>
                      <span className={`text-[10px] font-black uppercase tracking-widest ${popular ? 'text-accent' : 'text-primary'}`}>Limited Time Offer</span>
                    </div>
                  )}
                </div>
              </div>
              <ul className="space-y-3 flex-1">
                {fs.map((f) => {
                  const isJobAssistance = f.includes('JOB ASSISTANCE');
                  return (
                    <li key={f} className="flex items-start gap-3 text-sm">
                      <CheckCircle2 size={16} className={`mt-0.5 flex-shrink-0 ${popular ? 'text-accent' : 'text-primary'}`} />
                      <motion.span 
                        animate={isJobAssistance ? { 
                          scale: [1, 1.05, 1],
                          y: [0, -2, 0]
                        } : {}}
                        transition={isJobAssistance ? {
                          duration: 2,
                          repeat: Infinity,
                          ease: "easeInOut"
                        } : {}}
                        className={`
                          ${popular ? 'text-white/85' : 'text-foreground/70'}
                          ${isJobAssistance ? 'font-black text-white bg-accent/20 px-2 py-0.5 rounded-lg border border-accent/30 flex items-center gap-1.5 shadow-[0_0_15px_rgba(255,107,0,0.2)]' : ''}
                        `}>
                        {f}
                        {isJobAssistance && (
                          <motion.span
                            animate={{ scale: [1, 1.3, 1], opacity: [1, 0.5, 1] }}
                            transition={{ duration: 2, repeat: Infinity }}
                            className="w-2 h-2 rounded-full bg-accent"
                          />
                        )}
                      </motion.span>
                    </li>
                  );
                })}
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
        )})}
      </div>
    </SectionShell>
  )
}

/* ─────────────── ADMISSION CTA ─────────────── */
function AdmissionCTA() {
  return (
    <SectionShell>
      <div className="max-w-3xl mx-auto text-center">
        <Reveal>
          <div className="mb-8">
            <p className="text-accent font-bold tracking-widest text-sm uppercase mb-3">Secure Your Seat</p>
            <h2 className="text-4xl md:text-5xl font-black text-primary">Apply for Admission</h2>
            <p className="mt-4 text-lg text-foreground/60">Open the admission panel to choose your plan and submit your details.</p>
          </div>
        </Reveal>

        <Reveal delay={0.15}>
          <Link href="/admission">
              <motion.button
                whileHover={{ scale: 1.03, boxShadow: '0 0 50px rgba(255,107,0,0.45)' }}
                whileTap={{ scale: 0.97 }}
                className="px-10 py-5 rounded-2xl text-white text-lg font-black inline-flex items-center justify-center gap-2"
                style={{ background: 'linear-gradient(135deg,#FF6B00,#e65c00)' }}
              >
                Go to Admission Panel <ChevronRight size={20} />
              </motion.button>
          </Link>
        </Reveal>
      </div>
    </SectionShell>
  )
}

/* ─────────────── FAQ ─────────────── */
const faqs = [
  { q: "Is this training 100% practical?", a: "Yes, our training is focuses on hands-on practical experience with real equipment in our lab and on-site field work." },
  { q: "Do you provide job assistance?", a: "Absolutely. We provide 100% job assistance including interview preparation, resume building, and placement connections." },
  { q: "What is the duration of the course?", a: "The total program is 3 months — 2 months of intensive classroom/lab training and 1 month of real-project internship." },
  { q: "Will I get a certificate?", a: "Yes, you will receive an industry-recognized Certificate of Completion from TECHBES upon finishing the program." },
]

function FAQSection() {
  return (
    <SectionShell className="bg-white">
      <Reveal>
        <div className="text-center mb-12">
          <h2 className="text-4xl font-black text-primary mb-4">Frequently Asked Questions</h2>
          <p className="text-foreground/60">Everything you need to know about the TECHBES program</p>
        </div>
      </Reveal>
      <div className="max-w-4xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-6">
        {faqs.map((faq, i) => (
          <GlassCard key={i} delay={i * 0.1}>
            <div className="p-6">
              <h3 className="text-lg font-bold text-primary mb-2">{faq.q}</h3>
              <p className="text-foreground/70 text-sm leading-relaxed">{faq.a}</p>
            </div>
          </GlassCard>
        ))}
      </div>
    </SectionShell>
  )
}

/* ─────────────── PAGE ─────────────── */
export default function HomePage() {
  return (
    <main className="min-h-screen overflow-x-hidden" style={{ background: '#F5F9FF' }}>
      <Header />
      <EarnPopup />
      <HeroSection />
      <CoursesSection />
      <CareerSection />
      <PricingSection />
      <FAQSection />
      <AdmissionCTA />
      <Footer />
    </main>
  )
}
