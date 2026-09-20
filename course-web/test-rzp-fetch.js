const key_id = process.env.RAZORPAY_KEY_ID || '';
const key_secret = process.env.RAZORPAY_KEY_SECRET || '';

const auth = Buffer.from(`${key_id}:${key_secret}`).toString('base64');

fetch('https://api.razorpay.com/v1/orders', {
  method: 'POST',
  headers: {
    'Authorization': `Basic ${auth}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({
    amount: 799900,
    currency: 'INR',
    receipt: 'test_receipt',
  })
})
.then(res => res.json())
.then(console.log)
.catch(console.error);
