import { NextRequest, NextResponse } from 'next/server'
import { getBackendUrl } from '@/lib/backend-api'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const response = await fetch(getBackendUrl('/api/v2/analytics/visitors/track'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    })
    const data = await response.json().catch(() => ({}))
    return NextResponse.json(data, { status: response.status })
  } catch (error: any) {
    return NextResponse.json({ error: error.message || 'Failed to track event' }, { status: 500 })
  }
}
