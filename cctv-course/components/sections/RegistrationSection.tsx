"use client"
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'
import { motion } from 'framer-motion'
import { CheckCircle2, ArrowRight, Loader2, User, Phone, Mail, MapPin, GraduationCap, MessageCircle } from 'lucide-react'
import ScrollReveal from '../ui/ScrollReveal'

const schema = z.object({
  name:          z.string().min(2, 'Name must be at least 2 characters'),
  mobile:        z.string().min(10, 'Enter a valid 10-digit mobile number').max(15, 'Too long'),
  email:         z.string().email('Enter a valid email address'),
  location:      z.string().min(2, 'Location is required'),
  qualification: z.string().min(1, 'Please select your qualification'),
  whatsapp:      z.string().optional(),
  consent:       z.boolean().refine(v => v === true, 'Please accept to continue'),
})

type FormData = z.infer<typeof schema>

const qualificationOptions = [
  '10th', '12th', 'ITI', 'Diploma', 'BE', 'B.Tech', 'BCA', 'MCA', 'B.Sc', 'M.Sc', 'Other',
]

const leftFeatures = [
  'Live practical session — 2 hours',
  'E-Certificate on completion',
  'Expert guidance & doubt clearance',
  'Learning resources included',
  'Certificate verification portal',
]

interface FieldProps {
  label: string
  icon: React.ElementType
  error?: string
  children: React.ReactNode
}

function Field({ label, icon: Icon, error, children }: FieldProps) {
  return (
    <div>
      <label className="block text-sm font-semibold text-slate-300 mb-2 flex items-center gap-2">
        <Icon size={14} className="text-slate-500" />
        {label}
      </label>
      {children}
      {error && (
        <p className="mt-1.5 text-xs text-[#EF5350] flex items-center gap-1.5">
          <span className="inline-block w-1 h-1 rounded-full bg-[#EF5350]" />
          {error}
        </p>
      )}
    </div>
  )
}

