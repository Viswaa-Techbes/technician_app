'use client'

import { useEffect, useRef } from 'react'
import { usePathname, useSearchParams } from 'next/navigation'
import { FB_PIXEL_ID } from '../lib/fpixel'

export default function MetaPixel() {
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const isFirstRender = useRef(true)

  useEffect(() => {
    // Skip tracking on initial mount as the base script snippet in root layout handles the initial PageView
    if (isFirstRender.current) {
      isFirstRender.current = false
      return
    }

    if (FB_PIXEL_ID && typeof window !== 'undefined' && typeof window.fbq === 'function') {
      window.fbq('track', 'PageView')
    }
  }, [pathname, searchParams])

  return null
}

