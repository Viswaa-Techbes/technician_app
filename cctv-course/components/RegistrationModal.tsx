'use client'

import { useState, useCallback } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import { getApiBaseUrl, loadRazorpayScript } from '../lib/razorpay'

// ─── Zod Schema ───────────────────────────────────────────────────────────────
const schema = z.object({
  name: z.string().min(2, 'Full name must be at least 2 characters'),
  mobile: z
    .string()
    .regex(/^[6-9]\d{9}$/, 'Enter a valid 10-digit Indian mobile number'),
  email: z.string().email('Enter a valid email address'),
  location: z.string().min(2, 'Enter your location / area'),
  qualification: z.string().min(1, 'Please select your qualification'),
  whatsapp: z
    .string()
    .regex(/^[6-9]\d{9}$/, 'Enter a valid 10-digit WhatsApp number')
    .optional()
    .or(z.literal('')),
  agree: z.literal(true, { errorMap: () => ({ message: 'You must agree to receive updates' }) }),
})

type FormValues = z.infer<typeof schema>

const QUALIFICATIONS = ['10th', '12th', 'ITI', 'Diploma', 'BE', 'B.Tech', 'BCA', 'MCA', 'B.Sc', 'M.Sc', 'Other']

type ModalState = 'form' | 'initializing' | 'processing' | 'success' | 'failed'

interface SuccessData {
  registrationId: string
  enrollmentId: string
  name: string
  courseName: string
  amountPaid: number | string
  paymentStatus: string
  certificateId?: string
}

interface Props {
  onClose: () => void
}

declare global {
  interface Window {
    Razorpay: any
  }
}

