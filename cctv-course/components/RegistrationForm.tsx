"use client"
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'

const schema = z.object({
  name: z.string().min(2, 'Name must be at least 2 characters'),
  email: z.string().email('Invalid email address'),
  mobile: z.string().min(10, 'Mobile must be at least 10 digits'),
  location: z.string().min(2, 'Location is required'),
  qualification: z.string().min(1, 'Please select your qualification'),
  whatsapp: z.string().optional(),
  consent: z.boolean().refine(val => val === true, 'You must consent to proceed'),
})

type FormData = z.infer<typeof schema>

export default function RegistrationForm({ masterclassId }: { masterclassId?: string }) {
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({ resolver: zodResolver(schema) })
  const [loading, setLoading] = useState(false)

  async function onSubmit(data: FormData) {
    setLoading(true)
    const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || ''

    try {
      // 1. Save Registration on Common Backend
      const regRes = await fetch(`${apiBase}/api/v2/cctv-course/registrations`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ ...data, masterclassId })
      })
      const regJson = await regRes.json()
      if (!regRes.ok) throw new Error(regJson.message || 'Registration creation failed')

      const registrationId = regJson.registrationId

      // 2. Create Razorpay Order on Common Backend
      const orderRes = await fetch(`${apiBase}/api/v2/cctv-course/razorpay/create-order`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ registrationId })
      })
      const orderJson = await orderRes.json()
      if (!orderRes.ok) throw new Error(orderJson.message || 'Order creation failed')

      const order = orderJson.order

      // 3. Open Razorpay Checkout Dialog on Frontend
      if (typeof (window as any).Razorpay === 'undefined') {
        throw new Error('Razorpay payment gateway is not loaded. Please try again.')
      }

      const options = {
        key: process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID || '',
        amount: order.amount,
        currency: order.currency,
        name: 'TECHBES',
        description: 'CCTV Course Enrollment Fee',
        order_id: order.id,
        handler: async function (response: any) {
          setLoading(true)
          try {
            // 4. Verify payment on Common Backend
            const verifyRes = await fetch(`${apiBase}/api/v2/cctv-course/razorpay/verify`, {
              method: 'POST',
              headers: { 'Content-Type': 'application/json' },
              body: JSON.stringify({
                razorpay_order_id: response.razorpay_order_id,
                razorpay_payment_id: response.razorpay_payment_id,
                razorpay_signature: response.razorpay_signature
              })
            })
            const verifyJson = await verifyRes.json()
            if (!verifyRes.ok || !verifyJson.success) {
              throw new Error(verifyJson.message || 'Payment signature verification failed')
            }

            // Redirect to Success Page
            window.location.href = `/success?id=${registrationId}&cert=${verifyJson.certificateId || ''}`
          } catch (verifyErr: any) {
            console.error(verifyErr)
            alert(verifyErr.message || 'Verification Error')
            setLoading(false)
          }
        },
        prefill: {
          name: data.name,
          email: data.email,
          contact: data.mobile,
        },
        notes: {
          registrationId,
        },
        theme: {
          color: '#dc2626', // Premium Red matching TechBes style
        },
      }

      const rzp = new (window as any).Razorpay(options)
      rzp.open()
    } catch (err: any) {
      console.error(err)
      alert(err.message || 'Registration and payment initialization error')
    } finally {
      setLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-4 max-w-md bg-slate-900/50 p-6 rounded-xl border border-slate-800 backdrop-blur-md">
      <div>
        <input {...register('name')} placeholder="Full Name" className="w-full p-3 rounded bg-white/5 border border-slate-700/50 focus:border-red-500 focus:outline-none transition-colors text-white" />
        {errors.name && <div className="text-red-400 text-sm mt-1">{errors.name.message}</div>}
      </div>
      <div>
        <input {...register('mobile')} placeholder="Mobile Number" className="w-full p-3 rounded bg-white/5 border border-slate-700/50 focus:border-red-500 focus:outline-none transition-colors text-white" />
        {errors.mobile && <div className="text-red-400 text-sm mt-1">{errors.mobile.message}</div>}
      </div>
      <div>
        <input {...register('email')} placeholder="Email Address" className="w-full p-3 rounded bg-white/5 border border-slate-700/50 focus:border-red-500 focus:outline-none transition-colors text-white" />
        {errors.email && <div className="text-red-400 text-sm mt-1">{errors.email.message}</div>}
      </div>
      <div>
        <input {...register('location')} placeholder="Location / Area (e.g. Bangalore)" className="w-full p-3 rounded bg-white/5 border border-slate-700/50 focus:border-red-500 focus:outline-none transition-colors text-white" />
        {errors.location && <div className="text-red-400 text-sm mt-1">{errors.location.message}</div>}
      </div>
      <div>
        <select {...register('qualification')} className="w-full p-3 rounded bg-slate-900 border border-slate-700/50 focus:border-red-500 focus:outline-none transition-colors text-slate-300">
          <option value="">Select Qualification</option>
          <option>10th</option>
          <option>12th</option>
          <option>ITI</option>
          <option>Diploma</option>
          <option>BE</option>
          <option>B.Tech</option>
          <option>BCA</option>
          <option>MCA</option>
          <option>B.Sc</option>
          <option>M.Sc</option>
          <option>Other</option>
        </select>
        {errors.qualification && <div className="text-red-400 text-sm mt-1">{errors.qualification.message}</div>}
      </div>
      <div>
        <input {...register('whatsapp')} placeholder="WhatsApp Number (optional)" className="w-full p-3 rounded bg-white/5 border border-slate-700/50 focus:border-red-500 focus:outline-none transition-colors text-white" />
      </div>
      <div>
        <label className="flex items-start gap-3 cursor-pointer select-none">
          <input type="checkbox" {...register('consent')} className="mt-1 accent-red-600 rounded" />
          <span className="text-sm text-slate-400 leading-tight">I agree to receive important updates and reminders related to this masterclass via email/WhatsApp.</span>
        </label>
        {errors.consent && <div className="text-red-400 text-sm mt-1">{errors.consent.message}</div>}
      </div>

      <button type="submit" disabled={loading} className="w-full bg-red-600 hover:bg-red-700 disabled:bg-slate-700 py-3.5 rounded-lg text-white font-bold tracking-wide transition-all shadow-lg hover:shadow-red-600/10 cursor-pointer">
        {loading ? 'Processing...' : 'Proceed to Payment (₹499)'}
      </button>
    </form>
  )
}
