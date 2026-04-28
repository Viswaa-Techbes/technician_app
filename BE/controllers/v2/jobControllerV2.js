const jobServiceV2 = require('../../services/jobServiceV2');
const notificationService = require('../../services/notificationService');
const User = require('../../models/User');

async function createBooking(req, res, next) {
  try {
    const job = await jobServiceV2.createBookingV2({
      ...req.body,
      clientId: req.user.id,
    });

    const io = req.app.get('io');
    io.emit('newBooking', job);

    // Notify all admins about the new booking
    const admins = await User.find({ role: 'admin', isDeleted: { $ne: true } }).select('_id');
    await Promise.allSettled(admins.map(admin =>
      notificationService.createNotification(
        admin._id,
        'New Booking Request',
        `New service request: ${job.serviceName || job.title} on ${job.bookingDate || 'TBD'} at ${job.timeSlot || 'TBD'}`,
        'general',
        io
      )
    ));

    res.status(201).json({ success: true, data: job });
  } catch (err) {
    next(err);
  }
}

async function assignById(req, res, next) {
  try {
    const { id } = req.params;
    const { technicianId } = req.body;

    if (!technicianId) {
      return res.status(400).json({ success: false, message: 'technicianId is required' });
    }

    const job = await jobServiceV2.assignBookingV2(id, technicianId, req.user.id);

    // Real-time notification to technician
    const io = req.app.get('io');
    io.to(technicianId).emit('bookingAssigned', job);

    // Persist notification for technician
    await notificationService.createNotification(
      technicianId,
      'New Job Assigned',
      `You have a new service request: ${job.serviceName || job.title}${job.bookingDate ? ` on ${job.bookingDate}` : ''} at ${job.timeSlot || 'TBD'}`,
      'job_assigned',
      io
    );

    res.json({ success: true, data: job });
  } catch (err) {
    next(err);
  }
}

async function assignBooking(req, res, next) {
  try {
    const { bookingId, technicianId } = req.body;
    const job = await jobServiceV2.assignBookingV2(bookingId, technicianId, req.user.id);

    const io = req.app.get('io');
    io.to(technicianId).emit('bookingAssigned', job);

    await notificationService.createNotification(
      technicianId,
      'New Job Assigned',
      `New job assigned: ${job.title}`,
      'job_assigned',
      io
    );

    res.json({ success: true, data: job });
  } catch (err) {
    next(err);
  }
}

async function acceptJob(req, res, next) {
  try {
    const { id } = req.params;
    const job = await jobServiceV2.acceptJobV2(id, req.user.id);

    const io = req.app.get('io');
    if (job.client) {
      io.to(job.client.toString()).emit('technicianStarted', job);
    }

    res.json({ success: true, msg: 'Job started', data: job });
  } catch (err) {
    next(err);
  }
}

async function listBookings(req, res, next) {
  try {
    const { status } = req.query;
    const query = status ? { status } : {};
    if (req.user.role === 'client') query.client = req.user.id;
    if (req.user.role === 'technician') query.assignedTechnician = req.user.id;

    const jobs = await jobServiceV2.listJobsV2(query);
    res.json({ success: true, data: jobs });
  } catch (err) {
    next(err);
  }
}

async function uploadWork(req, res, next) {
  try {
    const { id } = req.params;
    const { images } = req.body;

    const Job = require('../../models/Job');
    const job = await Job.findById(id);
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });

    job.attachments = images || [];
    job.status = 'completion_requested';
    await job.save();

    const io = req.app.get('io');
    if (job.assignedManager) {
      io.to(job.assignedManager.toString()).emit('completionRequested', job);
    }

    res.json({ success: true, data: job });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createBooking,
  assignById,
  assignBooking,
  acceptJob,
  listBookings,
  uploadWork,
};
