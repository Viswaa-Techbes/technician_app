import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function GET() {
  try {
    const supabase = await createClient()

    const { data, error } = await supabase
      .from('enrollments')
      .select('*')
      .order('enrollment_date', { ascending: false })

    if (error) throw error

    return NextResponse.json({ enrollments: data || [] })
  } catch (error: any) {
    console.error('Error fetching enrollments:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to fetch enrollments' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const supabase = await createClient()
    const body = await request.json()

    const { course_id, student_name, student_email, student_phone } = body

    if (!course_id || !student_name || !student_email || !student_phone) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    const { data, error } = await supabase
      .from('enrollments')
      .insert({
        course_id,
        student_name,
        student_email,
        student_phone,
      })
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({ enrollment: data })
  } catch (error: any) {
    console.error('Error creating enrollment:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to create enrollment' },
      { status: 500 }
    )
  }
}
