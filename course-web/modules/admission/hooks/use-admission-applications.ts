'use client'

import { useEffect, useMemo, useState } from 'react'
import { fetchApplications } from '@/modules/admission/services/admission-api'
import type { AdmissionApplication } from '@/modules/admission/types'

export function useAdmissionApplications() {
  const [applications, setApplications] = useState<AdmissionApplication[]>([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)
  const [search, setSearch] = useState('')

  useEffect(() => {
    let active = true
    const timer = setTimeout(async () => {
      setLoading(true)
      try {
        const data = await fetchApplications({ search, limit: '20' })
        if (active) setApplications(data.items || [])
      } catch (err) {
        if (active) setError(err instanceof Error ? err.message : 'Failed to fetch applications')
      } finally {
        if (active) setLoading(false)
      }
    }, 300)
    return () => {
      active = false
      clearTimeout(timer)
    }
  }, [search])

  const stats = useMemo(() => {
    const total = applications.length
    const approved = applications.filter((a) => a.admissionStatus === 'approved').length
    const enrolled = applications.filter((a) => a.admissionStatus === 'enrolled').length
    return { total, approved, enrolled }
  }, [applications])

  return { applications, loading, error, search, setSearch, stats, setApplications }
}
