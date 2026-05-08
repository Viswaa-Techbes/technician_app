import type { MetadataRoute } from 'next'

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://techbes.in'

export default function sitemap(): MetadataRoute.Sitemap {
  const routes = [
    '',
    '/about',
    '/courses',
    '/internship',
    '/enquiry',
    '/contact',
    '/admission',
  ]

  return routes.map((route) => ({
    url: `${siteUrl}${route}`,
    lastModified: new Date(),
    changeFrequency: route === '' || route === '/courses' ? 'weekly' : 'monthly',
    priority: route === '' ? 1 : route === '/admission' ? 0.95 : route === '/courses' ? 0.9 : 0.8,
  }))
}
