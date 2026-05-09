'use client'

import { useState } from 'react'
import { motion } from 'framer-motion'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { Reveal, SectionShell } from '@/components/premium-ui'
import { Phone, MapPin, MessageCircle, Mail, Send } from 'lucide-react'

const contactDetails = [
  { icon: Phone, label: 'Phone', value: '9591144949', link: 'tel:9591144949', color: '#0B4DBA' },
  { icon: MessageCircle, label: 'WhatsApp', value: 'Chat Now', link: 'https://wa.me/919591144949', color: '#25D366' },
  { icon: Mail, label: 'Email', value: 'info@techbes.in', link: 'mailto:info@techbes.in', color: '#FF6B00' },
  { icon: MapPin, label: 'Address', value: 'Nagarbhavi, Bangalore, Karnataka – 560072', link: '#', color: '#0B4DBA' },
]

export default function EnquiryPage() {
  const [focused, setFocused] = useState<string | null>(null)
  const [submitted, setSubmitted] = useState(false)

  const fields = [
    { id: 'name', label: 'Full Name', type: 'text' },
    { id: 'phone', label: 'Phone Number', type: 'tel' },
    { id: 'email', label: 'Email Address', type: 'email' },
  ]

  return (
    <main className="min-h-screen overflow-x-hidden" style={{ background: '#F5F9FF' }}>
      <Header />

      {/* Hero */}
      <section className="relative pt-40 md:pt-48 pb-16 overflow-hidden">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_30%_50%,rgba(11,77,186,0.12),transparent_55%),radial-gradient(ellipse_at_75%_20%,rgba(255,107,0,0.08),transparent_45%)]" />
        <div className="container mx-auto px-6 lg:px-8 max-w-7xl relative z-10 text-center">
          <motion.div initial={{ opacity: 0, y: 30 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.7 }}>
            <p className="text-accent font-bold tracking-widest text-sm uppercase mb-4">Get In Touch</p>
            <h1 className="text-5xl md:text-7xl font-black text-primary mb-4">
              Have a <span style={{ color: '#FF6B00' }}>Question?</span>
            </h1>
            <p className="text-xl text-foreground/60 max-w-xl mx-auto">
              Our team is here to help. Fill the form or reach us directly — we respond within hours.
            </p>
          </motion.div>
        </div>
      </section>

      <SectionShell>
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 items-start">

          {/* Enquiry Form */}
          <Reveal>
            <motion.form
              onSubmit={(e) => { 
                e.preventDefault(); 
                setSubmitted(true);
                fetch(`${process.env.NEXT_PUBLIC_BACKEND_API_URL || ''}/api/v2/analytics/visitors/track`, {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({
                    domain: 'skills.techbes.co.in',
                    eventType: 'lead_submitted',
                    page: '/enquiry',
                    metadata: { source: 'enquiry_form' }
                  })
                }).catch(() => {});
              }}
              className="glass-form rounded-3xl p-8 md:p-10 space-y-6"
            >
              <h2 className="text-3xl font-black text-primary mb-2">Send Enquiry</h2>
              <p className="text-foreground/60 text-sm mb-6">We'll get back to you within 24 hours.</p>

              {fields.map(({ id, label, type }) => (
                <div key={id} className="relative">
                  <motion.label
                    animate={focused === id ? { y: -28, scale: 0.8, color: '#0B4DBA' } : { y: 0, scale: 1, color: '#083B8A99' }}
                    className="absolute left-4 top-4 font-semibold pointer-events-none origin-left z-10"
                  >
                    {label}
                  </motion.label>
                  <input
                    id={id} type={type}
                    onFocus={() => setFocused(id)} onBlur={() => setFocused(null)}
                    className="w-full px-4 pt-8 pb-3 rounded-2xl bg-white/60 border-2 border-transparent text-foreground font-medium outline-none transition-all duration-300 focus:border-primary focus:bg-white focus:shadow-[0_0_0_4px_rgba(11,77,186,0.1)]"
                  />
                </div>
              ))}

              <div className="relative">
                <label className="block text-sm font-bold text-foreground/60 mb-2">Course Interested In</label>
                <select className="w-full px-4 py-4 rounded-2xl bg-white/60 border-2 border-transparent text-foreground font-medium outline-none transition-all duration-300 focus:border-primary focus:bg-white">
                  <option value="">Select a course</option>
                  <option>CCTV Technology</option>
                  <option>Networking</option>
                  <option>Computer Hardware</option>
                  <option>Full Program (All Modules)</option>
                </select>
              </div>

              <div>
                <label className="block text-sm font-bold text-foreground/60 mb-2">Your Message (Optional)</label>
                <textarea
                  rows={4}
                  onFocus={() => setFocused('msg')} onBlur={() => setFocused(null)}
                  className="w-full px-4 py-4 rounded-2xl bg-white/60 border-2 border-transparent text-foreground font-medium outline-none transition-all duration-300 focus:border-primary focus:bg-white resize-none"
                  placeholder="Any specific questions or requirements?"
                />
              </div>

              {submitted ? (
                <motion.div initial={{ scale: 0.8, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} className="text-center py-6">
                  <div className="text-5xl mb-3">✅</div>
                  <p className="text-xl font-black text-primary">Enquiry sent! We'll reach you soon.</p>
                </motion.div>
              ) : (
                <motion.button
                  type="submit"
                  whileHover={{ scale: 1.03, boxShadow: '0 0 50px rgba(255,107,0,0.45)' }}
                  whileTap={{ scale: 0.97 }}
                  className="w-full py-5 rounded-2xl text-white text-lg font-black flex items-center justify-center gap-3"
                  style={{ background: 'linear-gradient(135deg,#FF6B00,#e65c00)' }}
                >
                  <Send size={20} /> Send Enquiry
                </motion.button>
              )}
            </motion.form>
          </Reveal>

          {/* Contact Card */}
          <Reveal delay={0.2}>
            <div className="space-y-6">
              <div className="glass-form rounded-3xl p-8 space-y-6">
                <h2 className="text-3xl font-black text-primary">Contact Details</h2>
                <p className="text-foreground/60">Prefer to reach us directly? Use any of these channels.</p>

                {contactDetails.map(({ icon: Icon, label, value, link, color }) => (
                  <motion.a
                    key={label}
                    href={link}
                    target={link.startsWith('http') ? '_blank' : undefined}
                    rel="noopener noreferrer"
                    whileHover={{ x: 6, boxShadow: `0 8px 30px ${color}20` }}
                    className="flex items-center gap-5 p-5 rounded-2xl bg-white/60 border border-white/40 cursor-pointer transition-all duration-300 hover:bg-white"
                  >
                    <div className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0" style={{ background: `${color}15` }}>
                      <Icon size={22} style={{ color }} />
                    </div>
                    <div>
                      <p className="text-xs font-bold text-foreground/50 uppercase tracking-wider">{label}</p>
                      <p className="font-bold text-foreground">{value}</p>
                    </div>
                  </motion.a>
                ))}
              </div>

              {/* WhatsApp CTA */}
              <motion.a
                href="https://wa.me/919591144949"
                target="_blank"
                rel="noopener noreferrer"
                whileHover={{ scale: 1.03, boxShadow: '0 0 40px rgba(37,211,102,0.45)' }}
                whileTap={{ scale: 0.97 }}
                className="w-full flex items-center justify-center gap-3 py-5 rounded-2xl text-white text-lg font-black"
                style={{ background: 'linear-gradient(135deg,#25D366,#1da851)' }}
              >
                <MessageCircle size={24} /> Chat on WhatsApp
              </motion.a>

              {/* Map placeholder */}
              <div className="glass-card rounded-3xl overflow-hidden">
                <div className="h-48 bg-gradient-to-br from-primary/10 to-accent/10 flex items-center justify-center">
                  <div className="text-center">
                    <MapPin size={40} className="text-primary mx-auto mb-2" />
                    <p className="font-bold text-primary">Nagarbhavi, Bangalore</p>
                    <p className="text-sm text-foreground/60">Karnataka – 560072</p>
                  </div>
                </div>
              </div>
            </div>
          </Reveal>
        </div>
      </SectionShell>

      <Footer />
    </main>
  )
}