export default function RegistrationModal({ onClose }: Props) {
  const [modalState, setModalState] = useState<ModalState>('form')
  const [successData, setSuccessData] = useState<SuccessData | null>(null)
  const [serverError, setServerError] = useState('')
  const [lastRegId, setLastRegId] = useState<string | null>(null)

  const {
    register,
    handleSubmit,
    formState: { errors },
    getValues,
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { agree: true },
  })

  const openRazorpay = useCallback(
    async (
      registrationId: string,
      order: { id: string; amount: number; currency: string; key_id: string; courseName?: string }
    ) => {
      return new Promise<void>((resolve, reject) => {
        if (!window.Razorpay) {
          reject(new Error('Payment gateway could not be loaded.'))
          return
        }

        const apiBase = getApiBaseUrl()

        const options = {
          key: order.key_id || process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID || '',
          amount: order.amount,
          currency: order.currency || 'INR',
          name: 'TECHBES',
          description: order.courseName || 'CCTV Masterclass Registration',
          order_id: order.id,
          prefill: {
            name: getValues('name'),
            email: getValues('email'),
            contact: getValues('mobile'),
          },
          theme: {
            color: '#F5C218',
          },
          modal: {
            ondismiss: async () => {
              try {
                await fetch(`${apiBase}/api/v2/cctv-course/cancel-payment`, {
                  method: 'POST',
                  headers: { 'Content-Type': 'application/json' },
                  body: JSON.stringify({ registrationId, status: 'CANCELLED' }),
                }).catch(() => {})
              } catch (_) {}
              reject(new Error('Payment cancelled by user.'))
            },
          },
          handler: async (response: {
            razorpay_order_id: string
            razorpay_payment_id: string
            razorpay_signature: string
          }) => {
            try {
              setModalState('processing')
              const verifyRes = await fetch(`${apiBase}/api/v2/cctv-course/razorpay/verify`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                  razorpay_order_id: response.razorpay_order_id,
                  razorpay_payment_id: response.razorpay_payment_id,
                  razorpay_signature: response.razorpay_signature,
                  registrationId,
                }),
              }).catch(() => {
                throw new Error('Unable to connect to payment verification service.')
              })

              const verifyData = await verifyRes.json().catch(() => ({}))

              if (!verifyRes.ok || !verifyData.success) {
                throw new Error(verifyData.message || 'Payment verification failed. Your registration has not been confirmed.')
              }

              setSuccessData({
                registrationId: verifyData.registrationId || registrationId,
                enrollmentId: verifyData.enrollmentId || verifyData.registrationId || 'CONFIRMED',
                name: verifyData.name || getValues('name'),
                courseName: verifyData.courseName || 'TechBes CCTV Masterclass',
                amountPaid: verifyData.amount || 499,
                paymentStatus: 'PAID',
                certificateId: verifyData.certificateId || undefined,
              })
              setModalState('success')
              resolve()
            } catch (err: any) {
              setServerError(err.message || 'Payment verification failed. Your registration has not been confirmed.')
              setModalState('failed')
              reject(err)
            }
          },
        }

        const rzp = new window.Razorpay(options)
        rzp.on('payment.failed', async (resp: any) => {
          const errMsg = resp?.error?.description || 'Payment failed. Your registration has not been confirmed.'
          setServerError(errMsg)
          setModalState('failed')

          try {
            await fetch(`${apiBase}/api/v2/cctv-course/cancel-payment`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                registrationId,
                status: 'FAILED',
                reason: errMsg,
              }),
            }).catch(() => {})
          } catch (_) {}

          reject(new Error(errMsg))
        })
        rzp.open()
      })
    },
    [getValues]
  )

  const handlePayment = async (data: FormValues) => {
    setServerError('')
    setModalState('initializing')
    const apiBase = getApiBaseUrl()

    try {
      // Step 0: Ensure Razorpay SDK is loaded
      const scriptReady = await loadRazorpayScript()
      if (!scriptReady || !window.Razorpay) {
        throw new Error('Unable to load payment gateway. Please check your internet connection and try again.')
      }

      // Step 1: Create registration (PENDING)
      const regRes = await fetch(`${apiBase}/api/v2/cctv-course/registrations`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          name: data.name,
          email: data.email,
          mobile: data.mobile,
          location: data.location,
          qualification: data.qualification,
          whatsapp: data.whatsapp || undefined,
        }),
      }).catch(() => {
        throw new Error('Unable to connect to course registration service.')
      })

      const regData = await regRes.json().catch(() => ({}))

      if (!regRes.ok || !regData.success) {
        throw new Error(regData.message || 'Registration failed. Please try again.')
      }

      const registrationId = regData.registrationId
      setLastRegId(registrationId)

      // Step 2: Create Razorpay order (paise ₹49900)
      const orderRes = await fetch(`${apiBase}/api/v2/cctv-course/razorpay/create-order`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ registrationId }),
      }).catch(() => {
        throw new Error('Unable to connect to order creation service.')
      })

      const orderData = await orderRes.json().catch(() => ({}))

      if (!orderRes.ok || !orderData.success) {
        throw new Error(orderData.message || 'Unable to initialize payment order. Please try again.')
      }

      const orderId = orderData.order_id || orderData.order?.id
      const keyId = orderData.key_id || orderData.order?.key_id || process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID || ''

      if (!orderId) {
        throw new Error('Unable to initialize payment order. Please try again.')
      }

      // Step 3: Open Razorpay checkout
      await openRazorpay(registrationId, {
        id: orderId,
        amount: orderData.amount || orderData.order?.amount || 49900,
        currency: orderData.currency || orderData.order?.currency || 'INR',
        key_id: keyId,
        courseName: orderData.courseName,
      })

    } catch (err: any) {
      if (err.message && err.message.includes('cancelled')) {
        setServerError('Payment was cancelled. You can retry when you are ready.')
        setModalState('form')
      } else {
        setServerError(err.message || 'Payment failed. Your registration has not been confirmed.')
        setModalState('failed')
      }
    }
  }

  // ── Prevent backdrop close while processing ──
  const handleBackdropClick = (e: React.MouseEvent) => {
    if (e.target === e.currentTarget && modalState !== 'processing' && modalState !== 'initializing') {
      onClose()
    }
  }

  return (
    <div className="modal-backdrop" onClick={handleBackdropClick} role="dialog" aria-modal="true">
      <div
        style={{
          background: '#FFFFFF',
          borderRadius: 20,
          width: '100%',
          maxWidth: 540,
          maxHeight: '90vh',
          overflowY: 'auto',
          boxShadow: '0 32px 80px rgba(0,0,0,0.18), 0 4px 24px rgba(0,0,0,0.06)',
          position: 'relative',
        }}
      >
        {/* ── Processing overlay ── */}
        {(modalState === 'processing' || modalState === 'initializing') && (
          <div style={{
            position: 'absolute', inset: 0, borderRadius: 20,
            background: 'rgba(255,255,255,0.94)',
            backdropFilter: 'blur(6px)',
            display: 'flex', flexDirection: 'column',
            alignItems: 'center', justifyContent: 'center',
            zIndex: 10, gap: 14,
          }}>
            <div style={{
              width: 46, height: 46,
              border: '3.5px solid rgba(245,194,24,0.2)',
              borderTop: '3.5px solid #F5C218',
              borderRadius: '50%',
              animation: 'spin 0.8s linear infinite',
            }} />
            <p style={{ fontSize: 15, fontWeight: 700, color: '#0A0F1E', margin: 0 }}>
              {modalState === 'processing' ? 'Processing payment...' : 'Initializing payment...'}
            </p>
            <p style={{ fontSize: 12.5, color: '#64748B', margin: 0 }}>Please do not refresh or close this window.</p>
          </div>
        )}

        {/* ── Success state ── */}
        {modalState === 'success' && successData ? (
          <SuccessView data={successData} onDone={onClose} />
        ) : modalState === 'failed' ? (
          /* ── Failure state ── */
          <div style={{ padding: '36px 28px 32px', textAlign: 'center' }}>
            <div style={{
              width: 68, height: 68,
              borderRadius: '50%',
              background: 'rgba(220,38,38,0.1)',
              border: '2px solid rgba(220,38,38,0.25)',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              margin: '0 auto 18px',
              fontSize: 30,
              color: '#DC2626',
            }}>
              ✕
            </div>

            <h2 style={{ fontSize: '1.35rem', fontWeight: 900, color: '#0A0F1E', margin: '0 0 8px', letterSpacing: '-0.02em' }}>
              PAYMENT NOT COMPLETED
            </h2>
            <p style={{ fontSize: 13.5, color: '#DC2626', fontWeight: 600, marginBottom: 20 }}>
              Payment failed. Your registration has not been confirmed.
            </p>
            {serverError && (
              <div style={{
                background: '#FEF2F2',
                border: '1px solid #FCA5A5',
                borderRadius: 10,
                padding: '12px 16px',
                fontSize: 12.5,
                color: '#991B1B',
                marginBottom: 24,
                textAlign: 'left',
              }}>
                {serverError}
              </div>
            )}

            <div style={{ display: 'flex', gap: 12 }}>
              <button
                type="button"
                onClick={() => {
                  setServerError('')
                  setModalState('form')
                }}
                className="btn-gold"
                style={{ flex: 1, padding: '14px', fontSize: '0.95rem', borderRadius: 10, fontWeight: 800, cursor: 'pointer' }}
              >
                ↻ RETRY PAYMENT
              </button>
              <button
                type="button"
                onClick={onClose}
                style={{
                  flex: 1, padding: '14px', fontSize: '0.95rem', borderRadius: 10,
                  fontWeight: 700, border: '1.5px solid #E2E8F0', background: '#F8FAFC',
                  color: '#475569', cursor: 'pointer',
                }}
              >
                CANCEL
              </button>
            </div>
          </div>
        ) : (
          <>
            {/* Modal header */}
            <div style={{
              padding: '28px 28px 0',
              borderBottom: '1px solid #F1F5F9',
              paddingBottom: 20,
              display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start',
            }}>
              <div>
                <div style={{
                  display: 'inline-flex', alignItems: 'center', gap: 6,
                  background: 'rgba(245,194,24,0.1)',
                  border: '1px solid rgba(245,194,24,0.25)',
                  borderRadius: 100,
                  padding: '3px 12px',
                  marginBottom: 10,
                }}>
                  <span style={{
                    width: 6, height: 6, borderRadius: '50%',
                    background: '#F5C218',
                    boxShadow: '0 0 6px #F5C218',
                    display: 'inline-block',
                  }} />
                  <span style={{ fontSize: 10, fontWeight: 800, color: '#D4A81A', letterSpacing: '0.15em', textTransform: 'uppercase' }}>
                    Limited Seats
                  </span>
                </div>
                <h2 style={{ fontSize: '1.4rem', fontWeight: 900, color: '#0A0F1E', margin: 0, letterSpacing: '-0.02em' }}>
                  RESERVE YOUR SEAT
                </h2>
                <p style={{ fontSize: 13, color: '#64748B', marginTop: 4, marginBottom: 0 }}>
                  Enter your details to continue and secure your registration.
                </p>
              </div>
              <button
                id="modal-close-btn"
                onClick={onClose}
                aria-label="Close"
                style={{
                  width: 34, height: 34, borderRadius: '50%',
                  border: '1.5px solid #E2E8F0', background: '#F8FAFC',
                  cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  color: '#64748B', fontSize: 16, lineHeight: 1,
                  transition: 'all 0.15s',
                  flexShrink: 0,
                }}
              >
                ×
              </button>
            </div>

            {/* Form */}
            <form onSubmit={handleSubmit(handlePayment)} noValidate style={{ padding: '24px 28px 28px' }}>
              {serverError && (
                <div style={{
                  background: 'rgba(220,38,38,0.06)', border: '1px solid rgba(220,38,38,0.2)',
                  borderRadius: 10, padding: '12px 16px', marginBottom: 20,
                  fontSize: 13, color: '#DC2626', fontWeight: 600,
                }}>
                  ⚠ {serverError}
                </div>
              )}

              <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
                {/* Full Name */}
                <Field label="Full Name" required error={errors.name?.message} colSpan="2">
                  <input
                    id="field-name"
                    className={`input-light ${errors.name ? 'input-error' : ''}`}
                    placeholder="e.g. Viswas Rajan"
                    {...register('name')}
                  />
                </Field>

                {/* Mobile */}
                <Field label="Mobile Number" required error={errors.mobile?.message}>
                  <input
                    id="field-mobile"
                    type="tel"
                    inputMode="numeric"
                    maxLength={10}
                    className={`input-light ${errors.mobile ? 'input-error' : ''}`}
                    placeholder="10-digit mobile"
                    {...register('mobile')}
                  />
                </Field>

                {/* Email */}
                <Field label="Email Address" required error={errors.email?.message}>
                  <input
                    id="field-email"
                    type="email"
                    className={`input-light ${errors.email ? 'input-error' : ''}`}
                    placeholder="you@email.com"
                    {...register('email')}
                  />
                </Field>

                {/* Location */}
                <Field label="City / Location" required error={errors.location?.message}>
                  <input
                    id="field-location"
                    className={`input-light ${errors.location ? 'input-error' : ''}`}
                    placeholder="e.g. Bangalore"
                    {...register('location')}
                  />
                </Field>

                {/* Qualification */}
                <Field label="Qualification" required error={errors.qualification?.message}>
                  <select
                    id="field-qualification"
                    className={`input-light ${errors.qualification ? 'input-error' : ''}`}
                    {...register('qualification')}
                  >
                    <option value="">Select qualification</option>
                    {QUALIFICATIONS.map(q => (
                      <option key={q} value={q}>{q}</option>
                    ))}
                  </select>
                </Field>

                {/* WhatsApp */}
                <Field label="WhatsApp Number" error={errors.whatsapp?.message} colSpan="2">
                  <input
                    id="field-whatsapp"
                    type="tel"
                    inputMode="numeric"
                    maxLength={10}
                    className={`input-light ${errors.whatsapp ? 'input-error' : ''}`}
                    placeholder="Optional — if different from mobile"
                    {...register('whatsapp')}
                  />
                </Field>

                {/* Agreement checkbox */}
                <div style={{ gridColumn: '1 / -1' }}>
                  <label style={{ display: 'flex', alignItems: 'flex-start', gap: 10, cursor: 'pointer' }}>
                    <input
                      id="field-agree"
                      type="checkbox"
                      {...register('agree')}
                      style={{ marginTop: 2, accentColor: '#F5C218', width: 15, height: 15, flexShrink: 0 }}
                    />
                    <span style={{ fontSize: 12.5, color: '#475569', lineHeight: 1.5 }}>
                      I agree to receive important updates related to this masterclass via WhatsApp, SMS and Email.
                    </span>
                  </label>
                  {errors.agree && (
                    <p style={{ fontSize: 11.5, color: '#DC2626', marginTop: 4, marginLeft: 25, fontWeight: 600 }}>
                      {errors.agree.message as string}
                    </p>
                  )}
                </div>
              </div>

              {/* Price summary */}
              <div style={{
                display: 'flex', alignItems: 'center', justifyContent: 'space-between',
                background: 'linear-gradient(135deg, rgba(245,194,24,0.06) 0%, rgba(14,165,233,0.04) 100%)',
                border: '1px solid rgba(245,194,24,0.2)',
                borderRadius: 12, padding: '14px 18px',
                marginTop: 20, marginBottom: 20,
              }}>
                <div>
                  <div style={{ fontSize: 12, fontWeight: 700, color: '#64748B', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                    CCTV Masterclass — Registration Fee
                  </div>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 4 }}>
                    <span style={{ fontSize: 22, fontWeight: 900, color: '#DC2626', letterSpacing: '-0.02em' }}>₹499</span>
                    <span style={{ fontSize: 13, color: '#94A3B8', textDecoration: 'line-through' }}>₹999</span>
                    <span style={{
                      fontSize: 10, fontWeight: 800, color: '#16A34A',
                      background: 'rgba(34,197,94,0.1)', border: '1px solid rgba(34,197,94,0.2)',
                      borderRadius: 4, padding: '2px 7px',
                    }}>50% OFF</span>
                  </div>
                </div>
                <div style={{ textAlign: 'right' }}>
                  <img
                    src="https://razorpay.com/assets/razorpay-glyph.svg"
                    alt="Razorpay"
                    style={{ height: 20, opacity: 0.5 }}
                    onError={e => (e.currentTarget.style.display = 'none')}
                  />
                  <div style={{ fontSize: 10, color: '#94A3B8', marginTop: 3 }}>Secure Payment</div>
                </div>
              </div>

              {/* Submit button */}
              <button
                id="modal-submit-btn"
                type="submit"
                disabled={modalState === 'initializing' || modalState === 'processing'}
                className="btn-red"
                style={{
                  width: '100%',
                  padding: '17px 24px',
                  fontSize: '1rem',
                  borderRadius: 12,
                  fontWeight: 900,
                  letterSpacing: '0.04em',
                  opacity: (modalState === 'initializing' || modalState === 'processing') ? 0.7 : 1,
                  cursor: (modalState === 'initializing' || modalState === 'processing') ? 'not-allowed' : 'pointer',
                }}
              >
                PROCEED TO PAYMENT — ₹499
              </button>

              <p style={{ fontSize: 11, color: '#94A3B8', textAlign: 'center', marginTop: 12 }}>
                🔒 100% secure payment verified via Razorpay
              </p>
            </form>
          </>
        )}
      </div>

      <style>{`
        @keyframes spin { to { transform: rotate(360deg); } }
      `}</style>
    </div>
  )
}

