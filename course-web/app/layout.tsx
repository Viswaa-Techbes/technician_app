import type { Metadata } from 'next'
import { Analytics } from '@vercel/analytics/next'
import { GoogleTagManager } from '@next/third-parties/google'
import Script from 'next/script'
import { MouseGlow } from '@/components/premium-ui'
import { WhatsAppFloatingButton } from '@/components/whatsapp-floating-button'
import './globals.css'


const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'https://skills.techbes.co.in'
const siteName = 'TECHBES'
const siteTitle = 'CCTV Training & IT Skill Development Program | TECHBES India'
const siteDescription =
  'Master CCTV installation, Networking, and IT skills with TECHBES. 100% practical training, 1-month internship, and job assistance. Start your technical career today.'

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
    'CCTV training India',
    'CCTV installation course',
    'Networking course',
    'Computer hardware training',
    'IT skill development program',
    'Field service engineer training',
    'CCTV technician course',
    'Network technician course',
    'Job oriented technical courses',
    'Skill development courses India',
  ],
  authors: [{ name: siteName }],
  creator: siteName,
  publisher: siteName,
  category: 'education',
  classification: 'Professional Technical Training Institute',
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
        width: 1200,
        height: 630,
        alt: 'TECHBES - CCTV & IT Training Excellence',
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
      description: siteDescription,
      sameAs: [`https://wa.me/919591144949`],
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
    {
      '@type': 'LocalBusiness',
      '@id': `${siteUrl}/#localbusiness`,
      name: siteName,
      image: `${siteUrl}/logo.png`,
      telephone: '+919591144949',
      url: siteUrl,
      address: {
        '@type': 'PostalAddress',
        addressLocality: 'Bangalore',
        addressRegion: 'Karnataka',
        postalCode: '560072',
        addressCountry: 'IN',
      },
      priceRange: '₹₹',
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
        {/* Meta Pixel base code - placed in head so it's on every page */}
        <Script id="facebook-pixel" strategy="afterInteractive">
          {`!function(f,b,e,v,n,t,s)
            {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
            n.callMethod.apply(n,arguments):n.queue.push(arguments)};
            if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
            n.queue=[];t=b.createElement(e);t.async=!0;
            t.src=v;s=b.getElementsByTagName(e)[0];
            s.parentNode.insertBefore(t,s)}(window, document,'script',
            'https://connect.facebook.net/en_US/fbevents.js');

            fbq('init', '1645190790022717');
            fbq('track', 'PageView');`}
        </Script>
      </head>
      <body className="antialiased bg-background text-foreground" style={{ fontFamily: "'Poppins', sans-serif" }}>
        {/* noscript fallback for Meta Pixel */}
        <noscript>
          <img height="1" width="1" style={{display:'none'}} alt="" src="https://www.facebook.com/tr?id=1645190790022717&ev=PageView&noscript=1" />
        </noscript>
        <GoogleTagManager gtmId="GTM-W2LHV9PC" />
        <MouseGlow />
        {children}
        <WhatsAppFloatingButton />
        {process.env.NODE_ENV === 'production' && <Analytics />}

        {process.env.NODE_ENV === 'production' && (
          <Script id="ga-domain-loader" strategy="afterInteractive">
            {`(function(){
  try{
    var mapping = {
      "techbes.co.in": "${process.env.NEXT_PUBLIC_GA_MAIN || ""}",
      "www.techbes.co.in": "${process.env.NEXT_PUBLIC_GA_MAIN || ""}",
      "skills.techbes.co.in": "${process.env.NEXT_PUBLIC_GA_SKILLS || ""}",
      "members.techbes.co.in": "${process.env.NEXT_PUBLIC_GA_MEMBERS || ""}",
      "localhost": "${process.env.NEXT_PUBLIC_GA_MAIN || ""}"
    };
    var host = window.location.hostname;
    var id = mapping[host] || mapping[host.replace(/^www\./,"")] || "${process.env.NEXT_PUBLIC_GA_MAIN || ""}";
    if(!id) return;
    var s = document.createElement('script');
    s.async = true;
    s.src = 'https://www.googletagmanager.com/gtag/js?id=' + id;
    document.head.appendChild(s);
    window.dataLayer = window.dataLayer || []; function gtag(){dataLayer.push(arguments);} window.gtag = window.gtag || gtag;
    gtag('js', new Date());
    gtag('config', id, { send_page_view: true });
  }catch(e){console.error('GA init error', e)}
})();`}
          </Script>

        )}
        
      </body>
    </html>
  )
}
