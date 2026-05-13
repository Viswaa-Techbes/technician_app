 'use client'

import React, { useEffect } from 'react'
import { event } from '@/lib/fpixel'
import Link from 'next/link'
import { CheckCircle, ArrowRight } from 'lucide-react'

export default function EnrollmentSuccessPage() {
  useEffect(() => {
    try {
      event('CompleteRegistration')
    } catch (e) {
      console.debug('fbq track error', e)
    }
  }, [])

  return (
    <main className="min-h-screen bg-background flex items-center justify-center px-4">
      <div className="max-w-md w-full">
        <div className="text-center space-y-6">
          <div className="flex justify-center">
            <CheckCircle className="w-16 h-16 text-green-600" />
          </div>

          <div className="space-y-2">
            <h1 className="text-3xl font-bold text-foreground">
              Enrollment Successful!
            </h1>
            <p className="text-foreground/70">
              Thank you for enrolling. A confirmation email has been sent to your email address.
            </p>
          </div>

          <div className="bg-accent/10 border border-accent/20 rounded-lg p-4 space-y-2">
            <p className="text-sm font-semibold text-foreground">
              What happens next?
            </p>
            <ul className="text-sm text-foreground/70 space-y-1">
              <li>• Check your email for course access details</li>
              <li>• Join our learning community</li>
              <li>• Start learning at your own pace</li>
            </ul>
          </div>

          <div className="flex flex-col gap-3">
            <Link
              href="/courses"
              className="inline-flex items-center justify-center gap-2 bg-accent hover:bg-accent/90 text-white font-semibold py-3 px-6 rounded-lg transition"
            >
              Browse More Courses
              <ArrowRight className="w-4 h-4" />
            </Link>
            <Link
              href="/"
              className="inline-flex items-center justify-center gap-2 bg-foreground/10 hover:bg-foreground/20 text-foreground font-semibold py-3 px-6 rounded-lg transition"
            >
              Back to Home
            </Link>
          </div>

          <p className="text-xs text-foreground/50 pt-4">
            Questions? Contact us at{' '}
            <a href="mailto:support@techbes.com" className="text-accent hover:underline">
              support@techbes.com
            </a>
          </p>
        </div>
      </div>
    </main>
  )
}
