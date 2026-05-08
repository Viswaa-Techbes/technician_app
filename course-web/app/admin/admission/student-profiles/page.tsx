'use client'

import { lazy, Suspense } from 'react'
import { AdmissionShell } from '@/modules/admission/components/admission-shell'

const StudentProfilesPage = lazy(() => import('@/modules/admission/pages/student-profiles-page'))

export default function Page() {
  return (
    <AdmissionShell>
      <Suspense fallback={<div className="animate-pulse p-4">Loading student profiles...</div>}>
        <StudentProfilesPage />
      </Suspense>
    </AdmissionShell>
  )
}
