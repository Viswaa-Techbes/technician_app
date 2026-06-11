require('dotenv').config();
const mongoose = require('mongoose');
const Address = require('./models/Address');

async function run() {
  const mongoUri = process.env.MONGODB_URI || 'mongodb://127.0.0.1:27017/technician_app';
  try {
    await mongoose.connect(mongoUri);
    const address = await Address.findOne({ latitude: { $ne: null } }).lean();
    console.log('--- ADDRESS DB RECORD ---');
    console.log(JSON.stringify(address, null, 2));
  } catch (err) {
    console.error('Error querying address:', err.message);
  } finally {
    await mongoose.disconnect();
  }
}

run();
