import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'

export async function GET() {
  try {
    const supabase = await createClient()

    const { data, error } = await supabase
      .from('inquiries')
      .select('*')
      .order('created_at', { ascending: false })

    if (error) throw error

    return NextResponse.json({ inquiries: data || [] })
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
    const supabase = await createClient()
    const body = await request.json()

    const { name, email, phone, message, course_interest } = body

    if (!name || !email || !phone || !message) {
      return NextResponse.json(
        { error: 'Missing required fields' },
        { status: 400 }
      )
    }

    const { data, error } = await supabase
      .from('inquiries')
      .insert({
        name,
        email,
        phone,
        message,
        course_interest: course_interest || null,
      })
      .select()
      .single()

    if (error) throw error

    return NextResponse.json({ inquiry: data })
  } catch (error: any) {
    console.error('Error creating inquiry:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to create inquiry' },
      { status: 500 }
    )
  }
}
