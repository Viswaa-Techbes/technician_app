import { NextRequest, NextResponse } from 'next/server'
import { backendJsonResponse } from '@/lib/backend-api'

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id } = await params
    return backendJsonResponse(`/api/v2/courses/${id}`, { method: 'DELETE' })
  } catch (error: any) {
    console.error('Error deleting course:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to delete course' },
      { status: 500 }
    )
  }
}
