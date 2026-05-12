export const FB_PIXEL = '1645190790022717'

export const pageview = () => {
    window.fbq('track', 'PageView')
}

export const event = (name, options = {}) => {
    window.fbq('track', name, options)
}