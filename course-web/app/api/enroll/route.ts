import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { sendEnrollmentConfirmation } from '@/lib/email-service'

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

    const supabase = await createClient()

    // Get course details
    const { data: course, error: courseError } = await supabase
      .from('courses')
      .select('title, id')
      .eq('id', course_id)
      .single()

    if (courseError || !course) {
      return NextResponse.json(
        { error: 'Course not found' },
        { status: 404 }
      )
    }

    // Create enrollment
    const { data: enrollment, error: enrollmentError } = await supabase
      .from('enrollments')
      .insert({
        course_id,
        student_name,
        student_email,
        student_phone,
      })
      .select()
      .single()

    if (enrollmentError) throw enrollmentError

    // Send confirmation email
    try {
      await sendEnrollmentConfirmation(
        student_email,
        student_name,
        course.title
      )
    } catch (emailError) {
      console.error('Error sending email:', emailError)
      // Don't fail the enrollment if email fails
    }

    return NextResponse.json({
      success: true,
      enrollment: enrollment,
      message: 'Enrollment successful! Check your email for confirmation.',
    })
  } catch (error: any) {
    console.error('Error creating enrollment:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to process enrollment' },
      { status: 500 }
    )
  }
}
