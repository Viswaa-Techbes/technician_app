/**
 * Omnichannel Notification Service
 * Dispatches notifications across: Push (FCM), Email (SMTP), SMS (Twilio), WhatsApp (Twilio WA)
 *
 * Each channel is fail-safe — if one fails, others still attempt.
 * Channel selection is driven by notification type and user preferences.
 *
 * Required ENV:
 *   FCM: handled by firebase-admin (existing)
 *   EMAIL: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, SMTP_FROM
 *   SMS/WA: TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_SMS_FROM, TWILIO_WA_FROM
 */

const nodemailer = require('nodemailer');
const { getEmailTemplate } = require('../utils/emailTemplates');
const { sendPushNotification } = require('../utils/notification');

// ─── Email Transport ───────────────────────────────────────────────────────────
function getEmailTransport() {
  return nodemailer.createTransport({
    host: process.env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(process.env.SMTP_PORT || '587', 10),
    secure: process.env.SMTP_SECURE === 'true',
    auth: {
      user: process.env.SMTP_USER,
      pass: process.env.SMTP_PASS,
    },
  });
}

// ─── Twilio Client ─────────────────────────────────────────────────────────────
function getTwilioClient() {
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  if (!sid || !token) return null;
  // Lazy require — don't crash if twilio not installed
  try {
    const twilio = require('twilio');
    return twilio(sid, token);
  } catch {
    return null;
  }
}

// ─── Individual Channel Senders ────────────────────────────────────────────────

async function sendEmail({ to, subject, html, text }) {
  if (!process.env.SMTP_USER || !to) return { success: false, reason: 'No SMTP config or email address' };
  try {
    const transport = getEmailTransport();
    const info = await transport.sendMail({
      from: process.env.SMTP_FROM || `"TechBes" <${process.env.SMTP_USER}>`,
      to,
      subject,
      html,
      text,
    });
    return { success: true, messageId: info.messageId };
  } catch (err) {
    console.error('[Channel:Email] Failed:', err.message);
    return { success: false, reason: err.message };
  }
}

async function sendSMS({ to, body }) {
  if (!to) return { success: false, reason: 'No phone number' };
  const client = getTwilioClient();
  if (!client) return { success: false, reason: 'Twilio not configured' };

  const from = process.env.TWILIO_SMS_FROM;
  if (!from) return { success: false, reason: 'TWILIO_SMS_FROM not set' };

  // Normalize to E.164 format — assumes Indian numbers if 10 digits
  const phone = to.startsWith('+') ? to : `+91${to.replace(/\D/g, '').slice(-10)}`;

  try {
    const msg = await client.messages.create({ body, from, to: phone });
    return { success: true, sid: msg.sid };
  } catch (err) {
    console.error('[Channel:SMS] Failed:', err.message);
    return { success: false, reason: err.message };
  }
}

async function sendWhatsApp({ to, body }) {
  if (!to) return { success: false, reason: 'No phone number' };
  const client = getTwilioClient();
  if (!client) return { success: false, reason: 'Twilio not configured' };

  const from = process.env.TWILIO_WA_FROM;
  if (!from) return { success: false, reason: 'TWILIO_WA_FROM not set' };

  const phone = to.startsWith('+') ? to : `+91${to.replace(/\D/g, '').slice(-10)}`;

  try {
    const msg = await client.messages.create({
      body,
      from: `whatsapp:${from}`,
      to: `whatsapp:${phone}`,
    });
    return { success: true, sid: msg.sid };
  } catch (err) {
    console.error('[Channel:WhatsApp] Failed:', err.message);
    return { success: false, reason: err.message };
  }
}

async function sendPush({ userId, title, body, data = {} }) {
  try {
    await sendPushNotification(userId.toString(), { title, body, data });
    return { success: true };
  } catch (err) {
    console.error('[Channel:Push] Failed:', err.message);
    return { success: false, reason: err.message };
  }
}

// ─── Notification Types & Templates ────────────────────────────────────────────

