import crypto from 'crypto'
import { NextResponse } from 'next/server'
import connect from '../../../../../lib/mongodb'
import Payment from '../../../../../models/Payment'
import Registration from '../../../../../models/Registration'

export async function POST(req: Request) {
  await connect()
  const payload = await req.text()
  const signature = req.headers.get('x-razorpay-signature') || ''
  const expected = crypto.createHmac('sha256', process.env.RAZORPAY_WEBHOOK_SECRET || '').update(payload).digest('hex')

  if (expected !== signature) {
    return NextResponse.json({ ok: false, message: 'Invalid signature' }, { status: 400 })
  }

  const body = JSON.parse(payload)
  const event = body.event

  try {
    if (event === 'payment.captured') {
      const { order_id, payment_id } = body.payload.payment.entity
      const reg = await Registration.findOne({ razorpayOrderId: order_id })
      if (reg) {
        reg.paymentStatus = 'PAID'
        reg.registrationStatus = 'REGISTERED'
        reg.razorpayPaymentId = payment_id
        reg.paidAt = new Date()
        await reg.save()
      }
      await Payment.create({ registrationId: reg?._id, razorpayOrderId: order_id, razorpayPaymentId: payment_id, status: 'captured', webhookVerified: true, signatureVerified: true, paidAt: new Date() })
    }

    return NextResponse.json({ ok: true })
  } catch (err: any) {
    console.error(err)
    return NextResponse.json({ ok: false }, { status: 500 })
  }
}
