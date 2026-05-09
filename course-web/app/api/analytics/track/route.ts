import { NextRequest, NextResponse } from 'next/server'
import { getBackendUrl } from '@/lib/backend-api'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    
    // Forward request with original client headers for IP and device detection
    const headers = new Headers()
    headers.set('Content-Type', 'application/json')
    
    const userAgent = request.headers.get('user-agent')
    if (userAgent) headers.set('user-agent', userAgent)
    
    const forwardedFor = request.headers.get('x-forwarded-for')
    if (forwardedFor) headers.set('x-forwarded-for', forwardedFor)

    const response = await fetch(getBackendUrl('/api/v2/analytics/visitors/track'), {
      method: 'POST',
      headers: headers,
      body: JSON.stringify(body),
    })
    const data = await response.json().catch(() => ({}))
    return NextResponse.json(data, { status: response.status })
  } catch (error: any) {
    return NextResponse.json({ error: error.message || 'Failed to track event' }, { status: 500 })
  }
}
