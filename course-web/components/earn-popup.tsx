 'use client'

import React, { useEffect, useState } from 'react'
import { X } from 'lucide-react'

export default function EarnPopup() {
  const [visible, setVisible] = useState(false)

  useEffect(() => {
    // show popup shortly after mount
    const t = setTimeout(() => setVisible(true), 900)
    return () => clearTimeout(t)
  }, [])

  if (!visible) return null

  return (
    <div className="fixed bottom-6 right-6 z-50">
      <div className="max-w-xs w-full bg-white rounded-2xl border shadow-lg p-4 flex items-start gap-3">
        <div className="flex-1">
          <p className="text-sm text-foreground/60">Quick Earning</p>
          <h3 className="text-lg font-black text-primary">Earn within 50 - 60 days</h3>
          <p className="text-xs text-foreground/60 mt-1">Join our hands-on training and start earning fast.</p>
        </div>
        <button aria-label="close" onClick={() => setVisible(false)} className="text-foreground/60 hover:text-foreground">
          <X size={18} />
        </button>
      </div>
    </div>
  )
}
