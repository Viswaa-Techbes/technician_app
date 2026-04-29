const express = require('express');
const paymentControllerV2 = require('../../controllers/v2/paymentControllerV2');
const { optionalAuthenticate } = require('../../middlewares/auth');

const router = express.Router();

router.post('/create-order', optionalAuthenticate, paymentControllerV2.createOrder);
router.post('/verify-payment', optionalAuthenticate, paymentControllerV2.verifyPayment);

module.exports = router;
