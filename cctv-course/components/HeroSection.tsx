'use client'

import { useState } from 'react'
import RegistrationModal from './RegistrationModal'

export default function HeroSection() {
  const [modalOpen, setModalOpen] = useState(false)

  return (
    <>
      {/* ── Page wrapper — full viewport height ── */}
      <div
        style={{
          minHeight: '100vh',
          background: 'linear-gradient(135deg, #FAFAFA 0%, #F8F6F0 50%, #F1F5F9 100%)',
          display: 'flex',
          flexDirection: 'column',
          position: 'relative',
          overflow: 'hidden',
        }}
      >
        {/* ── Decorative background shapes ── */}
        <div aria-hidden style={{
          position: 'absolute', inset: 0, pointerEvents: 'none', overflow: 'hidden',
        }}>
          {/* Top-right gold circle */}
          <div style={{
            position: 'absolute', top: '-120px', right: '-120px',
            width: 500, height: 500, borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(245,194,24,0.10) 0%, transparent 70%)',
          }} />
          {/* Bottom-left blue accent */}
          <div style={{
            position: 'absolute', bottom: '-80px', left: '-80px',
            width: 380, height: 380, borderRadius: '50%',
            background: 'radial-gradient(circle, rgba(14,165,233,0.07) 0%, transparent 70%)',
          }} />
          {/* Dot grid */}
          <div className="tech-dot-bg" style={{ position: 'absolute', inset: 0, opacity: 0.6 }} />
        </div>

        {/* ── Top bar (minimal logo) ── */}
        <header style={{
          position: 'relative', zIndex: 10,
          padding: '18px 5%',
          display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          borderBottom: '1px solid rgba(0,0,0,0.05)',
          background: 'rgba(250,250,250,0.8)',
          backdropFilter: 'blur(8px)',
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{
              width: 34, height: 34, borderRadius: 9,
              background: 'linear-gradient(135deg,#F5C218,#D4A81A)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 12, fontWeight: 800, color: '#0A0F1E',
              boxShadow: '0 2px 8px rgba(245,194,24,0.3)',
            }}>TB</div>
            <div>
              <div style={{ fontSize: 15, fontWeight: 800, color: '#0A0F1E', letterSpacing: '-0.3px' }}>TECHBES</div>
              <div style={{ fontSize: 9.5, color: '#94A3B8', letterSpacing: '0.8px', textTransform: 'uppercase', marginTop: -1 }}>Technology Services</div>
            </div>
          </div>
          <button
            id="hero-register-top"
            onClick={() => setModalOpen(true)}
            style={{
              padding: '9px 20px', borderRadius: 8,
              background: '#DC2626', color: 'white',
              fontWeight: 700, fontSize: 13, border: 'none',
              cursor: 'pointer', letterSpacing: '0.02em',
              transition: 'all 0.2s',
            }}
            onMouseEnter={e => (e.currentTarget.style.background = '#B91C1C')}
            onMouseLeave={e => (e.currentTarget.style.background = '#DC2626')}
          >
            Register — ₹499
          </button>
        </header>

        {/* ── Hero content ── */}
        <main style={{
          flex: 1, display: 'flex', alignItems: 'center',
          padding: '2% 5%',
          position: 'relative', zIndex: 5,
          maxWidth: 1320, margin: '0 auto', width: '100%',
        }}>
          <div style={{
            display: 'grid',
            gridTemplateColumns: '1fr 1fr',
            gap: '4%',
            alignItems: 'center',
            width: '100%',
          }}
          className="hero-grid"
          >
            {/* ════ LEFT — Copy ════ */}
            <div>
              {/* Badge */}
              <div style={{
                display: 'inline-flex', alignItems: 'center', gap: 7,
                background: 'rgba(245,194,24,0.12)',
                border: '1px solid rgba(245,194,24,0.3)',
                borderRadius: 100,
                padding: '5px 14px',
                marginBottom: 20,
              }}>
                <span style={{
                  width: 7, height: 7, borderRadius: '50%',
                  background: '#F5C218',
                  boxShadow: '0 0 8px #F5C218',
                  animation: 'pulse-dot 2s infinite',
                  display: 'inline-block',
                }} />
                <span style={{ fontSize: 11, fontWeight: 800, color: '#D4A81A', letterSpacing: '0.15em', textTransform: 'uppercase' }}>
                  Live &amp; Practical
                </span>
              </div>

              {/* Main heading */}
              <h1 style={{
                fontSize: 'clamp(2.8rem, 5.5vw, 5rem)',
                fontWeight: 900,
                lineHeight: 1.0,
                color: '#0A0F1E',
                letterSpacing: '-0.03em',
                margin: '0 0 6px 0',
              }}>
                CCTV
              </h1>
              <h1 style={{
                fontSize: 'clamp(2.8rem, 5.5vw, 5rem)',
                fontWeight: 900,
                lineHeight: 1.0,
                color: '#0A0F1E',
                letterSpacing: '-0.03em',
                margin: '0 0 20px 0',
                position: 'relative',
              }}>
                MASTER
                <span style={{
                  background: 'linear-gradient(135deg,#F5C218,#D4A81A)',
                  WebkitBackgroundClip: 'text',
                  WebkitTextFillColor: 'transparent',
                  backgroundClip: 'text',
                }}>CLASS</span>
              </h1>

              {/* Tagline */}
              <p style={{
                fontSize: '0.875rem',
                fontWeight: 800,
                letterSpacing: '0.18em',
                textTransform: 'uppercase',
                color: '#0EA5E9',
                marginBottom: 14,
              }}>
                LEARN. PRACTICE. BUILD YOUR CAREER.
              </p>

              {/* Description */}
              <p style={{
                fontSize: 'clamp(0.875rem, 1.2vw, 1rem)',
                color: '#475569',
                lineHeight: 1.65,
                maxWidth: 480,
                marginBottom: 28,
              }}>
                Learn CCTV Installation, IP Networking, NVR Configuration, Mobile Viewing and
                Troubleshooting through a <strong style={{ color: '#0A0F1E' }}>live practical masterclass</strong> from industry experts.
              </p>

              {/* Pricing */}
              <div style={{
                display: 'flex', alignItems: 'flex-end', gap: 14,
                marginBottom: 10,
              }}>
                <div style={{
                  fontSize: 'clamp(2rem, 3.5vw, 3rem)',
                  fontWeight: 900,
                  color: '#DC2626',
                  letterSpacing: '-0.03em',
                  lineHeight: 1,
                }}>₹499</div>
                <div>
                  <div style={{ fontSize: '1rem', color: '#94A3B8', textDecoration: 'line-through', fontWeight: 600 }}>₹999</div>
                  <div style={{
                    fontSize: '0.7rem', fontWeight: 800,
                    color: '#DC2626', letterSpacing: '0.12em',
                    textTransform: 'uppercase',
                    background: 'rgba(220,38,38,0.08)',
                    border: '1px solid rgba(220,38,38,0.2)',
                    borderRadius: 4,
                    padding: '2px 7px',
                    display: 'inline-block',
                    marginTop: 3,
                  }}>Special Launch Offer</div>
                </div>
              </div>

              {/* CTA */}
              <button
                id="hero-register-main"
                onClick={() => setModalOpen(true)}
                className="btn-red glow-red"
                style={{
                  width: '100%', maxWidth: 380,
                  padding: '17px 24px',
                  fontSize: '1rem',
                  borderRadius: 12,
                  marginTop: 8,
                  letterSpacing: '0.04em',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  gap: 10,
                  fontWeight: 900,
                }}
              >
                REGISTER NOW — ₹499
                <svg width="18" height="18" fill="none" viewBox="0 0 24 24" stroke="currentColor" strokeWidth={2.5}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M13 7l5 5-5 5M6 12h12" />
                </svg>
              </button>

              {/* Trust points */}
              <div style={{
                display: 'flex', gap: 20, marginTop: 18, flexWrap: 'wrap',
              }}>
                {['Live Practical Session', 'Industry Experts', 'E-Certificate'].map(tp => (
                  <div key={tp} style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                    <svg width="15" height="15" viewBox="0 0 20 20" fill="none">
                      <circle cx="10" cy="10" r="10" fill="rgba(34,197,94,0.12)" />
                      <path d="M6 10l3 3 5-5" stroke="#16A34A" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
                    </svg>
                    <span style={{ fontSize: 12.5, fontWeight: 600, color: '#475569' }}>{tp}</span>
                  </div>
                ))}
              </div>
            </div>

            {/* ════ RIGHT — Visual ════ */}
            <div style={{
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              position: 'relative',
            }}>
              {/* Glow plate behind image */}
              <div style={{
                position: 'absolute',
                width: '85%', height: '85%',
                borderRadius: '50%',
                background: 'radial-gradient(ellipse, rgba(245,194,24,0.12) 0%, rgba(14,165,233,0.07) 60%, transparent 100%)',
                filter: 'blur(30px)',
              }} />

              {/* Main CCTV visual card */}
              <div style={{
                position: 'relative',
                background: 'rgba(255,255,255,0.7)',
                border: '1px solid rgba(245,194,24,0.25)',
                borderRadius: 24,
                padding: '28px 28px 22px',
                boxShadow: '0 20px 60px rgba(0,0,0,0.10), 0 4px 20px rgba(245,194,24,0.12)',
                backdropFilter: 'blur(10px)',
                maxWidth: 480,
                width: '100%',
              }}>
                {/* TECHBES brand inside card */}
                <div style={{
                  display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
                  marginBottom: 16,
                }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 7 }}>
                    <div style={{
                      width: 26, height: 26, borderRadius: 7,
                      background: 'linear-gradient(135deg,#F5C218,#D4A81A)',
                      display: 'flex', alignItems: 'center', justifyContent: 'center',
                      fontSize: 9, fontWeight: 900, color: '#0A0F1E',
                    }}>TB</div>
                    <span style={{ fontSize: 12, fontWeight: 800, color: '#0A0F1E', letterSpacing: '-0.2px' }}>TECHBES®</span>
                  </div>
                  {/* LIVE badge */}
                  <div style={{
                    display: 'flex', alignItems: 'center', gap: 5,
                    background: '#DC2626', color: '#fff',
                    borderRadius: 100,
                    padding: '4px 10px',
                    fontSize: 10, fontWeight: 800, letterSpacing: '0.1em',
                  }}>
                    <span style={{
                      width: 5, height: 5, borderRadius: '50%',
                      background: '#fff', display: 'inline-block',
                      animation: 'pulse-dot 1.5s infinite',
                    }} />
                    LIVE
                  </div>
                </div>

                {/* CCTV visual illustration */}
                <div style={{
                  background: 'linear-gradient(145deg, #0A0F1E 0%, #1E293B 60%, #0EA5E9 200%)',
                  borderRadius: 16,
                  padding: '24px',
                  marginBottom: 18,
                  position: 'relative',
                  overflow: 'hidden',
                  minHeight: 190,
                }}>
                  {/* Circuit-like decorative lines */}
                  <svg style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', opacity: 0.15 }} viewBox="0 0 400 200" fill="none">
                    <line x1="0" y1="100" x2="400" y2="100" stroke="#0EA5E9" strokeWidth="1" strokeDasharray="8 6" />
                    <line x1="200" y1="0" x2="200" y2="200" stroke="#0EA5E9" strokeWidth="1" strokeDasharray="8 6" />
                    <circle cx="200" cy="100" r="60" stroke="#F5C218" strokeWidth="0.8" />
                    <circle cx="200" cy="100" r="100" stroke="#F5C218" strokeWidth="0.4" />
                  </svg>

                  {/* Camera icons arrangement */}
                  <div style={{ display: 'flex', alignItems: 'flex-end', justifyContent: 'space-around', position: 'relative', zIndex: 2, height: '100%' }}>
                    {/* Dome camera */}
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                      <div style={{
                        width: 56, height: 56, borderRadius: '50%',
                        background: 'linear-gradient(145deg, #E2E8F0, #CBD5E1)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        boxShadow: '0 4px 20px rgba(0,0,0,0.4), 0 0 20px rgba(245,194,24,0.2)',
                        border: '2px solid rgba(255,255,255,0.15)',
                        position: 'relative',
                      }}>
                        <CameraIcon />
                        <div style={{
                          position: 'absolute', bottom: -2, left: '50%', transform: 'translateX(-50%)',
                          width: 8, height: 8, borderRadius: '50%',
                          background: '#F5C218',
                          boxShadow: '0 0 8px #F5C218',
                        }} />
                      </div>
                      <span style={{ fontSize: 9, color: 'rgba(255,255,255,0.5)', fontWeight: 600, letterSpacing: '0.05em' }}>DOME</span>
                    </div>

                    {/* NVR box (center) */}
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                      <div style={{
                        background: 'linear-gradient(135deg, #1E293B, #0F172A)',
                        border: '1px solid rgba(14,165,233,0.4)',
                        borderRadius: 10,
                        padding: '10px 16px',
                        boxShadow: '0 0 24px rgba(14,165,233,0.2)',
                        position: 'relative',
                      }}>
                        <div style={{ fontSize: 9, color: '#0EA5E9', fontWeight: 800, letterSpacing: '0.12em', marginBottom: 5 }}>NVR</div>
                        <div style={{ display: 'flex', gap: 4 }}>
                          <div style={{ width: 6, height: 6, borderRadius: 2, background: '#22C55E', boxShadow: '0 0 6px #22C55E' }} />
                          <div style={{ width: 6, height: 6, borderRadius: 2, background: '#F5C218', boxShadow: '0 0 6px #F5C218' }} />
                          <div style={{ width: 6, height: 6, borderRadius: 2, background: '#94A3B8' }} />
                        </div>
                        <div style={{
                          fontSize: 7, color: 'rgba(255,255,255,0.3)', marginTop: 4, letterSpacing: '0.04em',
                          display: 'flex', gap: 6,
                        }}>
                          <span>PWR</span><span>HDD</span><span>NET</span>
                        </div>
                      </div>
                      <span style={{ fontSize: 9, color: 'rgba(255,255,255,0.5)', fontWeight: 600, letterSpacing: '0.05em' }}>NVR / HDD</span>
                    </div>

                    {/* Bullet camera */}
                    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                      <div style={{
                        width: 52, height: 52, borderRadius: 10,
                        background: 'linear-gradient(145deg, #E2E8F0, #CBD5E1)',
                        display: 'flex', alignItems: 'center', justifyContent: 'center',
                        boxShadow: '0 4px 20px rgba(0,0,0,0.4), 0 0 20px rgba(14,165,233,0.15)',
                        border: '2px solid rgba(255,255,255,0.15)',
                        transform: 'rotate(-15deg)',
                      }}>
                        <BulletCameraIcon />
                      </div>
                      <span style={{ fontSize: 9, color: 'rgba(255,255,255,0.5)', fontWeight: 600, letterSpacing: '0.05em' }}>BULLET</span>
                    </div>
                  </div>

                  {/* IP + PoE labels at bottom */}
                  <div style={{
                    position: 'absolute', bottom: 8, left: 0, right: 0,
                    display: 'flex', justifyContent: 'center', gap: 10, zIndex: 2,
                  }}>
                    {['IP CAMERA', 'PoE SWITCH', 'MOBILE VIEW'].map(l => (
                      <span key={l} style={{
                        fontSize: 8, fontWeight: 700, letterSpacing: '0.08em',
                        color: '#0EA5E9',
                        background: 'rgba(14,165,233,0.12)',
                        border: '1px solid rgba(14,165,233,0.25)',
                        borderRadius: 4, padding: '2px 7px',
                      }}>{l}</span>
                    ))}
                  </div>
                </div>

                {/* Info row below image */}
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                  <div style={{ display: 'flex', gap: 14 }}>
                    {[
                      { label: '2 HRS', sub: 'Duration' },
                      { label: 'LIVE', sub: 'Format' },
                    ].map(({ label, sub }) => (
                      <div key={label}>
                        <div style={{ fontSize: 15, fontWeight: 900, color: '#0A0F1E', letterSpacing: '-0.02em' }}>{label}</div>
                        <div style={{ fontSize: 10, color: '#94A3B8', fontWeight: 600 }}>{sub}</div>
                      </div>
                    ))}
                  </div>
                  <div style={{
                    background: 'linear-gradient(135deg,#F5C218,#D4A81A)',
                    color: '#0A0F1E', fontWeight: 900,
                    fontSize: 11, letterSpacing: '0.06em',
                    borderRadius: 8, padding: '7px 14px',
                    textTransform: 'uppercase',
                  }}>
                    Only ₹499
                  </div>
                </div>
              </div>

              {/* ── Floating badges ── */}
              {/* Top-right badge */}
              <div style={{
                position: 'absolute', top: -12, right: -12,
                background: '#0EA5E9', color: '#fff',
                borderRadius: 12,
                padding: '8px 14px',
                fontWeight: 800, fontSize: 12,
                letterSpacing: '0.04em',
                boxShadow: '0 4px 16px rgba(14,165,233,0.35)',
                transform: 'rotate(3deg)',
              }}>
                2 HOURS LIVE
              </div>

              {/* Bottom-left badge */}
              <div style={{
                position: 'absolute', bottom: 8, left: -18,
                background: '#fff',
                border: '1px solid rgba(34,197,94,0.25)',
                borderRadius: 12,
                padding: '8px 14px',
                boxShadow: '0 4px 20px rgba(0,0,0,0.08)',
                display: 'flex', alignItems: 'center', gap: 7,
              }}>
                <div style={{
                  width: 28, height: 28, borderRadius: 8,
                  background: 'rgba(34,197,94,0.1)',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                }}>
                  <svg width="14" height="14" viewBox="0 0 20 20" fill="none">
                    <path d="M10 2a8 8 0 100 16A8 8 0 0010 2zm0 14.5A6.5 6.5 0 1110 3.5 6.5 6.5 0 0110 16.5zm3-7.5H11V7a1 1 0 10-2 0v2H7a1 1 0 100 2h2v2a1 1 0 102 0v-2h2a1 1 0 100-2z" fill="#16A34A" />
                  </svg>
                </div>
                <div>
                  <div style={{ fontSize: 11, fontWeight: 800, color: '#0A0F1E', whiteSpace: 'nowrap' }}>E-Certificate</div>
                  <div style={{ fontSize: 9, color: '#94A3B8', fontWeight: 600 }}>Included</div>
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
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          gap: 24, flexWrap: 'wrap',
        }}>
          {[
            { icon: '🔒', text: 'Secure Payment via Razorpay' },
            { icon: '📱', text: 'Online Live Session' },
            { icon: '🎓', text: 'Open to All Students' },
          ].map(({ icon, text }) => (
            <div key={text} style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: '#64748B' }}>
              <span>{icon}</span>
              <span style={{ fontWeight: 600 }}>{text}</span>
            </div>
          ))}
        </footer>
      </div>

      {/* Registration Modal */}
      {modalOpen && (
        <RegistrationModal onClose={() => setModalOpen(false)} />
      )}

      {/* Keyframes */}
      <style>{`
        @keyframes pulse-dot {
          0%, 100% { opacity: 1; transform: scale(1); }
          50% { opacity: 0.5; transform: scale(0.85); }
        }
        @media (max-width: 768px) {
          .hero-grid {
            grid-template-columns: 1fr !important;
          }
        }
      `}</style>
    </>
  )
}

function CameraIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#334155" strokeWidth="1.5">
      <path d="M23 7l-7 5 7 5V7z" />
      <rect x="1" y="5" width="15" height="14" rx="2" ry="2" />
    </svg>
  )
}

function BulletCameraIcon() {
  return (
    <svg width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="#334155" strokeWidth="1.5">
      <circle cx="12" cy="12" r="3" />
      <path d="M2 12h4M18 12h4M12 2v4M12 18v4" />
      <circle cx="12" cy="12" r="8" />
    </svg>
  )
}
