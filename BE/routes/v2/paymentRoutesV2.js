const express = require('express');
const paymentControllerV2 = require('../../controllers/v2/paymentControllerV2');
const { authenticate, requireRoles } = require('../../middlewares/auth');

const router = express.Router();

router.post('/create-order', authenticate, paymentControllerV2.createOrder);
router.post('/verify-payment', authenticate, paymentControllerV2.verifyPayment);

// New Flow
router.post('/request', authenticate, paymentControllerV2.requestPayment);
router.get('/requests', authenticate, requireRoles('admin'), paymentControllerV2.getPaymentRequests);
router.post('/approve', authenticate, requireRoles('admin'), paymentControllerV2.approvePaymentRequest);

module.exports = router;
