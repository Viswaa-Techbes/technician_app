const Job = require('../models/Job');
const User = require('../models/User');

async function createJob(jobData) {
  const { title, description, location, googleMapsLink, attachments, scheduledTime, customerName, customerPhone, assignedManager, assignedTechnician, price } = jobData;

  const job = await Job.create({
    title,
    description,
    location,
    googleMapsLink,
    attachments,
    scheduledTime,
    customerName,
    customerPhone,
    assignedManager,
    assignedTechnician: assignedTechnician || null,
    status: assignedTechnician ? 'assigned' : 'pending',
    price,
  });

  return job;
}

async function assignTechnician(jobId, technicianId, managerId) {
  const job = await Job.findById(jobId);
  if (!job) throw new Error('Job not found');

  // Verify manager
  if (job.assignedManager.toString() !== managerId) {
    throw new Error('Not authorized to assign this job');
  }

  const technician = await User.findOne({ _id: technicianId, role: 'technician' });
  if (!technician) throw new Error('Technician not found');

  job.assignedTechnician = technicianId;
  job.status = 'assigned';
  await job.save();

  return job;
}

async function listJobs(query, page, limit) {
  const skip = (page - 1) * limit;
  const [jobs, total] = await Promise.all([
    Job.find(query)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate('assignedTechnician', 'name email role phone status')
      .populate('assignedManager', 'name email role phone')
      .lean(),
    Job.countDocuments(query),
  ]);

  return { jobs, total };
}

module.exports = {
  createJob,
  assignTechnician,
  listJobs,
};
