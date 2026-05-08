'use client'

import { lazy, Suspense } from 'react'
import { AdmissionShell } from '@/modules/admission/components/admission-shell'

const InternshipAssignmentPage = lazy(() => import('@/modules/admission/pages/internship-assignment-page'))

export default function Page() {
  return (
    <AdmissionShell>
      <Suspense fallback={<div className="animate-pulse p-4">Loading internship assignment...</div>}>
        <InternshipAssignmentPage />
      </Suspense>
    </AdmissionShell>
  )
}
