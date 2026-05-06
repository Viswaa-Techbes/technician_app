'use client'

import Link from 'next/link'
import { motion } from 'framer-motion'
import { Facebook, Instagram, Linkedin, MapPin, Phone, Twitter } from 'lucide-react'

export function Footer() {
  return (
    <footer className="relative mt-20 overflow-hidden bg-[#061f4f] pt-24 pb-12 text-white">
      {/* Background Effects */}
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_-20%,rgba(11,77,186,0.3),transparent_60%)]" />
      <div className="absolute inset-0 bg-[linear-gradient(rgba(255,255,255,0.02)_1px,transparent_1px),linear-gradient(90deg,rgba(255,255,255,0.02)_1px,transparent_1px)] bg-[size:40px_40px]" />

      <div className="container relative z-10 mx-auto px-4">
        <div className="grid grid-cols-1 gap-12 md:grid-cols-2 lg:grid-cols-4">
          {/* Brand Info */}
          <div className="space-y-6">
            <Link href="/" className="flex items-center gap-2">
              <img 
                src="/logo.png" 
                alt="TECHBES Logo" 
                className="h-14 md:h-16 w-auto object-contain bg-white/90 p-2 rounded-xl" 
              />
            </Link>
            <p className="text-lg font-medium text-white/70">
              Skills Today, Career Tomorrow. The leading institute for CCTV and IT skill development.
            </p>
            <div className="flex gap-4">
              {[Facebook, Instagram, Twitter, Linkedin].map((Icon, i) => (
                <motion.a
                  key={i}
                  href="#"
                  whileHover={{ y: -5, scale: 1.1 }}
                  className="flex h-10 w-10 items-center justify-center rounded-lg bg-white/10 transition-colors hover:bg-primary"
                >
                  <Icon size={20} />
                </motion.a>
              ))}
            </div>
          </div>

          {/* Quick Links */}
          <div>
            <h4 className="mb-8 text-xl font-bold text-accent">Quick Links</h4>
            <ul className="space-y-4 text-white/70">
              {['Home', 'Courses', 'Admission', 'Internship', 'Enquiry', 'Contact'].map((item) => (
                <li key={item}>
                  <Link href={`/${item.toLowerCase() === 'home' ? '' : item.toLowerCase()}`} className="transition-colors hover:text-primary">
                    {item}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Courses */}
          <div>
            <h4 className="mb-8 text-xl font-bold text-accent">Our Courses</h4>
            <ul className="space-y-4 text-white/70">
              <li>CCTV Technology</li>
              <li>Networking</li>
              <li>Computer Hardware</li>
              <li>Practical Training</li>
              <li>Business Skills</li>
            </ul>
          </div>

          {/* Contact Info */}
          <div className="space-y-6">
            <h4 className="mb-8 text-xl font-bold text-accent">Contact Us</h4>
            <div className="flex items-start gap-4">
              <div className="mt-1 rounded-lg bg-white/10 p-2 text-accent">
                <Phone size={20} />
              </div>
              <div>
                <p className="text-sm font-bold text-white/50">Phone</p>
                <p className="text-lg font-bold">9591144949</p>
              </div>
            </div>
            <div className="flex items-start gap-4">
              <div className="mt-1 rounded-lg bg-white/10 p-2 text-accent">
                <MapPin size={20} />
              </div>
              <div>
                <p className="text-sm font-bold text-white/50">Address</p>
                <p className="text-lg font-medium">Nagarbhavi, Bangalore, Karnataka – 560072</p>
              </div>
            </div>
          </div>
        </div>

        {/* Divider */}
        <div className="my-16 h-px w-full bg-gradient-to-r from-transparent via-white/20 to-transparent" />

        {/* Copyright */}
        <div className="flex flex-col items-center justify-between gap-6 md:flex-row text-white/50">
          <p>© {new Date().getFullYear()} TECHBES. All rights reserved.</p>
          <div className="flex gap-8 text-sm">
            <a href="#" className="hover:text-white">Privacy Policy</a>
            <a href="#" className="hover:text-white">Terms of Service</a>
          </div>
        </div>
      </div>
    </footer>
  )
}
