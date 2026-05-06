import { NextRequest, NextResponse } from 'next/server'
import { createClient } from '@/lib/supabase/server'
import { sendWelcomeEmail } from '@/lib/email-service'

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

    const supabase = await createClient()

    // Create inquiry
    const { data: inquiry, error: inquiryError } = await supabase
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

    if (inquiryError) throw inquiryError

    // Send welcome email
    try {
      await sendWelcomeEmail(email, name)
    } catch (emailError) {
      console.error('Error sending welcome email:', emailError)
      // Don't fail the inquiry if email fails
    }

    return NextResponse.json({
      success: true,
      inquiry: inquiry,
      message: 'Thank you for your inquiry! We will get back to you soon.',
    })
  } catch (error: any) {
    console.error('Error creating inquiry:', error)
    return NextResponse.json(
      { error: error.message || 'Failed to submit inquiry' },
      { status: 500 }
    )
  }
}
