'use client'

import { useEffect, useRef } from 'react'
import { usePathname, useSearchParams } from 'next/navigation'
import Script from 'next/script'
import { FB_PIXEL_ID } from '../lib/fpixel'

export default function MetaPixel() {
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const isFirstRender = useRef(true)

  useEffect(() => {
    // Skip tracking on initial mount as the base script snippet handles the first PageView
    if (isFirstRender.current) {
      isFirstRender.current = false
      return
    }

    if (FB_PIXEL_ID && typeof window !== 'undefined' && typeof window.fbq === 'function') {
      window.fbq('track', 'PageView')
    }
  }, [pathname, searchParams])

  if (!FB_PIXEL_ID) {
    if (process.env.NODE_ENV === 'development') {
      console.warn(
        '[Meta Pixel] NEXT_PUBLIC_META_PIXEL_ID is not configured. Meta Pixel tracking is disabled.'
      )
    }
    return null
  }

  return (
    <Script
      id="meta-pixel-base"
      strategy="afterInteractive"
      dangerouslySetInnerHTML={{
        __html: `
          !function(f,b,e,v,n,t,s)
          {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
          n.callMethod.apply(n,arguments):n.queue.push(arguments)};
          if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
          n.queue=[];t=b.createElement(e);t.async=!0;
          t.src=v;s=b.getElementsByTagName(e)[0];
          s.parentNode.insertBefore(t,s)}
          (window, document,'script',
          'https://connect.facebook.net/en_US/fbevents.js');

          fbq('init', '${FB_PIXEL_ID}');
          fbq('track', 'PageView');

          if (window._fbqQueue && Array.isArray(window._fbqQueue)) {
            window._fbqQueue.forEach(function(item) {
              if (item && item.length >= 2) {
                fbq(item[0], item[1], item[2] || {});
              }
            });
            window._fbqQueue = [];
          }
        `,
      }}
    />
  )
}
