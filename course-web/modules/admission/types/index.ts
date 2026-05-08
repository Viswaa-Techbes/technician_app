export type AdmissionStatus =
  | 'applied'
  | 'under_review'
  | 'approved'
  | 'payment_pending'
  | 'enrolled'
  | 'rejected'

export type PaymentStatus = 'paid' | 'partially_paid' | 'pending'

export interface AdmissionApplication {
  _id: string
  fullName: string
  phone: string
  email: string
  qualification: string
  programType: 'course' | 'internship' | 'placement_program'
  financialStability?: string
  paymentStatus: PaymentStatus
  admissionStatus: AdmissionStatus
  assignedCourse?: string
  assignedInternship?: string
  createdAt: string
}