export default function RegistrationSection({ masterclassId }: { masterclassId?: string }) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<FormData>({ resolver: zodResolver(schema) })

  const [loading, setLoading] = useState(false)

  async function onSubmit(data: FormData) {
    if (loading) return
    setLoading(true)
    const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || ''

    try {
      // 1. Create registration
      const regRes = await fetch(`${apiBase}/api/v2/cctv-course/registrations`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ ...data, masterclassId }),
      })
      const regJson = await regRes.json()
      if (!regRes.ok) throw new Error(regJson.message || 'Registration failed')
      const registrationId = regJson.registrationId

      // 2. Create Razorpay order
      const orderRes = await fetch(`${apiBase}/api/v2/cctv-course/razorpay/create-order`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify({ registrationId }),
      })
      const orderJson = await orderRes.json()
      if (!orderRes.ok) throw new Error(orderJson.message || 'Order creation failed')
      const order = orderJson.order

      // 3. Open Razorpay
      if (typeof (window as any).Razorpay === 'undefined') {
        throw new Error('Payment gateway not loaded. Please refresh and try again.')
      }

      const options = {
        key:         process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID || '',
        amount:      order.amount,
        currency:    order.currency,
        name:        'TECHBES',
        description: 'CCTV Masterclass Registration',
        order_id:    order.id,
        handler: async (response: any) => {
          setLoading(true)
          try {
            // 4. Verify payment
            const verifyRes = await fetch(`${apiBase}/api/v2/cctv-course/razorpay/verify`, {
              method:  'POST',
              headers: { 'Content-Type': 'application/json' },
              body:    JSON.stringify({
                razorpay_order_id:   response.razorpay_order_id,
                razorpay_payment_id: response.razorpay_payment_id,
                razorpay_signature:  response.razorpay_signature,
              }),
            })
            const verifyJson = await verifyRes.json()
            if (!verifyRes.ok || !verifyJson.success) {
              throw new Error(verifyJson.message || 'Payment verification failed')
            }
            window.location.href = `/success?id=${registrationId}&cert=${verifyJson.certificateId || ''}`
          } catch (err: any) {
            console.error(err)
            alert(err.message || 'Verification Error')
            setLoading(false)
          }
        },
        prefill: { name: data.name, email: data.email, contact: data.mobile },
        notes:   { registrationId },
        theme:   { color: '#E53935' },
      }

      const rzp = new (window as any).Razorpay(options)
      rzp.open()
    } catch (err: any) {
      console.error(err)
      alert(err.message || 'Something went wrong. Please try again.')
    } finally {
      setLoading(false)
    }
  }

  return (
    <section id="register" className="bg-[#0A1020] section-pad">
      <div className="max-w-section mx-auto">

        {/* Heading */}
        <ScrollReveal className="text-center mb-14">
          <div className="inline-flex items-center gap-2 mb-4">
            <div className="h-[2px] w-8 bg-[#F5C842]" />
            <span className="text-[#F5C842] text-xs font-bold tracking-[0.2em] uppercase">Enroll Now</span>
            <div className="h-[2px] w-8 bg-[#F5C842]" />
          </div>
          <h2
            className="font-extrabold text-white leading-tight"
            style={{ fontSize: 'clamp(1.8rem, 3.5vw, 2.75rem)' }}
          >
            READY TO START?
          </h2>
          <p className="mt-3 text-slate-400 text-base max-w-xl mx-auto">
            Reserve your seat for the TECHBES CCTV Masterclass.
          </p>
        </ScrollReveal>

        <div className="grid lg:grid-cols-2 gap-10 lg:gap-16 items-start">

          {/* LEFT — Info */}
          <ScrollReveal direction="left">
            <div className="lg:sticky lg:top-24">
              <div className="mb-8">
                <div className="flex items-baseline gap-3 mb-1">
                  <span className="text-slate-500 line-through text-xl">₹999</span>
                  <span
                    className="text-[#F5C842] font-extrabold"
                    style={{ fontSize: 'clamp(3rem, 5vw, 4rem)' }}
                  >
                    ₹499
                  </span>
                </div>
                <div className="inline-flex items-center gap-2 bg-[#E53935]/12 border border-[#E53935]/30 text-[#EF5350] text-xs font-bold px-3 py-1.5 rounded-full tracking-widest uppercase">
                  <span className="w-1.5 h-1.5 rounded-full bg-[#E53935] animate-pulse inline-block" />
                  Limited Seats Available
                </div>
              </div>

              <div className="space-y-3 mb-10">
                {leftFeatures.map(f => (
                  <div key={f} className="flex items-start gap-3">
                    <div className="w-6 h-6 rounded-full bg-[#F5C842]/12 flex items-center justify-center flex-shrink-0 mt-0.5">
                      <CheckCircle2 size={13} className="text-[#F5C842]" />
                    </div>
                    <span className="text-slate-300 text-sm font-medium leading-relaxed">{f}</span>
                  </div>
                ))}
              </div>

              {/* Quote */}
              <div className="p-5 rounded-xl" style={{ background: 'rgba(245,200,66,0.04)', border: '1px solid rgba(245,200,66,0.12)' }}>
                <p className="text-slate-400 text-sm leading-relaxed italic">
                  "Join 100+ learners who are building real-world CCTV skills with TECHBES."
                </p>
              </div>
            </div>
          </ScrollReveal>

          {/* RIGHT — Form */}
          <ScrollReveal direction="right" delay={0.1}>
            <div className="relative">
              <div
                className="absolute -inset-4 rounded-3xl pointer-events-none"
                style={{ background: 'radial-gradient(ellipse at top, rgba(229,57,53,0.07) 0%, transparent 70%)' }}
              />

              <div className="relative card-glass rounded-2xl p-7 sm:p-8 border border-white/[0.07]">
                {/* Form header */}
                <div className="mb-7 pb-5 border-b border-white/[0.06]">
                  <h3 className="text-white font-extrabold text-xl">RESERVE YOUR SEAT</h3>
                  <p className="text-slate-400 text-sm mt-1.5">
                    Enter your details to continue to secure payment.
                  </p>
                </div>

                <form onSubmit={handleSubmit(onSubmit)} noValidate className="space-y-5">

                  {/* Name */}
                  <Field label="Full Name *" icon={User} error={errors.name?.message}>
                    <input
                      {...register('name')}
                      placeholder="Enter your full name"
                      className={`input-premium ${errors.name ? 'input-error' : ''}`}
                    />
                  </Field>

                  {/* Mobile */}
                  <Field label="Mobile Number *" icon={Phone} error={errors.mobile?.message}>
                    <input
                      {...register('mobile')}
                      placeholder="+91 XXXXX XXXXX"
                      type="tel"
                      className={`input-premium ${errors.mobile ? 'input-error' : ''}`}
                    />
                  </Field>

                  {/* Email */}
                  <Field label="Email Address *" icon={Mail} error={errors.email?.message}>
                    <input
                      {...register('email')}
                      placeholder="your@email.com"
                      type="email"
                      className={`input-premium ${errors.email ? 'input-error' : ''}`}
                    />
                  </Field>

                  {/* 2-col row */}
                  <div className="grid sm:grid-cols-2 gap-4">
                    <Field label="Location / Area *" icon={MapPin} error={errors.location?.message}>
                      <input
                        {...register('location')}
                        placeholder="e.g. Bangalore"
                        className={`input-premium ${errors.location ? 'input-error' : ''}`}
                      />
                    </Field>

                    <Field label="Qualification *" icon={GraduationCap} error={errors.qualification?.message}>
                      <select
                        {...register('qualification')}
                        className={`input-premium select-premium ${errors.qualification ? 'input-error' : ''}`}
                      >
                        <option value="">Select...</option>
                        {qualificationOptions.map(q => (
                          <option key={q} value={q}>{q}</option>
                        ))}
                      </select>
                    </Field>
                  </div>

                  {/* WhatsApp (optional) */}
                  <Field label="WhatsApp Number (optional)" icon={MessageCircle}>
                    <input
                      {...register('whatsapp')}
                      placeholder="If different from mobile"
                      type="tel"
                      className="input-premium"
                    />
                  </Field>

                  {/* Consent */}
                  <div>
                    <label className="flex items-start gap-3 cursor-pointer select-none group">
                      <div className="relative mt-0.5 flex-shrink-0">
                        <input
                          type="checkbox"
                          {...register('consent')}
                          className="sr-only"
                          id="consent-check"
                        />
                        <div
                          className={`w-5 h-5 rounded border-2 flex items-center justify-center transition-all ${
                            errors.consent
                              ? 'border-[#E53935] bg-[#E53935]/10'
                              : 'border-slate-600 group-hover:border-[#F5C842]/60 bg-transparent'
                          }`}
                          onClick={() => {
                            const el = document.getElementById('consent-check') as HTMLInputElement
                            if (el) el.click()
                          }}
                        >
                          <CheckCircle2 size={12} className="text-[#F5C842] opacity-0 peer-checked:opacity-100" />
                        </div>
                      </div>
                      <span className="text-sm text-slate-400 leading-relaxed">
                        I agree to receive important updates, reminders, and session links related
                        to this masterclass via email and WhatsApp.
                      </span>
                    </label>
                    {errors.consent && (
                      <p className="mt-1.5 text-xs text-[#EF5350] flex items-center gap-1.5 ml-8">
                        <span className="inline-block w-1 h-1 rounded-full bg-[#EF5350]" />
                        {errors.consent.message}
                      </p>
                    )}
                  </div>

                  {/* Submit */}
                  <motion.button
                    type="submit"
                    disabled={loading}
                    whileHover={loading ? {} : { scale: 1.02, boxShadow: '0 0 40px rgba(229,57,53,0.5)' }}
                    whileTap={loading ? {} : { scale: 0.97 }}
                    className="w-full btn-red py-4 rounded-xl text-base font-extrabold tracking-wide mt-2 disabled:opacity-60 disabled:cursor-not-allowed shadow-[0_0_30px_rgba(229,57,53,0.25)]"
                  >
                    {loading ? (
                      <>
                        <Loader2 size={18} className="animate-spin" />
                        PROCESSING...
                      </>
                    ) : (
                      <>
                        PROCEED TO PAYMENT — ₹499
                        <ArrowRight size={18} />
                      </>
                    )}
                  </motion.button>

                  <p className="text-center text-xs text-slate-500">
                    Secured by Razorpay · SSL Encrypted · No hidden charges
                  </p>
                </form>
              </div>
            </div>
          </ScrollReveal>
        </div>
      </div>
    </section>
  )
}
