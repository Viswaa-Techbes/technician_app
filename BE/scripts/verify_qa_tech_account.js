const mongoose = require('mongoose');
require('dotenv').config({ path: '/var/www/techbes-BE/.env' });
const User = require('../models/User');
const { signToken } = require('../utils/jwt');

async function run() {
  await mongoose.connect(process.env.MONGODB_URI);
  console.log('MongoDB connected');

  // Find an admin user
  let admin = await User.findOne({ role: 'admin', isDeleted: { $ne: true } });
  if (!admin) {
    console.error('No active admin found');
    process.exit(1);
  }
  console.log('Using admin:', admin.name, '(', admin.email || admin.mobileNumber, ') ID:', admin._id);

  // Update admin lastSeen to now and sessionActive to true
  admin.lastSeen = new Date();
  admin.sessionActive = true;
  await admin.save({ validateBeforeSave: false });

  // Generate Admin JWT
  const adminToken = signToken(admin._id, 'admin');

  // Call Admin API to register test technician
  const targetUrl = 'https://api.techbes.co.in/api/v2/admin/users';
  const payload = {
    name: 'QA Tech Tester',
    mobileNumber: '9000099999',
    password: 'TechTest@123',
    role: 'technician',
    specialty: 'CCTV & Networking',
    pincode: '560001',
    employeeStatus: 'Active'
  };

  console.log('\nCalling POST ' + targetUrl + ' with Admin JWT...');
  const regRes = await fetch(targetUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + adminToken
    },
    body: JSON.stringify(payload)
  });

  const regData = await regRes.json();
  console.log('Registration HTTP Status:', regRes.status);
  console.log('Registration Response:', JSON.stringify(regData, null, 2));

  // Now verify live Technician login endpoint (POST /auth/login)
  console.log('\nVerifying login against https://api.techbes.co.in/auth/login...');
  const loginRes = await fetch('https://api.techbes.co.in/auth/login', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      mobileNumber: '9000099999',
      password: 'TechTest@123'
    })
  });

  const loginData = await loginRes.json();
  console.log('Login HTTP Status:', loginRes.status);
  console.log('Login Response:', JSON.stringify(loginData, null, 2));

  // Also check if user exists in DB to display the Employee ID / Code
  const techUser = await User.findOne({ mobileNumber: '9000099999' }).select('-password');
  console.log('\nCreated Technician Record in DB:');
  console.log({
    id: techUser._id,
    employeeId: techUser.employeeId || techUser.employeeCode || techUser._id,
    name: techUser.name,
    mobileNumber: techUser.mobileNumber,
    role: techUser.role,
    status: techUser.status,
    employeeStatus: techUser.employeeStatus
  });

  await mongoose.disconnect();
  process.exit(0);
}

run().catch(err => {
  console.error('Error running script:', err);
  process.exit(1);
});
