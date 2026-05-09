import { NextResponse } from 'next/server'

const BACKEND_URL = process.env.BACKEND_API_URL || 'https://technician-app.onrender.com'

export async function POST(req: Request) {
  try {
    const data = await req.json()
    
    // 1. Prepare payload for backend (Admission Schema)
    const payload = {
      fullName: data.name,
      phone: data.phone,
      email: data.email,
      address: data.address,
      qualification: data.qualification,
      programType: 'course', // Must be one of ['course', 'internship', 'placement_program']
      selectedPlan: data.plan,
      assignedCourse: data.course, // Map descriptive name here
      paymentStatus: 'paid',
      admissionStatus: 'applied',
      payment: {
        totalFees: data.amountPaid || 0,
        paidAmount: data.amountPaid || 0,
        paymentStatus: 'paid',
        transactionLogs: [{
          transactionId: data.razorpayPaymentId || 'TEST_TXN',
          amount: data.amountPaid || 0,
          mode: 'razorpay',
          status: 'success',
          note: `OrderId: ${data.razorpayOrderId}`
        }]
      }
    }

    // 2. Send to central backend
    const res = await fetch(`${BACKEND_URL}/api/v2/admission`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload)
    })
    
    const result = await res.json()
    
    if (!res.ok) {
      console.error('Backend Sync Error:', result)
      // Return a partial success so user isn't blocked, but log the error
      return NextResponse.json({ 
        success: true, 
        enrollment: { id: `ERR-${Date.now()}`, ...data },
        warning: 'Sync to admin panel pending'
      })
    }
    
    return NextResponse.json({ 
      success: true, 
      enrollment: { 
        id: result.data?._id || `ENR-${Math.floor(1000 + Math.random()*9000)}`,
        ...data 
      } 
    })

  } catch (error: any) {
    console.error('Enrollment Route Error:', error)
    return NextResponse.json({ success: false, error: error.message }, { status: 500 })
  }
}
