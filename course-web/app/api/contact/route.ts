import { NextRequest, NextResponse } from 'next/server'
import { backendJsonResponse } from '@/lib/backend-api'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { name, email, phone, message, course_interest } = body

    // Validate input
    if (!name || !email || !phone || !message) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    return backendJsonResponse('/api/v2/course-inquiries', {
      method: 'POST',
      body: JSON.stringify({
        name,
        email,
        phone,
        message,
        course_interest: course_interest || null,
      }),
    })
  } catch (error: any) {
    console.error('Error creating inquiry:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to submit inquiry' },
      { status: 500 }
    )
  }
}
