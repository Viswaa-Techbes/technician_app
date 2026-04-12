const jobService = require('../services/jobService');
const Job = require('../models/Job');

async function listJobs(req, res, next) {
  try {
    const { role, id } = req.user;
    const { status, page = 1, limit = 10 } = req.query;
    
    const query = {};
    if (role === 'manager') {
      query.assignedManager = id;
    } else if (role === 'technician') {
      query.assignedTechnician = id;
    }
    
    if (status) {
      query.status = status;
    }

    const { jobs, total } = await jobService.listJobs(query, page, limit);

    return res.json({
      success: true,
      data: jobs,
      pagination: {
        total,
        page: parseInt(page),
        limit: parseInt(limit),
        totalPages: Math.ceil(total / limit),
      },
    });
  } catch (err) {
    next(err);
  }
}

async function getJobDetails(req, res, next) {
  try {
    const { id: jobId } = req.params;
    const job = await Job.findById(jobId)
      .populate('assignedTechnician', 'name email role phone status')
      .populate('assignedManager', 'name email role phone');

    if (!job) {
      return res.status(404).json({ success: false, message: 'Job not found' });
    }

    if (req.user.role === 'manager' && job.assignedManager.toString() !== req.user.id) {
        return res.status(403).json({ success: false, message: 'Access denied' });
    }
    if (req.user.role === 'technician' && job.assignedTechnician && job.assignedTechnician._id.toString() !== req.user.id) {
        return res.status(403).json({ success: false, message: 'Access denied' });
    }

    return res.json({
      success: true,
      data: job,
    });
  } catch (err) {
    next(err);
  }
}

async function createJob(req, res, next) {
  try {
    const jobData = { ...req.body, assignedManager: req.user.id };
    if (!jobData.title) return res.status(400).json({ success: false, message: 'Title is required' });

    const job = await jobService.createJob(jobData);
    return res.status(201).json({ success: true, data: job });
  } catch (err) {
    next(err);
  }
}

async function assignJob(req, res, next) {
  try {
    const { jobId, technicianId } = req.body;
    if (!jobId || !technicianId) return res.status(400).json({ success: false, message: 'jobId and technicianId are required' });

    const job = await jobService.assignTechnician(jobId, technicianId, req.user.id);
    
    // Real-time Notification
    const io = req.app.get('io');
    if (io) {
      io.to(technicianId).emit('notification', {
        title: 'New Job Assigned',
        message: `You have been assigned a new project: ${job.title}`,
        jobId: job._id
      });
    }

    return res.json({ success: true, message: 'Technician assigned successfully', data: job });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
}

async function updateJobStatus(req, res, next) {
  try {
    const { id: jobId } = req.params;
    const { status } = req.body;
    
    const allowedStatuses = ['pending', 'assigned', 'in_progress', 'pending_approval', 'completed'];
    if (!status || !allowedStatuses.includes(status)) {
        return res.status(400).json({ success: false, message: 'Invalid status' });
    }

    const job = await Job.findById(jobId);
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });

    // Authorization & Rules
    if (req.user.role === 'technician') {
        if (job.assignedTechnician?.toString() !== req.user.id) {
            return res.status(403).json({ success: false, message: 'Not assigned to this job' });
        }
        // Technician can only move to in_progress or pending_approval
        if (!['in_progress', 'pending_approval'].includes(status)) {
            return res.status(403).json({ success: false, message: 'Technician cannot move job to this status' });
        }
    } else if (req.user.role === 'manager' || req.user.role === 'admin') {
        // Managers/Admins can approve or reject
    } else {
        return res.status(403).json({ success: false, message: 'Unauthorized' });
    }

    job.status = status;
    await job.save();

    // Real-time Notification
    const io = req.app.get('io');
    if (io) {
      if (req.user.role === 'technician') {
        // Notify manager
        io.to(job.assignedManager.toString()).emit('notification', {
          title: 'Job Update',
          message: `Technician updated job status to ${status}`,
          jobId: job._id
        });
      } else {
        // Notify technician
        if (job.assignedTechnician) {
          io.to(job.assignedTechnician.toString()).emit('notification', {
            title: 'Job Update',
            message: `Manager updated job status to ${status}`,
            jobId: job._id
          });
        }
      }
    }

    return res.json({ success: true, message: `Job status updated to ${status}`, data: job });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  listJobs,
  getJobDetails,
  createJob,
  assignJob,
  updateJobStatus,
};
