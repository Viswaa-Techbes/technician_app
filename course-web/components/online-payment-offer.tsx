"use client"

import { motion } from 'framer-motion'
import { Lock, Star, CreditCard } from 'lucide-react'
import React from 'react'

export default function OnlinePaymentOffer() {
  const [open, setOpen] = React.useState(true)

  if (!open) return null

  return (
    <motion.div
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.6 }}
      className="fixed right-4 bottom-28 z-50"
    >
      <div className="relative">
        <div className="rounded-2xl p-[2px] bg-gradient-to-r from-[#FF6B00] to-[#0B4DBA] shadow-[0_20px_50px_rgba(11,77,186,0.12)]">
          <div className="w-72 md:w-80 p-4 rounded-2xl bg-white/50 backdrop-blur-md border border-white/30 relative overflow-hidden">
            <button
              onClick={() => setOpen(false)}
              aria-label="Dismiss offer"
              className="absolute top-2 right-2 text-foreground/70 hover:text-foreground"
            >
              ×
            </button>

            <div className="flex items-start gap-3">
              <div className="w-12 h-12 rounded-xl flex items-center justify-center bg-gradient-to-br from-[#FF6B00] to-[#ff984d] text-white shadow-md">
                <CreditCard size={18} />
              </div>
              <div>
                <p className="text-xs font-semibold text-foreground/70">⚡ Online Payment Offer</p>
                <h3 className="text-lg font-black text-primary leading-tight">Get Instant 10% Discount</h3>
              </div>
            </div>

            <p className="text-sm text-foreground/60 mt-3">Pay online using Razorpay and get instant admission confirmation with secure checkout.</p>

            <ul className="text-sm text-foreground/70 mt-3 space-y-1">
              <li>• Secure Razorpay Payment</li>
              <li>• Instant Confirmation</li>
              <li>• EMI Support Available</li>
            </ul>

            <div className="mt-4 flex items-center justify-between gap-3">
              <div className="text-sm text-foreground/70">&nbsp;</div>
              <motion.button
                whileHover={{ scale: 1.02, boxShadow: '0 12px 40px rgba(255,107,0,0.18)' }}
                whileTap={{ scale: 0.98 }}
                className="inline-flex items-center gap-2 py-2 px-4 rounded-lg font-black text-sm text-white bg-gradient-to-r from-[#FF6B00] to-[#ff8c3a]"
              >
                <Lock size={14} />
                Pay & Save Now
              </motion.button>
            </div>
          </div>
        </div>
        <div className="absolute -right-2 -bottom-6 bg-white/90 text-sm rounded-full px-3 py-1 font-bold text-[#FF6B00] shadow-md animate-pulse">10% OFF</div>
      </div>
    </motion.div>
  )
}
