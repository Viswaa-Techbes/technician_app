'use client'

import { useEffect, useState } from 'react'
import { fetchVisitorDashboard } from '@/modules/analytics/services/analytics-api'

export function useVisitorDashboard() {
  const [data, setData] = useState<any>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  useEffect(() => {
    let active = true
    ;(async () => {
      try {
        const response = await fetchVisitorDashboard()
        if (active) setData(response.data)
      } catch (err) {
        if (active) setError(err instanceof Error ? err.message : 'Unable to load analytics')
      } finally {
        if (active) setLoading(false)
      }
    })()
    return () => {
      active = false
    }
  }, [])

  return { data, loading, error }
}
