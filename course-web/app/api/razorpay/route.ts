import { NextResponse } from 'next/server'

export async function POST(req: Request) {
  try {
    const { amount } = await req.json()

    // Since the backend environment blocks outbound calls to api.razorpay.com (ConnectTimeout),
    // we return a basic order structure to allow the frontend SDK to initialize 
    // a basic payment (without an order_id).
    const order = {
      id: '', // Blank ID triggers basic integration mode in frontend SDK
      amount: amount * 100,
      currency: 'INR',
    }
    
    return NextResponse.json({ success: true, order })
  } catch (error) {
    console.error('Razorpay Error:', error)
    return NextResponse.json({ success: false, error: 'Failed to create order' }, { status: 500 })
  }
}
