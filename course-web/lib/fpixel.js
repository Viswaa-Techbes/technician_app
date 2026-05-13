export const FB_PIXEL = '1645190790022717'

function isBrowser() {
    return typeof window !== 'undefined'
}

export const pageview = () => {
    if (!isBrowser()) return
    try {
        if (typeof window.fbq === 'function') {
            window.fbq('track', 'PageView')
        } else {
            window.__fbqQueue = window.__fbqQueue || []
            window.__fbqQueue.push({ name: 'PageView', options: {} })
        }
    } catch (e) {
        // swallow errors to avoid breaking client code
        console.debug('fb pixel pageview error', e)
    }
}

export const event = (name, options = {}) => {
    if (!isBrowser()) return
    if (!name || typeof name !== 'string') {
        console.warn('fb pixel: invalid event name', name)
        return
    }

    try {
        if (typeof window.fbq === 'function') {
            window.fbq('track', name, options)
        } else {
            window.__fbqQueue = window.__fbqQueue || []
            window.__fbqQueue.push({ name, options })
        }
    } catch (e) {
        console.debug('fb pixel event error', e)
    }
}