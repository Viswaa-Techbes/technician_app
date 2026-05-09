'use client'

import { useEffect, useState } from 'react'
import { motion } from 'framer-motion'
import { CheckCircle2, ChevronRight, Download, Laptop } from 'lucide-react'
import Link from 'next/link'
import { Header } from '@/components/header'
import { Footer } from '@/components/footer'
import { useSearchParams } from 'next/navigation'

import { Suspense } from 'react'

function SuccessContent() {
  const searchParams = useSearchParams()
  const id = searchParams?.get('id') || 'ENR-XXXXXX'
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) return null

  const handleDownloadReceipt = () => {
    window.print()
  }

  return (
    <div className="flex-1 flex items-center justify-center pt-32 pb-20 px-4 relative overflow-hidden">
      <style jsx global>{`
        @media print {
          .no-print { display: none !important; }
          .print-only { display: block !important; }
          body { background: white !important; }
          .receipt-card { border: 1px solid #eee !important; box-shadow: none !important; margin: 0 !important; width: 100% !important; }
        }
      `}</style>

      <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_50%,rgba(37,211,102,0.1),transparent_50%)] no-print" />
      
      <motion.div 
        initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} transition={{ duration: 0.5 }}
        className="bg-white/80 backdrop-blur-xl border border-white shadow-[0_20px_80px_rgba(37,211,102,0.15)] rounded-[2rem] p-8 md:p-12 max-w-2xl w-full text-center relative z-10 receipt-card"
      >
        <div className="no-print">
          <motion.div 
            initial={{ scale: 0 }} animate={{ scale: 1 }} transition={{ type: 'spring', delay: 0.2 }}
            className="w-24 h-24 bg-gradient-to-br from-green-400 to-green-600 rounded-full flex items-center justify-center mx-auto mb-6 shadow-lg shadow-green-500/30"
          >
            <CheckCircle2 size={48} className="text-white" />
          </motion.div>

          <h1 className="text-4xl md:text-5xl font-black text-primary mb-4">Payment Successful!</h1>
          <p className="text-lg text-foreground/60 mb-8">
            Welcome to TECHBES. Your enrollment is confirmed and your tech journey starts now.
          </p>
        </div>

        {/* PRINT HEADER */}
        <div className="hidden print-only text-left mb-8 border-b pb-6">
           <h2 className="text-2xl font-bold text-primary">TECHBES PAYMENT RECEIPT</h2>
           <p className="text-sm text-gray-500">Official Enrollment Confirmation</p>
        </div>

        <div className="bg-primary/5 rounded-2xl p-6 text-left mb-8 border border-primary/10">
          <p className="text-xs font-bold text-accent uppercase tracking-widest mb-4">Enrollment Details</p>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-foreground/50 font-medium">Enrollment ID</p>
              <p className="font-bold text-primary">{id}</p>
            </div>
            <div>
              <p className="text-sm text-foreground/50 font-medium">Status</p>
              <p className="font-bold text-green-600 flex items-center gap-1"><CheckCircle2 size={14}/> Confirmed</p>
            </div>
            <div className="col-span-2 mt-2">
              <p className="text-sm text-foreground/50 font-medium">Course</p>
              <p className="font-bold text-foreground">CCTV & IT Skill Development Program</p>
            </div>
          </div>
        </div>

        <div className="flex flex-col sm:flex-row gap-4 justify-center no-print">
          <Link href="/dashboard">
            <motion.button 
              whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
              className="w-full sm:w-auto px-8 py-4 bg-primary text-white font-bold rounded-xl flex items-center justify-center gap-2 shadow-[0_8px_30px_rgba(11,77,186,0.3)]"
            >
              <Laptop size={20} /> Go to Dashboard
            </motion.button>
          </Link>
          <motion.button 
            onClick={handleDownloadReceipt}
            whileHover={{ scale: 1.05 }} whileTap={{ scale: 0.95 }}
            className="w-full sm:w-auto px-8 py-4 bg-white text-primary font-bold rounded-xl border-2 border-primary/20 flex items-center justify-center gap-2"
          >
            <Download size={20} /> Download Receipt
          </motion.button>
        </div>
        
        <p className="hidden print-only text-xs text-gray-400 mt-12 text-center">
          This is a computer generated receipt and does not require a signature. <br/>
          TECHBES - Skill Development & Field Services
        </p>
      </motion.div>
    </div>
  )
}

export default function SuccessPage() {
  return (
    <main className="min-h-screen flex flex-col bg-[#F5F9FF]">
      <Header />
      <Suspense fallback={<div className="flex-1 flex items-center justify-center pt-32 pb-20">Loading...</div>}>
        <SuccessContent />
      </Suspense>
      <Footer />
    </main>
  )
}
