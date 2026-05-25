const paymentService = require('../../services/paymentService');
const Job = require('../../models/Job');

async function createOrder(req, res, next) {
  try {
    const { jobId, amount, description, receipt } = req.body;
    let payableAmount = Number(amount);
    let paymentDescription = description;
    let paymentReceipt = receipt;

    if (jobId) {
      const job = await Job.findById(jobId);
      if (!job) return res.status(404).json({ success: false, message: 'Booking not found' });
      if (job.client && job.client.toString() !== req.user.id && !['admin', 'manager'].includes(req.user.role)) {
        return res.status(403).json({ success: false, message: 'Not authorized to pay for this booking' });
      }
      payableAmount = Math.round(Number(job.advanceAmount || Math.round((job.amount || job.price || 0) / 2)) * 100);
      paymentDescription = paymentDescription || `Advance for booking ${job._id}`;
      paymentReceipt = paymentReceipt || `job_${job._id}`;
    }

    const orderData = await paymentService.createRazorpayOrder(payableAmount, paymentDescription, paymentReceipt, req.user.id);
    res.status(201).json({ success: true, data: orderData });
  } catch (err) {
    next(err);
  }
}

async function verifyPayment(req, res, next) {
  try {
    const { jobId, razorpay_order_id, razorpay_payment_id, razorpay_signature, amount } = req.body;

    if (!jobId || !razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
      return res.status(400).json({ success: false, message: 'jobId, razorpay_order_id, razorpay_payment_id and razorpay_signature are required' });
    }

    // amount is expected in paise for advance verification
    const amountPaise = Number(amount) || 0;

    const result = await paymentService.verifyAdvancePayment(jobId, razorpay_order_id, razorpay_payment_id, razorpay_signature, amountPaise, req.user?.id);
    console.log(`[Payment] Verified advance payment for Job ${jobId}.`);
    res.json({ success: true, data: result });
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
