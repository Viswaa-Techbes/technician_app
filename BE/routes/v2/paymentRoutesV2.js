const express = require('express');
const paymentControllerV2 = require('../../controllers/v2/paymentControllerV2');
const { authenticate } = require('../../middlewares/auth');

const router = express.Router();

router.post('/create-order', authenticate, paymentControllerV2.createOrder);
router.post('/verify-payment', authenticate, paymentControllerV2.verifyPayment);

module.exports = router;
