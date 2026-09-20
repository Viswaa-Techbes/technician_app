const Razorpay = require('razorpay');

const razorpay = new Razorpay({
  key_id: process.env.RAZORPAY_KEY_ID || '',
  key_secret: process.env.RAZORPAY_KEY_SECRET || '',
});

razorpay.orders.create({
  amount: 799900,
  currency: 'INR',
  receipt: 'test_receipt',
}).then(console.log).catch(console.error);
