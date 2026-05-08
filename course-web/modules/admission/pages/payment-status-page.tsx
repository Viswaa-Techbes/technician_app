export default function PaymentStatusPage() {
  return (
    <div className="rounded-xl bg-white p-6">
      <h2 className="text-xl font-black text-primary">Payment Status</h2>
      <p className="mt-2 text-sm text-primary/70">
        Track total fees, paid amount, pending amount, EMI status, and transaction logs through `PUT /api/admission/:id/payment`.
      </p>
    </div>
  )
}
