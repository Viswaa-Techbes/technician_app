export const GA_ADS_ID = process.env.NEXT_PUBLIC_GOOGLE_ADS_ID || 'AW-11352221800'

declare global {
  interface Window {
    dataLayer?: any[]
    gtag?: (...args: any[]) => void
  }
}

function isBrowser(): boolean {
  return typeof window !== 'undefined'
}

/**
 * Track page view with Google tag
 */
export const pageview = (url: string) => {
  if (!isBrowser()) return
  try {
    if (typeof window.gtag === 'function') {
      window.gtag('config', GA_ADS_ID, {
        page_path: url,
      })
    }
  } catch (e) {
    console.debug('[Google Ads] pageview error:', e)
  }
}

/**
 * Track conversion or custom event with Google Ads / gtag
 */
export const event = (action: string, params: Record<string, any> = {}) => {
  if (!isBrowser()) return
  try {
    if (typeof window.gtag === 'function') {
      window.gtag('event', action, params)
    }
  } catch (e) {
    console.debug(`[Google Ads] event error (${action}):`, e)
  }
}
