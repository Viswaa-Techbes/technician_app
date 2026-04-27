const User = require('../../models/User');
const Lead = require('../../models/Lead');
const Job = require('../../models/Job');
const Review = require('../../models/Review');
const Attendance = require('../../models/Attendance'); // Ensure this model exists

/**
 * Dashboard Stats
 */
async function getDashboard(req, res, next) {
  try {
    const [userCounts, jobCounts, leadsCount, liveTechnicians, pendingRequests, paymentQueue, reviews] = await Promise.all([
      User.aggregate([
        { $match: { isDeleted: { $ne: true } } },
        { $group: { _id: '$role', count: { $sum: 1 } } },
      ]),
      Job.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
      Lead.countDocuments({ isDeleted: { $ne: true } }),
      User.find({ role: 'technician', isOnline: true, isDeleted: { $ne: true } }).limit(5).lean(),
      Job.find({ status: { $in: ['completion_requested', 'pending_approval'] } }).limit(5).populate('assignedTechnician', 'name').lean(),
      Job.find({ paymentStatus: 'verification_pending' }).limit(5).lean(),
      Review.find().limit(5).populate('technicianId', 'name').sort({ createdAt: -1 }).lean()
    ]);

    const usersByRole = userCounts.reduce((acc, row) => {
      acc[row._id] = row.count;
      return acc;
    }, {});

    const jobsByStatus = jobCounts.reduce((acc, row) => {
      acc[row._id] = row.count;
      return acc;
    }, {});

    const totalJobs = Object.values(jobsByStatus).reduce((a, b) => a + b, 0);

    return res.json({
      success: true,
      data: {
        summary: {
          totalLeads: leadsCount,
          totalJobs,
          completedJobs: (jobsByStatus.completed || 0) + (jobsByStatus.payment_done || 0),
          activeTechnicians: liveTechnicians.length,
          approvalQueue: pendingRequests.length,
          paymentQueue: paymentQueue.length,
        },
        usersByRole,
        jobsByStatus,
        recentJobs: (await Job.find().sort({ createdAt: -1 }).limit(5).populate('assignedTechnician', 'name').lean()).map(j => ({
          id: j._id,
          customerName: j.customerName,
          title: j.title,
          location: j.location,
          status: j.status,
          technicianName: j.assignedTechnician?.name,
          createdAt: j.createdAt
        })),
        liveTechnicians: liveTechnicians.map(t => ({
          id: t._id,
          name: t.name,
          status: t.isOnline ? 'Available' : 'Offline',
          specialty: t.specialty
        })),
        pendingRequests: pendingRequests.map(j => ({
          id: j._id,
          customerName: j.customerName,
          technicianName: j.assignedTechnician?.name
        })),
        paymentRequests: paymentQueue.map(j => ({
          id: j._id,
          customerName: j.customerName,
          amount: j.amount
        })),
        recentReviews: reviews.map(r => ({
          id: r._id,
          technicianName: r.technicianId?.name,
          rating: r.rating,
          comment: r.comment,
          createdAt: r.createdAt
        }))
      }
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Leads Management
 */
async function getLeads(req, res, next) {
  try {
    const leads = await Lead.find({ isDeleted: { $ne: true } }).sort({ createdAt: -1 });
    return res.json({ success: true, data: leads });
  } catch (err) {
    next(err);
  }
}

async function updateLead(req, res, next) {
  try {
    const lead = await Lead.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true });
    if (!lead) return res.status(404).json({ success: false, message: 'Lead not found' });
    return res.json({ success: true, data: lead });
  } catch (err) {
    next(err);
  }
}

async function deleteLead(req, res, next) {
  try {
    const lead = await Lead.findByIdAndUpdate(req.params.id, { isDeleted: true }, { new: true });
    if (!lead) return res.status(404).json({ success: false, message: 'Lead not found' });
    return res.json({ success: true, message: 'Lead deleted successfully' });
  } catch (err) {
    next(err);
  }
}

/**
 * User Management
 */
async function getUsers(req, res, next) {
  try {
    const users = await User.find({ isDeleted: { $ne: true } }).sort({ createdAt: -1 }).select('-password');
    return res.json({ success: true, data: users });
  } catch (err) {
    next(err);
  }
}

async function createUser(req, res, next) {
  try {
    const user = await User.create(req.body);
    const safeUser = user.toSafeObject();
    return res.status(201).json({ success: true, data: { ...safeUser, password: req.body.password } });
  } catch (err) {
    next(err);
  }
}

async function updateUser(req, res, next) {
  try {
    const user = await User.findByIdAndUpdate(req.params.id, req.body, { new: true, runValidators: true }).select('-password');
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    return res.json({ success: true, data: user });
  } catch (err) {
    next(err);
  }
}

async function deleteUser(req, res, next) {
  try {
    const user = await User.findByIdAndUpdate(req.params.id, { isDeleted: true }, { new: true });
    if (!user) return res.status(404).json({ success: false, message: 'User not found' });
    return res.json({ success: true, message: 'User deleted successfully' });
  } catch (err) {
    next(err);
  }
}

/**
 * Jobs Management
 */
async function getJobs(req, res, next) {
  try {
    const jobs = await Job.find()
      .populate('assignedTechnician', 'name email specialty')
      .sort({ createdAt: -1 });
    return res.json({ success: true, data: jobs });
  } catch (err) {
    next(err);
  }
}

/**
 * Reviews
 */
async function getReviews(req, res, next) {
  try {
    const reviews = await Review.find()
      .populate('technicianId', 'name specialty')
      .sort({ createdAt: -1 });
    return res.json({
      success: true,
      data: reviews.map(r => ({
        id: r._id,
        technicianName: r.technicianId?.name || 'Unknown',
        rating: r.rating,
        comment: r.comment,
        createdAt: r.createdAt
      }))
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Tracking
 */
async function getTracking(req, res, next) {
  try {
    const techs = await User.find({ role: 'technician', isDeleted: { $ne: true } })
      .select('name lat lng isOnline updatedAt specialty');
    return res.json({
      success: true,
      data: techs.map(t => ({
        technicianId: t._id,
        name: t.name,
        lat: t.lat || 0,
        lng: t.lng || 0,
        isOnline: t.isOnline,
        specialty: t.specialty,
        lastUpdate: t.updatedAt
      }))
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Attendance
 */
async function getAttendance(req, res, next) {
  try {
    // Basic implementation - can be expanded with filters
    const users = await User.find({ role: { $in: ['technician', 'manager'] }, isDeleted: { $ne: true } })
      .select('name role status lastSeen');
    
    return res.json({
      success: true,
      data: users.map(u => ({
        id: u._id,
        name: u.name,
        role: u.role,
        status: u.isOnline ? 'Active' : 'Offline',
        loginTime: u.lastSeen,
      }))
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Requests & Approvals
 */
async function getCompletionRequests(req, res, next) {
  try {
    const jobs = await Job.find({ status: { $in: ['completion_requested', 'pending_approval'] } })
      .populate('assignedTechnician', 'name')
      .sort({ updatedAt: -1 });
    return res.json({
      success: true,
      data: jobs.map(j => ({
        id: j._id,
        customerName: j.customerName,
        serviceName: j.title,
        technicianName: j.assignedTechnician?.name,
        updatedAt: j.updatedAt
      }))
    });
  } catch (err) {
    next(err);
  }
}

async function updateCompletionRequest(req, res, next) {
  try {
    const { id } = req.params;
    const { action } = req.body;
    const status = action === 'approve' ? 'approved_by_manager' : 'assigned';
    
    const job = await Job.findByIdAndUpdate(id, { status }, { new: true });
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });
    
    return res.json({ success: true, message: `Request ${action}d` });
  } catch (err) {
    next(err);
  }
}

async function getPaymentRequests(req, res, next) {
  try {
    const jobs = await Job.find({ paymentStatus: 'verification_pending' })
      .populate('assignedTechnician', 'name')
      .sort({ updatedAt: -1 });
    return res.json({
      success: true,
      data: jobs.map(j => ({
        id: j._id,
        customerName: j.customerName,
        customerPhone: j.customerPhone,
        serviceName: j.title,
        amount: j.amount,
        technicianName: j.assignedTechnician?.name,
        paymentId: j.paymentId,
        paymentStatus: j.paymentStatus
      }))
    });
  } catch (err) {
    next(err);
  }
}

async function updatePaymentRequest(req, res, next) {
  try {
    const { id } = req.params;
    const { action } = req.body;
    const paymentStatus = action === 'approve' ? 'paid' : 'rejected';
    const updates = { paymentStatus };
    if (action === 'approve') updates.status = 'completed';
    
    const job = await Job.findByIdAndUpdate(id, updates, { new: true });
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });
    
    return res.json({ success: true, message: `Payment ${action}d` });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getDashboard,
  getLeads,
  updateLead,
  deleteLead,
  getUsers,
  createUser,
  updateUser,
  deleteUser,
  getJobs,
  getReviews,
  getTracking,
  getAttendance,
  getCompletionRequests,
  updateCompletionRequest,
  getPaymentRequests,
  updatePaymentRequest
};
