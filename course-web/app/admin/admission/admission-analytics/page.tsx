'use client'

import { lazy, Suspense } from 'react'
import { AdmissionShell } from '@/modules/admission/components/admission-shell'

const AdmissionAnalyticsPage = lazy(() => import('@/modules/admission/pages/admission-analytics-page'))

export default function Page() {
  return (
    <AdmissionShell>
      <Suspense fallback={<div className="animate-pulse p-4">Loading admission analytics...</div>}>
        <AdmissionAnalyticsPage />
      </Suspense>
    </AdmissionShell>
  )
}
