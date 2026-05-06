import Razorpay from 'razorpay'
import { NextResponse } from 'next/server'

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || 'rzp_live_SSi3PthRn4IDft',
  key_secret: process.env.RAZORPAY_KEY_SECRET || 'SYeuAE0Liu6jNSvwaOVxTISm',
})

export async function POST(req: Request) {
  try {
    const { amount } = await req.json()

    // Razorpay amount is in currency subunits (paise for INR)
    const options = {
      amount: amount * 100,
      currency: 'INR',
      receipt: `rcpt_${Math.random().toString(36).substring(2, 10)}`,
    }

    const order = await razorpay.orders.create(options)
    
    return NextResponse.json({ success: true, order })
  } catch (error) {
    console.error('Razorpay Error:', error)
    return NextResponse.json({ success: false, error: 'Failed to create order' }, { status: 500 })
  }
}
