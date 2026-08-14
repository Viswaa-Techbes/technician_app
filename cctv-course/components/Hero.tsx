import Link from 'next/link'
import { motion } from 'framer-motion'

export default function Hero() {
  return (
    <section className="grid md:grid-cols-2 gap-8 items-center">
      <div>
        <div className="inline-flex items-center gap-2 bg-yellow-400/10 text-yellow-300 px-3 py-1 rounded-full text-sm">LIVE & PRACTICAL</div>
        <h1 className="mt-6 text-4xl md:text-5xl font-extrabold">CCTV MASTERCLASS</h1>
        <p className="mt-3 text-slate-300">Learn. Practice. Build Your Career.</p>

        <p className="mt-6 text-slate-300">Learn CCTV Installation, IP Networking, NVR Configuration, Mobile Viewing and Troubleshooting through a live practical masterclass.</p>

        <div className="mt-6 flex items-center gap-4">
          <div className="text-sm text-slate-400 line-through">₹999</div>
          <div className="text-3xl font-bold text-yellow-300">₹499</div>
          <div className="ml-3 px-2 py-1 bg-red-600 text-white rounded">SPECIAL LAUNCH OFFER</div>
        </div>

        <div className="mt-6">
          <Link href="#register">
            <motion.a whileHover={{ scale: 1.02 }} className="inline-block bg-red-600 text-white px-6 py-3 rounded font-semibold">REGISTER NOW – ₹499</motion.a>
          </Link>
        </div>

        <div className="mt-6 grid grid-cols-2 gap-2 text-sm text-slate-300">
          <div className="p-3 bg-white/3 rounded">Live Interactive Session</div>
          <div className="p-3 bg-white/3 rounded">Practical Demonstration</div>
          <div className="p-3 bg-white/3 rounded">E-Certificate</div>
          <div className="p-3 bg-white/3 rounded">Industry Experts</div>
        </div>
      </div>

      <div className="flex justify-center">
        <div className="w-full max-w-md h-64 bg-gradient-to-br from-slate-800 to-slate-900 rounded-lg border border-yellow-800 flex items-center justify-center">
          <img src="/images/poster-preview.jpg" alt="CCTV Masterclass" className="object-cover h-full w-full rounded-lg" />
        </div>
      </div>
    </section>
  )
}
