const fs = require('fs');
let code = fs.readFileSync('BE/controllers/v2/paymentControllerV2.js', 'utf8');

// Update webhookHandler for idempotency and Quote sync
const oldWebhook = `    if (event === 'payment.captured' || event === 'order.paid') {
      const paymentEntity = payload.payload && (payload.payload.payment || payload.payload.order);
      // prefer payment object
      const paymentObj = paymentEntity?.entity || null;
      if (paymentObj) {
        const Payment = require('../../models/Payment');
        const orderId = paymentObj.order_id || (paymentObj.notes && paymentObj.notes.receipt) || null;
        const paymentId = paymentObj.id || paymentObj.payment_id || null;
        if (orderId) {
          const pay = await Payment.findOne({ razorpayOrderId: orderId });
          if (pay) {
            pay.razorpayPaymentId = paymentId;
            pay.status = 'verified';
            await pay.save();
            console.log('[Payment Webhook] Marked payment verified for order', orderId);
            await PaymentAudit.create({ paymentId: pay._id, orderId, event: 'webhook_received', payload: { status: 'verified' } });
          }
        }
      }
    }`;

const newWebhook = `    if (event === 'payment.captured' || event === 'order.paid') {
      const paymentEntity = payload.payload && (payload.payload.payment || payload.payload.order);
      // prefer payment object
      const paymentObj = paymentEntity?.entity || null;
      if (paymentObj) {
        const Payment = require('../../models/Payment');
        const orderId = paymentObj.order_id || (paymentObj.notes && paymentObj.notes.receipt) || null;
        const paymentId = paymentObj.id || paymentObj.payment_id || null;
        if (orderId) {
          const pay = await Payment.findOne({ razorpayOrderId: orderId });
          if (pay) {
            if (pay.status === 'verified' || pay.status === 'paid') {
              console.log('[Payment Webhook] Order already verified/paid, idempotent ignore duplicate:', orderId);
              return res.json({ status: 'ok', message: 'Already processed', idempotent: true });
            }
            pay.razorpayPaymentId = paymentId;
            pay.status = 'verified';
            await pay.save();
            console.log('[Payment Webhook] Marked payment verified for order', orderId);
            await PaymentAudit.create({ paymentId: pay._id, orderId, event: 'webhook_received', payload: { status: 'verified' } });

            // If quoteId is present, synchronize quotation payment status
            if (pay.quoteId) {
              const QuoteRequest = require('../../models/QuoteRequest');
              const quote = await QuoteRequest.findById(pay.quoteId);
              if (quote) {
                if (pay.paymentType === 'advance' && quote.advancePaidAmount <= 0) {
                  quote.advancePaidAmount = quote.advanceAmount;
                  quote.balanceAmount = Math.max(0, Math.round((quote.finalAmount - quote.advancePaidAmount) * 100) / 100);
                  quote.status = quote.balanceAmount === 0 ? 'paid' : 'advance_paid';
                  quote.quotePaymentStatus = quote.balanceAmount === 0 ? 'fully_paid' : 'advance_paid';
                  await quote.save();
                } else if (pay.paymentType === 'balance') {
                  quote.balancePaidAmount = quote.balanceAmount;
                  quote.balanceAmount = 0;
                  quote.status = 'paid';
                  quote.quotePaymentStatus = 'fully_paid';
                  await quote.save();
                }
              }
            }
          }
        }
      }
    }`;

// Update getAllPayments
const oldGetAllPayments = `// Admin: list all payments with pagination
async function getAllPayments(req, res, next) {
  try {
    const Payment = require('../../models/Payment');
    const { page = 1, limit = 50 } = req.query;
    const payments = await Payment.find({}).sort({ createdAt: -1 }).skip((page - 1) * limit).limit(Number(limit)).lean();
    res.json({ success: true, data: payments });
  } catch (err) {
    next(err);
  }
}`;

const newGetAllPayments = `// Admin: list all payments with pagination, filtering by paymentType and status
async function getAllPayments(req, res, next) {
  try {
    const Payment = require('../../models/Payment');
    const { page = 1, limit = 50, paymentType, status } = req.query;
    const filter = {};
    if (paymentType && paymentType !== 'All') {
      filter.paymentType = paymentType;
    }
    if (status && status !== 'All') {
      filter.status = status;
    }
    const payments = await Payment.find(filter)
      .populate('userId', 'name mobileNumber email customerId')
      .populate('quoteId', 'requestId serviceCategory finalAmount advanceAmount balanceAmount')
      .populate('jobId', 'title status orderNumber')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit))
      .lean();
    res.json({ success: true, data: payments });
  } catch (err) {
    next(err);
  }
}`;

if (code.includes('if (event === \'payment.captured\' || event === \'order.paid\')')) {
  code = code.replace(oldWebhook, newWebhook);
}

if (code.includes('async function getAllPayments(req, res, next)')) {
  code = code.replace(oldGetAllPayments, newGetAllPayments);
}

fs.writeFileSync('BE/controllers/v2/paymentControllerV2.js', code, 'utf8');
console.log('paymentControllerV2 updated successfully');
