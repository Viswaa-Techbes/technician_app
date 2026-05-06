import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function GET() {
  try {
    const supabase = await createClient()

    const { data, error } = await supabase
      .from('courses')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error

    return NextResponse.json({ courses: data || [] })
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
    const supabase = await createClient()
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

    const { data, error } = await supabase
      .from('courses')
      .insert({
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
      })
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({ course: data })
  } catch (error: any) {
    console.error('Error creating course:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to create course' },
      { status: 500 }
    )
  }
}
