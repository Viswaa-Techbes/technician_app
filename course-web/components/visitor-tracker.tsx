'use client'

import { useEffect } from 'react'
import { usePathname } from 'next/navigation'

export function VisitorTracker() {
  const pathname = usePathname()

  useEffect(() => {
    const payload = {
      page: pathname || '/',
      eventType: 'page_view',
      metadata: {
        language: typeof navigator !== 'undefined' ? navigator.language : 'unknown',
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      },
    }

    fetch('/api/analytics/track', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      keepalive: true,
    }).catch(() => {})
  }, [pathname])

  return null
}
