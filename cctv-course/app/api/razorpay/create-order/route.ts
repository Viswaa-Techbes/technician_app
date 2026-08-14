import connect from '../../../../../lib/mongodb'
import Registration from '../../../../../models/Registration'
import Masterclass from '../../../../../models/Masterclass'
import razor from '../../../../../lib/razorpay'
import { NextResponse } from 'next/server'

export async function POST(req: Request) {
  await connect()
  try {
    const { registrationId } = await req.json()
    if (!registrationId) return NextResponse.json({ message: 'Missing registrationId' }, { status: 400 })

    const reg = await Registration.findById(registrationId)
    if (!reg) return NextResponse.json({ message: 'Registration not found' }, { status: 404 })

    const mc = await Masterclass.findById(reg.masterclassId)
    if (!mc) return NextResponse.json({ message: 'Masterclass not found' }, { status: 404 })

    const amount = mc.price * 100 // paise
    const options = {
      amount,
      currency: 'INR',
      receipt: `reg_${reg._id}`,
      notes: { registrationId: String(reg._id) }
    }

    const order = await razor.orders.create(options)
    reg.razorpayOrderId = order.id
    await reg.save()

    return NextResponse.json({ order })
  } catch (err: any) {
    console.error(err)
    return NextResponse.json({ message: 'Server error' }, { status: 500 })
  }
}
