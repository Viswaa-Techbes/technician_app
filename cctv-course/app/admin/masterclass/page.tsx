import connect from '../../../../lib/mongodb'
import Registration from '../../../../models/Registration'

export default async function AdminPage() {
  await connect()
  const total = await Registration.countDocuments()
  const paid = await Registration.countDocuments({ paymentStatus: 'PAID' })
  return (
    <div className="container px-4 py-10">
      <h1 className="text-2xl font-semibold">Admin - Masterclass</h1>
      <div className="mt-6 grid grid-cols-3 gap-4">
        <div className="p-4 bg-slate-900 rounded">Total Registrations: {total}</div>
        <div className="p-4 bg-slate-900 rounded">Paid: {paid}</div>
        <div className="p-4 bg-slate-900 rounded">Pending: {/* TODO */}</div>
      </div>
    </div>
  )
}
