'use client'

import { useAdmissionApplications } from '@/modules/admission/hooks/use-admission-applications'
import { ApplicationTable } from '@/modules/admission/components/application-table'

export default function AllApplicationsPage() {
  const { applications, loading, search, setSearch, stats } = useAdmissionApplications()

  return (
    <div className="space-y-4">
      <div className="grid grid-cols-1 gap-3 md:grid-cols-3">
        <div className="rounded-xl bg-white p-4">
          <div className="text-xs text-primary/70">Total Applications</div>
          <div className="text-2xl font-black text-primary">{stats.total}</div>
        </div>
        <div className="rounded-xl bg-white p-4">
          <div className="text-xs text-primary/70">Approved</div>
          <div className="text-2xl font-black text-primary">{stats.approved}</div>
        </div>
        <div className="rounded-xl bg-white p-4">
          <div className="text-xs text-primary/70">Enrolled</div>
          <div className="text-2xl font-black text-primary">{stats.enrolled}</div>
        </div>
      </div>
      <input
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        placeholder="Search applications"
        className="w-full rounded-xl border border-primary/20 bg-white px-3 py-2"
      />
      <ApplicationTable data={applications} loading={loading} />
    </div>
  )
}
