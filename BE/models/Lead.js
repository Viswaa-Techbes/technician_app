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
      required: [true, 'Email is required'],
      lowercase: true,
      trim: true,
    },
    phone: {
      type: String,
      required: [true, 'Phone number is required'],
      trim: true,
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
