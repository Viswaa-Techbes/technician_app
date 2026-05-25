const mongoose = require('mongoose');

const JOB_STATUSES = [
  'pending',
  'not_visited',
  'site_visited',
  'assigned',
  'advance_paid',
  'confirmed',
  'in_progress',
  'started',
  'work_uploaded',
  'completion_requested',
  'approved_by_manager',
  'payment_requested',
  'payment_pending',
  'payment_done',
  'completed'
];
const PAYMENT_STATUSES = ['pending', 'advance_paid', 'requested', 'pending_payment', 'verification_pending', 'paid', 'rejected'];

const jobSchema = new mongoose.Schema(
  {
    title: {
      type: String,
      required: [true, 'Job title is required'],
      trim: true,
    },
    description: {
      type: String,
      default: '',
      trim: true,
    },
    status: {
      type: String,
      enum: JOB_STATUSES,
      default: 'assigned',
    },
    assignedTechnician: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    assignedManager: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: false,
      default: null,
    },
    location: {
      type: String, // Acts as address
      default: '',
    },
    googleMapsLink: {
      type: String,
      default: '',
    },
    attachments: [
      {
        type: String,
      },
    ],
    // Compatibility fields
    customerName: {
      type: String,
      default: '',
    },
    serviceType: {
      type: String,
      enum: ['installation', 'repair', 'other'],
      default: 'other',
    },
    customerPhone: {
      type: String,
      default: '',
    },
    scheduledTime: {
      type: String,
      default: 'ASAP',
    },
    price: {
      type: Number,
      default: 0,
    },
    amount: {
      type: Number,
      default: 0,
      min: 0,
    },
    paymentStatus: {
      type: String,
      enum: PAYMENT_STATUSES,
      default: 'pending',
    },
    paymentDescription: {
      type: String,
      default: '',
      trim: true,
    },
    currency: {
      type: String,
      default: 'INR',
      trim: true,
    },
    orderId: {
      type: String,
      default: '',
      trim: true,
    },
    paymentId: {
      type: String,
      default: '',
      trim: true,
    },
    paymentSignature: {
      type: String,
      default: '',
      trim: true,
    },
    useNewFlow: {
      type: Boolean,
      default: false,
    },
    v2Metadata: {
      type: Map,
      of: String,
      default: {},
    },
    appId: {
      type: String,
      default: 'technician-v1',
    },
    client: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    // Booking-flow specific fields
    bookingDate: {
      type: String,
      default: '',
    },
    timeSlot: {
      type: String,
      default: '',
    },
    serviceId: {
      type: String,
      default: '',
    },
    serviceName: {
      type: String,
      default: '',
    },
    acceptedAt: Date,
    startedAt: Date,
    completedAt: Date,
    // Advance payment tracking
    advancePaid: {
      type: Boolean,
      default: false,
    },
    advancePaymentId: {
      type: String,
      default: '',
    },
    advanceAmount: {
      type: Number,
      default: 0,
    },
    remainingAmount: {
      type: Number,
      default: 0,
    },
    transactionId: {
      type: String,
      default: '',
    },
    // Business logic module routing
    module: {
      type: String,
      enum: ['project', 'service_request', 'general'],
      default: 'general',
    },
    // RBAC: which manager/admin created this
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
  },
  { timestamps: true }
);

jobSchema.index({ assignedTechnician: 1, status: 1 });
jobSchema.index({ assignedManager: 1, createdAt: -1 });

module.exports = mongoose.model('Job', jobSchema);
module.exports.JOB_STATUSES = JOB_STATUSES;
module.exports.PAYMENT_STATUSES = PAYMENT_STATUSES;
