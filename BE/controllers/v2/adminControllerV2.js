const User = require('../../models/User');
const Lead = require('../../models/Lead');
const Job = require('../../models/Job');
const Review = require('../../models/Review');
const Attendance = require('../../models/Attendance');
const Career = require('../../models/Career');
const Payment = require('../../models/Payment');
const Address = require('../../models/Address');

/**
 * Bookings (v2 service requests)
 */
async function getBookings(req, res, next) {
  try {
    const { status } = req.query;
    const query = { useNewFlow: true };
    if (status && status !== 'all') query.status = status;
    if (req.query.paymentStatus && req.query.paymentStatus !== 'all') query.paymentStatus = req.query.paymentStatus;
    if (req.query.cctvCategory && req.query.cctvCategory !== 'all') query['cctvDetails.category.slug'] = req.query.cctvCategory;
    if (req.query.cctvSubcategory && req.query.cctvSubcategory !== 'all') query['cctvDetails.subcategory.slug'] = req.query.cctvSubcategory;
    if (req.query.cameraType && req.query.cameraType !== 'all') query['cctvDetails.cameraType.slug'] = req.query.cameraType;

    const bookings = await Job.find(query)
      .sort({ createdAt: -1 })
      .populate('client', 'name phone email')
      .populate('assignedTechnician', 'name email specialty')
      .lean();

    return res.json({
      success: true,
      data: bookings.map(b => ({
        id: b._id,
        customerName: b.client?.name || b.customerName || 'Customer',
        customerPhone: b.client?.phone || b.customerPhone || '',
        customerEmail: b.client?.email || '',
        serviceName: b.serviceName || b.title || 'Service',
        serviceId: b.serviceId || '',
        date: b.bookingDate || '',
        timeSlot: b.timeSlot || '',
        address: b.location || '',
        status: b.status,
        paymentStatus: b.paymentStatus,
        description: b.description || '',
        cctvDetails: b.cctvDetails || null,
        grandTotal: b.cctvDetails?.priceBreakdown?.grandTotal || b.amount || b.price || 0,
        technicianName: b.assignedTechnician?.name || null,
        technicianId: b.assignedTechnician?._id || null,
        bookingNumber: b.bookingNumber || null,
        createdAt: b.createdAt,
      }))
    });
  } catch (err) {
    next(err);
  }
}

/**
 * Dashboard Stats
 */
async function getDashboard(req, res, next) {
  try {
    const [userCounts, jobCounts, leadsCount, liveTechnicians, pendingRequests, paymentQueue, reviews, revenueAgg, upcomingJobs] = await Promise.all([
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
      ,
      Payment.aggregate([
        { $match: { status: { $in: ['paid', 'verified'] } } },
        { $group: { _id: null, total: { $sum: '$amount' } } },
      ]),
      Job.find({ status: { $in: ['confirmed', 'assigned', 'travelling', 'arrived'] } }).limit(5).populate('assignedTechnician', 'name').lean(),
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
          totalUsers: Object.values(usersByRole).reduce((a, b) => a + b, 0),
          totalBookings: totalJobs,
          totalRevenue: Math.round((revenueAgg[0]?.total || 0) / 100),
          totalJobs,
          completedJobs: (jobsByStatus.completed || 0) + (jobsByStatus.payment_done || 0),
          activeTechnicians: liveTechnicians.length,
          approvalQueue: pendingRequests.length,
          paymentQueue: paymentQueue.length,
          pendingPayments: paymentQueue.length,
          upcomingJobs: upcomingJobs.length,
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
        ,
        upcomingJobs: upcomingJobs.map(j => ({
          id: j._id,
          customerName: j.customerName,
          title: j.title,
          status: j.status,
          technicianName: j.assignedTechnician?.name,
          bookingDate: j.bookingDate,
          timeSlot: j.timeSlot,
        })),
      }
    });
  } catch (err) {
    next(err);
  }
}

