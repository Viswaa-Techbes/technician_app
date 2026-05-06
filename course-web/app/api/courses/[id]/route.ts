import { backendJsonResponse } from '@/lib/backend-api'

export async function GET(
  request: Request,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params
  const url = new URL(request.url)
  return backendJsonResponse(`/api/v2/courses/${id}${url.search}`)
}
