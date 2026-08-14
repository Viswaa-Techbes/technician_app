import mongoose, { Schema, Document } from 'mongoose'

export interface ICertificate extends Document {
  certificateId: string
  registrationId: mongoose.Types.ObjectId
  masterclassId: mongoose.Types.ObjectId
  participantName: string
  programName: string
  issueDate: Date
  pdfPath?: string
  verificationUrl?: string
}

const CertificateSchema = new Schema<ICertificate>({
  certificateId: { type: String, unique: true },
  registrationId: { type: Schema.Types.ObjectId, ref: 'Registration' },
  masterclassId: { type: Schema.Types.ObjectId, ref: 'Masterclass' },
  participantName: String,
  programName: String,
  issueDate: Date,
  pdfPath: String,
  verificationUrl: String
}, { timestamps: true })

export default mongoose.models.Certificate || mongoose.model<ICertificate>('Certificate', CertificateSchema)
