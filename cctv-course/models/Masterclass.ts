import mongoose, { Schema, Document } from 'mongoose'

export interface IMasterclass extends Document {
  title: string
  slug: string
  description?: string
  price: number
  date: Date
  startTime?: string
  endTime?: string
  duration?: string
  maxSeats?: number
  registrationOpen: boolean
  certificateEnabled: boolean
  status?: string
  createdAt?: Date
  updatedAt?: Date
}

const MasterclassSchema = new Schema<IMasterclass>({
  title: { type: String, required: true },
  slug: { type: String, required: true, unique: true },
  description: String,
  price: { type: Number, required: true, default: 499 },
  date: { type: Date, required: true },
  startTime: String,
  endTime: String,
  duration: String,
  maxSeats: Number,
  registrationOpen: { type: Boolean, default: true },
  certificateEnabled: { type: Boolean, default: true },
  status: { type: String, default: 'draft' }
}, { timestamps: true })

export default mongoose.models.Masterclass || mongoose.model<IMasterclass>('Masterclass', MasterclassSchema)
