const Job = require('../models/Job');
const User = require('../models/User');
const TechnicianLocation = require('../models/TechnicianLocation');

async function createBookingV2(bookingData) {
  const {
    clientId,
    service,
    address,
    description,
    scheduledTime,
    lat,
    lng,
  } = bookingData;

  const job = await Job.create({
    title: service,
    description,
    location: address,
    client: clientId,
    scheduledTime: scheduledTime || 'ASAP',
    status: 'pending', // Swiggy style starts as pending
    useNewFlow: true,
    appId: 'technician-v2',
    v2Metadata: {
      lat: String(lat || ''),
      lng: String(lng || ''),
    }
  });

  return job;
}

async function assignBookingV2(jobId, technicianId, managerId) {
  const job = await Job.findById(jobId);
  if (!job) throw new Error('Job not found');

  const technician = await User.findOne({ _id: technicianId, role: 'technician' });
  if (!technician) throw new Error('Technician not found');

  job.assignedTechnician = technicianId;
  job.assignedManager = managerId;
  job.status = 'assigned';
  await job.save();

  return job;
}

async function acceptJobV2(jobId, technicianId) {
  const job = await Job.findOne({ _id: jobId, assignedTechnician: technicianId });
  if (!job) throw new Error('Job not found or not assigned to you');

  job.status = 'started'; // Swiggy style: accepting starts the journey
  job.acceptedAt = new Date();
  await job.save();

  return job;
}

async function updateLiveLocation(technicianId, lat, lng) {
  return await TechnicianLocation.findOneAndUpdate(
    { technicianId },
    { lat, lng, updatedAt: new Date() },
    { upsert: true, new: true }
  );
}

async function getTechnicianLocation(technicianId) {
  return await TechnicianLocation.findOne({ technicianId });
}

async function listJobsV2(query = {}) {
  return await Job.find({ ...query, useNewFlow: true })
    .sort({ createdAt: -1 })
    .populate('assignedTechnician', 'name email status')
    .populate('client', 'name phone email')
    .lean();
}

module.exports = {
  createBookingV2,
  assignBookingV2,
  acceptJobV2,
  updateLiveLocation,
  getTechnicianLocation,
  listJobsV2,
};
