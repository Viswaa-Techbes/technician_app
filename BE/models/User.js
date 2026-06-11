const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const ROLES = ['admin', 'manager', 'technician', 'client'];

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      trim: true,
      default: '',
    },
    mobileNumber: {
      type: String,
      required: [true, 'Mobile number is required'],
      unique: true,
      trim: true,
      match: [/^\d{10,15}$/, 'Please use a valid mobile number'],
    },
    email: {
      type: String,
      lowercase: true,
      trim: true,
      default: undefined,
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false,
    },
    role: {
      type: String,
      enum: ROLES,
      required: true,
      default: 'technician',
    },
    phone: String,
    isOnline: {
      type: Boolean,
      default: false,
    },
    sessionActive: {
      type: Boolean,
      default: false,
    },
    lastSeen: {
      type: Date,
      default: Date.now,
    },
    status: {
      type: String,
      enum: ['available', 'busy', 'offline'],
      default: 'offline',
    },
    // ─── Dispatch Status (replaces isOnline for technicians) ──────────────────
    availabilityStatus: {
      type: String,
      enum: ['ONLINE', 'OFFLINE', 'BUSY'],
      default: 'OFFLINE',
    },
    // ─── Technician Profile Fields ────────────────────────────────────────────
    profilePhoto: {
      type: String,
      default: '',
    },
    specialty: String,
    serviceCategories: {
      type: [String],
      default: [],
    },
    pincodeCoverage: {
      type: [String],
      default: [],
    },
    rating: {
      type: Number,
      default: 5.0,
      min: 0,
      max: 5,
    },
    completedJobs: {
      type: Number,
      default: 0,
    },
    totalEarnings: {
      type: Number,
      default: 0,
    },
    penaltyPoints: {
      type: Number,
      default: 0,
    },
    performanceScore: {
      type: Number,
      default: 100,
    },
    activeJobId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Job',
      default: null,
    },
    penalties: {
      type: [{
        amount: { type: Number, default: 0 },
        reason: { type: String, default: '' },
        penaltyDate: { type: Date, default: Date.now },
        jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', default: null },
      }],
      default: [],
    },
    // ─── Location (updated by app in real-time) ───────────────────────────────
    locationUpdatedAt: {
      type: Date,
      default: null,
    },
    // ─── Legacy / Auth Fields ─────────────────────────────────────────────────
    permissions: {
      type: [String],
      default: []
    },
    assignedManager: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      default: null,
    },
    lat: {
      type: Number,
      default: 0.0,
    },
    lng: {
      type: Number,
      default: 0.0,
    },
    fcmToken: {
      type: String,
      default: null,
    },
    resetToken: {
      type: String,
      select: false,
    },
    resetTokenExpiry: {
      type: Date,
      select: false,
    },
    appId: {
      type: String,
      default: 'technician-v1',
    },
    isDeleted: {
      type: Boolean,
      default: false,
    },
    userType: {
      type: String,
      enum: ['member', 'web_user'],
      default: 'member',
    },
  },
  { timestamps: true }
);

userSchema.index({ email: 1 }, { unique: true, sparse: true });

userSchema.pre('validate', function normalizeBlankEmail(next) {
  if (typeof this.email === 'string' && this.email.trim() === '') {
    this.email = undefined;
  }
  next();
});

userSchema.pre('save', async function hashPassword(next) {
  if (!this.isModified('password')) return next();
  const salt = await bcrypt.genSalt(12);
  this.password = await bcrypt.hash(this.password, salt);
  next();
});

userSchema.methods.comparePassword = async function comparePassword(candidate) {
  return bcrypt.compare(candidate, this.password);
};

userSchema.methods.toSafeObject = function toSafeObject() {
  return {
    id: this._id.toString(),
    userId: this._id.toString(),
    name: this.name,
    mobileNumber: this.mobileNumber,
    email: this.email,
    role: this.role,
    phone: this.phone,
    isOnline: this.isOnline,
    status: this.status,
    specialty: this.specialty,
    assignedManager: this.assignedManager,
    createdAt: this.createdAt,
    updatedAt: this.updatedAt,
  };
};

module.exports = mongoose.model('User', userSchema);
module.exports.ROLES = ROLES;
