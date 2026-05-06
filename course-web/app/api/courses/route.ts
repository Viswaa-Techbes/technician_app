import { backendJsonResponse } from '@/lib/backend-api'

export async function GET(request: Request) {
  const url = new URL(request.url)
  return backendJsonResponse(`/api/v2/courses${url.search}`)
}
