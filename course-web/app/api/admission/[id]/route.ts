import { NextRequest, NextResponse } from 'next/server'
import { getBackendUrl } from '@/lib/backend-api'

function authHeaders(req: NextRequest) {
  const auth = req.headers.get('authorization')
  return auth ? { Authorization: auth } : {}
}

export async function GET(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const response = await fetch(getBackendUrl(`/api/v2/admission/${id}`), {
    headers: { 'Content-Type': 'application/json', ...authHeaders(req) },
    cache: 'no-store',
  })
  const data = await response.json().catch(() => ({}))
  return NextResponse.json(data, { status: response.status })
}

export async function PUT(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const body = await req.json()
  const response = await fetch(getBackendUrl(`/api/v2/admission/${id}`), {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json', ...authHeaders(req) },
    body: JSON.stringify(body),
    cache: 'no-store',
  })
  const data = await response.json().catch(() => ({}))
  return NextResponse.json(data, { status: response.status })
}

export async function DELETE(req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params
  const response = await fetch(getBackendUrl(`/api/v2/admission/${id}`), {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json', ...authHeaders(req) },
    cache: 'no-store',
  })
  const data = await response.json().catch(() => ({}))
  return NextResponse.json(data, { status: response.status })
}
