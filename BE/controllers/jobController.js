const jobService = require('../services/jobService');
const Job = require('../models/Job');
const notificationService = require('../services/notificationService');

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
    if (!Number.isFinite(Number(jobData.amount ?? jobData.price ?? 0)) || Number(jobData.amount ?? jobData.price ?? 0) <= 0) {
      return res.status(400).json({ success: false, message: 'A valid amount is required' });
    }

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
    
    const io = req.app.get('io');
    await notificationService.createNotification(
      technicianId,
      'New Job Assigned',
      `You have been assigned a new project: ${job.title}`,
      'job_assigned',
      io
    );

    return res.json({ success: true, message: 'Technician assigned successfully', data: job });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
}

async function updateJobStatus(req, res, next) {
  try {
    const { id: jobId } = req.params;
    let { status } = req.body;
    
    // Map camelCase to snake_case for consistency
    const statusMap = {
      'inProgress': 'in_progress',
      'pendingApproval': 'pending_approval',
    };
    if (statusMap[status]) status = statusMap[status];

    const allowedStatuses = ['pending', 'assigned', 'in_progress', 'pending_approval', 'completed'];
    if (!status || !allowedStatuses.includes(status)) {
        return res.status(400).json({ success: false, message: `Invalid status: ${status}` });
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

    const io = req.app.get('io');
    if (req.user.role === 'technician') {
        await notificationService.createNotification(
            job.assignedManager.toString(),
            'Job Update',
            `Technician updated job status to ${status}`,
            'status_update',
            io
        );
    } else {
        if (job.assignedTechnician) {
            await notificationService.createNotification(
                job.assignedTechnician.toString(),
                'Job Update',
                `Manager updated job status to ${status}`,
                'status_update',
                io
            );
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
