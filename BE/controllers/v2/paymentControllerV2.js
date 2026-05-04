const paymentService = require('../../services/paymentService');
const Job = require('../../models/Job');

async function createOrder(req, res, next) {
  try {
    const { amount, description, receipt } = req.body;
    const orderData = await paymentService.createRazorpayOrder(amount, description, receipt, req.user?.id);
    res.status(201).json({ success: true, data: orderData });
  } catch (err) {
    next(err);
  }
}

async function verifyPayment(req, res, next) {
  try {
    const { jobId, razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    const job = await paymentService.verifyRazorpayPayment(jobId, razorpay_order_id, razorpay_payment_id, razorpay_signature);
    console.log(`[Payment] Verified payment for Job ${jobId}. Status: ${job.paymentStatus}`);
    res.json({ success: true, data: job });
  } catch (err) {
    next(err);
  }
}

async function requestPayment(req, res, next) {
  try {
    const { jobId, amount, description } = req.body;
    const job = await Job.findById(jobId);
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });

    job.amount = amount;
    job.paymentDescription = description || 'Technician requested payment';
    job.paymentStatus = 'requested';
    job.status = 'payment_requested';
    await job.save();

    console.log(`[Payment] Payment requested for Job ${jobId}, Amount: ${amount}`);
    res.json({ success: true, data: job });
  } catch (err) {
    next(err);
  }
}

async function getPaymentRequests(req, res, next) {
  try {
    const requests = await Job.find({ paymentStatus: 'requested' })
      .populate('assignedTechnician', 'name')
      .populate('client', 'name mobileNumber')
      .sort({ updatedAt: -1 });
    res.json({ success: true, data: requests });
  } catch (err) {
    next(err);
  }
}

async function approvePaymentRequest(req, res, next) {
  try {
    const { jobId } = req.body;
    const job = await Job.findById(jobId);
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });

    // Create Razorpay Order
    const orderData = await paymentService.createRazorpayOrder(
      job.amount * 100, // to paise
      job.paymentDescription,
      `job_${jobId}`,
      req.user.id
    );

    job.orderId = orderData.orderId;
    job.paymentStatus = 'pending_payment';
    job.status = 'payment_pending';
    await job.save();

    console.log(`[Payment] Approved payment request for Job ${jobId}. Order created: ${orderData.orderId}`);
    res.json({ success: true, data: { ...job.toObject(), razorpayOrder: orderData } });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createOrder,
  verifyPayment,
  requestPayment,
  getPaymentRequests,
  approvePaymentRequest
};
