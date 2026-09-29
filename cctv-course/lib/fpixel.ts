export const FB_PIXEL_ID = process.env.NEXT_PUBLIC_META_PIXEL_ID || '1645190790022717'

declare global {
  interface Window {
    fbq?: any
    _fbq?: any
    _fbqQueue?: any[]
  }
}

function isBrowser(): boolean {
  return typeof window !== 'undefined'
}

/**
 * Track standard PageView event
 */
export const pageview = () => {
  if (!isBrowser()) return
  try {
    if (typeof window.fbq === 'function') {
      window.fbq('track', 'PageView')
    } else {
      window._fbqQueue = window._fbqQueue || []
      window._fbqQueue.push(['track', 'PageView', {}])
    }
  } catch (e) {
    console.debug('[Meta Pixel] PageView error:', e)
  }
}

/**
 * Generic standard or custom event tracker
 */
export const event = (name: string, options: Record<string, any> = {}) => {
  if (!isBrowser()) return
  if (!name || typeof name !== 'string') {
    console.warn('[Meta Pixel] Invalid event name:', name)
    return
  }

  try {
    if (typeof window.fbq === 'function') {
      if (options && Object.keys(options).length > 0) {
        window.fbq('track', name, options)
      } else {
        window.fbq('track', name)
      }
    } else {
      window._fbqQueue = window._fbqQueue || []
      window._fbqQueue.push(['track', name, options])
    }
  } catch (e) {
    console.debug(`[Meta Pixel] Event error (${name}):`, e)
  }
}

/**
 * Track ViewContent for the CCTV Masterclass page
 */
export const trackViewContent = (options: Record<string, any> = {}) => {
  event('ViewContent', {
    content_name: 'CCTV Masterclass — Live Practical Training',
    content_category: 'Course',
    content_ids: ['cctv-masterclass'],
    content_type: 'product',
    value: 499,
    currency: 'INR',
    ...options,
  })
}

let lastInitiateCheckoutTime = 0

/**
 * Track InitiateCheckout with a 3-second debounce guard against accidental multi-clicks
 */
export const trackInitiateCheckout = (options: Record<string, any> = {}) => {
  const now = Date.now()
  if (now - lastInitiateCheckoutTime < 3000) return
  lastInitiateCheckoutTime = now

  event('InitiateCheckout', {
    content_name: 'CCTV Masterclass — Live Practical Training',
    content_category: 'Course',
    content_ids: ['cctv-masterclass'],
    content_type: 'product',
    value: 499,
    currency: 'INR',
    num_items: 1,
    ...options,
  })
}

const PURCHASE_STORAGE_KEY = 'tb_meta_pixel_purchases'

/**
 * Track Purchase event exactly once per transaction identifier.
 * Deduplicates using localStorage so page refreshes or revisits will NEVER fire a duplicate Purchase event.
 */
export const trackPurchase = (
  transactionId: string,
  options: {
    value?: number
    currency?: string
    content_name?: string
    content_ids?: string[]
    payment_id?: string
    order_id?: string
    [key: string]: any
  } = {}
): boolean => {
  if (!transactionId) {
    console.warn('[Meta Pixel] trackPurchase skipped: Missing transaction identifier.')
    return false
  }

  if (isBrowser()) {
    try {
      const stored = localStorage.getItem(PURCHASE_STORAGE_KEY)
      const recorded: string[] = stored ? JSON.parse(stored) : []
      if (recorded.includes(transactionId)) {
        console.debug(`[Meta Pixel] Purchase for transaction "${transactionId}" already tracked. Skipping duplicate.`)
        return false
      }
      recorded.push(transactionId)
      localStorage.setItem(PURCHASE_STORAGE_KEY, JSON.stringify(recorded))
    } catch (e) {
      console.debug('[Meta Pixel] Purchase deduplication storage check error:', e)
    }
  }

  event('Purchase', {
    content_name: options.content_name || 'CCTV Masterclass — Live Practical Training',
    content_category: 'Course',
    content_ids: options.content_ids || ['cctv-masterclass'],
    content_type: 'product',
    value: options.value ?? 499,
    currency: options.currency || 'INR',
    num_items: 1,
    order_id: options.order_id || transactionId,
    ...(options.payment_id ? { payment_id: options.payment_id } : {}),
    ...options,
  })

  return true
}

const LEAD_STORAGE_KEY = 'tb_meta_pixel_leads'
const trackedLeadIds = new Set<string>()

/**
 * Track Meta Pixel standard Lead event exactly once per registration/lead identifier.
 * Deduplicates using localStorage and an in-memory set so page refreshes, back navigation,
 * or repeated component renders will NEVER fire duplicate Lead events.
 */
export const trackLead = (
  leadId: string,
  options: {
    content_name?: string
    content_category?: string
    value?: number
    currency?: string
    [key: string]: any
  } = {}
): boolean => {
  if (!leadId) {
    console.warn('[Meta Pixel] trackLead skipped: Missing registration/lead identifier.')
    return false
  }

  // Session / in-memory deduplication (guards against React StrictMode & immediate re-renders)
  if (trackedLeadIds.has(leadId)) {
    console.debug(`[Meta Pixel] Lead for identifier "${leadId}" already tracked in current session. Skipping duplicate.`)
    return false
  }

  if (isBrowser()) {
    try {
      const stored = localStorage.getItem(LEAD_STORAGE_KEY)
      const recorded: string[] = stored ? JSON.parse(stored) : []
      if (recorded.includes(leadId)) {
        console.debug(`[Meta Pixel] Lead for identifier "${leadId}" already tracked. Skipping duplicate.`)
        trackedLeadIds.add(leadId)
        return false
      }
      recorded.push(leadId)
      localStorage.setItem(LEAD_STORAGE_KEY, JSON.stringify(recorded))
    } catch (e) {
      console.debug('[Meta Pixel] Lead deduplication storage check error:', e)
    }
  }

  trackedLeadIds.add(leadId)

  event('Lead', {
    content_name: options.content_name || 'CCTV Masterclass — Live Practical Training',
    content_category: options.content_category || 'Course',
    value: options.value ?? 499,
    currency: options.currency || 'INR',
    ...options,
  })

  return true
}

