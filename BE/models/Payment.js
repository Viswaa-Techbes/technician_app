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
    status: { type: String, enum: ['created','paid','failed','verified'], default: 'created' },
    meta: { type: Object, default: {} },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Payment', paymentSchema);
