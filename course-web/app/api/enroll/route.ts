import { NextRequest, NextResponse } from 'next/server'
import { backendJsonResponse } from '@/lib/backend-api'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { course_id, student_name, student_email, student_phone } = body

    // Validate input
    if (!course_id || !student_name || !student_email || !student_phone) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    return backendJsonResponse('/api/v2/course-enrollments', {
      method: 'POST',
      body: JSON.stringify({
        course_id,
        student_name,
        student_email,
        student_phone,
      }),
    })
  } catch (error: any) {
    console.error('Error creating enrollment:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to process enrollment' },
      { status: 500 }
    )
  }
}
