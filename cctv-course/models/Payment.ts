import mongoose, { Schema, Document } from 'mongoose'

export interface IPayment extends Document {
  registrationId: mongoose.Types.ObjectId
  razorpayOrderId?: string
  razorpayPaymentId?: string
  amount?: number
  currency?: string
  status?: string
  signatureVerified?: boolean
  webhookVerified?: boolean
  paidAt?: Date
}

const PaymentSchema = new Schema<IPayment>({
  registrationId: { type: Schema.Types.ObjectId, ref: 'Registration', required: true },
  razorpayOrderId: String,
  razorpayPaymentId: String,
  amount: Number,
  currency: { type: String, default: 'INR' },
  status: String,
  signatureVerified: { type: Boolean, default: false },
  webhookVerified: { type: Boolean, default: false },
  paidAt: Date
}, { timestamps: true })

export default mongoose.models.Payment || mongoose.model<IPayment>('Payment', PaymentSchema)
