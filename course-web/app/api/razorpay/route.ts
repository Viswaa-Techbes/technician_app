import { NextResponse } from 'next/server'
import Razorpay from 'razorpay'

// Authoritative server-side prices in paise (INR)
const PLAN_PRICES: Record<string, number> = {
  masterclass: 49900,   // ₹499 - CCTV Masterclass
  basic: 719900,        // ₹7,199 - Basic Course Plan (after 10% online offer)
  'job-ready': 1349900, // ₹13,499 - Job Ready Plan (after 10% online offer)
  premium: 2249900,     // ₹22,499 - Premium Plan (after 10% online offer)
}

export async function POST(req: Request) {
  try {
    const body = await req.json().catch(() => ({}))
    const { plan } = body
    const normalizedPlan = String(plan || '').trim().toLowerCase()

    // 1. Enforce plan validation and reject arbitrary client-controlled amounts
    if (!normalizedPlan || !PLAN_PRICES[normalizedPlan]) {
      return NextResponse.json(
        {
          success: false,
          message: 'Invalid payment plan',
        },
        { status: 400 }
      )
    }

    const key_id = process.env.RAZORPAY_KEY_ID || process.env.NEXT_PUBLIC_RAZORPAY_KEY_ID
    const key_secret = process.env.RAZORPAY_KEY_SECRET

    if (!key_id || !key_secret) {
      console.error('[Razorpay Route] Missing RAZORPAY_KEY_ID or RAZORPAY_KEY_SECRET in server environment')
      return NextResponse.json(
        { success: false, message: 'Payment gateway configuration error' },
        { status: 500 }
      )
    }

    // 2. Authoritative server-side amount
    const amountInPaise = PLAN_PRICES[normalizedPlan]
    const receipt = `rcpt_${normalizedPlan}_${Date.now()}`

    // 3. Create verified Razorpay order server-side
    const razorpay = new Razorpay({
      key_id,
      key_secret,
    })

    const order = await razorpay.orders.create({
      amount: amountInPaise,
      currency: 'INR',
      receipt,
      notes: {
        plan: normalizedPlan,
      },
    })

    if (!order || !order.id) {
      throw new Error('Failed to obtain valid order ID from Razorpay')
    }

    return NextResponse.json({
      success: true,
      orderId: order.id,
      order: {
        id: order.id,
        amount: order.amount,
        currency: order.currency,
        receipt: order.receipt,
      },
      keyId: key_id,
    })
  } catch (error: any) {
    console.error('[Razorpay Route] Order creation failed:', error.message || error)
    return NextResponse.json(
      { success: false, message: error.message || 'Failed to create payment order' },
      { status: 500 }
    )
  }
}

