'use client'

import { lazy, Suspense } from 'react'

const AnalyticsDashboardPage = lazy(() => import('@/modules/analytics/pages/analytics-dashboard-page'))

export default function Page() {
  return (
    <main className="min-h-screen bg-[#F5F9FF] p-4 md:p-8">
      <Suspense fallback={<div className="animate-pulse rounded-xl bg-white p-6">Loading dashboard...</div>}>
        <AnalyticsDashboardPage />
      </Suspense>
    </main>
  )
}
