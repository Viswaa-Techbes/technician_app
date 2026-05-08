'use client'

import { AnalyticsCards } from '@/modules/analytics/components/analytics-cards'
import { useVisitorDashboard } from '@/modules/analytics/hooks/use-visitor-dashboard'

export default function AnalyticsDashboardPage() {
  const { data, loading, error } = useVisitorDashboard()

  if (loading) return <div className="animate-pulse rounded-xl bg-white p-6">Loading analytics...</div>
  if (error) return <div className="rounded-xl bg-red-50 p-6 text-red-700">{error}</div>

  return (
    <div className="space-y-4">
      <h2 className="text-2xl font-black text-primary">Analytics Dashboard</h2>
      <AnalyticsCards data={data} />
    </div>
  )
}
