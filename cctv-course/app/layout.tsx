import './globals.css'
import { ReactNode } from 'react'
import Script from 'next/script'

export const metadata = {
  title: 'CCTV Masterclass | TECHBES',
  description:
    'Join the TECHBES live CCTV Masterclass and learn CCTV basics, IP cameras, NVR, PoE networking, mobile viewing and troubleshooting through practical demonstrations.',
}

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body>
        <main className="min-h-screen">
          {children}
        </main>
        <Script src="https://checkout.razorpay.com/v1/checkout.js" strategy="lazyOnload" />
      </body>
    </html>
  )
}
