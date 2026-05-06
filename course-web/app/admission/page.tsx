'use client'

import { useState } from 'react'
import { motion, AnimatePresence } from 'framer-motion'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { ShieldCheck, CheckCircle2, ChevronRight, Briefcase, GraduationCap, Lock, Star, Loader2 } from 'lucide-react'
import { useRouter } from 'next/navigation'

const plans = [
  { id: 'basic', name: 'Basic Plan', price: 7999, originalPrice: 12000 },
  { id: 'job-ready', name: 'Job Ready Plan', price: 14999, originalPrice: 25000, recommended: true },
  { id: 'premium', name: 'Premium Plan', price: 24999, originalPrice: 40000 },
]

export default function AdmissionPage() {
  const router = useRouter()
  const [focused, setFocused] = useState<string | null>(null)
  const [isProcessing, setIsProcessing] = useState(false)
  const [showGateway, setShowGateway] = useState(false)
  
  const [formData, setFormData] = useState({
    name: '',
    phone: '',
    email: '',
    address: '',
    qualification: '',
    course: 'CCTV & IT Skill Development Program',
    plan: 'job-ready',
  })

  const handleChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    setFormData((prev) => ({ ...prev, [e.target.name]: e.target.value }))
  }

  const handleProceedPayment = (e: React.FormEvent) => {
    e.preventDefault()
    setIsProcessing(true)
    
    // Simulate gateway initialisation
    setTimeout(() => {
      setIsProcessing(false)
      setShowGateway(true)
    }, 1500)
  }

  const handleSimulatePayment = async (success: boolean) => {
    if (!success) {
      setShowGateway(false)
      return
    }

    setIsProcessing(true)
    // Save enrollment to API
    try {
      const selectedPlanDetails = plans.find(p => p.id === formData.plan)
      const res = await fetch('/api/enroll', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          ...formData,
          amountPaid: selectedPlanDetails?.price
        })
      })
      const data = await res.json()
      
      if (data.success) {
        // Save to local storage for dashboard
        localStorage.setItem('userEnrollment', JSON.stringify(data.enrollment))
        router.push(`/success?id=${data.enrollment.id}`)
      }
    } catch (err) {
      console.error(err)
      setIsProcessing(false)
      setShowGateway(false)
    }
  }

  return (
    <main className="min-h-screen overflow-x-hidden bg-[#F5F9FF]">
      <Header />

      <section className="relative pt-36 pb-20 px-4">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_left,rgba(11,77,186,0.15),transparent_50%),radial-gradient(ellipse_at_bottom_right,rgba(255,107,0,0.1),transparent_50%)]" />
        
        <div className="container mx-auto max-w-7xl relative z-10">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 lg:gap-8 items-start">
            
            {/* LEFT SIDE: Features & Trust */}
            <div className="lg:col-span-5 space-y-8 lg:sticky lg:top-36">
              <motion.div initial={{ opacity: 0, x: -30 }} animate={{ opacity: 1, x: 0 }} transition={{ duration: 0.6 }}>
                <span className="text-accent font-bold tracking-widest text-sm uppercase mb-3 block">Enrollment</span>
                <h1 className="text-5xl md:text-6xl font-black text-primary leading-tight mb-4">
                  Start Your <br/>
                  <span className="text-transparent bg-clip-text bg-gradient-to-r from-[#FF6B00] to-[#ff984d]">
                    Tech Journey
                  </span>
                </h1>
                <p className="text-foreground/60 text-lg">
                  Join hundreds of successful technicians. Fill the form to complete your admission and secure your seat.
                </p>
              </motion.div>

              <div className="space-y-4">
                {[
                  { icon: ShieldCheck, title: 'Secure Payment', desc: '100% safe & encrypted checkout', color: '#0B4DBA' },
                  { icon: Briefcase, title: 'Job Guarantee', desc: 'Placement assistance included', color: '#FF6B00' },
                  { icon: GraduationCap, title: '100% Practical', desc: 'Learn on live sites with real projects', color: '#0B4DBA' }
                ].map((feature, i) => (
                  <motion.div 
                    key={i}
                    initial={{ opacity: 0, y: 20 }}
                    animate={{ opacity: 1, y: 0 }}
                    transition={{ delay: 0.2 + (i * 0.1) }}
                    className="flex items-start gap-4 p-5 rounded-2xl bg-white/60 border border-white/40 shadow-sm backdrop-blur-md"
                  >
                    <div className="w-12 h-12 rounded-xl flex items-center justify-center flex-shrink-0" style={{ background: `${feature.color}15` }}>
                      <feature.icon size={24} style={{ color: feature.color }} />
                    </div>
                    <div>
                      <h4 className="font-bold text-primary text-lg">{feature.title}</h4>
                      <p className="text-sm text-foreground/60">{feature.desc}</p>
                    </div>
                  </motion.div>
                ))}
              </div>

              {/* Stats Badge */}
              <motion.div 
                initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: 0.6 }}
                className="flex items-center gap-3 p-4 rounded-xl bg-gradient-to-r from-[#0B4DBA] to-[#061f4f] text-white"
              >
                <div className="flex -space-x-3">
                  {[1,2,3].map(n => (
                    <div key={n} className="w-10 h-10 rounded-full border-2 border-[#0B4DBA] bg-white/20 backdrop-blur-md flex items-center justify-center">
                      <Star size={14} className="text-[#FF6B00] fill-[#FF6B00]" />
                    </div>
                  ))}
                </div>
                <div>
                  <p className="text-sm font-bold">Trusted by 500+ Students</p>
                  <p className="text-xs text-white/70">4.9/5 Average Rating</p>
                </div>
              </motion.div>
            </div>

            {/* RIGHT SIDE: Enrollment Form */}
            <div className="lg:col-span-7">
              <motion.form 
                initial={{ opacity: 0, y: 40 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ duration: 0.7 }}
                onSubmit={handleProceedPayment}
                className="relative bg-white/80 backdrop-blur-2xl border border-white shadow-[0_20px_60px_rgba(11,77,186,0.08)] rounded-[2rem] p-8 md:p-10"
              >
                <h2 className="text-3xl font-black text-primary mb-8">Personal Details</h2>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                  {/* Name */}
                  <div className="relative group">
                    <label className={`absolute left-4 transition-all duration-300 pointer-events-none z-10 ${focused === 'name' || formData.name ? '-top-2.5 text-xs font-bold text-primary bg-white px-2 rounded-full' : 'top-4 text-foreground/50 font-medium'}`}>
                      Full Name
                    </label>
                    <input 
                      type="text" name="name" required
                      value={formData.name} onChange={handleChange}
                      onFocus={() => setFocused('name')} onBlur={() => setFocused(null)}
                      className="w-full px-4 py-4 rounded-2xl bg-white/50 border-2 border-[#0B4DBA]/10 text-foreground font-medium outline-none transition-all duration-300 focus:border-primary focus:bg-white focus:shadow-[0_0_0_4px_rgba(11,77,186,0.1)]"
                    />
                  </div>
                  {/* Phone */}
                  <div className="relative group">
                    <label className={`absolute left-4 transition-all duration-300 pointer-events-none z-10 ${focused === 'phone' || formData.phone ? '-top-2.5 text-xs font-bold text-primary bg-white px-2 rounded-full' : 'top-4 text-foreground/50 font-medium'}`}>
                      Phone Number
                    </label>
                    <input 
                      type="tel" name="phone" required
                      value={formData.phone} onChange={handleChange}
                      onFocus={() => setFocused('phone')} onBlur={() => setFocused(null)}
                      className="w-full px-4 py-4 rounded-2xl bg-white/50 border-2 border-[#0B4DBA]/10 text-foreground font-medium outline-none transition-all duration-300 focus:border-primary focus:bg-white focus:shadow-[0_0_0_4px_rgba(11,77,186,0.1)]"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-6">
                  {/* Email */}
                  <div className="relative group">
                    <label className={`absolute left-4 transition-all duration-300 pointer-events-none z-10 ${focused === 'email' || formData.email ? '-top-2.5 text-xs font-bold text-primary bg-white px-2 rounded-full' : 'top-4 text-foreground/50 font-medium'}`}>
                      Email Address
                    </label>
                    <input 
                      type="email" name="email" required
                      value={formData.email} onChange={handleChange}
                      onFocus={() => setFocused('email')} onBlur={() => setFocused(null)}
                      className="w-full px-4 py-4 rounded-2xl bg-white/50 border-2 border-[#0B4DBA]/10 text-foreground font-medium outline-none transition-all duration-300 focus:border-primary focus:bg-white focus:shadow-[0_0_0_4px_rgba(11,77,186,0.1)]"
                    />
                  </div>
                  {/* Qualification */}
                  <div className="relative group">
                    <label className={`absolute left-4 transition-all duration-300 pointer-events-none z-10 ${focused === 'qualification' || formData.qualification ? '-top-2.5 text-xs font-bold text-primary bg-white px-2 rounded-full' : 'top-4 text-foreground/50 font-medium'}`}>
                      Highest Qualification
                    </label>
                    <input 
                      type="text" name="qualification" required
                      value={formData.qualification} onChange={handleChange}
                      onFocus={() => setFocused('qualification')} onBlur={() => setFocused(null)}
                      className="w-full px-4 py-4 rounded-2xl bg-white/50 border-2 border-[#0B4DBA]/10 text-foreground font-medium outline-none transition-all duration-300 focus:border-primary focus:bg-white focus:shadow-[0_0_0_4px_rgba(11,77,186,0.1)]"
                    />
                  </div>
                </div>

                {/* Address */}
                <div className="relative group mb-8">
                  <label className={`absolute left-4 transition-all duration-300 pointer-events-none z-10 ${focused === 'address' || formData.address ? '-top-2.5 text-xs font-bold text-primary bg-white px-2 rounded-full' : 'top-4 text-foreground/50 font-medium'}`}>
                    Full Address
                  </label>
                  <textarea 
                    name="address" rows={2} required
                    value={formData.address} onChange={handleChange}
                    onFocus={() => setFocused('address')} onBlur={() => setFocused(null)}
                    className="w-full px-4 py-4 rounded-2xl bg-white/50 border-2 border-[#0B4DBA]/10 text-foreground font-medium outline-none transition-all duration-300 focus:border-primary focus:bg-white focus:shadow-[0_0_0_4px_rgba(11,77,186,0.1)] resize-none"
                  />
                </div>

                <div className="h-px w-full bg-gradient-to-r from-transparent via-[#0B4DBA]/10 to-transparent mb-8" />

                <h2 className="text-3xl font-black text-primary mb-6">Select Plan</h2>
                
                <div className="space-y-4 mb-10">
                  {plans.map((plan) => (
                    <label 
                      key={plan.id}
                      className={`relative flex items-center justify-between p-5 rounded-2xl cursor-pointer border-2 transition-all duration-300 ${
                        formData.plan === plan.id 
                        ? 'border-primary bg-primary/5 shadow-[0_0_30px_rgba(11,77,186,0.1)]' 
                        : 'border-transparent bg-white hover:border-[#0B4DBA]/20'
                      }`}
                    >
                      <div className="flex items-center gap-4">
                        <div className={`w-6 h-6 rounded-full border-2 flex items-center justify-center transition-colors ${formData.plan === plan.id ? 'border-primary' : 'border-gray-300'}`}>
                          {formData.plan === plan.id && <div className="w-3 h-3 rounded-full bg-primary" />}
                        </div>
                        <div>
                          <div className="flex items-center gap-3">
                            <span className="font-bold text-primary text-lg">{plan.name}</span>
                            {plan.recommended && (
                              <span className="bg-accent text-white text-[10px] font-black uppercase tracking-wider px-2 py-0.5 rounded-full">Recommended</span>
                            )}
                          </div>
                        </div>
                      </div>
                      <div className="text-right">
                        <span className="block text-xl font-black text-primary">₹{plan.price.toLocaleString()}</span>
                        <span className="text-xs text-foreground/40 line-through">₹{plan.originalPrice.toLocaleString()}</span>
                      </div>
                    </label>
                  ))}
                </div>

                <motion.button
                  whileHover={{ scale: 1.02, boxShadow: '0 10px 40px rgba(255,107,0,0.3)' }}
                  whileTap={{ scale: 0.98 }}
                  type="submit"
                  disabled={isProcessing}
                  className="w-full flex items-center justify-center gap-2 py-5 rounded-2xl text-white font-black text-lg bg-gradient-to-r from-[#FF6B00] to-[#ff8c3a] disabled:opacity-70 disabled:cursor-not-allowed transition-all"
                >
                  {isProcessing ? <Loader2 className="animate-spin" /> : <Lock size={20} />}
                  {isProcessing ? 'Processing...' : 'Proceed to Secure Payment'}
                </motion.button>
              </motion.form>
            </div>
          </div>
        </div>
      </section>

      {/* FAKE RAZORPAY MODAL (Since we don't have real keys for demo) */}
      <AnimatePresence>
        {showGateway && (
          <motion.div 
            initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
            className="fixed inset-0 z-[100] flex items-center justify-center bg-black/60 backdrop-blur-sm px-4"
          >
            <motion.div 
              initial={{ scale: 0.9, y: 20 }} animate={{ scale: 1, y: 0 }} exit={{ scale: 0.9, y: 20 }}
              className="bg-white rounded-3xl overflow-hidden shadow-2xl w-full max-w-md"
            >
              <div className="bg-[#0B4DBA] text-white p-6 text-center">
                <img src="/logo.png" alt="Logo" className="h-8 mx-auto mb-4 bg-white/10 p-1 rounded" />
                <p className="text-sm opacity-80">Test Payment Gateway</p>
                <h3 className="text-3xl font-black mt-2">₹{plans.find(p => p.id === formData.plan)?.price.toLocaleString()}</h3>
              </div>
              <div className="p-8 space-y-4">
                <p className="text-center font-medium text-foreground/70 mb-6">Choose a payment method to complete your enrollment.</p>
                
                <button onClick={() => handleSimulatePayment(true)} className="w-full py-4 bg-[#25D366] hover:bg-[#20bd5a] text-white font-bold rounded-xl transition-colors">
                  Pay via UPI
                </button>
                <button onClick={() => handleSimulatePayment(true)} className="w-full py-4 bg-gray-100 hover:bg-gray-200 text-gray-800 font-bold rounded-xl transition-colors">
                  Pay via Credit / Debit Card
                </button>
                <button onClick={() => handleSimulatePayment(false)} className="w-full py-3 mt-4 text-red-500 font-bold hover:bg-red-50 rounded-xl transition-colors">
                  Cancel Payment
                </button>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      <Footer />
    </main>
  )
}
