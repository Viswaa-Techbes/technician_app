'use client'

import { useEffect } from 'react'
import { usePathname } from 'next/navigation'

export function VisitorTracker() {
  const pathname = usePathname()

  useEffect(() => {
    // Generate or retrieve session ID
    let sessionId = localStorage.getItem('techbes_session_id')
    if (!sessionId) {
      sessionId = 'sess_' + Math.random().toString(36).substring(2, 15) + Date.now().toString(36)
      localStorage.setItem('techbes_session_id', sessionId)
    }

    const payload = {
      domain: typeof window !== 'undefined' ? window.location.hostname : 'skills.techbes.co.in',
      page: pathname || '/',
      eventType: 'page_view',
      sessionId: sessionId,
      referral: typeof document !== 'undefined' ? document.referrer : '',
      metadata: {
        language: typeof navigator !== 'undefined' ? navigator.language : 'unknown',
        timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
        screen: typeof window !== 'undefined' ? `${window.screen.width}x${window.screen.height}` : 'unknown',
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
