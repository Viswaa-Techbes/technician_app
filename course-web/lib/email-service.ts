import { Resend } from 'resend'
import { createClient } from '@/lib/supabase/server'

const resend = new Resend(process.env.RESEND_API_KEY)

export interface EmailTemplate {
  type: 'enrollment_confirmation' | 'inquiry_response' | 'welcome'
  recipient: string
  subject: string
  data: Record<string, any>
}

export async function sendEnrollmentConfirmation(
  studentEmail: string,
  studentName: string,
  courseTitle: string
) {
  try {
    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #1e40af;">Enrollment Confirmation - TECHBES</h1>
        <p>Dear ${studentName},</p>
        <p>Thank you for enrolling in our course! We're excited to have you join us.</p>
        <div style="background-color: #f0f9ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <h2 style="margin-top: 0; color: #1e40af;">${courseTitle}</h2>
          <p>Your enrollment has been confirmed and you will receive further details soon.</p>
        </div>
        <p>If you have any questions, please don't hesitate to contact us.</p>
        <p>Best regards,<br/>The TECHBES Team</p>
      </div>
    `

    const result = await resend.emails.send({
      from: process.env.RESEND_FROM_EMAIL || 'noreply@techbes.com',
      to: studentEmail,
      subject: `Enrollment Confirmation - ${courseTitle}`,
      html: htmlContent,
    })

    // Log the email
    const supabase = await createClient()
    await supabase.from('email_logs').insert({
      recipient_email: studentEmail,
      template_type: 'enrollment_confirmation',
      subject: `Enrollment Confirmation - ${courseTitle}`,
      status: result.error ? 'failed' : 'sent',
      error_message: result.error?.message || null,
    })

    return result
  } catch (error) {
    console.error('Error sending enrollment confirmation:', error)
    throw error
  }
}

export async function sendInquiryResponse(
  inquirerEmail: string,
  inquirerName: string,
  responseMessage: string
) {
  try {
    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #1e40af;">Response to Your Inquiry - TECHBES</h1>
        <p>Dear ${inquirerName},</p>
        <p>Thank you for reaching out to us. Here's our response to your inquiry:</p>
        <div style="background-color: #f0f9ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <p>${responseMessage}</p>
        </div>
        <p>If you have further questions, feel free to reply to this email or visit our website.</p>
        <p>Best regards,<br/>The TECHBES Team</p>
      </div>
    `

    const result = await resend.emails.send({
      from: process.env.RESEND_FROM_EMAIL || 'noreply@techbes.com',
      to: inquirerEmail,
      subject: 'Response to Your Inquiry - TECHBES',
      html: htmlContent,
    })

    // Log the email
    const supabase = await createClient()
    await supabase.from('email_logs').insert({
      recipient_email: inquirerEmail,
      template_type: 'inquiry_response',
      subject: 'Response to Your Inquiry - TECHBES',
      status: result.error ? 'failed' : 'sent',
      error_message: result.error?.message || null,
    })

    return result
  } catch (error) {
    console.error('Error sending inquiry response:', error)
    throw error
  }
}

export async function sendWelcomeEmail(email: string, name: string) {
  try {
    const htmlContent = `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <h1 style="color: #1e40af;">Welcome to TECHBES!</h1>
        <p>Dear ${name},</p>
        <p>Welcome to TECHBES - your gateway to professional training in technology.</p>
        <div style="background-color: #f0f9ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <h2 style="margin-top: 0; color: #1e40af;">What's Next?</h2>
          <ul>
            <li>Explore our course catalog</li>
            <li>Enroll in courses that interest you</li>
            <li>Connect with fellow learners</li>
            <li>Achieve your learning goals</li>
          </ul>
        </div>
        <p>Visit our website to get started: <a href="https://techbes.com" style="color: #1e40af;">www.techbes.com</a></p>
        <p>Best regards,<br/>The TECHBES Team</p>
      </div>
    `

    const result = await resend.emails.send({
      from: process.env.RESEND_FROM_EMAIL || 'noreply@techbes.com',
      to: email,
      subject: 'Welcome to TECHBES!',
      html: htmlContent,
    })

    // Log the email
    const supabase = await createClient()
    await supabase.from('email_logs').insert({
      recipient_email: email,
      template_type: 'welcome',
      subject: 'Welcome to TECHBES!',
      status: result.error ? 'failed' : 'sent',
      error_message: result.error?.message || null,
    })

    return result
  } catch (error) {
    console.error('Error sending welcome email:', error)
    throw error
  }
}
