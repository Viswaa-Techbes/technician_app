const mongoose = require('mongoose');

const leadSchema = new mongoose.Schema(
  {
    leadId: { type: String, required: true, unique: true, index: true },
    name: { type: String, required: true, trim: true },
    phone: { type: String, required: true, trim: true },
    email: { type: String, trim: true, lowercase: true },
    company: { type: String, trim: true },
    address: { type: String, trim: true },
    location: {
      lat: { type: Number },
      lng: { type: Number },
      mapLink: { type: String, default: '' },
    },
    source: { type: String, default: 'web' },
    requiredService: { type: String, trim: true },
    budget: { type: Number, default: 0 },
    priority: { type: String, enum: ['low','medium','high'], default: 'medium' },
    assignedTo: { type: mongoose.Schema.Types.ObjectId, ref: 'User', default: null },
    status: { type: String, enum: ['New','Contacted','Qualified','Proposal Sent','Negotiation','Won','Lost','Project Created'], default: 'New' },
    remarks: { type: String, default: '' },
    isDeleted: { type: Boolean, default: false },
  },
  { timestamps: true }
);

leadSchema.pre('validate', function(next) {
  if (!this.leadId) {
    this.leadId = `LD${Date.now().toString().slice(-8)}`;
  }
  next();
});

module.exports = mongoose.model('Lead', leadSchema);
const mongoose = require('mongoose');

const leadSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      required: false,
      lowercase: true,
      trim: true,
      default: null,
    },
    phone: {
      type: String,
      required: false,
      trim: true,
      default: '',
    },
    password: {
      type: String,
      select: false,
    },
    service: {
      type: String,
      default: null,
      trim: true,
    },
    plan: {
      type: String,
      default: null,
      trim: true,
    },
    pincode: {
      type: String,
      trim: true,
    },
    paymentId: {
      type: String,
      trim: true,
    },
    role: {
      type: String,
      default: 'user',
      trim: true,
    },
    status: {
      type: String,
      default: 'Active',
      trim: true,
    },
    isDeleted: {
      type: Boolean,
      default: false,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Lead', leadSchema, 'leads');
