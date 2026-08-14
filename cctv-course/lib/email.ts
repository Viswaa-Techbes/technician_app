import nodemailer from 'nodemailer'

const host = process.env.SMTP_HOST
const port = Number(process.env.SMTP_PORT || 587)
const user = process.env.SMTP_USER
const pass = process.env.SMTP_PASSWORD

const transporter = nodemailer.createTransport({ host, port, auth: { user, pass } })

export async function sendRegistrationEmail(to: string, subject: string, html: string) {
  if (!host || !user) {
    console.warn('SMTP not configured; skipping email')
    return
  }
  await transporter.sendMail({ from: process.env.SMTP_USER, to, subject, html })
}
