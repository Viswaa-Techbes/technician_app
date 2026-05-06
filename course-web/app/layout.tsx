import type { Metadata } from 'next'
import { Analytics } from '@vercel/analytics/next'
import { MouseGlow } from '@/components/premium-ui'
import './globals.css'

export const metadata: Metadata = {
  title: 'TECHBES - CCTV & IT Skill Development Program',
  description: '2 Months Training + 1 Month Internship. 100% Practical Training, Real Project Internship, Job Assistance. Admissions Open!',
  icons: {
    icon: [
      { url: '/icon-light-32x32.png', media: '(prefers-color-scheme: light)' },
      { url: '/icon-dark-32x32.png', media: '(prefers-color-scheme: dark)' },
      { url: '/icon.svg', type: 'image/svg+xml' },
    ],
    apple: '/apple-icon.png',
  },
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
      </head>
      <body className="antialiased bg-background text-foreground" style={{ fontFamily: "'Poppins', sans-serif" }}>
        <MouseGlow />
        {children}
        {process.env.NODE_ENV === 'production' && <Analytics />}
      </body>
    </html>
  )
}
