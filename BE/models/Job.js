const mongoose = require('mongoose');

const JOB_STATUSES = [
  'pending',
  'assigned',
  'started',
  'work_uploaded',
  'completion_requested',
  'approved_by_manager',
  'payment_pending',
  'payment_done',
  'completed'
];
const PAYMENT_STATUSES = ['pending', 'verification_pending', 'paid', 'rejected'];

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
      required: [true, 'assignedManager is required'],
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
  },
  { timestamps: true }
);

jobSchema.index({ assignedTechnician: 1, status: 1 });
jobSchema.index({ assignedManager: 1, createdAt: -1 });

module.exports = mongoose.model('Job', jobSchema);
module.exports.JOB_STATUSES = JOB_STATUSES;
module.exports.PAYMENT_STATUSES = PAYMENT_STATUSES;
