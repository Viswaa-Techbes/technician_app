"use client"
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import * as z from 'zod'

const schema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  mobile: z.string().min(10),
  location: z.string().min(2),
  qualification: z.string().min(1),
  whatsapp: z.string().optional(),
  consent: z.boolean(),
})

type FormData = z.infer<typeof schema>

export default function RegistrationForm({ masterclassId }: { masterclassId?: string }) {
  const { register, handleSubmit, formState: { errors } } = useForm<FormData>({ resolver: zodResolver(schema) })
  const [loading, setLoading] = useState(false)

  async function onSubmit(data: FormData) {
    setLoading(true)
    try {
      const res = await fetch('/api/registrations', { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ ...data, masterclassId }) })
      const json = await res.json()
      if (!res.ok) throw new Error(json.message || 'Registration failed')
      // frontend will handle razorpay flow using order returned
      console.log('registered', json)
    } catch (err) {
      console.error(err)
      alert('Registration error')
    } finally { setLoading(false) }
  }

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="space-y-3 max-w-md">
      <input {...register('name')} placeholder="Full Name" className="w-full p-2 rounded bg-white/5" />
      {errors.name && <div className="text-red-400 text-sm">{errors.name.message}</div>}
      <input {...register('mobile')} placeholder="Mobile Number" className="w-full p-2 rounded bg-white/5" />
      {errors.mobile && <div className="text-red-400 text-sm">{errors.mobile.message}</div>}
      <input {...register('email')} placeholder="Email" className="w-full p-2 rounded bg-white/5" />
      {errors.email && <div className="text-red-400 text-sm">{errors.email.message}</div>}
      <input {...register('location')} placeholder="Location / Area" className="w-full p-2 rounded bg-white/5" />
      <select {...register('qualification')} className="w-full p-2 rounded bg-white/5">
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
      <input {...register('whatsapp')} placeholder="WhatsApp Number (optional)" className="w-full p-2 rounded bg-white/5" />
      <label className="flex items-center gap-2">
        <input type="checkbox" {...register('consent')} />
        <span className="text-sm text-slate-300">I agree to receive important updates related to this masterclass.</span>
      </label>

      <button type="submit" disabled={loading} className="w-full bg-red-600 py-3 rounded text-white">{loading ? 'Processing...' : 'Proceed to Payment'}</button>
    </form>
  )
}
