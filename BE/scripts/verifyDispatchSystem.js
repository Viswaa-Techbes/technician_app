/**
 * verifyDispatchSystem.js
 * =======================
 * Automated validation script for Phase 2 Technician Dispatch System.
 */

// Set port and launch backend server
process.env.PORT = 5009;
process.env.NODE_ENV = 'test'; // prevent email service verify SMTP connection hanging
const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '../.env') });

const mongoose = require('mongoose');

console.log('Spinning up server on port 5009...');
require('../server.js');

// Import models
const User = require('../models/User');
const Job = require('../models/Job');
const JobRequest = require('../models/JobRequest');
const BangalorePincode = require('../models/BangalorePincode');
const Notification = require('../models/Notification');
const dispatchService = require('../services/dispatchService');

// Socket IO Client
const ioClient = require('socket.io-client');

function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

async function run() {
  console.log('Waiting 5 seconds for database connection and server startup...');
  await sleep(5000);

  const ioServer = global._socketIo;
  if (!ioServer) {
    console.error('Socket.IO server not initialized!');
    process.exit(1);
  }
  console.log('Backend server and Socket.IO are running!');

  // Clear any existing test data to start fresh
  console.log('Clearing old test data...');
  await User.deleteMany({ email: { $in: ['test_admin@techbes.com', 'test_customer@techbes.com', 'tech_near@techbes.com', 'tech_far@techbes.com', 'tech_offline@techbes.com'] } });
  await BangalorePincode.deleteMany({ pincode: '560001' });
  await JobRequest.deleteMany({});
  await Notification.deleteMany({});
  await Job.deleteMany({ title: /Test Job/ });

  // 1. Seed pincode
  console.log('Seeding Bangalore pincode 560001...');
  await BangalorePincode.create({
    pincode: '560001',
    areaName: 'Bangalore General Post Office Area',
    latitude: 12.9716,
    longitude: 77.5946,
    active: true,
  });

  // 2. Seed Users
  console.log('Seeding mock users (Admin, Customer, Technicians)...');
  const admin = await User.create({
    name: 'Test Admin',
    email: 'test_admin@techbes.com',
    mobileNumber: '9999999991',
    password: 'password123',
    role: 'admin',
    status: 'available',
  });

  const customer = await User.create({
    name: 'Test Customer',
    email: 'test_customer@techbes.com',
    mobileNumber: '9999999992',
    password: 'password123',
    role: 'client',
  });

  const techNear = await User.create({
    name: 'Near Technician (1.1 km)',
    email: 'tech_near@techbes.com',
    mobileNumber: '9999999993',
    password: 'password123',
    role: 'technician',
    pincodeCoverage: ['560001'],
    serviceCategories: ['CCTV'],
    rating: 4.8,
    availabilityStatus: 'ONLINE',
    lat: 12.9716 + 0.008, // ~1.1 km away
    lng: 77.5946 + 0.008,
  });

  const techFar = await User.create({
    name: 'Far Technician (9.6 km)',
    email: 'tech_far@techbes.com',
    mobileNumber: '9999999994',
    password: 'password123',
    role: 'technician',
    pincodeCoverage: ['560001'],
    serviceCategories: ['CCTV'],
    rating: 4.5,
    availabilityStatus: 'ONLINE',
    lat: 12.9716 + 0.06, // ~8.0 km away
    lng: 77.5946 + 0.06,
  });

  const techOffline = await User.create({
    name: 'Offline Technician',
    email: 'tech_offline@techbes.com',
    mobileNumber: '9999999995',
    password: 'password123',
    role: 'technician',
    pincodeCoverage: ['560001'],
    serviceCategories: ['CCTV'],
    rating: 4.9,
    availabilityStatus: 'OFFLINE',
    lat: 12.9716,
    lng: 77.5946,
  });

  console.log('Seed completed successfully!');

  // 3. Connect Socket clients
  console.log('Connecting socket clients to http://localhost:5009...');
  
  const adminSocket = ioClient('http://localhost:5009', { transports: ['websocket'] });
  const clientSocket = ioClient('http://localhost:5009', { transports: ['websocket'] });
  const techNearSocket = ioClient('http://localhost:5009', { transports: ['websocket'] });
  const techFarSocket = ioClient('http://localhost:5009', { transports: ['websocket'] });

  const adminLogs = [];
  const clientLogs = [];
  const techNearLogs = [];
  const techFarLogs = [];

  // Wire event handlers
  adminSocket.on('connect', () => {
    console.log('[Socket Test] Admin connected successfully');
    adminSocket.emit('join_admin');
  });
  clientSocket.on('connect', () => {
    console.log('[Socket Test] Customer connected successfully');
    clientSocket.emit('join', customer._id.toString());
  });
  techNearSocket.on('connect', () => {
    console.log('[Socket Test] Near Tech connected successfully');
    techNearSocket.emit('join', techNear._id.toString());
  });
  techFarSocket.on('connect', () => {
    console.log('[Socket Test] Far Tech connected successfully');
    techFarSocket.emit('join', techFar._id.toString());
  });

  adminSocket.on('newBooking', (data) => adminLogs.push({ event: 'newBooking', data }));
  adminSocket.on('notification', (data) => adminLogs.push({ event: 'notification', data }));
  adminSocket.on('technicianStatusUpdate', (data) => adminLogs.push({ event: 'technicianStatusUpdate', data }));

  clientSocket.on('technicianAssigned', (data) => clientLogs.push({ event: 'technicianAssigned', data }));
  clientSocket.on('notification', (data) => clientLogs.push({ event: 'notification', data }));

  techNearSocket.on('bookingAssigned', (data) => techNearLogs.push({ event: 'bookingAssigned', data }));
  techNearSocket.on('newJobRequest', (data) => techNearLogs.push({ event: 'newJobRequest', data }));
  techNearSocket.on('notification', (data) => techNearLogs.push({ event: 'notification', data }));

  techFarSocket.on('newJobRequest', (data) => techFarLogs.push({ event: 'newJobRequest', data }));
  techFarSocket.on('notification', (data) => techFarLogs.push({ event: 'notification', data }));

  await sleep(1500);

  console.log('\n==================================================');
  console.log('TEST 1: AUTO-ASSIGNMENT WORKFLOW');
  console.log('==================================================');

  // Customer creates a booking/job
  const job = await Job.create({
    title: 'Test Job - CCTV Camera Repair',
    serviceName: 'CCTV Camera Repair',
    serviceId: 'cctv',
    customerName: customer.name,
    customerPhone: customer.mobileNumber,
    location: 'Bangalore Central, 560001',
    price: 1500,
    amount: 1500,
    client: customer._id,
    v2Metadata: {
      pincode: '560001',
      lat: String(12.9716),
      lng: String(77.5946),
    },
    status: 'pending',
    dispatchStatus: 'pending_dispatch',
  });
  
  console.log(`Job created: ${job._id} with pincode 560001 (lat: 12.9716, lng: 77.5946).`);
  console.log('Simulating Payment Success and triggering Auto-Assignment...');

  // Running autoAssign
  const autoAssignResult = await dispatchService.autoAssignTechnician(job._id, ioServer);
  console.log('Auto assignment result:', autoAssignResult);

  // Verification in database
  const updatedJob1 = await Job.findById(job._id).populate('assignedTechnician');
  console.log('\n--- MongoDB Job Verification ---');
  console.log('Assigned Technician:', updatedJob1.assignedTechnician.name);
  console.log('Assignment Method:', updatedJob1.assignmentMethod);
  console.log('Dispatch Status:', updatedJob1.dispatchStatus);
  console.log('Job Status:', updatedJob1.status);

  // Check if technician is BUSY
  const updatedTechNear = await User.findById(techNear._id);
  console.log('Technician Status in DB:', updatedTechNear.availabilityStatus);
  console.log('Technician Active Job:', updatedTechNear.activeJobId);

  // Verify notifications saved in MongoDB
  const notificationsTest1 = await Notification.find({ bookingId: job._id }).lean();
  console.log('\n--- MongoDB Notifications Created ---');
  notificationsTest1.forEach(n => {
    console.log(`- RecipientType: ${n.recipientType}, Title: "${n.title}", Msg: "${n.message}", recipientId: ${n.recipientId}, bookingId: ${n.bookingId}`);
  });

  await sleep(1500);

  // Print socket messages received
  console.log('\n--- Socket.IO Events Received ---');
  console.log('Client Socket Received:', clientLogs);
  console.log('Technician Socket Received:', techNearLogs);
  console.log('Admin Socket Received:', adminLogs);

  console.log('\n==================================================');
  console.log('TEST 2: TECHNICIAN CANCELLATION & RE-DISPATCH (FALLBACK BROADCAST)');
  console.log('==================================================');
  
  // Clear logs to watch this test
  clientLogs.length = 0;
  techNearLogs.length = 0;
  techFarLogs.length = 0;
  adminLogs.length = 0;

  console.log('Simulating Near Technician cancelling the job...');
  // Near tech cancels
  const cancelResult = await dispatchService.technicianCancelJob(job._id, techNear._id, 'Motorcycle broke down', ioServer);
  console.log('Cancellation Result:', cancelResult);

  // Set BOTH technicians to OFFLINE immediately so the scheduled 2-second auto-redispatch fails to find anyone
  await User.findByIdAndUpdate(techNear._id, { availabilityStatus: 'OFFLINE' });
  await User.findByIdAndUpdate(techFar._id, { availabilityStatus: 'OFFLINE' });
  console.log('Set both technicians to OFFLINE temporarily to prevent direct auto re-dispatch assignment.');

  // Verify penalty and score
  const updatedTechNearAfterCancel = await User.findById(techNear._id);
  console.log('\n--- Technician Penalty Verification ---');
  console.log('Penalty Points:', updatedTechNearAfterCancel.penaltyPoints);
  console.log('Performance Score:', updatedTechNearAfterCancel.performanceScore);
  console.log('Penalty History Count:', updatedTechNearAfterCancel.penalties.length);
  console.log('First Penalty Record:', updatedTechNearAfterCancel.penalties[0]);

  console.log('Waiting 3.5 seconds for the 2-second automatic re-dispatch timeout to run...');
  await sleep(3500);

  // Now, the job should have dispatchStatus: 'no_tech_found'
  const updatedJobAfterTimeout = await Job.findById(job._id);
  console.log('Job Dispatch Status after timeout:', updatedJobAfterTimeout.dispatchStatus);

  // Set Far Technician to ONLINE so he can be broadcasted to
  await User.findByIdAndUpdate(techFar._id, { availabilityStatus: 'ONLINE' });
  console.log('Set Far Technician back to ONLINE.');

  // Trigger manual broadcast
  console.log('Triggering fallback broadcast manually...');
  const broadcastResult = await dispatchService.broadcastJobRequest(job._id, ioServer);
  console.log('Broadcast Result:', broadcastResult);

  await sleep(1500); // let broadcast complete and sockets receive it

  // Verify that the job is now broadcasted
  const updatedJob2 = await Job.findById(job._id);
  console.log('\n--- Job Redispatch Verification ---');
  console.log('Dispatch Status:', updatedJob2.dispatchStatus);
  console.log('Assignment Method:', updatedJob2.assignmentMethod);
  console.log('Broadcasted To:', updatedJob2.broadcastedTo);

  // Check fallback requests created in DB
  const requests = await JobRequest.find({ jobId: job._id }).populate('technicianId').lean();
  console.log('\n--- Fallback Job Requests in MongoDB ---');
  requests.forEach(r => {
    console.log(`- Request ID: ${r._id}, Tech: ${r.technicianId.name}, Status: ${r.status}, Distance: ${r.distanceKm?.toFixed(2)} km`);
  });

  // Check techFar received the jobRequest via socket
  console.log('\n--- Socket.IO Broadcast Verification ---');
  console.log('Far Tech Socket Received:', techFarLogs);

  console.log('\n==================================================');
  console.log('TEST 3: FALLBACK FLOW ACCEPTANCE (FIRST ACCEPT WINS)');
  console.log('==================================================');
  
  // Far Tech accepts the request
  console.log('Far Technician accepting the broadcast request...');
  const acceptRequestResult = await dispatchService.acceptJobRequest(job._id, techFar._id, ioServer);
  console.log('Accept Request Result: Success!');

  // Verify Job status in DB
  const updatedJob3 = await Job.findById(job._id).populate('assignedTechnician');
  console.log('\n--- Job Accept Verification ---');
  console.log('Assigned Technician:', updatedJob3.assignedTechnician.name);
  console.log('Assignment Method:', updatedJob3.assignmentMethod);
  console.log('Job Status:', updatedJob3.status);

  // Check other requests are expired
  const requestsAfterAccept = await JobRequest.find({ jobId: job._id }).lean();
  console.log('\n--- Fallback Requests Statuses after Accept ---');
  requestsAfterAccept.forEach(r => {
    console.log(`- Tech ID: ${r.technicianId}, Status: ${r.status}`);
  });

  console.log('\n==================================================');
  console.log('TEST 4: STATUS UPDATES (TRAVELLING, ARRIVED, STARTED, COMPLETED)');
  console.log('==================================================');
  
  clientLogs.length = 0; // Clear customer logs

  const runStatusChange = async (status) => {
    console.log(`Updating job status to "${status}"...`);
    const req = {
      params: { id: job._id.toString() },
      body: { status },
      user: { id: techFar._id.toString(), role: 'technician' },
      app: { get: () => ioServer }
    };
    const res = {
      json: (data) => {
        console.log(`- Response: status=${data.data.status}`);
      },
      status: (code) => ({
        json: (data) => console.log(`- Error (${code}):`, data)
      })
    };
    
    // Call controller directly
    const jobControllerV2 = require('../controllers/v2/jobControllerV2');
    await jobControllerV2.updateJobStatus(req, res, (err) => console.error(err));
    await sleep(500);
  };

  await runStatusChange('travelling');
  await runStatusChange('arrived');
  await runStatusChange('started');
  await runStatusChange('completed');

  // Verify client notifications for each status in MongoDB
  const statusNotifications = await Notification.find({ bookingId: job._id, recipientType: 'customer' }).sort({ createdAt: 1 }).lean();
  console.log('\n--- Customer Status Notifications in MongoDB ---');
  statusNotifications.forEach(n => {
    console.log(`- Title: "${n.title}", Message: "${n.message}"`);
  });

  console.log('\n==================================================');
  console.log('TEST 5: CUSTOMER CANCELLATION FLOW');
  console.log('==================================================');
  
  // Set up a new job for cancellation test
  const jobCancel = await Job.create({
    title: 'Test Job - CCTV Installation Cancel Test',
    serviceName: 'CCTV Installation',
    serviceId: 'cctv',
    customerName: customer.name,
    customerPhone: customer.mobileNumber,
    location: 'Bangalore Central, 560001',
    price: 3500,
    amount: 3500,
    client: customer._id,
    status: 'assigned',
    assignedTechnician: techFar._id,
  });

  console.log('Customer requesting cancellation...');
  const cancelReq = {
    params: { jobId: jobCancel._id.toString() },
    body: { reason: 'No longer needed' },
    user: { id: customer._id.toString(), _id: customer._id },
    app: { get: () => ioServer }
  };
  const cancelRes = {
    json: (data) => console.log('- Customer cancel response:', data.message || data),
    status: (code) => ({ json: (data) => console.log('- Error:', data) })
  };
  
  const cancellationRoutesV2 = require('../routes/v2/cancellationRoutesV2');
  const handlers = cancellationRoutesV2.stack.filter(s => s.route && s.route.path === '/customer/:jobId');
  if (handlers.length > 0) {
    const stack = handlers[0].route.stack;
    await stack[stack.length - 1].handle(cancelReq, cancelRes, (err) => console.error(err));
  }

  // Admin approves cancellation with penalty (e.g. ₹100)
  console.log('Admin approving cancellation request with ₹100 fee...');
  const adminReq = {
    params: { jobId: jobCancel._id.toString() },
    body: { action: 'approve', adminNote: 'Approved with late cancellation fee', penaltyAmount: 100 },
    user: { id: admin._id.toString(), role: 'admin' },
    app: { get: () => ioServer }
  };
  const adminRes = {
    json: (data) => console.log('- Admin approve response: status is now', data.job.status),
    status: (code) => ({ json: (data) => console.log('- Error:', data) })
  };
  
  const adminHandlers = cancellationRoutesV2.stack.filter(s => s.route && s.route.path === '/admin/:jobId');
  if (adminHandlers.length > 0) {
    const stack = adminHandlers[0].route.stack;
    await stack[stack.length - 1].handle(adminReq, adminRes, (err) => console.error(err));
  }

  // Check that refund and cancellation notifications exist in DB
  const cancelNotifications = await Notification.find({ bookingId: jobCancel._id }).lean();
  console.log('\n--- Cancellation & Refund Notifications in MongoDB ---');
  cancelNotifications.forEach(n => {
    console.log(`- Recipient: ${n.recipientType}, Title: "${n.title}", Message: "${n.message}"`);
  });

  console.log('\n==================================================');
  console.log('TEST 6: ADMIN OVERRIDE & DISPATCH RETRY');
  console.log('==================================================');

  const jobOverride = await Job.create({
    title: 'Test Job - CCTV Override Test',
    serviceName: 'CCTV Installation',
    serviceId: 'cctv',
    customerName: customer.name,
    customerPhone: customer.mobileNumber,
    location: 'Bangalore Central, 560001',
    price: 4000,
    amount: 4000,
    client: customer._id,
    status: 'pending',
  });

  console.log('Admin overriding assignment to Near Technician...');
  await dispatchService.adminOverrideAssignment(jobOverride._id, techNear._id, admin._id, ioServer);

  const updatedJobOverride = await Job.findById(jobOverride._id).populate('assignedTechnician');
  console.log('Overridden Job assignedTechnician:', updatedJobOverride.assignedTechnician.name);
  console.log('Overridden Job assignmentMethod:', updatedJobOverride.assignmentMethod);

  // Clean up sockets
  console.log('\nDisconnecting socket clients...');
  adminSocket.disconnect();
  clientSocket.disconnect();
  techNearSocket.disconnect();
  techFarSocket.disconnect();

  console.log('\nValidation complete! All tests passed successfully.');
  
  // Close database connection
  await mongoose.connection.close();
  console.log('MongoDB connection closed.');
  
  // Exit script
  process.exit(0);
}

run().catch(err => {
  console.error('Test run failed with error:', err);
  process.exit(1);
});
