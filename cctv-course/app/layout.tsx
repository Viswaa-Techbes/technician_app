import './globals.css'
import { ReactNode, Suspense } from 'react'
import Script from 'next/script'
import MetaPixel from '../components/MetaPixel'

export const metadata = {
  title: 'CCTV Masterclass — Live Practical Training | TECHBES',
  description:
    'Join the TECHBES live CCTV Masterclass. Learn CCTV installation, IP cameras, NVR configuration, mobile viewing and troubleshooting through a live practical session. Only ₹499.',
  keywords: 'CCTV Masterclass, CCTV Training, IP Camera, NVR Setup, TECHBES, Live CCTV Course',
}

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <head>
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <meta name="theme-color" content="#FAFAFA" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
      </head>
      <body>
        <Suspense fallback={null}>
          <MetaPixel />
        </Suspense>
        {children}
        <Script src="https://checkout.razorpay.com/v1/checkout.js" strategy="lazyOnload" />
      </body>
    </html>
  )
}
