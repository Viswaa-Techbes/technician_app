const mongoose = require('mongoose');

const JOB_STATUSES = [
  'pending',
  'otp_verified',
  'not_visited',
  'site_visited',
  'assigned',
  'accepted',
  'travelling',
  'arrived',
  'working',
  'in_progress',
  'started',
  'work_uploaded',
  'completion_requested',
  'approved_by_manager',
  'payment_requested',
  'payment_pending',
  'payment_done',
  'completed',
  'closed'
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
    cctvDetails: {
      category: {
        id: { type: mongoose.Schema.Types.ObjectId, ref: 'CctvCategory', default: null },
        name: { type: String, default: '', trim: true },
        slug: { type: String, default: '', trim: true },
      },
      subcategory: {
        id: { type: mongoose.Schema.Types.ObjectId, ref: 'CctvSubcategory', default: null },
        name: { type: String, default: '', trim: true },
        slug: { type: String, default: '', trim: true },
      },
      cameraType: {
        id: { type: mongoose.Schema.Types.ObjectId, ref: 'CctvCameraType', default: null },
        name: { type: String, default: '', trim: true },
        slug: { type: String, default: '', trim: true },
        unitPrice: { type: Number, default: 0, min: 0 },
      },
      cameraCount: { type: Number, default: 0, min: 0 },
      installationArea: { type: String, enum: ['indoor', 'outdoor', ''], default: '' },
      wireLength: { type: Number, default: 0, min: 0 },
      addons: [
        {
          id: { type: mongoose.Schema.Types.ObjectId, ref: 'CctvAddon', default: null },
          name: { type: String, default: '', trim: true },
          slug: { type: String, default: '', trim: true },
          price: { type: Number, default: 0, min: 0 },
          quantity: { type: Number, default: 1, min: 1 },
          total: { type: Number, default: 0, min: 0 },
        },
      ],
      priceBreakdown: {
        baseCharge: { type: Number, default: 0, min: 0 },
        cameraUnitPrice: { type: Number, default: 0, min: 0 },
        cameraCount: { type: Number, default: 0, min: 0 },
        cameraTotal: { type: Number, default: 0, min: 0 },
        indoorCharge: { type: Number, default: 0, min: 0 },
        outdoorCharge: { type: Number, default: 0, min: 0 },
        areaCharge: { type: Number, default: 0, min: 0 },
        wireLength: { type: Number, default: 0, min: 0 },
        wirePricePerMeter: { type: Number, default: 0, min: 0 },
        wireTotal: { type: Number, default: 0, min: 0 },
        addonsTotal: { type: Number, default: 0, min: 0 },
        discountTotal: { type: Number, default: 0, min: 0 },
        couponTotal: { type: Number, default: 0, min: 0 },
        offerAdjustment: { type: Number, default: 0, min: 0 },
        taxableAmount: { type: Number, default: 0, min: 0 },
        taxTotal: { type: Number, default: 0, min: 0 },
        grandTotal: { type: Number, default: 0, min: 0 },
      },
      notes: { type: String, default: '', trim: true },
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
    bookingNumber: {
      type: String,
      unique: true,
      sparse: true,
    },
    // New Booking Collection Schema Fields
    bookingId: {
      type: String,
      default: '',
    },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      index: true,
    },
    materials: {
      type: mongoose.Schema.Types.Mixed,
      default: null,
    },
    addressId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Address',
      default: null,
    },
    bookingStatus: {
      type: String,
      default: 'pending',
    },
    totalAmount: {
      type: Number,
      default: 0,
    },
    technicianId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    scheduledDate: {
      type: String,
      default: '',
    },
    scheduledTime: {
      type: String,
      default: 'ASAP',
    },
  },
  { timestamps: true }
);

jobSchema.pre('validate', function(next) {
  if (!this.bookingNumber) {
    const timestamp = Math.floor(Date.now() / 1000);
    const randomSuffix = Math.random().toString(36).substring(2, 6).toUpperCase();
    this.bookingNumber = `BOOK-${timestamp}-${randomSuffix}`;
  }
  
  // Synchronize Booking Collection schema fields
  this.bookingId = this.bookingNumber;
  if (this.client) this.userId = this.client;
  if (this.assignedTechnician) this.technicianId = this.assignedTechnician;
  if (this.bookingDate) this.scheduledDate = this.bookingDate;
  if (this.timeSlot) this.scheduledTime = this.timeSlot;
  if (this.price || this.amount) this.totalAmount = this.price || this.amount;
  if (this.status) this.bookingStatus = this.status;
  if (this.cctvDetails && !this.materials) {
    this.materials = this.cctvDetails;
  }
  
  next();
});

jobSchema.index({ assignedTechnician: 1, status: 1 });
jobSchema.index({ assignedManager: 1, createdAt: -1 });
jobSchema.index({ 'cctvDetails.category.slug': 1, 'cctvDetails.subcategory.slug': 1 });
jobSchema.index({ 'cctvDetails.cameraType.slug': 1, status: 1, paymentStatus: 1 });

module.exports = mongoose.model('Job', jobSchema);
module.exports.JOB_STATUSES = JOB_STATUSES;
module.exports.PAYMENT_STATUSES = PAYMENT_STATUSES;
