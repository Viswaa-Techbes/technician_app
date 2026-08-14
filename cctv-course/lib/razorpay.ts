import Razorpay from 'razorpay'

const key_id = process.env.RAZORPAY_KEY_ID || ''
const key_secret = process.env.RAZORPAY_KEY_SECRET || ''

if (!key_id || !key_secret) {
  // do not throw here so dev can work without keys until payment is tested
}

const razor = new Razorpay({ key_id, key_secret })

export default razor
