'use client'
import { Suspense } from 'react'
import { useSearchParams } from 'next/navigation'
import Link from 'next/link'

function SuccessContent() {
  const searchParams = useSearchParams()
  const id   = searchParams.get('id')
  const cert = searchParams.get('cert')
  const name = searchParams.get('name') || ''

  return (
    <div style={{
      minHeight: '100vh',
      background: 'linear-gradient(135deg, #FAFAFA 0%, #F8F6F0 50%, #F1F5F9 100%)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: '24px',
      position: 'relative',
      overflow: 'hidden',
    }}>
      {/* Background decoration */}
      <div aria-hidden style={{ position: 'absolute', inset: 0, pointerEvents: 'none' }}>
        <div style={{
          position: 'absolute', top: '-80px', right: '-80px',
          width: 400, height: 400, borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(34,197,94,0.08) 0%, transparent 70%)',
        }} />
        <div style={{
          position: 'absolute', bottom: '-80px', left: '-80px',
          width: 350, height: 350, borderRadius: '50%',
          background: 'radial-gradient(circle, rgba(245,194,24,0.08) 0%, transparent 70%)',
        }} />
      </div>

      <div style={{
        position: 'relative', maxWidth: 520, width: '100%',
        animation: 'fadeInUp 0.5s ease',
      }}>
        {/* Logo */}
        <div style={{ textAlign: 'center', marginBottom: 28 }}>
          <div style={{
            display: 'inline-flex', alignItems: 'center', gap: 9,
            padding: '7px 16px',
            background: '#fff', border: '1px solid #E2E8F0',
            borderRadius: 100,
            boxShadow: '0 2px 8px rgba(0,0,0,0.06)',
          }}>
            <div style={{
              width: 24, height: 24, borderRadius: 6,
              background: 'linear-gradient(135deg,#F5C218,#D4A81A)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              fontSize: 9, fontWeight: 900, color: '#0A0F1E',
            }}>TB</div>
            <span style={{ fontSize: 13, fontWeight: 800, color: '#0A0F1E' }}>TECHBES</span>
          </div>
        </div>

        {/* Success card */}
        <div style={{
          background: '#FFFFFF',
          borderRadius: 24,
          boxShadow: '0 20px 60px rgba(0,0,0,0.08), 0 4px 16px rgba(0,0,0,0.04)',
          border: '1px solid #E2E8F0',
          overflow: 'hidden',
        }}>
          {/* Green header */}
          <div style={{
            background: 'linear-gradient(135deg, rgba(34,197,94,0.08) 0%, rgba(34,197,94,0.03) 100%)',
            borderBottom: '1px solid rgba(34,197,94,0.12)',
            padding: '32px 28px 28px',
            textAlign: 'center',
          }}>
            {/* Check icon */}
            <div style={{
              width: 68, height: 68,
              borderRadius: '50%',
              background: 'rgba(34,197,94,0.1)',
              border: '2px solid rgba(34,197,94,0.25)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              margin: '0 auto 16px',
            }}>
              <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="#16A34A" strokeWidth="2.5">
                <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
              </svg>
            </div>
            <h1 style={{
              fontSize: 'clamp(1.4rem, 3vw, 1.8rem)',
              fontWeight: 900, color: '#0A0F1E', margin: '0 0 8px',
              letterSpacing: '-0.025em',
            }}>
              REGISTRATION SUCCESSFUL
            </h1>
            <p style={{ fontSize: 14, color: '#64748B', margin: 0 }}>
              You're in! Your seat for the TECHBES CCTV Masterclass is reserved.
            </p>
          </div>

          {/* Details */}
          <div style={{ padding: '24px 28px' }}>
            {/* Enrollment ID + paid badge */}
            <div style={{
              display: 'flex', alignItems: 'center', justifyContent: 'space-between',
              background: '#F8FAFC',
              border: '1px solid #E2E8F0',
              borderRadius: 12,
              padding: '14px 18px',
              marginBottom: 20,
              flexWrap: 'wrap', gap: 10,
            }}>
              <div>
                <div style={{ fontSize: 10.5, fontWeight: 700, color: '#94A3B8', textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: 4 }}>
                  Enrollment ID
                </div>
                <code style={{ fontSize: 15, fontWeight: 800, color: '#F5C218', fontFamily: 'monospace', letterSpacing: '0.02em' }}>
                  {id || 'TB-CCTV-XXXXXX'}
                </code>
              </div>
              <div style={{
                background: 'rgba(34,197,94,0.1)',
                border: '1px solid rgba(34,197,94,0.2)',
                borderRadius: 100,
                padding: '5px 14px',
                fontSize: 12, fontWeight: 800, color: '#16A34A',
                letterSpacing: '0.04em',
              }}>
                ₹499 PAID ✓
              </div>
            </div>

            {/* Details list */}
            {[
              { icon: '👤', label: 'Registered As', value: name || 'Participant' },
              { icon: '📋', label: 'Course', value: 'CCTV Masterclass' },
              { icon: '💳', label: 'Amount Paid', value: '₹499' },
              { icon: '✅', label: 'Payment Status', value: 'PAID', green: true },
            ].map(({ icon, label, value, green }) => (
              <div key={label} style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                padding: '11px 0',
                borderBottom: '1px solid #F1F5F9',
              }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 9 }}>
                  <span style={{ fontSize: 15 }}>{icon}</span>
                  <span style={{ fontSize: 13, color: '#64748B', fontWeight: 600 }}>{label}</span>
                </div>
                <span style={{
                  fontSize: 13.5, fontWeight: 800,
                  color: green ? '#16A34A' : '#0A0F1E',
                }}>{value}</span>
              </div>
            ))}

            {/* What's next */}
            <div style={{
              background: 'rgba(245,194,24,0.05)',
              border: '1px solid rgba(245,194,24,0.18)',
              borderRadius: 12,
              padding: '16px',
              marginTop: 20, marginBottom: 24,
            }}>
              <div style={{ fontSize: 11, fontWeight: 800, color: '#D4A81A', letterSpacing: '0.12em', textTransform: 'uppercase', marginBottom: 10 }}>
                What Happens Next
              </div>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {[
                  '📧 Check your email for session details and confirmation',
                  '📱 You will be added to the TECHBES CCTV Masterclass WhatsApp group',
                  '🎓 Your e-certificate will be issued after the session',
                  '🔔 Log in 10 minutes early on the session day',
                ].map(item => (
                  <div key={item} style={{ fontSize: 12.5, color: '#475569', lineHeight: 1.5 }}>{item}</div>
                ))}
              </div>
            </div>

            {/* Certificate link */}
            {cert && (
              <div style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                background: 'rgba(14,165,233,0.05)',
                border: '1px solid rgba(14,165,233,0.18)',
                borderRadius: 12, padding: '14px 16px',
                marginBottom: 20, flexWrap: 'wrap', gap: 8,
              }}>
                <div>
                  <div style={{ fontSize: 12.5, fontWeight: 800, color: '#0EA5E9' }}>Certificate Pre-Allocated</div>
                  <div style={{ fontSize: 11.5, color: '#64748B', marginTop: 2 }}>Verify your certificate after the session</div>
                </div>
                <Link
                  href={`/certificate/${cert}`}
                  style={{
                    fontSize: 12.5, fontWeight: 800, color: '#0EA5E9',
                    textDecoration: 'underline', textUnderlineOffset: 3,
                  }}
                >
                  View Certificate →
                </Link>
              </div>
            )}

            {/* Done button */}
            <Link href="/">
              <button
                id="success-done-btn"
                style={{
                  width: '100%', padding: '16px',
                  borderRadius: 12, border: 'none',
                  background: 'linear-gradient(135deg,#F5C218,#D4A81A)',
                  color: '#0A0F1E', fontWeight: 900,
                  fontSize: '1rem', letterSpacing: '0.04em',
                  cursor: 'pointer',
                  transition: 'all 0.2s',
                }}
                onMouseEnter={e => (e.currentTarget.style.opacity = '0.9')}
                onMouseLeave={e => (e.currentTarget.style.opacity = '1')}
              >
                DONE — Back to Home
              </button>
            </Link>
          </div>
        </div>

        <p style={{ textAlign: 'center', fontSize: 12, color: '#94A3B8', marginTop: 20 }}>
          Questions? Email us at <a href="mailto:viswaatechbes@gmail.com" style={{ color: '#F5C218' }}>viswaatechbes@gmail.com</a>
        </p>
      </div>

      <style>{`
        @keyframes fadeInUp {
          from { opacity: 0; transform: translateY(24px); }
          to { opacity: 1; transform: translateY(0); }
        }
      `}</style>
    </div>
  )
}

export default function SuccessPage() {
  return (
    <Suspense fallback={
      <div style={{
        minHeight: '100vh', background: '#FAFAFA',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <div style={{
          width: 36, height: 36,
          border: '3px solid rgba(245,194,24,0.2)',
          borderTop: '3px solid #F5C218',
          borderRadius: '50%',
          animation: 'spin 0.8s linear infinite',
        }} />
      </div>
    }>
      <SuccessContent />
    </Suspense>
  )
}
