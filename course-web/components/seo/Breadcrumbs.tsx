'use client'

import Link from 'next/link'
import { ChevronRight, Home } from 'lucide-react'

interface BreadcrumbItem {
  label: string
  href: string
}

interface BreadcrumbsProps {
  items: BreadcrumbItem[]
}

export function Breadcrumbs({ items }: BreadcrumbsProps) {
  return (
    <nav aria-label="Breadcrumb" className="flex items-center space-x-2 text-sm text-foreground/50 mb-6">
      <Link href="/" className="hover:text-primary transition-colors flex items-center gap-1">
        <Home size={14} />
        <span>Home</span>
      </Link>
      {items.map((item, index) => (
        <div key={item.href} className="flex items-center space-x-2">
          <ChevronRight size={14} />
          <Link
            href={item.href}
            className={`hover:text-primary transition-colors ${
              index === items.length - 1 ? 'text-primary font-bold pointer-events-none' : ''
            }`}
          >
            {item.label}
          </Link>
        </div>
      ))}
    </nav>
  )
}
