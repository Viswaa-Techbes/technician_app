const crypto = require('crypto');

const Job = require('../models/Job');
const { getRazorpayCredentials, getRazorpayInstance } = require('../config/razorpay');

async function createOrder(req, res, next) {
  try {
    const amount = Number(req.body.amount);
    const description = req.body.description?.toString().trim() || 'Job payment';
    const receipt = req.body.receipt?.toString().trim() || `job_${Date.now()}`;

    if (!Number.isFinite(amount) || amount <= 0) {
      return res.status(400).json({ success: false, message: 'Valid amount is required in paise' });
    }

    const razorpay = getRazorpayInstance();
    const order = await razorpay.orders.create({
      amount: Math.round(amount),
      currency: 'INR',
      receipt,
      notes: {
        description,
        createdBy: req.user.id,
      },
    });

    return res.status(201).json({
      success: true,
      data: {
        orderId: order.id,
        amount: order.amount,
        currency: order.currency,
        receipt: order.receipt,
        description,
        keyId: getRazorpayCredentials().keyId,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function verifyPayment(req, res, next) {
  try {
    const {
      jobId,
      razorpay_order_id: orderId,
      razorpay_payment_id: paymentId,
      razorpay_signature: signature,
    } = req.body;

    if (!jobId || !orderId || !paymentId || !signature) {
      return res.status(400).json({ success: false, message: 'jobId, razorpay_order_id, razorpay_payment_id and razorpay_signature are required' });
    }

    const { keySecret } = getRazorpayCredentials();
    const expectedSignature = crypto
      .createHmac('sha256', keySecret)
      .update(`${orderId}|${paymentId}`)
      .digest('hex');

    if (expectedSignature !== signature) {
      return res.status(400).json({ success: false, message: 'Payment signature verification failed' });
    }

    const job = await Job.findById(jobId);
    if (!job) {
      return res.status(404).json({ success: false, message: 'Job not found' });
    }

    const assignedTechnicianId = job.assignedTechnician?.toString();
    const allowedRoles = ['manager', 'admin'];
    const isAssignedTechnician = req.user.role === 'technician' && assignedTechnicianId === req.user.id;

    if (!allowedRoles.includes(req.user.role) && !isAssignedTechnician) {
      return res.status(403).json({ success: false, message: 'Not authorized to verify this payment' });
    }

    job.orderId = orderId;
    job.paymentId = paymentId;
    job.paymentSignature = signature;
    job.paymentStatus = 'verification_pending';
    await job.save();

    return res.json({
      success: true,
      message: 'Payment verified and sent for admin confirmation',
      data: {
        jobId: job._id.toString(),
        orderId: job.orderId,
        paymentId: job.paymentId,
        paymentStatus: job.paymentStatus,
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createOrder,
  verifyPayment,
};
