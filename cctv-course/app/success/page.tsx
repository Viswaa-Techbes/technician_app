"use client"
import { useSearchParams } from 'next/navigation'
import Link from 'next/link'
import { CheckCircle2, Calendar, Clock, BookOpen, ExternalLink, ArrowLeft } from 'lucide-react'

export default function SuccessPage() {
  const searchParams = useSearchParams()
  const id = searchParams.get('id')
  const certId = searchParams.get('cert')

  return (
    <div className="min-h-screen bg-slate-950 text-white flex items-center justify-center p-4">
      <div className="max-w-xl w-full bg-slate-900/60 border border-slate-800/80 rounded-2xl p-8 backdrop-blur-md shadow-2xl text-center space-y-6">
        <div className="flex justify-center">
          <div className="p-3 bg-green-500/10 rounded-full border border-green-500/20">
            <CheckCircle2 className="w-16 h-16 text-green-500 animate-pulse" />
          </div>
        </div>
        
        <div className="space-y-2">
          <h1 className="text-3xl font-extrabold tracking-tight text-white bg-gradient-to-r from-white via-slate-200 to-slate-400 bg-clip-text text-transparent">
            Enrollment Confirmed!
          </h1>
          <p className="text-slate-400 text-sm">
            Thank you for registering. Your payment has been verified, and your seat is secured.
          </p>
        </div>

        {id && (
          <div className="bg-slate-950/60 py-3 px-5 rounded-lg inline-block border border-slate-800">
            <span className="text-xs text-slate-500 block uppercase tracking-wider font-bold mb-1">
              Registration ID
            </span>
            <code className="text-red-400 font-mono text-sm font-semibold">{id}</code>
          </div>
        )}

        <div className="border-t border-b border-slate-800/80 py-6 my-6 text-left space-y-4">
          <h3 className="font-semibold text-lg text-slate-200">What's Next?</h3>
          <div className="grid gap-3.5 text-sm text-slate-300">
            <div className="flex items-start gap-3">
              <Calendar className="w-5 h-5 text-red-500 shrink-0 mt-0.5" />
              <span>
                <strong>Confirmation Email:</strong> A verification and confirmation email has been dispatched to your email address containing schedule details.
              </span>
            </div>
            <div className="flex items-start gap-3">
              <Clock className="w-5 h-5 text-red-500 shrink-0 mt-0.5" />
              <span>
                <strong>Timing:</strong> Live sessions will be held from 10:00 AM to 4:00 PM. Please log in 10 minutes early.
              </span>
            </div>
            <div className="flex items-start gap-3">
              <BookOpen className="w-5 h-5 text-red-500 shrink-0 mt-0.5" />
              <span>
                <strong>Course Materials:</strong> Relevant links, software downloads, and guidebooks will be shared via email prior to the session.
              </span>
            </div>
          </div>
        </div>

        {certId && (
          <div className="bg-red-950/10 border border-red-900/30 p-5 rounded-xl text-left space-y-3">
            <p className="text-sm text-slate-300">
              A certificate verification profile has been pre-allocated to you. You can preview and verify your certificate details below:
            </p>
            <Link href={`/certificate/${certId}`} className="inline-flex items-center gap-2 text-red-400 font-bold hover:text-red-300 transition-colors text-sm">
              <span>Verify Pre-allocated Certificate</span>
              <ExternalLink className="w-4 h-4" />
            </Link>
          </div>
        )}

        <div className="pt-4 flex flex-col sm:flex-row gap-3 justify-center">
          <Link href="/" className="flex items-center justify-center gap-2 bg-slate-800 hover:bg-slate-700 text-slate-200 px-6 py-3 rounded-lg font-semibold transition-colors text-sm cursor-pointer border border-slate-700/50">
            <ArrowLeft className="w-4 h-4" />
            <span>Back to Home</span>
          </Link>
        </div>
      </div>
    </div>
  )
}
