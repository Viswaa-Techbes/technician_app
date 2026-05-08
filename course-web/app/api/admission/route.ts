import { NextRequest, NextResponse } from 'next/server'
import { getBackendUrl } from '@/lib/backend-api'

function authHeaders(req: NextRequest) {
  const auth = req.headers.get('authorization')
  return auth ? { Authorization: auth } : {}
}

export async function GET(req: NextRequest) {
  try {
    const query = req.nextUrl.search
    const response = await fetch(getBackendUrl(`/api/v2/admission${query}`), {
      headers: { 'Content-Type': 'application/json', ...authHeaders(req) },
      cache: 'no-store',
    })
    const data = await response.json().catch(() => ({}))
    return NextResponse.json(data, { status: response.status })
  } catch (error: any) {
    return NextResponse.json({ error: error.message || 'Failed to fetch admissions' }, { status: 500 })
  }
}

export async function POST(req: NextRequest) {
  try {
    const body = await req.json()
    const response = await fetch(getBackendUrl('/api/v2/admission'), {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...authHeaders(req) },
      body: JSON.stringify(body),
      cache: 'no-store',
    })
    const data = await response.json().catch(() => ({}))
    return NextResponse.json(data, { status: response.status })
  } catch (error: any) {
    return NextResponse.json({ error: error.message || 'Failed to create admission' }, { status: 500 })
  }
}
