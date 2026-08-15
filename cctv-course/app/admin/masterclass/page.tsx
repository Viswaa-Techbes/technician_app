import { Users, DollarSign, CheckCircle, Clock, Award, TrendingUp } from 'lucide-react'

interface Stats {
  total: number
  paid: number
  pending: number
  attended?: number
  absent?: number
  certificates?: number
  revenue?: number
}

async function getStats(): Promise<Stats> {
  const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5000'
  try {
    const res = await fetch(`${apiBase}/api/v2/cctv-course/admin/masterclass/stats`, { cache: 'no-store' })
    if (res.ok) {
      const json = await res.json()
      return json.data || json.stats || { total: 0, paid: 0, pending: 0 }
    }
  } catch {}
  return { total: 0, paid: 0, pending: 0 }
}

const statCards = (s: Stats) => [
  { label: 'Total Registrations', value: s.total,              icon: Users,       color: '#F5C842', bg: 'rgba(245,200,66,0.1)',  border: 'rgba(245,200,66,0.2)'  },
  { label: 'Paid',                value: s.paid,               icon: CheckCircle, color: '#22C55E', bg: 'rgba(34,197,94,0.1)',   border: 'rgba(34,197,94,0.2)'   },
  { label: 'Pending Payment',     value: s.pending,            icon: Clock,       color: '#F97316', bg: 'rgba(249,115,22,0.1)',  border: 'rgba(249,115,22,0.2)'  },
  { label: 'Attended',            value: s.attended ?? '—',    icon: TrendingUp,  color: '#0EA5E9', bg: 'rgba(14,165,233,0.1)',  border: 'rgba(14,165,233,0.2)'  },
  { label: 'Certificates Issued', value: s.certificates ?? '—', icon: Award,      color: '#A855F7', bg: 'rgba(168,85,247,0.1)', border: 'rgba(168,85,247,0.2)'  },
  { label: 'Revenue',             value: s.revenue != null ? `₹${(s.revenue / 100).toLocaleString('en-IN')}` : '—', icon: DollarSign, color: '#22C55E', bg: 'rgba(34,197,94,0.1)', border: 'rgba(34,197,94,0.2)' },
]

export default async function AdminPage() {
  const stats = await getStats()
  const apiBase = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:5000'
  const cards = statCards(stats)

  return (
    <div className="min-h-screen bg-[#050912] text-white" style={{ paddingTop: '80px' }}>
      <div className="max-w-section mx-auto px-6 lg:px-10 py-12">

        {/* Header */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-10">
          <div>
            <div className="text-[#F5C842] font-bold text-xs tracking-[0.2em] uppercase mb-2">
              TECHBES Admin
            </div>
            <h1 className="font-extrabold text-white" style={{ fontSize: 'clamp(1.5rem, 3vw, 2rem)' }}>
              Masterclass Dashboard
            </h1>
            <p className="text-slate-400 text-sm mt-1">
              Live enrollment activity and participant metrics
            </p>
          </div>
          <div className="flex items-center gap-2 text-xs text-slate-500 bg-[#0A1020] border border-white/[0.07] px-4 py-2 rounded-xl">
            <span className="w-2 h-2 rounded-full bg-green-500 animate-pulse inline-block" />
            Live Data — {new Date().toLocaleDateString('en-IN', { day: 'numeric', month: 'short', year: 'numeric' })}
          </div>
        </div>

        {/* Stat Cards */}
        <div className="grid grid-cols-2 lg:grid-cols-3 gap-4 mb-10">
          {cards.map(({ label, value, icon: Icon, color, bg, border }) => (
            <div
              key={label}
              className="rounded-2xl p-5"
              style={{ background: 'rgba(10,16,32,0.8)', border: `1px solid ${border}`, backdropFilter: 'blur(12px)' }}
            >
              <div className="flex items-start justify-between mb-4">
                <div
                  className="w-10 h-10 rounded-xl flex items-center justify-center"
                  style={{ background: bg }}
                >
                  <Icon size={18} style={{ color }} />
                </div>
              </div>
              <div className="font-extrabold text-2xl text-white mb-1">{value}</div>
              <div className="text-slate-400 text-xs font-semibold tracking-wide">{label}</div>
            </div>
          ))}
        </div>

        {/* Technical note */}
        <div
          className="rounded-xl p-5 mb-8"
          style={{ background: 'rgba(10,16,32,0.6)', border: '1px solid rgba(255,255,255,0.06)' }}
        >
          <h3 className="text-slate-300 font-semibold text-sm mb-2">Data Source</h3>
          <p className="text-slate-500 text-xs leading-relaxed">
            All data is pulled from the shared backend API at{' '}
            <code className="text-[#F5C842] text-xs bg-[#0A1020] px-1.5 py-0.5 rounded">{apiBase}</code>.
            For full participant management, search, and attendance marking, use the backend admin panel.
          </p>
        </div>

        {/* Legend */}
        <div
          className="rounded-xl p-5"
          style={{ background: 'rgba(245,200,66,0.04)', border: '1px solid rgba(245,200,66,0.12)' }}
        >
          <h3 className="text-[#F5C842] font-bold text-xs tracking-widest uppercase mb-3">Admin Actions</h3>
          <div className="grid sm:grid-cols-2 gap-2 text-xs text-slate-400">
            {[
              'Mark Attendance — via Backend API',
              'Generate Certificates — via Backend API',
              'Export Participant List — via Backend API',
              'Send Certificate Emails — via Backend API',
            ].map(a => (
              <div key={a} className="flex items-center gap-2">
                <span className="w-1.5 h-1.5 rounded-full bg-[#F5C842] inline-block" />
                {a}
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  )
}
