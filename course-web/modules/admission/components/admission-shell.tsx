'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { FileText, GraduationCap, CreditCard, BarChart3, BookCopy, Briefcase } from 'lucide-react'
import { cn } from '@/lib/utils'

const MENU = [
  { href: '/admin/admission/all-applications', label: 'All Applications', icon: FileText },
  { href: '/admin/admission/student-profiles', label: 'Student Profiles', icon: GraduationCap },
  { href: '/admin/admission/payment-status', label: 'Payment Status', icon: CreditCard },
  { href: '/admin/admission/admission-analytics', label: 'Admission Analytics', icon: BarChart3 },
  { href: '/admin/admission/course-assignment', label: 'Course Assignment', icon: BookCopy },
  { href: '/admin/admission/internship-assignment', label: 'Internship Assignment', icon: Briefcase },
]

export function AdmissionShell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname()

  return (
    <div className="min-h-screen bg-[#F5F9FF] text-[#083B8A]">
      <div className="mx-auto grid max-w-7xl grid-cols-1 gap-6 px-4 py-8 lg:grid-cols-[280px_1fr]">
        <aside className="glass-card rounded-2xl p-4">
          <h1 className="mb-4 text-lg font-black text-primary">Admission Management</h1>
          <nav className="space-y-2">
            {MENU.map(({ href, label, icon: Icon }) => (
              <Link
                key={href}
                href={href}
                className={cn(
                  'flex items-center gap-3 rounded-xl px-3 py-2 text-sm font-semibold transition-all',
                  pathname === href ? 'bg-primary text-white' : 'bg-white/70 text-primary hover:bg-accent hover:text-white'
                )}
              >
                <Icon className="h-4 w-4" />
                <span>{label}</span>
              </Link>
            ))}
          </nav>
        </aside>
        <section className="glass-card rounded-2xl p-4 md:p-6">{children}</section>
      </div>
    </div>
  )
}
