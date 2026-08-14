export default async function Page({ params }: { params: { certificateId: string } }) {
  const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5000'
  let cert = null

  try {
    const res = await fetch(`${apiBase}/api/v2/cctv-course/certificates/${params.certificateId}`, {
      cache: 'no-store'
    })
    if (res.ok) {
      const json = await res.json()
      cert = json.data || json.certificate
    }
  } catch (err) {
    console.error('Failed to fetch certificate verification details:', err)
  }

  if (!cert) {
    return (
      <div className="container px-4 py-10 text-white min-h-screen flex items-center justify-center bg-slate-950">
        <div className="bg-slate-900 border border-slate-800 p-6 rounded-xl text-center max-w-md w-full">
          <div className="text-red-500 font-bold text-lg mb-2">Verification Failed</div>
          <div className="text-slate-400 text-sm">Certificate ID "{params.certificateId}" could not be verified or is invalid.</div>
        </div>
      </div>
    )
  }

  return (
    <div className="container px-4 py-10 text-white min-h-screen flex items-center justify-center bg-slate-950">
      <div className="max-w-md w-full bg-slate-900 border border-slate-800 p-8 rounded-2xl shadow-xl space-y-6">
        <h1 className="text-2xl font-bold text-center border-b border-slate-800 pb-4 text-slate-100 font-extrabold">Certificate Verification</h1>
        <div className="space-y-4">
          <div className="bg-green-500/10 border border-green-500/20 text-green-400 font-bold py-2.5 px-3 rounded-lg text-center text-sm">
            ✓ Authentic & Verified Certificate
          </div>
          <div className="space-y-3 text-sm text-slate-300">
            <div>
              <span className="text-slate-500 font-semibold block text-xs uppercase tracking-wider mb-0.5">Certificate ID</span>
              <code className="text-red-400 font-mono font-semibold">{cert.certificateId}</code>
            </div>
            <div>
              <span className="text-slate-500 font-semibold block text-xs uppercase tracking-wider mb-0.5">Participant Name</span>
              <span className="font-bold text-slate-100">{cert.participantName}</span>
            </div>
            <div>
              <span className="text-slate-500 font-semibold block text-xs uppercase tracking-wider mb-0.5">Program / Course</span>
              <span className="font-semibold text-slate-100">{cert.programName}</span>
            </div>
            <div>
              <span className="text-slate-500 font-semibold block text-xs uppercase tracking-wider mb-0.5">Date of Issue</span>
              <span className="text-slate-100">{cert.issueDate ? new Date(cert.issueDate).toDateString() : 'N/A'}</span>
            </div>
          </div>
          {cert.pdfPath && (
            <div className="pt-4 border-t border-slate-800">
              <a href={`${apiBase}${cert.pdfPath}`} target="_blank" rel="noopener noreferrer" className="block text-center bg-red-600 hover:bg-red-700 text-white font-bold py-2.5 px-4 rounded-lg transition-colors text-sm shadow-md shadow-red-950/20">
                Download PDF Copy
              </a>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
