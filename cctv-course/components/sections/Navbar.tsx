"use client"
import { useState, useEffect } from 'react'
import Link from 'next/link'
import { motion, AnimatePresence } from 'framer-motion'
import { Menu, X } from 'lucide-react'

const navLinks = [
  { label: 'Masterclass',      href: '#overview'   },
  { label: "What You'll Learn", href: '#learn'      },
  { label: 'Why Join',          href: '#practical'  },
  { label: 'Who Can Join',      href: '#audience'   },
  { label: 'FAQ',               href: '#faq'        },
]

export default function Navbar() {
  const [scrolled, setScrolled] = useState(false)
  const [menuOpen, setMenuOpen] = useState(false)

  useEffect(() => {
    const handleScroll = () => setScrolled(window.scrollY > 60)
    window.addEventListener('scroll', handleScroll, { passive: true })
    return () => window.removeEventListener('scroll', handleScroll)
  }, [])

  const handleNavClick = (href: string) => {
    setMenuOpen(false)
    const el = document.querySelector(href)
    if (el) {
      const offset = 72
      const top = el.getBoundingClientRect().top + window.scrollY - offset
      window.scrollTo({ top, behavior: 'smooth' })
    }
  }

  return (
    <>
      <header
        className={`fixed top-0 left-0 right-0 z-50 transition-all duration-300 ${
          scrolled
            ? 'bg-[#050912]/90 backdrop-blur-xl border-b border-white/[0.06] shadow-[0_4px_30px_rgba(0,0,0,0.4)]'
            : 'bg-transparent'
        }`}
      >
        <div className="max-w-section mx-auto px-6 lg:px-10 h-[68px] flex items-center justify-between">

          {/* Logo */}
          <Link href="/" className="flex items-center gap-1.5 group">
            <div className="font-extrabold text-xl tracking-widest text-white select-none">
              TECH<span className="text-[#F5C842]">BES</span>
              <sup className="text-[#F5C842] text-[10px] ml-0.5">®</sup>
            </div>
          </Link>

          {/* Desktop Nav Links */}
          <nav className="hidden lg:flex items-center gap-7">
            {navLinks.map(link => (
              <button
                key={link.href}
                onClick={() => handleNavClick(link.href)}
                className="text-sm text-slate-400 hover:text-white transition-colors duration-200 font-medium tracking-wide cursor-pointer bg-transparent border-none"
              >
                {link.label}
              </button>
            ))}
          </nav>

          {/* Desktop CTA */}
          <div className="hidden lg:block">
            <motion.button
              whileHover={{ scale: 1.03 }}
              whileTap={{ scale: 0.97 }}
              onClick={() => handleNavClick('#register')}
              className="bg-[#E53935] hover:bg-[#C62828] text-white font-bold text-sm px-5 py-2.5 rounded-lg tracking-wide transition-colors shadow-[0_0_20px_rgba(229,57,53,0.25)] hover:shadow-[0_0_30px_rgba(229,57,53,0.45)] cursor-pointer border-none"
            >
              REGISTER NOW — ₹499
            </motion.button>
          </div>

          {/* Mobile Hamburger */}
          <button
            onClick={() => setMenuOpen(prev => !prev)}
            className="lg:hidden text-white p-2 -mr-2"
            aria-label="Toggle menu"
          >
            {menuOpen ? <X size={22} /> : <Menu size={22} />}
          </button>
        </div>

        {/* Mobile Menu */}
        <AnimatePresence>
          {menuOpen && (
            <motion.div
              key="mobile-menu"
              initial={{ opacity: 0, height: 0 }}
              animate={{ opacity: 1, height: 'auto' }}
              exit={{ opacity: 0, height: 0 }}
              transition={{ duration: 0.25 }}
              className="lg:hidden overflow-hidden bg-[#0A1020]/98 backdrop-blur-xl border-b border-white/[0.06]"
            >
              <div className="px-6 py-5 flex flex-col gap-1">
                {navLinks.map(link => (
                  <button
                    key={link.href}
                    onClick={() => handleNavClick(link.href)}
                    className="text-slate-300 hover:text-white font-medium py-3 text-left border-b border-white/[0.05] last:border-0 w-full bg-transparent border-l-0 border-r-0 border-t-0 cursor-pointer transition-colors"
                  >
                    {link.label}
                  </button>
                ))}
                <motion.button
                  whileTap={{ scale: 0.97 }}
                  onClick={() => handleNavClick('#register')}
                  className="mt-3 bg-[#E53935] hover:bg-[#C62828] text-white font-bold py-3.5 rounded-lg text-sm tracking-wide w-full cursor-pointer border-none transition-colors"
                >
                  REGISTER NOW — ₹499
                </motion.button>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </header>
    </>
  )
}
