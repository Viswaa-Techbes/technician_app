import { NextResponse } from 'next/server'

export function getBackendUrl(path = '') {
  const baseUrl =
    process.env.BACKEND_API_URL ||
    process.env.NEXT_PUBLIC_BACKEND_API_URL ||
    'https://api.techbes.co.in'

  return `${baseUrl.replace(/\/$/, '')}${path.startsWith('/') ? path : `/${path}`}`
}

export async function backendRequest(path: string, init: RequestInit = {}) {
  return fetch(getBackendUrl(path), {
    ...init,
    headers: {
      'Content-Type': 'application/json',
      ...(init.headers || {}),
    },
    cache: 'no-store',
  })
}

export async function backendJsonResponse(path: string, init: RequestInit = {}) {
  const response = await backendRequest(path, init)
  const data = await response.json().catch(() => ({}))

  if (!response.ok) {
    return NextResponse.json(
      { error: data.message || data.error || 'Backend request failed' },
      { status: response.status }
    )
  }

  return NextResponse.json(data, { status: response.status })
}