const NOTIFICATION_TEMPLATES = {
  booking_confirmed: {
    subject: 'Booking Confirmed – TechBes',
    getBody: (data) =>
      `Hi ${data.customerName || 'Customer'}, your booking for ${data.serviceName || 'service'} has been confirmed. Date: ${data.date || 'TBD'} at ${data.timeSlot || 'TBD'}. Reference: #${data.bookingId || ''}`,
  },
  technician_assigned: {
    subject: 'Technician Assigned – TechBes',
    getBody: (data) =>
      `Hi ${data.customerName || 'Customer'}, technician ${data.technicianName || ''} has been assigned to your job. ETA: ${data.eta || 'TBD'}.`,
  },
  job_started: {
    subject: 'Technician On the Way – TechBes',
    getBody: (data) =>
      `Hi ${data.customerName || 'Customer'}, your technician has started work on your request #${data.jobId || ''}.`,
  },
  payment_request: {
    subject: 'Payment Request – TechBes',
    getBody: (data) =>
      `Hi ${data.customerName || 'Customer'}, your service #${data.jobId || ''} is complete. Payment of ₹${data.amount || 0} is due. Pay here: ${data.paymentLink || 'Contact support'}`,
  },
  job_completed: {
    subject: 'Job Completed – TechBes',
    getBody: (data) =>
      `Hi ${data.customerName || 'Customer'}, your service request #${data.jobId || ''} has been completed. Thank you for choosing TechBes!`,
  },
  job_assigned_tech: {
    subject: 'New Job Assigned – TechBes',
    getBody: (data) =>
      `Hi ${data.technicianName || 'Technician'}, you have a new job assigned: ${data.serviceName || ''}. Customer: ${data.customerName || ''}. Address: ${data.address || ''}. Date: ${data.date || 'ASAP'}.`,
  },
};

// ─── Main Dispatch Function ────────────────────────────────────────────────────

/**
 * Dispatch an omnichannel notification.
 *
 * @param {object} options
 * @param {string} options.type        - One of NOTIFICATION_TEMPLATES keys
 * @param {object} options.data        - Template data
 * @param {object} options.recipient   - { userId, name, email, phone, role }
 * @param {string[]} [options.channels] - ['push','email','sms','whatsapp'] (defaults by type)
 */
async function dispatch({ type, data, recipient, channels }) {
  const template = NOTIFICATION_TEMPLATES[type];
  if (!template) {
    console.warn(`[OmniChannel] Unknown notification type: ${type}`);
    return;
  }

  const body = template.getBody(data);
  const subject = template.subject;

  // Default channels by audience
  const defaultChannels = recipient.role === 'technician'
    ? ['push', 'sms']
    : ['push', 'email', 'whatsapp'];

  const activeChannels = channels || defaultChannels;
  const results = {};

  await Promise.allSettled([
    activeChannels.includes('push') && recipient.userId
      ? sendPush({ userId: recipient.userId, title: subject, body, data: { type, ...data } })
          .then((r) => { results.push = r; })
      : Promise.resolve(),

    activeChannels.includes('email') && recipient.email
      ? sendEmail({
          to: recipient.email,
          subject,
          html: getEmailTemplate(type, subject, body, data),
          text: body,
        }).then((r) => { results.email = r; })
      : Promise.resolve(),

    activeChannels.includes('sms') && recipient.phone
      ? sendSMS({ to: recipient.phone, body: `[TechBes] ${body}` })
          .then((r) => { results.sms = r; })
      : Promise.resolve(),

    activeChannels.includes('whatsapp') && recipient.phone
      ? sendWhatsApp({ to: recipient.phone, body: `*TechBes*\n${body}` })
          .then((r) => { results.whatsapp = r; })
      : Promise.resolve(),
  ]);

  console.log(`[OmniChannel] Dispatched '${type}' to ${recipient.name || recipient.userId}:`, results);
  return results;
}

module.exports = {
  dispatch,
  sendEmail,
  sendSMS,
  sendWhatsApp,
  sendPush,
};