// ── Field wrapper ──────────────────────────────────────────────────────────────
function Field({
  label, required, error, children, colSpan,
}: {
  label: string
  required?: boolean
  error?: string
  children: React.ReactNode
  colSpan?: string
}) {
  return (
    <div style={{ gridColumn: colSpan === '2' ? '1 / -1' : undefined }}>
      <label style={{
        display: 'block',
        fontSize: 12.5,
        fontWeight: 700,
        color: '#334155',
        marginBottom: 6,
        letterSpacing: '0.01em',
      }}>
        {label}
        {required && <span style={{ color: '#DC2626', marginLeft: 3 }}>*</span>}
      </label>
      {children}
      {error && (
        <p style={{ fontSize: 11.5, color: '#DC2626', marginTop: 5, fontWeight: 600 }}>
          {error}
        </p>
      )}
    </div>
  )
}

// ── Success View ───────────────────────────────────────────────────────────────
function SuccessView({ data, onDone }: { data: SuccessData; onDone: () => void }) {
  const [viewingDetails, setViewingDetails] = useState(false)

  return (
    <div style={{ padding: '36px 28px 32px', textAlign: 'center' }}>
      {/* Icon */}
      <div style={{
        width: 72, height: 72,
        borderRadius: '50%',
        background: 'rgba(34,197,94,0.1)',
        border: '2px solid rgba(34,197,94,0.25)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        margin: '0 auto 18px',
      }}>
        <svg width="36" height="36" viewBox="0 0 24 24" fill="none" stroke="#16A34A" strokeWidth="2.5">
          <path strokeLinecap="round" strokeLinejoin="round" d="M5 13l4 4L19 7" />
        </svg>
      </div>

      <h2 style={{ fontSize: '1.4rem', fontWeight: 900, color: '#0A0F1E', margin: '0 0 6px', letterSpacing: '-0.02em' }}>
        REGISTRATION SUCCESSFUL
      </h2>
      <p style={{ fontSize: 13.5, color: '#64748B', marginBottom: 24 }}>
        You're successfully registered for {data.courseName}.
      </p>

      {/* Details card */}
      <div style={{
        background: '#F8FAFC',
        border: '1px solid #E2E8F0',
        borderRadius: 14,
        padding: '20px 22px',
        textAlign: 'left',
        marginBottom: 20,
      }}>
        {[
          { label: 'Student Name', value: data.name },
          { label: 'Course Name', value: data.courseName },
          { label: 'Registration ID', value: data.registrationId || data.enrollmentId, mono: true },
          { label: 'Enrollment ID', value: data.enrollmentId, mono: true },
          { label: 'Amount Paid', value: `₹${data.amountPaid}` },
          { label: 'Payment Status', value: 'PAID ✓', highlight: true },
        ].map(({ label, value, highlight, mono }) => (
          <div key={label} style={{
            display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            padding: '9px 0',
            borderBottom: label !== 'Payment Status' ? '1px solid #F1F5F9' : 'none',
          }}>
            <span style={{ fontSize: 12.5, color: '#64748B', fontWeight: 600 }}>{label}</span>
            <span style={{
              fontSize: 13, fontWeight: 800,
              color: highlight ? '#16A34A' : '#0A0F1E',
              fontFamily: mono ? 'monospace' : 'inherit',
            }}>{value}</span>
          </div>
        ))}
      </div>

      {/* Info notice */}
      <div style={{
        background: 'rgba(245,194,24,0.06)',
        border: '1px solid rgba(245,194,24,0.2)',
        borderRadius: 12, padding: '14px 16px',
        fontSize: 12.5, color: '#64748B', textAlign: 'left',
        marginBottom: 24, lineHeight: 1.6,
      }}>
        📧 A confirmation email with masterclass details has been sent to your inbox.<br />
        🎥 The online Zoom class link will be shared prior to the session.
      </div>

      <div style={{ display: 'flex', gap: 12 }}>
        <button
          id="success-done-btn"
          onClick={onDone}
          className="btn-gold"
          style={{ flex: 1, padding: '14px', fontSize: '0.95rem', borderRadius: 10, fontWeight: 900, cursor: 'pointer' }}
        >
          Back to Course
        </button>
        {data.certificateId ? (
          <a
            href={`/certificate/${data.certificateId}`}
            style={{
              flex: 1, padding: '14px', fontSize: '0.95rem', borderRadius: 10,
              fontWeight: 700, border: '1.5px solid #E2E8F0', background: '#F8FAFC',
              color: '#0A0F1E', textDecoration: 'none', display: 'flex', alignItems: 'center',
              justifyContent: 'center',
            }}
          >
            View Certificate
          </a>
        ) : (
          <button
            onClick={() => alert(`Registration confirmed. ID: ${data.enrollmentId}`)}
            style={{
              flex: 1, padding: '14px', fontSize: '0.95rem', borderRadius: 10,
              fontWeight: 700, border: '1.5px solid #E2E8F0', background: '#F8FAFC',
              color: '#0A0F1E', cursor: 'pointer',
            }}
          >
            View Registration
          </button>
        )}
      </div>
    </div>
  )
}
