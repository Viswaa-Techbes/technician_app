import connect from '../../../../lib/mongodb'
import Registration from '../../../../models/Registration'
import Masterclass from '../../../../models/Masterclass'
import { NextResponse } from 'next/server'

export async function POST(req: Request) {
  await connect()
  try {
    const body = await req.json()
    const { name, email, mobile, location, qualification, whatsapp, masterclassId } = body

    if (!name || !email || !mobile || !location || !qualification) {
      return NextResponse.json({ message: 'Invalid input' }, { status: 400 })
    }

    // basic duplicate prevention
    const existing = await Registration.findOne({ $or: [{ email }, { mobile }], masterclassId })
    if (existing && existing.paymentStatus === 'PAID') {
      return NextResponse.json({ message: 'Already registered and paid' }, { status: 409 })
    }

    // ensure masterclass exists
    const mc = await Masterclass.findById(masterclassId)
    if (!mc || !mc.registrationOpen) {
      return NextResponse.json({ message: 'Registration closed' }, { status: 400 })
    }

    const registration = new Registration({ masterclassId, name, email, mobile, location, qualification, whatsapp, paymentStatus: 'PENDING', registrationStatus: 'PENDING' })
    await registration.save()

    return NextResponse.json({ registrationId: registration._id, message: 'created' })
  } catch (err: any) {
    console.error(err)
    return NextResponse.json({ message: 'Server error' }, { status: 500 })
  }
}
