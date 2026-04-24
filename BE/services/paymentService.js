const crypto = require('crypto');
const Job = require('../models/Job');
const { getRazorpayCredentials, getRazorpayInstance } = require('../config/razorpay');

async function createRazorpayOrder(amount, description, receipt, userId) {
  if (!Number.isFinite(amount) || amount <= 0) {
    throw new Error('Valid amount is required in paise');
  }

  const razorpay = getRazorpayInstance();
  const order = await razorpay.orders.create({
    amount: Math.round(amount),
    currency: 'INR',
    receipt,
    notes: {
      description,
      createdBy: userId,
    },
  });

  return {
    orderId: order.id,
    amount: order.amount,
    currency: order.currency,
    receipt: order.receipt,
    description,
    keyId: getRazorpayCredentials().keyId,
  };
}

async function verifyRazorpayPayment(jobId, orderId, paymentId, signature) {
  const { keySecret } = getRazorpayCredentials();
  const expectedSignature = crypto
    .createHmac('sha256', keySecret)
    .update(`${orderId}|${paymentId}`)
    .digest('hex');

  if (expectedSignature !== signature) {
    throw new Error('Payment signature verification failed');
  }

  const job = await Job.findById(jobId);
  if (!job) throw new Error('Job not found');

  job.orderId = orderId;
  job.paymentId = paymentId;
  job.paymentSignature = signature;
  job.paymentStatus = 'paid';
  
  // v2 flow might have different status updates
  if (job.useNewFlow) {
    job.status = 'completed'; 
  } else {
    job.status = 'completed'; // keeping consistency for now
  }
  
  await job.save();
  return job;
}

module.exports = {
  createRazorpayOrder,
  verifyRazorpayPayment,
};
