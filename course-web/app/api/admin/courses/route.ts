import { NextRequest, NextResponse } from 'next/server'
import { backendJsonResponse } from '@/lib/backend-api'

export async function GET() {
  try {
    return backendJsonResponse('/api/v2/courses')
  } catch (error: any) {
    console.error('Error fetching courses:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to fetch courses' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()

    const {
      title,
      slug,
      description,
      long_description,
      price,
      duration,
      level,
      instructor_name,
      start_date,
      end_date,
      max_students,
      status,
    } = body

    // Validate required fields
    if (!title || !slug || !description || !duration || !level || !instructor_name) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    return backendJsonResponse('/api/v2/courses', {
      method: 'POST',
      body: JSON.stringify({
        title,
        slug,
        description,
        long_description,
        price: parseFloat(price) || 0,
        duration,
        level,
        instructor_name,
        start_date,
        end_date,
        max_students: parseInt(max_students) || 30,
        status: status || 'draft',
      }),
    })
  } catch (error: any) {
    console.error('Error creating course:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to create course' },
      { status: 500 }
    )
  }
}
