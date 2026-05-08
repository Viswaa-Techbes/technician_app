import { NextRequest, NextResponse } from 'next/server'
import { getBackendUrl } from '@/lib/backend-api'

export async function GET(request: NextRequest) {
  try {
    const authorization = request.headers.get('authorization') || ''
    const response = await fetch(getBackendUrl('/api/v2/analytics/visitors/dashboard'), {
      headers: {
        'Content-Type': 'application/json',
        ...(authorization ? { Authorization: authorization } : {}),
      },
      cache: 'no-store',
    })
    const data = await response.json().catch(() => ({}))
    return NextResponse.json(data, { status: response.status })
  } catch (error: any) {
    return NextResponse.json({ error: error.message || 'Failed to load dashboard' }, { status: 500 })
  }
}
