import './globals.css'
import { ReactNode, Suspense } from 'react'
import Script from 'next/script'
import MetaPixel from '../components/MetaPixel'
import { FB_PIXEL_ID } from '../lib/fpixel'

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
        {/* Meta Pixel Base Script */}
        <Script
          id="meta-pixel-base"
          strategy="afterInteractive"
          dangerouslySetInnerHTML={{
            __html: `
              !function(f,b,e,v,n,t,s)
              {if(f.fbq)return;n=f.fbq=function(){n.callMethod?
              n.callMethod.apply(n,arguments):n.queue.push(arguments)};
              if(!f._fbq)f._fbq=n;n.push=n;n.loaded=!0;n.version='2.0';
              n.queue=[];t=b.createElement(e);t.async=!0;
              t.src=v;s=b.getElementsByTagName(e)[0];
              s.parentNode.insertBefore(t,s)}
              (window, document,'script',
              'https://connect.facebook.net/en_US/fbevents.js');
              fbq('init', '${FB_PIXEL_ID}');
              fbq('track', 'PageView');
              if (window._fbqQueue && Array.isArray(window._fbqQueue)) {
                window._fbqQueue.forEach(function(item) {
                  if (item && item.length >= 2) {
                    fbq(item[0], item[1], item[2] || {});
                  }
                });
                window._fbqQueue = [];
              }
            `,
          }}
        />
        <noscript>
          <img
            height="1"
            width="1"
            style={{ display: 'none' }}
            src={`https://www.facebook.com/tr?id=${FB_PIXEL_ID}&ev=PageView&noscript=1`}
            alt=""
          />
        </noscript>
        <Suspense fallback={null}>
          <MetaPixel />
        </Suspense>
        {children}
        <Script src="https://checkout.razorpay.com/v1/checkout.js" strategy="lazyOnload" />
      </body>
    </html>
  )
}
