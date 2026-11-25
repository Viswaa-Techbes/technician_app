const mongoose = require('mongoose');
require('dotenv').config();

async function fix() {
  await mongoose.connect(process.env.MONGODB_URI);
  const coll = mongoose.connection.collection('users');
  const res = await coll.updateOne(
    { email: 'lohith@techbes.co.in' },
    { $set: { mobileNumber: '9123456789', phone: '9123456789' } }
  );
  console.log('Admin user update result:', res);
  await mongoose.disconnect();
}

fix().catch(console.error);
