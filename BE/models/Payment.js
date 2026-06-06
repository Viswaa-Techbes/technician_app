const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema(
  {
    jobId: { type: mongoose.Schema.Types.ObjectId, ref: 'Job', required: false },
    userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: false },
    razorpayOrderId: { type: String, required: true },
    razorpayPaymentId: { type: String, required: false },
    razorpaySignature: { type: String, required: false },
    amount: { type: Number, required: true }, // in paise
    currency: { type: String, default: 'INR' },
    status: { type: String, enum: ['created','pending','processing','paid','failed','cancelled','refunded','verified'], default: 'created' },
    meta: { type: Object, default: {} },
    orderNumber: { type: String, unique: true, sparse: true },
    paymentReference: { type: String, unique: true, sparse: true },
  },
  { timestamps: true }
);

paymentSchema.pre('validate', function(next) {
  const timestamp = Math.floor(Date.now() / 1000);
  const randomSuffix = Math.random().toString(36).substring(2, 6).toUpperCase();
  if (!this.orderNumber) {
    this.orderNumber = `ORD-${timestamp}-${randomSuffix}`;
  }
  if (!this.paymentReference) {
    this.paymentReference = `PAY-${timestamp}-${randomSuffix}`;
  }
  next();
});

module.exports = mongoose.model('Payment', paymentSchema);
