import type { Metadata } from 'next'
import { Analytics } from '@vercel/analytics/next'
import { MouseGlow } from '@/components/premium-ui'
import { WhatsAppFloatingButton } from '@/components/whatsapp-floating-button'
import { VisitorTracker } from '@/components/visitor-tracker'
import './globals.css'

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://techbes.in'
const siteName = 'TECHBES'
const siteTitle = 'TECHBES - CCTV & Networking IT Skill Development Program'
const siteDescription =
  'Join TECHBES for practical CCTV installation, networking, computer hardware, field service training, internship, certification, and job assistance in Bangalore.'

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  applicationName: siteName,
  title: {
    default: siteTitle,
    template: `%s | ${siteName}`,
  },
  description: siteDescription,
  keywords: [
    'TECHBES',
    'TECHBES Bangalore',
    'CCTV training Bangalore',
    'CCTV installation course Bangalore',
    'networking course Bangalore',
    'computer hardware course Bangalore',
    'IT skill development program',
    'field service engineer training',
    'CCTV technician course',
    'network technician course',
    'job ready IT training',
    'CCTV internship Bangalore',
  ],
  authors: [{ name: siteName }],
  creator: siteName,
  publisher: siteName,
  category: 'education',
  classification: 'CCTV and IT skill development training institute',
  alternates: {
    canonical: '/',
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      'max-image-preview': 'large',
      'max-snippet': -1,
      'max-video-preview': -1,
    },
  },
  openGraph: {
    title: siteTitle,
    description: siteDescription,
    url: '/',
    siteName,
    images: [
      {
        url: '/logo.png',
        width: 1366,
        height: 451,
        alt: 'TECHBES logo',
      },
    ],
    locale: 'en_IN',
    type: 'website',
  },
  twitter: {
    card: 'summary_large_image',
    title: siteTitle,
    description: siteDescription,
    images: ['/logo.png'],
  },
  icons: {
    icon: '/logo.png',
    shortcut: '/logo.png',
    apple: '/logo.png',
  },
}

const structuredData = {
  '@context': 'https://schema.org',
  '@graph': [
    {
      '@type': 'EducationalOrganization',
      '@id': `${siteUrl}/#organization`,
      name: siteName,
      url: siteUrl,
      logo: `${siteUrl}/logo.png`,
      image: `${siteUrl}/logo.png`,
      telephone: '+919591144949',
      address: {
        '@type': 'PostalAddress',
        addressLocality: 'Bangalore',
        addressRegion: 'Karnataka',
        postalCode: '560072',
        addressCountry: 'IN',
      },
      sameAs: [`https://wa.me/919591144949`],
    },
    {
      '@type': 'Course',
      '@id': `${siteUrl}/#cctv-it-course`,
      name: 'CCTV & Networking IT Skill Development Program',
      description: siteDescription,
      provider: {
        '@id': `${siteUrl}/#organization`,
      },
      educationalCredentialAwarded: 'Certificate of Completion',
      teaches: [
        'CCTV installation',
        'IP and analog cameras',
        'Networking',
        'Computer hardware',
        'Field service',
        'Client handling',
      ],
      offers: {
        '@type': 'Offer',
        url: `${siteUrl}/admission`,
        priceCurrency: 'INR',
        price: '1',
        availability: 'https://schema.org/InStock',
      },
    },
    {
      '@type': 'WebSite',
      '@id': `${siteUrl}/#website`,
      name: siteName,
      url: siteUrl,
      publisher: {
        '@id': `${siteUrl}/#organization`,
      },
    },
  ],
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html lang="en" className="bg-background">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;500;600;700;800;900&display=swap"
          rel="stylesheet"
        />
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(structuredData) }}
        />
      </head>
      <body className="antialiased bg-background text-foreground" style={{ fontFamily: "'Poppins', sans-serif" }}>
        <MouseGlow />
        <VisitorTracker />
        {children}
        <WhatsAppFloatingButton />
        {process.env.NODE_ENV === 'production' && <Analytics />}
      </body>
    </html>
  )
}
