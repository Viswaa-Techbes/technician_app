import Link from 'next/link'
import { Phone, MapPin } from 'lucide-react'

export function Footer() {
  return (
    <footer className="w-full border-t border-gray-200 bg-white">
      <div className="container mx-auto px-4 py-12 md:py-16">
        <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-8">
          {/* Brand */}
          <div className="space-y-4">
            <h3 className="text-2xl font-bold" style={{ color: '#0B4DBA' }}>
              TECHBES
            </h3>
            <p className="text-sm text-gray-600 max-w-xs">
              Professional CCTV & IT Skill Development Program with practical training and real project internship.
            </p>
          </div>

          {/* Contact Info */}
          <div className="space-y-4">
            <h4 className="font-semibold" style={{ color: '#0B4DBA' }}>
              Contact
            </h4>
            <div className="space-y-3 text-sm text-gray-600">
              <div className="flex items-center gap-2">
                <Phone size={18} style={{ color: '#FF6B00' }} />
                <span>9591144949</span>
              </div>
              <div className="flex items-start gap-2">
                <MapPin size={18} style={{ color: '#FF6B00' }} className="flex-shrink-0 mt-0.5" />
                <div>
                  <p>Nagarbhavi, Bangalore</p>
                  <p>Karnataka – 560072</p>
                </div>
              </div>
            </div>
          </div>

          {/* Quick Links */}
          <div className="space-y-4">
            <h4 className="font-semibold" style={{ color: '#0B4DBA' }}>
              Quick Links
            </h4>
            <ul className="space-y-2 text-sm text-gray-600">
              <li>
                <Link href="/" className="hover:underline" style={{ color: '#0B4DBA' }}>
                  Home
                </Link>
              </li>
              <li>
                <Link href="/admission" className="hover:underline" style={{ color: '#0B4DBA' }}>
                  Admission
                </Link>
              </li>
              <li>
                <Link href="/internship" className="hover:underline" style={{ color: '#0B4DBA' }}>
                  Internship
                </Link>
              </li>
              <li>
                <Link href="/enquiry" className="hover:underline" style={{ color: '#0B4DBA' }}>
                  Enquiry
                </Link>
              </li>
            </ul>
          </div>
        </div>

        {/* Bottom Section */}
        <div className="border-t border-gray-200 pt-8 text-center text-sm text-gray-600">
          <p className="font-semibold mb-2" style={{ color: '#FF6B00' }}>
            Admissions Open – Limited Seats – Enroll Now
          </p>
          <p>&copy; {new Date().getFullYear()} TECHBES. All rights reserved.</p>
        </div>
      </div>
    </footer>
  )
}
