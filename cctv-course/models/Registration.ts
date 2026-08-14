import mongoose, { Schema, Document } from 'mongoose'

export type PaymentStatus = 'PENDING' | 'PAID' | 'FAILED' | 'REFUNDED'
export type RegistrationStatus = 'PENDING' | 'REGISTERED' | 'ATTENDED' | 'ABSENT' | 'CANCELLED'

export interface IRegistration extends Document {
  enrollmentId?: string
  masterclassId: mongoose.Types.ObjectId
  name: string
  mobile: string
  email: string
  whatsapp?: string
  location: string
  qualification: string
  paymentStatus: PaymentStatus
  registrationStatus: RegistrationStatus
  razorpayOrderId?: string
  razorpayPaymentId?: string
  amount?: number
  paidAt?: Date
  attended?: boolean
  certificateStatus?: string
}

const RegistrationSchema = new Schema<IRegistration>({
  enrollmentId: { type: String, index: true, unique: true, sparse: true },
  masterclassId: { type: Schema.Types.ObjectId, ref: 'Masterclass', required: true, index: true },
  name: String,
  mobile: String,
  email: String,
  whatsapp: String,
  location: String,
  qualification: String,
  paymentStatus: { type: String, enum: ['PENDING','PAID','FAILED','REFUNDED'], default: 'PENDING' },
  registrationStatus: { type: String, enum: ['PENDING','REGISTERED','ATTENDED','ABSENT','CANCELLED'], default: 'PENDING' },
  razorpayOrderId: String,
  razorpayPaymentId: String,
  amount: Number,
  paidAt: Date,
  attended: { type: Boolean, default: false },
  certificateStatus: { type: String, default: 'NOT_ELIGIBLE' }
}, { timestamps: true })

RegistrationSchema.index({ email: 1 })
RegistrationSchema.index({ mobile: 1 })

export default mongoose.models.Registration || mongoose.model<IRegistration>('Registration', RegistrationSchema)