async function getAddresses(req, res, next) {
  try {
    const data = await Address.find()
      .populate('userId', 'name phone mobileNumber email')
      .sort({ createdAt: -1 })
      .lean();
    res.json({ success: true, data: data.map((item) => ({
      id: item._id,
      customerName: item.userId?.name || 'Customer',
      phone: item.userId?.phone || item.userId?.mobileNumber || '',
      email: item.userId?.email || '',
      address: [item.addressLine1, item.addressLine2, item.landmark].filter(Boolean).join(', '),
      city: item.city,
      state: item.state,
      pincode: item.pincode,
      isDefault: item.isDefault,
      createdAt: item.createdAt,
    })) });
  } catch (err) { next(err); }
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

async function createLead(req, res, next) {
  try {
    const { name, email, phone, pincode, status, service, plan } = req.body;
    if (!name) return res.status(400).json({ success: false, message: 'name is required' });
    const lead = await Lead.create({
      name: name.trim(),
      email: email?.toLowerCase().trim() || undefined,
      phone: phone?.trim() || '',
      pincode: pincode ? String(pincode).trim() : undefined,
      service: service?.trim() || undefined,
      plan: plan?.trim() || undefined,
      status: status || 'Active',
    });
    return res.status(201).json({ success: true, data: lead });
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
    const user = await User.create({ ...req.body, userType: 'member' });
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

async function createJob(req, res, next) {
  try {
    const { title, customerName, customerPhone, location, technicianId, price, description, serviceType } = req.body;
    if (!title) return res.status(400).json({ success: false, message: 'title is required' });
    const job = await Job.create({
      title: title.trim(),
      description: description?.trim() || '',
      customerName: customerName?.trim() || '',
      customerPhone: customerPhone?.trim() || '',
      location: location?.trim() || '',
      price: Number(price) || 0,
      amount: Number(price) || 0,
      serviceType: serviceType || 'installation',
      assignedTechnician: technicianId || null,
      assignedManager: req.user.id,
      status: technicianId ? 'assigned' : 'pending',
    });
    const populated = await Job.findById(job._id).populate('assignedTechnician', 'name email specialty').lean();
    return res.status(201).json({ success: true, data: populated });
  } catch (err) {
    next(err);
  }
}

async function updateJob(req, res, next) {
  try {
    console.log(`[updateJob] Updating job ID: ${req.params.id}`);
    console.log(`[updateJob] Request body:`, req.body);

    const allowedUpdates = {};
    const allowedFields = [
      'title',
      'description',
      'customerName',
      'customerPhone',
      'location',
      'assignedTechnician',
      'status',
      'price',
      'amount',
      'serviceType',
    ];

    for (const field of allowedFields) {
      if (Object.prototype.hasOwnProperty.call(req.body, field)) {
        allowedUpdates[field] = req.body[field];
      }
    }

    if (Object.prototype.hasOwnProperty.call(req.body, 'technicianId')) {
      allowedUpdates.assignedTechnician = req.body.technicianId || null;
      if (req.body.technicianId && !allowedUpdates.status) {
        allowedUpdates.status = 'assigned';
      }
    }

    console.log(`[updateJob] Allowed updates:`, allowedUpdates);

    const job = await Job.findByIdAndUpdate(req.params.id, allowedUpdates, {
      new: true,
      runValidators: true,
    }).populate('assignedTechnician', 'name email specialty');

    console.log(`[updateJob] Job found:`, !!job);
    if (job) console.log(`[updateJob] Updated job status:`, job.status);

    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });
    return res.json({ success: true, data: job });
  } catch (err) {
    console.error(`[updateJob] Error:`, err.message);
    next(err);
  }
}

async function deleteJob(req, res, next) {
  try {
    const job = await Job.findByIdAndDelete(req.params.id);
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });
    return res.json({ success: true, message: 'Job deleted successfully' });
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
      .select('name lat lng isOnline status updatedAt specialty');
    return res.json({
      success: true,
      data: techs.map(t => ({
        technicianId: t._id,
        name: t.name,
        lat: t.lat || 0,
        lng: t.lng || 0,
        isOnline: t.isOnline,
        status: t.status,
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
        updatedAt: j.updatedAt,
        attachments: j.attachments || [],
        price: j.price,
        address: j.location
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
    console.log(`[V2] Update Completion Request - ID: ${id}, Action: ${action}`);

    if (!action) return res.status(400).json({ success: false, message: "Action required (approve/reject)" });

    let status = "";
    if (action === "approve") {
      status = "approved_by_manager";
    } else if (action === "reject") {
      status = "assigned"; // Return to assigned state for technician to fix
    } else {
      return res.status(400).json({ success: false, message: "Invalid action" });
    }

    const job = await Job.findByIdAndUpdate(id, { status }, { new: true });
    if (!job) return res.status(404).json({ success: false, message: "Job not found" });
    
    return res.status(200).json({
      success: true,
      message: `Request ${action}d successfully`,
      data: job
    });
  } catch (err) {
    console.error("[V2] Completion Update Error:", err);
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
    console.log(`[V2] Update Payment Request - ID: ${id}, Action: ${action}`);

    if (!action) return res.status(400).json({ success: false, message: "Action required (approve/reject)" });

    const paymentStatus = action === 'approve' ? 'paid' : 'rejected';
    const updates = { paymentStatus };
    if (action === 'approve') updates.status = 'completed';
    
    const job = await Job.findByIdAndUpdate(id, updates, { new: true });
    if (!job) return res.status(404).json({ success: false, message: "Job not found" });
    
    return res.status(200).json({
      success: true,
      message: `Payment ${action}d successfully`,
      data: job
    });
  } catch (err) {
    console.error("[V2] Payment Update Error:", err);
    next(err);
  }
}

async function assignBooking(req, res, next) {
  try {
    const { id } = req.params;
    const { technicianId } = req.body;

    if (!technicianId) {
      return res.status(400).json({ success: false, message: 'technicianId is required' });
    }

    const job = await Job.findById(id);
    if (!job) return res.status(404).json({ success: false, message: 'Job not found' });

    const technician = await User.findOne({ _id: technicianId, role: 'technician' });
    if (!technician) return res.status(404).json({ success: false, message: 'Technician not found' });

    job.assignedTechnician = technicianId;
    job.assignedManager = req.user.id;
    job.status = 'assigned';
    await job.save();

    // Notify technician
    const notificationService = require('../../services/notificationService');
    const io = req.app.get('io');
    io.to(technicianId.toString()).emit('bookingAssigned', job);
    await notificationService.createNotification(
      technicianId,
      'New Job Assigned',
      `You have a new service request: ${job.serviceName || job.title}${job.bookingDate ? ' on ' + job.bookingDate : ''} at ${job.timeSlot || 'TBD'}`,
      'job_assigned',
      io
    );

    return res.json({ success: true, data: job });
  } catch (err) {
    next(err);
  }
}

async function updateServiceRequest(req, res, next) {
  try {
    const job = await Job.findByIdAndUpdate(req.params.id, req.body, { new: true });
    if (!job) return res.status(404).json({ success: false, message: 'Service request not found' });
    return res.json({ success: true, data: job });
  } catch (err) {
    next(err);
  }
}

async function deleteServiceRequest(req, res, next) {
  try {
    const job = await Job.findByIdAndDelete(req.params.id);
    if (!job) return res.status(404).json({ success: false, message: 'Service request not found' });
    return res.json({ success: true, message: 'Service request deleted successfully' });
  } catch (err) {
    next(err);
  }
}

/**
 * Change User Password (Admin action)
 */
async function changeUserPassword(req, res, next) {
  try {
    const { id } = req.params;
    const { newPassword } = req.body;

    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Password must be at least 6 characters',
      });
    }

    const user = await User.findById(id).select('+password');
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    user.password = newPassword; // Will be hashed by pre-save hook
    await user.save();

    return res.json({
      success: true,
      message: `Password changed successfully for ${user.name || 'user'}`,
    });
  } catch (err) {
    next(err);
  }
}

async function getApplications(req, res, next) {
  try {
    const applications = await Career.find().sort({ createdAt: -1 });
    res.json({ success: true, data: applications });
  } catch (err) {
    next(err);
  }
}

async function updateApplicationStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { status } = req.body;
    const application = await Career.findByIdAndUpdate(id, { status }, { new: true });
    if (!application) return res.status(404).json({ success: false, message: 'Application not found' });
    res.json({ success: true, message: `Status updated to ${status}`, data: application });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getBookings,
  assignBooking,
  getDashboard,
  getLeads,
  createLead,
  updateLead,
  deleteLead,
  getUsers,
  createUser,
  updateUser,
  deleteUser,
  getJobs,
  createJob,
  updateJob,
  deleteJob,
  getReviews,
  getTracking,
  getAttendance,
  getAddresses,
  getCompletionRequests,
  updateCompletionRequest,
  getPaymentRequests,
  updatePaymentRequest,
  updateServiceRequest,
  deleteServiceRequest,
  changeUserPassword,
  getApplications,
  updateApplicationStatus,
};
