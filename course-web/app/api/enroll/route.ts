import { NextResponse } from 'next/server'

// Simple in-memory DB for demo purposes
const globalAny = global as any
if (!globalAny.enrollments) {
  globalAny.enrollments = []
}

export async function POST(req: Request) {
  try {
    const data = await req.json()
    
    const newEnrollment = {
      id: `ENR-${Math.floor(100000 + Math.random() * 900000)}`,
      txId: `TXN-${Math.random().toString(36).substr(2, 9).toUpperCase()}`,
      date: new Date().toISOString(),
      status: 'Paid',
      ...data
    }
    
    globalAny.enrollments.push(newEnrollment)
    
    return NextResponse.json({ success: true, enrollment: newEnrollment })
  } catch (error) {
    return NextResponse.json({ success: false, error: 'Failed to process enrollment' }, { status: 500 })
  }
}

export async function GET() {
  return NextResponse.json({ enrollments: globalAny.enrollments || [] })
}
