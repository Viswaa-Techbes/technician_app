const Job = require('../models/Job');
const User = require('../models/User');
const TechnicianLocation = require('../models/TechnicianLocation');

async function createBookingV2(bookingData) {
  const {
    clientId,
    service,
    serviceId,
    serviceName,
    address,
    description,
    scheduledTime,
    date,
    timeSlot,
    lat,
    lng,
    customerName,
    customerPhone,
  } = bookingData;

  const job = await Job.create({
    title: serviceName || service || 'Service Request',
    description,
    location: address,
    client: clientId,
    customerName: customerName || '',
    customerPhone: customerPhone || '',
    scheduledTime: scheduledTime || (date && timeSlot ? `${date} ${timeSlot}` : 'ASAP'),
    status: 'pending',
    useNewFlow: true,
    appId: 'technician-v2',
    bookingDate: date || '',
    timeSlot: timeSlot || '',
    serviceId: serviceId || service || '',
    serviceName: serviceName || service || '',
    // Pricing fields
    price: Number(bookingData.totalAmount || bookingData.priceValue || 0),
    amount: Number(bookingData.totalAmount || bookingData.priceValue || 0),
    advanceAmount: Math.round((Number(bookingData.totalAmount || bookingData.priceValue || 0) || 0) / 2),
    remainingAmount: Math.max((Number(bookingData.totalAmount || bookingData.priceValue || 0) || 0) - Math.round((Number(bookingData.totalAmount || bookingData.priceValue || 0) || 0) / 2), 0),
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

  job.status = 'in_progress';
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
