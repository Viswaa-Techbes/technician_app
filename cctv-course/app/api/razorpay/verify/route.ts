import crypto from 'crypto'
import connect from '../../../../../lib/mongodb'
import Registration from '../../../../../models/Registration'
import Payment from '../../../../../models/Payment'
import { NextResponse } from 'next/server'

export async function POST(req: Request) {
  await connect()
  try {
    const body = await req.json()
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = body

    const generated_signature = crypto.createHmac('sha256', process.env.RAZORPAY_KEY_SECRET || '').update(razorpay_order_id + '|' + razorpay_payment_id).digest('hex')

    const signatureVerified = generated_signature === razorpay_signature

    const reg = await Registration.findOne({ razorpayOrderId: razorpay_order_id })
    if (!reg) return NextResponse.json({ message: 'Registration not found' }, { status: 404 })

    const payment = await Payment.create({ registrationId: reg._id, razorpayOrderId: razorpay_order_id, razorpayPaymentId: razorpay_payment_id, amount: reg.amount || 0, currency: 'INR', status: signatureVerified ? 'captured' : 'failed', signatureVerified, webhookVerified: false, paidAt: new Date() })

    if (signatureVerified) {
      reg.paymentStatus = 'PAID'
      reg.registrationStatus = 'REGISTERED'
      reg.razorpayPaymentId = razorpay_payment_id
      reg.paidAt = new Date()
      await reg.save()
    }

    return NextResponse.json({ ok: signatureVerified })
  } catch (err: any) {
    console.error(err)
    return NextResponse.json({ message: 'Server error' }, { status: 500 })
  }
}
