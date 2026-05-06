'use client'

import Link from 'next/link'
import Image from 'next/image'
import { Button } from '@/components/ui/button'
import { Menu, X } from 'lucide-react'
import { useState } from 'react'

export function Header() {
  const [isOpen, setIsOpen] = useState(false)

  return (
    <header className="sticky top-0 z-50 w-full bg-white border-b border-gray-200">
      <div className="container mx-auto flex h-16 items-center justify-between px-4">
        {/* Logo */}
        <Link href="/" className="flex items-center">
          <Image
            src="/logo.png"
            alt="TECHBES Logo"
            width={140}
            height={50}
            className="h-12 w-auto"
            priority
          />
        </Link>

        {/* Desktop Navigation */}
        <nav className="hidden md:flex items-center space-x-8">
          <Link href="/" className="text-sm font-medium" style={{ color: '#0B4DBA' }}>
            Home
          </Link>
          <Link href="/courses" className="text-sm font-medium" style={{ color: '#0B4DBA' }}>
            Courses
          </Link>
          <Link href="/admission" className="text-sm font-medium" style={{ color: '#0B4DBA' }}>
            Admission
          </Link>
          <Link href="/internship" className="text-sm font-medium" style={{ color: '#0B4DBA' }}>
            Internship
          </Link>
          <Link href="/enquiry" className="text-sm font-medium" style={{ color: '#0B4DBA' }}>
            Enquiry
          </Link>
          <Link href="/contact" className="text-sm font-medium" style={{ color: '#0B4DBA' }}>
            Contact
          </Link>
        </nav>

        {/* CTA Button */}
        <div className="hidden md:block">
          <Button
            className="font-medium text-white"
            style={{ backgroundColor: '#FF6B00' }}
          >
            Admissions Open
          </Button>
        </div>

        {/* Mobile Menu Button */}
        <button
          onClick={() => setIsOpen(!isOpen)}
          className="md:hidden"
          style={{ color: '#0B4DBA' }}
        >
          {isOpen ? <X size={24} /> : <Menu size={24} />}
        </button>
      </div>

      {/* Mobile Navigation */}
      {isOpen && (
        <nav className="md:hidden bg-white border-t border-gray-200">
          <div className="container mx-auto px-4 py-4 space-y-3">
            <Link href="/" className="block text-sm font-medium" style={{ color: '#0B4DBA' }}>
              Home
            </Link>
            <Link href="/courses" className="block text-sm font-medium" style={{ color: '#0B4DBA' }}>
              Courses
            </Link>
            <Link href="/admission" className="block text-sm font-medium" style={{ color: '#0B4DBA' }}>
              Admission
            </Link>
            <Link href="/internship" className="block text-sm font-medium" style={{ color: '#0B4DBA' }}>
              Internship
            </Link>
            <Link href="/enquiry" className="block text-sm font-medium" style={{ color: '#0B4DBA' }}>
              Enquiry
            </Link>
            <Link href="/contact" className="block text-sm font-medium" style={{ color: '#0B4DBA' }}>
              Contact
            </Link>
            <Button
              className="w-full font-medium text-white"
              style={{ backgroundColor: '#FF6B00' }}
            >
              Admissions Open
            </Button>
          </div>
        </nav>
      )}
    </header>
  )
}
