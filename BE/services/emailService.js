const nodemailer = require('nodemailer');

function getTransporter() {
  const host = process.env.SMTP_HOST;
  const port = Number(process.env.SMTP_PORT || 587);
  const user = process.env.SMTP_USER;
  const pass = process.env.SMTP_PASS;

  if (!host || !user || !pass) {
    throw new Error('SMTP is not configured');
  }

  return nodemailer.createTransport({
    host,
    port,
    secure: String(process.env.SMTP_SECURE || '').toLowerCase() === 'true' || port === 465,
    auth: { user, pass },
  });
}

function otpTemplate(otp) {
  return `
    <div style="font-family:Arial,sans-serif;background:#f8fafc;padding:32px;color:#0f172a">
      <div style="max-width:520px;margin:0 auto;background:#fff;border:1px solid #e2e8f0;border-radius:16px;overflow:hidden">
        <div style="padding:24px;border-bottom:1px solid #e2e8f0">
          <h1 style="margin:0;font-size:22px">Verify your Techbes account</h1>
          <p style="margin:8px 0 0;color:#64748b">Use this code to finish creating your account.</p>
        </div>
        <div style="padding:28px 24px">
          <p style="margin:0 0 12px;color:#475569">Your verification code is:</p>
          <div style="font-size:32px;letter-spacing:8px;font-weight:700;color:#059669">${otp}</div>
          <p style="margin:20px 0 0;color:#64748b">This code expires in 5 minutes.</p>
        </div>
      </div>
    </div>
  `;
}

async function sendOtpEmail(email, otp) {
  const transporter = getTransporter();
  const from = process.env.MAIL_FROM || process.env.SMTP_FROM || process.env.SMTP_USER;

  await transporter.sendMail({
    from,
    to: email,
    subject: 'Your Techbes verification code',
    text: `Your verification code is: ${otp}\n\nThis code expires in 5 minutes.`,
    html: otpTemplate(otp),
  });
}

module.exports = {
  sendOtpEmail,
};
