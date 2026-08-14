import connect from '../lib/mongodb'
import Registration from '../models/Registration'
import Masterclass from '../models/Masterclass'

export async function createRegistration(data: any) {
  await connect()
  const mc = await Masterclass.findById(data.masterclassId)
  if (!mc) throw new Error('Masterclass not found')

  const existing = await Registration.findOne({ $or: [{ email: data.email }, { mobile: data.mobile }], masterclassId: data.masterclassId })
  if (existing && existing.paymentStatus === 'PAID') throw new Error('Already registered')

  const reg = new Registration({ ...data, paymentStatus: 'PENDING', registrationStatus: 'PENDING' })
  await reg.save()
  return reg
}
