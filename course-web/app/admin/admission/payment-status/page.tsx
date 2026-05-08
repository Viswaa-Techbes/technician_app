'use client'

import { lazy, Suspense } from 'react'
import { AdmissionShell } from '@/modules/admission/components/admission-shell'

const PaymentStatusPage = lazy(() => import('@/modules/admission/pages/payment-status-page'))

export default function Page() {
  return (
    <AdmissionShell>
      <Suspense fallback={<div className="animate-pulse p-4">Loading payment status...</div>}>
        <PaymentStatusPage />
      </Suspense>
    </AdmissionShell>
  )
}
