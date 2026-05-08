'use client'

import { MessageCircle } from 'lucide-react'

const whatsappMessage = encodeURIComponent(
  'Hi TECHBES, I would like to know more about your CCTV and IT training programs.'
)

export function WhatsAppFloatingButton() {
  return (
    <a
      href={`https://wa.me/919591144949?text=${whatsappMessage}`}
      target="_blank"
      rel="noopener noreferrer"
      aria-label="Chat with TECHBES on WhatsApp"
      className="fixed bottom-6 right-6 z-[60] flex h-14 w-14 items-center justify-center rounded-full bg-[#25D366] text-white shadow-[0_12px_35px_rgba(37,211,102,0.35)] transition-transform duration-300 hover:scale-110 focus:outline-none focus:ring-4 focus:ring-[#25D366]/30 md:h-16 md:w-16"
    >
      <MessageCircle className="h-7 w-7 md:h-8 md:w-8" />
    </a>
  )
}
