"use client"
import Link from 'next/link'
import { Mail, Phone } from 'lucide-react'

const footerLinks = [
  {
    title: 'Masterclass',
    links: [
      { label: 'About',           href: '#overview'   },
      { label: "What You'll Learn", href: '#learn'    },
      { label: 'Why Join',         href: '#practical' },
      { label: 'Registration',     href: '#register'  },
      { label: 'FAQ',              href: '#faq'       },
    ],
  },
  {
    title: 'Legal',
    links: [
      { label: 'Privacy Policy',   href: '/privacy'  },
      { label: 'Terms & Conditions', href: '/terms'  },
      { label: 'Refund Policy',    href: '/refund'   },
    ],
  },
  {
    title: 'Verify',
    links: [
      { label: 'Certificate Verification', href: '/certificate' },
    ],
  },
]

export default function Footer() {
  return (
    <footer className="bg-[#050912] border-t border-white/[0.06]">
      <div className="max-w-section mx-auto px-6 lg:px-10 pt-14 pb-8">
        <div className="grid sm:grid-cols-2 lg:grid-cols-4 gap-10 mb-12">

          {/* Brand */}
          <div className="lg:col-span-1">
            <div className="font-extrabold text-2xl tracking-widest text-white mb-3">
              TECH<span className="text-[#F5C842]">BES</span>
              <sup className="text-[#F5C842] text-xs ml-0.5">®</sup>
            </div>
            <p className="text-slate-500 text-sm leading-relaxed mb-5">
              Technology Services. Simplified.
            </p>
            <div className="space-y-2">
              <div className="flex items-center gap-2 text-slate-500 text-sm">
                <Mail size={13} />
                <span>contact@techbes.in</span>
              </div>
            </div>
          </div>

          {/* Link columns */}
          {footerLinks.map(col => (
            <div key={col.title}>
              <h4 className="text-white font-bold text-xs tracking-[0.15em] uppercase mb-5">
                {col.title}
              </h4>
              <ul className="space-y-3">
                {col.links.map(link => (
                  <li key={link.label}>
                    <a
                      href={link.href}
                      className="text-slate-500 hover:text-[#F5C842] text-sm transition-colors"
                    >
                      {link.label}
                    </a>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>

        {/* Divider */}
        <div className="h-[1px] bg-gradient-to-r from-transparent via-white/[0.07] to-transparent mb-6" />

        {/* Bottom row */}
        <div className="flex flex-col sm:flex-row items-center justify-between gap-3 text-xs text-slate-600">
          <div>© 2026 TECHBES. All rights reserved.</div>
          <div className="flex items-center gap-1.5">
            <span className="inline-block w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse" />
            Payment secured by Razorpay
          </div>
        </div>
      </div>
    </footer>
  )
}
