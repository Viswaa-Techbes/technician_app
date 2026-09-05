"use client"
import { Wifi, Wrench, GraduationCap, ShieldCheck, Users } from 'lucide-react'

const items = [
  { icon: Wifi,          label: 'Online Live Class' },
  { icon: Wrench,        label: 'Practical Demo'   },
  { icon: Users,         label: 'Industry Experts'  },
  { icon: GraduationCap, label: 'E-Certificate'     },
  { icon: ShieldCheck,   label: 'No Prior Experience' },
]

export default function TrustStrip() {
  return (
    <section className="relative bg-[#0A1020] border-y border-white/[0.05] overflow-hidden">
      {/* Subtle top gold line */}
      <div className="absolute top-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-[#F5C842]/30 to-transparent" />

      <div className="max-w-section mx-auto px-6 lg:px-10 py-5">
        <div className="flex flex-wrap items-center justify-center gap-0">
          {items.map((item, i) => {
            const Icon = item.icon
            return (
              <div key={item.label} className="flex items-center">
                <div className="flex items-center gap-2.5 px-6 py-3">
                  <div className="w-8 h-8 rounded-lg bg-[#F5C842]/10 flex items-center justify-center flex-shrink-0">
                    <Icon size={15} className="text-[#F5C842]" />
                  </div>
                  <span className="text-slate-300 font-semibold text-sm tracking-wide whitespace-nowrap">
                    {item.label}
                  </span>
                </div>
                {i < items.length - 1 && (
                  <div className="w-[1px] h-6 bg-white/10 hidden sm:block" />
                )}
              </div>
            )
          })}
        </div>
      </div>

      <div className="absolute bottom-0 left-0 right-0 h-[1px] bg-gradient-to-r from-transparent via-[#F5C842]/20 to-transparent" />
    </section>
  )
}
