import { CheckCircle2, XCircle, Download } from 'lucide-react'
import Link from 'next/link'

interface Certificate {
  certificateId: string
  participantName: string
  programName: string
  issueDate?: string
  pdfPath?: string
}

async function getCertificate(id: string): Promise<Certificate | null> {
  const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5000'
  try {
    const res = await fetch(`${apiBase}/api/v2/cctv-course/certificates/${id}`, { cache: 'no-store' })
    if (res.ok) {
      const json = await res.json()
      return json.data || json.certificate || null
    }
  } catch {}
  return null
}

export default async function CertificatePage({ params }: { params: { certificateId: string } }) {
  const cert = await getCertificate(params.certificateId)
  const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5000'

  if (!cert) {
    return (
      <div className="min-h-screen bg-[#050912] text-white flex items-center justify-center p-4" style={{ paddingTop: '80px' }}>
        <div
          className="max-w-md w-full rounded-2xl p-8 text-center"
          style={{ background: 'rgba(10,16,32,0.8)', border: '1px solid rgba(229,57,53,0.2)', backdropFilter: 'blur(16px)' }}
        >
          <div className="w-16 h-16 rounded-full bg-[#E53935]/10 border border-[#E53935]/25 flex items-center justify-center mx-auto mb-5">
            <XCircle size={32} className="text-[#E53935]" />
          </div>
          <h1 className="font-extrabold text-white text-xl mb-2">Verification Failed</h1>
          <p className="text-slate-400 text-sm mb-1">
            Certificate ID <code className="text-[#EF5350]">{params.certificateId}</code> could not be verified.
          </p>
          <p className="text-slate-500 text-xs mt-2">
            This certificate may be invalid, expired, or does not exist.
          </p>
          <Link href="/" className="inline-block mt-6 text-[#F5C842] text-sm font-semibold hover:text-[#FFD96A] transition-colors">
            ← Back to Home
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-[#050912] text-white flex items-center justify-center p-4" style={{ paddingTop: '80px', paddingBottom: '80px' }}>
      {/* Background glow */}
      <div
        className="fixed inset-0 pointer-events-none"
        style={{ background: 'radial-gradient(ellipse 50% 50% at 50% 30%, rgba(245,200,66,0.05) 0%, transparent 70%)' }}
      />

      <div className="relative max-w-lg w-full">
        {/* Verified badge */}
        <div className="text-center mb-6">
          <div
            className="inline-flex items-center justify-center w-20 h-20 rounded-full mx-auto mb-4"
            style={{ background: 'rgba(34,197,94,0.1)', border: '2px solid rgba(34,197,94,0.3)' }}
          >
            <CheckCircle2 size={40} className="text-green-400" />
          </div>
          <div className="bg-green-500/12 border border-green-500/25 text-green-400 font-bold text-xs tracking-widest uppercase px-5 py-2 rounded-full inline-flex items-center gap-2">
            <span className="w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse inline-block" />
            CERTIFICATE VERIFIED ✓
          </div>
        </div>

        {/* Certificate card */}
        <div
          className="rounded-2xl overflow-hidden"
          style={{ background: 'rgba(10,16,32,0.85)', border: '1px solid rgba(245,200,66,0.2)', backdropFilter: 'blur(16px)' }}
        >
          {/* Gold header */}
          <div
            className="px-7 py-5 text-center"
            style={{ background: 'linear-gradient(135deg, rgba(245,200,66,0.08) 0%, rgba(10,16,32,1) 70%)', borderBottom: '1px solid rgba(245,200,66,0.12)' }}
          >
            <div className="font-extrabold text-xl tracking-widest text-white">
              TECH<span className="text-[#F5C842]">BES</span>
              <sup className="text-[#F5C842] text-xs ml-0.5">®</sup>
            </div>
            <div className="text-slate-400 text-xs mt-1 tracking-widest uppercase">Certificate of Participation</div>
          </div>

          {/* Details */}
          <div className="px-7 py-6 space-y-5">
            <div className="text-center py-4 border-b border-white/[0.06]">
              <div className="text-slate-500 text-xs font-semibold tracking-widest uppercase mb-1">
                This certifies that
              </div>
              <div className="font-extrabold text-white text-2xl">{cert.participantName}</div>
              <div className="text-slate-400 text-sm mt-1">successfully participated in</div>
              <div className="text-[#F5C842] font-bold text-base mt-1">{cert.programName}</div>
            </div>

            {[
              { label: 'Certificate ID',  value: cert.certificateId,  mono: true  },
              { label: 'Program',         value: cert.programName,     mono: false },
              { label: 'Date of Issue',   value: cert.issueDate ? new Date(cert.issueDate).toLocaleDateString('en-IN', { day: 'numeric', month: 'long', year: 'numeric' }) : 'Pending', mono: false },
            ].map(({ label, value, mono }) => (
              <div key={label} className="flex items-start justify-between gap-4">
                <span className="text-slate-500 text-xs font-bold tracking-widest uppercase flex-shrink-0">{label}</span>
                <span className={`font-semibold text-sm text-right ${mono ? 'font-mono text-[#F5C842]' : 'text-slate-200'}`}>
                  {value}
                </span>
              </div>
            ))}
          </div>

          {/* Download */}
          {cert.pdfPath && (
            <div className="px-7 pb-7">
              <a
                href={`${apiBase}${cert.pdfPath}`}
                target="_blank"
                rel="noopener noreferrer"
                className="btn-gold w-full py-3.5 rounded-xl text-sm font-extrabold tracking-wide flex items-center justify-center gap-2"
              >
                <Download size={16} />
                Download PDF Certificate
              </a>
            </div>
          )}
        </div>

        <div className="text-center mt-5">
          <Link href="/" className="text-slate-500 text-xs hover:text-slate-300 transition-colors">
            ← Back to TECHBES Masterclass
          </Link>
        </div>
      </div>
    </div>
  )
}
