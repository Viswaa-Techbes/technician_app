import { Metadata } from 'next'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { SectionShell, Reveal, GlassCard } from '@/components/premium-ui'
import { JsonLd } from '@/components/seo/JsonLd'
import { Breadcrumbs } from '@/components/seo/Breadcrumbs'
import { Cpu, CheckCircle2 } from 'lucide-react'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'Computer Hardware Repairing Course | TECHBES',
  description: 'Learn computer hardware from scratch. OS installation, laptop repair basics, and system maintenance. Become a certified IT Support professional.',
  keywords: ['computer hardware course', 'laptop repair training', 'IT support course', 'PC assembling'],
}

const courseSchema = {
  "@context": "https://schema.org",
  "@type": "Course",
  "name": "Computer Hardware & IT Support Training",
  "description": "Hands-on training in assembling, repairing, and maintaining desktop and laptop systems from the ground up.",
  "provider": {
    "@type": "EducationalOrganization",
    "name": "TECHBES",
    "sameAs": "https://skills.techbes.co.in"
  }
}

export default function HardwarePage() {
  return (
    <main className="min-h-screen bg-[#F5F9FF]">
      <JsonLd data={courseSchema} />
      <Header />
      
      <section className="pt-32 pb-16 px-6">
        <div className="container mx-auto max-w-7xl">
          <Breadcrumbs items={[{ label: 'Courses', href: '/courses' }, { label: 'Computer Hardware', href: '/courses/computer-hardware' }]} />
          
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <Reveal>
              <div className="space-y-6">
                <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-blue-600/10 border border-blue-600/20 text-blue-600 text-sm font-bold">
                  <Cpu size={16} /> Core Module
                </div>
                <h1 className="text-4xl md:text-6xl font-black text-primary leading-tight">
                  Computer <span className="text-accent">Hardware</span> & Repairing
                </h1>
                <p className="text-xl text-foreground/60">
                  Master the art of computer maintenance. From assembling high-end PCs to repairing laptops and installing operating systems.
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
                <h2 className="text-2xl font-black text-primary mb-6">Learning Outcomes</h2>
                <ul className="space-y-4">
                  {[
                    'Desktop & Laptop Assembling',
                    'OS & Software Installation',
                    'Hardware Troubleshooting',
                    'Virus & Malware Removal',
                    'Laptop Repairing Basics',
                    'System Upgradation & Maintenance'
                  ].map((item) => (
                    <li key={item} className="flex items-center gap-3 text-foreground/70">
                      <CheckCircle2 size={20} className="text-blue-500" />
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
            <h2 className="text-3xl md:text-5xl font-black text-primary mb-4">Job Roles</h2>
            <p className="text-foreground/60 max-w-2xl mx-auto">Start your career with these high-demand roles:</p>
          </div>
        </Reveal>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[
            { role: 'IT Support Engineer', desc: 'Providing technical assistance and hardware maintenance for offices.' },
            { role: 'Hardware Technician', desc: 'Diagnosing and repairing desktop/laptop issues.' },
            { role: 'Desktop Support', desc: 'Managing corporate IT infrastructure and software deployment.' }
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
