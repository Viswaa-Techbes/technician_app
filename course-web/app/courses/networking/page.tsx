import { Metadata } from 'next'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { SectionShell, Reveal, GlassCard } from '@/components/premium-ui'
import { JsonLd } from '@/components/seo/JsonLd'
import { Breadcrumbs } from '@/components/seo/Breadcrumbs'
import { Network, CheckCircle2 } from 'lucide-react'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'Enterprise Networking Course | TECHBES',
  description: 'Master enterprise networking. Learn IP addressing, router/switch configuration, and WiFi setup. Hands-on training for network technicians.',
  keywords: ['networking course', 'CCNA basics', 'router configuration', 'network technician training'],
}

const courseSchema = {
  "@context": "https://schema.org",
  "@type": "Course",
  "name": "Enterprise Networking Training",
  "description": "Learn to design and configure enterprise-grade networks including routers, switches, LAN infrastructure and WiFi systems.",
  "provider": {
    "@type": "EducationalOrganization",
    "name": "TECHBES",
    "sameAs": "https://skills.techbes.co.in"
  }
}

export default function NetworkingPage() {
  return (
    <main className="min-h-screen bg-[#F5F9FF]">
      <JsonLd data={courseSchema} />
      <Header />
      
      <section className="pt-32 pb-16 px-6">
        <div className="container mx-auto max-w-7xl">
          <Breadcrumbs items={[{ label: 'Courses', href: '/courses' }, { label: 'Networking', href: '/courses/networking' }]} />
          
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-center">
            <Reveal>
              <div className="space-y-6">
                <div className="inline-flex items-center gap-2 px-4 py-2 rounded-full bg-orange-500/10 border border-orange-500/20 text-orange-600 text-sm font-bold">
                  <Network size={16} /> Core Module
                </div>
                <h1 className="text-4xl md:text-6xl font-black text-primary leading-tight">
                  Enterprise <span className="text-accent">Networking</span> Training
                </h1>
                <p className="text-xl text-foreground/60">
                  Build the backbone of modern business. Learn how to configure routers, switches, and secure wireless networks for any scale.
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
              <GlassCard className="p-8 border-orange-500/10">
                <h2 className="text-2xl font-black text-primary mb-6">Course Curriculum</h2>
                <ul className="space-y-4">
                  {[
                    'Basics of Networking & IP Addressing',
                    'Router & Switch Configuration',
                    'LAN, WAN & WiFi Setup',
                    'Network Security Fundamentals',
                    'Subnetting & VLANs',
                    'Network Troubleshooting'
                  ].map((item) => (
                    <li key={item} className="flex items-center gap-3 text-foreground/70">
                      <CheckCircle2 size={20} className="text-orange-500" />
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
            <h2 className="text-3xl md:text-5xl font-black text-primary mb-4">Career Pathways</h2>
            <p className="text-foreground/60 max-w-2xl mx-auto">High demand roles for networking graduates:</p>
          </div>
        </Reveal>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          {[
            { role: 'Network Support Executive', desc: 'Managing day-to-day network operations and user support.' },
            { role: 'Network Technician', desc: 'Hands-on installation and maintenance of network hardware.' },
            { role: 'System Administrator', desc: 'Configuring servers and network infrastructure for stability.' }
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
