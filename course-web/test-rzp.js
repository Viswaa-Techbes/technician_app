const Razorpay = require('razorpay');

const razorpay = new Razorpay({
  key_id: 'rzp_live_SSi3PthRn4IDft',
  key_secret: 'SYeuAE0Liu6jNSvwaOVxTISm',
});

razorpay.orders.create({
  amount: 799900,
  currency: 'INR',
  receipt: 'test_receipt',
}).then(console.log).catch(console.error);
