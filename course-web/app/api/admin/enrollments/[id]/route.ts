import { NextRequest, NextResponse } from 'next/server'
import { backendJsonResponse } from '@/lib/backend-api'

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const body = await request.json()
    const { id } = await params
    return backendJsonResponse(`/api/v2/course-enrollments/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    })
  } catch (error: any) {
    console.error('Error updating enrollment:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to update enrollment' },
      { status: 500 }
    )
  }
}
