const jobServiceV2 = require('../../services/jobServiceV2');
const notificationService = require('../../services/notificationService');

async function createBooking(req, res, next) {
  try {
    const job = await jobServiceV2.createBookingV2({
      ...req.body,
      clientId: req.user.id,
    });
    
    // Notify Admins/Managers? (Custom logic)
    const io = req.app.get('io');
    io.emit('newBooking', job);

    res.status(201).json({ success: true, data: job });
  } catch (err) {
    next(err);
  }
}

async function assignBooking(req, res, next) {
  try {
    const { bookingId, technicianId } = req.body;
    const job = await jobServiceV2.assignBookingV2(bookingId, technicianId, req.user.id);
    
    // Real-time notification to technician
    const io = req.app.get('io');
    io.to(technicianId).emit('bookingAssigned', job);
    
    // FCM Notification
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
    // Notify Client
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
    io.to(job.assignedManager.toString()).emit('completionRequested', job);

    res.json({ success: true, data: job });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createBooking,
  assignBooking,
  acceptJob,
  listBookings,
  uploadWork,
};
