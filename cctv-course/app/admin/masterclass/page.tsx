export default async function AdminPage() {
  const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5000'
  let stats = { total: 0, paid: 0, pending: 0 }

  try {
    const res = await fetch(`${apiBase}/api/v2/cctv-course/admin/masterclass/stats`, {
      cache: 'no-store'
    })
    if (res.ok) {
      const json = await res.json()
      stats = json.data || json.stats || stats
    }
  } catch (err) {
    console.error('Failed to fetch admin stats:', err)
  }

  return (
    <div className="container px-4 py-10 text-white min-h-screen bg-slate-950 flex flex-col items-center">
      <div className="max-w-4xl w-full space-y-8">
        <div className="flex flex-col md:flex-row md:items-center justify-between border-b border-slate-800 pb-5">
          <h1 className="text-3xl font-extrabold tracking-tight">Admin - Masterclass Metrics</h1>
          <p className="text-slate-400 text-sm mt-1 md:mt-0">Live enrollment activity dashboard</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
          <div className="p-6 bg-slate-900 border border-slate-800 rounded-xl space-y-2">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider block">Total Registrations</span>
            <div className="text-3xl font-extrabold text-white">{stats.total}</div>
          </div>
          <div className="p-6 bg-slate-900 border border-slate-800 rounded-xl space-y-2">
            <span className="text-xs font-bold text-green-500 uppercase tracking-wider block">Paid Enrolled Students</span>
            <div className="text-3xl font-extrabold text-green-400">{stats.paid}</div>
          </div>
          <div className="p-6 bg-slate-900 border border-slate-800 rounded-xl space-y-2">
            <span className="text-xs font-bold text-yellow-500 uppercase tracking-wider block">Pending Payments</span>
            <div className="text-3xl font-extrabold text-yellow-400">{stats.pending}</div>
          </div>
        </div>

        <div className="bg-slate-900/50 border border-slate-800 rounded-xl p-6">
          <h3 className="font-semibold text-base text-slate-200 mb-2">Technical Summary</h3>
          <p className="text-sm text-slate-400 leading-relaxed">
            All data shown in this dashboard is pulled from the common shared backend API (<code className="text-red-400 text-xs">{apiBase}</code>) dynamically. Direct database connectivity has been removed to satisfy frontend-only decoupling requirements.
          </p>
        </div>
      </div>
    </div>
  )
}
