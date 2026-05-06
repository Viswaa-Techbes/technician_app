import { NextRequest, NextResponse } from 'next/server'
import { backendJsonResponse } from '@/lib/backend-api'

export async function GET() {
  try {
    return backendJsonResponse('/api/v2/course-inquiries')
  } catch (error: any) {
    console.error('Error fetching inquiries:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to fetch inquiries' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()

    const { name, email, phone, message, course_interest } = body

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
      { error: error.message || 'Failed to create inquiry' },
      { status: 500 }
    )
  }
}
