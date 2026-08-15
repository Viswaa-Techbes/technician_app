'use client'

import { useState } from 'react'
import Image from 'next/image'
import RegistrationModal from './RegistrationModal'

export default function HeroSection() {
  const [modalOpen, setModalOpen] = useState(false)

  return (
    <>
      <div style={{
        minHeight: '100vh',
        background: '#FAFAFA',
        display: 'flex',
        flexDirection: 'column',
        position: 'relative',
        overflow: 'hidden',
      }}>
        {/* ── Subtle background texture ── */}
        <div aria-hidden style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
          {/* Large gold radial top-right */}
          <div style={{
            position: 'absolute', top: -160, right: -100,
            width: 600, height: 600, borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(245,194,24,0.07) 0%, transparent 65%)',
          }} />
          {/* Blue accent bottom-left */}
          <div style={{
            position: 'absolute', bottom: -100, left: -60,
            width: 450, height: 450, borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(14,165,233,0.06) 0%, transparent 65%)',
          }} />
          {/* Subtle dot grid */}
          <div style={{
            position: 'absolute', inset: 0,
            backgroundImage: 'radial-gradient(circle, rgba(14,165,233,0.06) 1px, transparent 1px)',
            backgroundSize: '32px 32px',
            opacity: 0.7,
          }} />
        </div>

        {/* ── NAVBAR ── */}
        <header style={{
          position: 'relative', zIndex: 20,
          padding: '0 5%',
          height: 68,
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          borderBottom: '1px solid rgba(0,0,0,0.06)',
          background: 'rgba(250,250,250,0.9)',
          backdropFilter: 'blur(10px)',
        }}>
          {/* Real TECHBES logo */}
          <div style={{ display: 'flex', alignItems: 'center' }}>
            <Image
              src="/images/techbes-logo.png"
              alt="TECHBES"
              width={160}
              height={52}
              priority
              style={{ objectFit: 'contain', height: 44, width: 'auto' }}
            />
          </div>

          <button
            id="hero-register-top"
            onClick={() => setModalOpen(true)}
            className="btn-red"
            style={{
              padding: '10px 22px',
              fontSize: '0.85rem',
              whiteSpace: 'nowrap',
            }}
          >
            Register — ₹499
          </button>
        </header>

        {/* ── HERO BODY ── */}
        <main
          className="hero-main-container"
          style={{
            flex: 1,
            display: 'flex',
            alignItems: 'center',
            padding: '0 5%',
            position: 'relative',
            zIndex: 5,
            maxWidth: 1320,
            margin: '0 auto',
            width: '100%',
            gap: '4%',
          }}
        >
          {/* ════════════════════════════
              LEFT — Sales copy
          ════════════════════════════ */}
          <div className="hero-left-col" style={{ flex: '0 0 50%', maxWidth: 560 }}>

            {/* Live badge */}
            <div style={{
              display: 'inline-flex',
              alignItems: 'center',
              gap: 8,
              background: 'rgba(220,38,38,0.07)',
              border: '1px solid rgba(220,38,38,0.2)',
              borderRadius: 100,
              padding: '5px 14px',
              marginBottom: 22,
            }}>
              <span style={{
                width: 7, height: 7, borderRadius: '50%',
                background: '#DC2626',
                boxShadow: '0 0 0 3px rgba(220,38,38,0.2)',
                display: 'inline-block',
                animation: 'pulseDot 2s infinite',
                flexShrink: 0,
              }} />
              <span style={{ fontSize: 11, fontWeight: 800, color: '#B91C1C', letterSpacing: '0.14em', textTransform: 'uppercase' }}>
                Live &amp; Practical — Special Launch Offer
              </span>
            </div>

            {/* Heading */}
            <h1 style={{
              fontSize: 'clamp(3rem, 5.5vw, 5.2rem)',
              fontWeight: 900,
              lineHeight: 0.95,
              color: '#0A0F1E',
              letterSpacing: '-0.04em',
              margin: '0 0 8px 0',
            }}>
              CCTV
            </h1>
            <h1 style={{
              fontSize: 'clamp(3rem, 5.5vw, 5.2rem)',
              fontWeight: 900,
              lineHeight: 0.95,
              letterSpacing: '-0.04em',
              margin: '0 0 22px 0',
            }}>
              <span style={{ color: '#0A0F1E' }}>MASTER</span>
              <span style={{
                background: 'linear-gradient(135deg, #F5C218 0%, #D4A81A 100%)',
                WebkitBackgroundClip: 'text',
                WebkitTextFillColor: 'transparent',
                backgroundClip: 'text',
              }}>CLASS</span>
            </h1>

            {/* Tagline */}
            <p style={{
              fontSize: 11,
              fontWeight: 800,
              letterSpacing: '0.22em',
              textTransform: 'uppercase',
              color: '#0EA5E9',
              marginBottom: 18,
            }}>
              LEARN. PRACTICE. BUILD YOUR CAREER.
            </p>

            {/* Description */}
            <p style={{
              fontSize: 'clamp(0.875rem, 1.15vw, 1rem)',
              color: '#475569',
              lineHeight: 1.7,
              maxWidth: 460,
              marginBottom: 30,
            }}>
              Learn CCTV Installation, IP Networking, NVR Configuration, Mobile
              Viewing and Troubleshooting through a{' '}
              <strong style={{ color: '#0A0F1E', fontWeight: 700 }}>live practical masterclass</strong>{' '}
              from industry experts with 10+ years experience.
            </p>

            {/* Pricing block */}
            <div style={{
              display: 'flex',
              alignItems: 'flex-end',
              gap: 16,
              marginBottom: 28,
            }}>
              <div style={{
                fontSize: 'clamp(2.4rem, 4vw, 3.4rem)',
                fontWeight: 900,
                color: '#DC2626',
                letterSpacing: '-0.04em',
                lineHeight: 1,
              }}>₹499</div>
              <div style={{ marginBottom: 4 }}>
                <div style={{
                  fontSize: 14,
                  color: '#94A3B8',
                  textDecoration: 'line-through',
                  fontWeight: 600,
                  marginBottom: 4,
                }}>₹999</div>
                <div style={{
                  display: 'inline-flex',
                  alignItems: 'center',
                  gap: 5,
                  background: '#DC2626',
                  color: '#fff',
                  fontSize: 10,
                  fontWeight: 800,
                  letterSpacing: '0.12em',
                  textTransform: 'uppercase',
                  borderRadius: 5,
                  padding: '3px 9px',
                }}>
                  50% OFF — Today Only
                </div>
              </div>
            </div>

            {/* CTA Button */}
            <button
              id="hero-register-main"
              onClick={() => setModalOpen(true)}
              className="btn-red"
              style={{
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 10,
                width: '100%',
                maxWidth: 400,
                padding: '18px 28px',
                borderRadius: 12,
                fontSize: '1rem',
                fontWeight: 900,
                letterSpacing: '0.04em',
              }}
            >
              REGISTER NOW — ₹499
              <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5-5 5M6 12h12" />
              </svg>
            </button>

            {/* Trust points */}
            <div style={{
              display: 'flex',
              gap: 20,
              marginTop: 20,
              flexWrap: 'wrap',
            }}>
              {[
                'Live Practical Session',
                'Industry Experts',
                'E-Certificate',
              ].map(tp => (
                <div key={tp} style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                  <svg width="16" height="16" viewBox="0 0 20 20" fill="none">
                    <circle cx="10" cy="10" r="10" fill="rgba(34,197,94,0.12)" />
                    <path d="M6 10l3 3 5-5" stroke="#16A34A" strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round" />
                  </svg>
                  <span style={{ fontSize: 12.5, fontWeight: 600, color: '#475569' }}>{tp}</span>
                </div>
              ))}
            </div>
          </div>

          {/* ════════════════════════════
              RIGHT — CCTV Visual
          ════════════════════════════ */}
          <div
            className="hero-right-col"
            style={{
              flex: '0 0 46%',
              position: 'relative',
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              minHeight: 480,
            }}
          >
            {/* Large ambient glow behind image */}
            <div style={{
              position: 'absolute',
              inset: '10% 5%',
              borderRadius: '50%',
              background: 'radial-gradient(ellipse at center, rgba(245,194,24,0.14) 0%, rgba(14,165,233,0.08) 50%, transparent 75%)',
              filter: 'blur(40px)',
              pointerEvents: 'none',
            }} />

            {/* ── Main CCTV composition image ── */}
            <div style={{ position: 'relative', width: '100%', maxWidth: 560, overflow: 'visible' }}>
              <Image
                src="/images/cctv-composition.jpg"
                alt="CCTV cameras and NVR installation setup"
                width={1040}
                height={780}
                priority
                style={{
                  width: '100%',
                  height: 'auto',
                  display: 'block',
                  objectFit: 'contain',
                  position: 'relative',
                  zIndex: 1,
                }}
              />

              {/* ── Floating badge: 2 HOURS LIVE ── */}
              <div style={{
                position: 'absolute',
                top: '6%',
                right: '-8px',
                background: '#0A0F1E',
                color: '#fff',
                borderRadius: 10,
                padding: '9px 15px',
                display: 'flex',
                alignItems: 'center',
                gap: 7,
                boxShadow: '0 8px 24px rgba(0,0,0,0.18)',
                animation: 'floatBadge 3s ease-in-out infinite',
                zIndex: 2,
              }}>
                <span style={{
                  width: 7, height: 7, borderRadius: '50%',
                  background: '#DC2626',
                  boxShadow: '0 0 8px #DC2626',
                  display: 'inline-block',
                  flexShrink: 0,
                  animation: 'pulseDot 1.5s infinite',
                }} />
                <div>
                  <div style={{ fontSize: 10, fontWeight: 800, letterSpacing: '0.1em', textTransform: 'uppercase' }}>Live Session</div>
                  <div style={{ fontSize: 12, fontWeight: 900, color: '#F5C218', letterSpacing: '-0.01em' }}>2 HOURS</div>
                </div>
              </div>

              {/* ── Floating badge: IP Networking ── */}
              <div style={{
                position: 'absolute',
                bottom: '22%',
                left: '-12px',
                background: '#fff',
                border: '1px solid rgba(14,165,233,0.2)',
                borderRadius: 10,
                padding: '9px 15px',
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                boxShadow: '0 8px 24px rgba(0,0,0,0.08)',
                animation: 'floatBadge 3.5s ease-in-out infinite 0.8s',
                zIndex: 2,
              }}>
                <div style={{
                  width: 30, height: 30, borderRadius: 8,
                  background: 'rgba(14,165,233,0.1)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}>
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#0EA5E9" strokeWidth="2">
                    <circle cx="12" cy="5" r="3" /><circle cx="5" cy="19" r="3" /><circle cx="19" cy="19" r="3" />
                    <line x1="12" y1="8" x2="5" y2="16" /><line x1="12" y1="8" x2="19" y2="16" />
                  </svg>
                </div>
                <div>
                  <div style={{ fontSize: 11, fontWeight: 800, color: '#0A0F1E' }}>IP Networking</div>
                  <div style={{ fontSize: 10, color: '#64748B' }}>PoE Switch + NVR</div>
                </div>
              </div>

              {/* ── Floating badge: E-Certificate ── */}
              <div style={{
                position: 'absolute',
                bottom: '4%',
                right: '4%',
                background: '#fff',
                border: '1px solid rgba(245,194,24,0.25)',
                borderRadius: 10,
                padding: '9px 15px',
                display: 'flex',
                alignItems: 'center',
                gap: 8,
                boxShadow: '0 8px 24px rgba(0,0,0,0.08)',
                animation: 'floatBadge 4s ease-in-out infinite 1.6s',
                zIndex: 2,
              }}>
                <div style={{
                  width: 30, height: 30, borderRadius: 8,
                  background: 'rgba(245,194,24,0.1)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  flexShrink: 0,
                }}>
                  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="#D4A81A" strokeWidth="2">
                    <circle cx="12" cy="8" r="4" />
                    <path d="M8 14l-2 7 6-3 6 3-2-7" />
                  </svg>
                </div>
                <div>
                  <div style={{ fontSize: 11, fontWeight: 800, color: '#0A0F1E' }}>E-Certificate</div>
                  <div style={{ fontSize: 10, color: '#64748B' }}>Included</div>
                </div>
              </div>
            </div>
          </div>
        </main>

        {/* ── Footer strip ── */}
        <footer style={{
          position: 'relative', zIndex: 5,
          padding: '14px 5%',
          borderTop: '1px solid rgba(0,0,0,0.06)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          gap: 28,
          flexWrap: 'wrap',
        }}>
          {[
            { icon: '🔒', text: 'Secure Payment via Razorpay' },
            { icon: '📱', text: 'Online Live Session' },
            { icon: '🇮🇳', text: 'Open Across India' },
          ].map(({ icon, text }) => (
            <div key={text} style={{ display: 'flex', alignItems: 'center', gap: 7, fontSize: 12.5, color: '#64748B' }}>
              <span>{icon}</span>
              <span style={{ fontWeight: 600 }}>{text}</span>
            </div>
          ))}
        </footer>
      </div>

      {/* Registration Modal */}
      {modalOpen && <RegistrationModal onClose={() => setModalOpen(false)} />}
    </>
  )
}
