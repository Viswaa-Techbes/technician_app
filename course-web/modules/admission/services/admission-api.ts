import type { AdmissionApplication } from '@/modules/admission/types'

export interface AdmissionListResponse {
  success: boolean
  items: AdmissionApplication[]
  pagination: {
    page: number
    limit: number
    total: number
    totalPages: number
  }
}

export async function fetchApplications(params: Record<string, string> = {}) {
  const query = new URLSearchParams(params).toString()
  const res = await fetch(`/api/admission${query ? `?${query}` : ''}`, { cache: 'no-store' })
  if (!res.ok) throw new Error('Failed to load applications')
  return (await res.json()) as AdmissionListResponse
}
