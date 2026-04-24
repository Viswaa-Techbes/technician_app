const paymentService = require('../../services/paymentService');

async function createOrder(req, res, next) {
  try {
    const { amount, description, receipt } = req.body;
    const orderData = await paymentService.createRazorpayOrder(amount, description, receipt, req.user.id);
    res.status(201).json({ success: true, data: orderData });
  } catch (err) {
    next(err);
  }
}

async function verifyPayment(req, res, next) {
  try {
    const { jobId, razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    const job = await paymentService.verifyRazorpayPayment(jobId, razorpay_order_id, razorpay_payment_id, razorpay_signature);
    res.json({ success: true, data: job });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createOrder,
  verifyPayment,
};
