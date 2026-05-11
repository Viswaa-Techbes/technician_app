import { Metadata } from 'next'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { SectionShell, Reveal, GlassCard } from '@/components/premium-ui'
import { JsonLd } from '@/components/seo/JsonLd'
import { Breadcrumbs } from '@/components/seo/Breadcrumbs'
import { Camera, CheckCircle2, ChevronRight } from 'lucide-react'
import Link from 'next/link'
import { motion } from 'framer-motion'

export const metadata: Metadata = {
  title: 'Professional CCTV Installation Course | TECHBES',
  description: 'Master CCTV systems from analog to IP networks. Learn installation, DVR/NVR setup, and remote monitoring with 100% practical lab sessions.',
  keywords: ['CCTV training', 'CCTV installation course', 'IP camera training', 'security system course'],
}

const courseSchema = {
  "@context": "https://schema.org",
  "@type": "Course",
  "name": "Professional CCTV Technology Training",
  "description": "Master the full stack of CCTV systems — from basic analog cameras to advanced IP camera networks with remote monitoring.",
  "provider": {
    "@type": "EducationalOrganization",
    "name": "TECHBES",
    "sameAs": "https://skills.techbes.co.in"
  }
}

export default function CCTVPage() {
  return (
    <main className="min-h-screen bg-[#F5F9FF]">
      <JsonLd data={courseSchema} />
      <Header />
      
      <section className="pt-32 pb-16 px-6">
        <div className="container mx-auto max-w-7xl">
          <Breadcrumbs items={[{ label: 'Courses', href: '/courses' }, { label: 'CCTV Technology', href: '/courses/cctv-technology' }]} />
          
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <Reveal>
              <div className="space-y-6">
                <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-primary/10 border border-primary/20 text-primary text-sm font-bold">
                  <Camera size={16} /> Core Module
                </div>
                <h1 className="text-4xl md:text-6xl font-black text-primary leading-tight">
                  Professional <span className="text-accent">CCTV</span> Installation Course
                </h1>
                <p className="text-xl text-foreground/60">
                  Become a certified CCTV expert. Our comprehensive training covers everything from basic wiring to advanced IP camera networking and remote surveillance setup.
                </p>
                <div className="flex gap-4">
                  <Link href="/admission">
                    <button className="px-8 py-4 rounded-2xl bg-accent text-white font-bold shadow-lg shadow-accent/20 hover:scale-105 transition-transform">
                      Enroll Now
                    </button>
                  </Link>
                </div>
              </div>
            </Reveal>
            
            <Reveal delay={0.2}>
              <GlassCard className="p-8">
                <h2 className="text-2xl font-black text-primary mb-6">What You Will Learn</h2>
                <ul className="space-y-4">
                  {[
                    'Introduction to Analog & IP Cameras',
                    'CCTV Wiring & Connection Techniques',
                    'DVR & NVR Configuration',
                    'Mobile & Remote Viewing Setup',
                    'PTZ Camera Installation',
                    'Troubleshooting & Maintenance'
                  ].map((item) => (
                    <li key={item} className="flex items-center gap-3 text-foreground/70">
                      <CheckCircle2 size={20} className="text-emerald-500" />
                      {item}
                    </li>
                  ))}
                </ul>
              </GlassCard>
            </Reveal>
          </div>
        </div>
      </section>

      <SectionShell>
        <Reveal>
          <div className="text-center mb-12">
            <h2 className="text-3xl md:text-5xl font-black text-primary mb-4">Career Opportunities</h2>
            <p className="text-foreground/60 max-w-2xl mx-auto">After completing this module, you can work as:</p>
          </div>
        </Reveal>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[
            { role: 'CCTV Technician', desc: 'Expert in installing and maintaining surveillance systems.' },
            { role: 'Security System Integrator', desc: 'Designing complex security networks for enterprises.' },
            { role: 'Field Service Engineer', desc: 'On-site support and troubleshooting for client installations.' }
          ].map((career, i) => (
            <GlassCard key={i} delay={i * 0.1} className="p-6 text-center">
              <h3 className="text-xl font-bold text-primary mb-2">{career.role}</h3>
              <p className="text-foreground/60 text-sm">{career.desc}</p>
            </GlassCard>
          ))}
        </div>
      </SectionShell>

      <Footer />
    </main>
  )
}
