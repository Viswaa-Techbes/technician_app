'use client'

import { lazy, Suspense } from 'react'
import { AdmissionShell } from '@/modules/admission/components/admission-shell'

const CourseAssignmentPage = lazy(() => import('@/modules/admission/pages/course-assignment-page'))

export default function Page() {
  return (
    <AdmissionShell>
      <Suspense fallback={<div className="animate-pulse p-4">Loading course assignment...</div>}>
        <CourseAssignmentPage />
      </Suspense>
    </AdmissionShell>
  )
}
