const User = require('../models/User');
const Job = require('../models/Job');

/**
 * GET /technicians
 * List all technicians (Manager/Admin only)
 */
async function listTechnicians(req, res, next) {
  try {
    const technicians = await User.find({ role: 'technician' })
      .sort({ name: 1 })
      .populate('assignedManager', 'name email')
      .lean();

    return res.json({
      success: true,
      data: technicians.map(u => ({
        id: u._id.toString(),
        name: u.name,
        email: u.email,
        phone: u.phone,
        status: u.status,
        isOnline: u.isOnline,
        specialty: u.specialty,
        assignedManager: u.assignedManager,
        createdAt: u.createdAt,
      })),
    });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /technicians/:id
 * Technician details (Manager/Admin/Self)
 */
async function getTechnicianDetails(req, res, next) {
  try {
    const { id } = req.params;
    const technician = await User.findById(id).populate('assignedManager', 'name email');

    if (!technician) {
      return res.status(404).json({ success: false, message: 'Technician not found' });
    }

    return res.json({
      success: true,
      data: technician.toSafeObject(),
    });
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /technicians/:id/status
 * Update availability status (available, busy, offline)
 */
async function updateStatus(req, res, next) {
  try {
    const { id } = req.params;
    const { status, isOnline, lat, lng } = req.body;
    
    // Authorization: only the tech or admin/manager can update
    if (req.user.role === 'technician' && req.user.id !== id) {
        return res.status(403).json({ success: false, message: 'Not authorized to update other technicians status' });
    }

    const update = {};
    if (status) {
        const allowed = ['available', 'busy', 'offline'];
        if (!allowed.includes(status)) return res.status(400).json({ success: false, message: 'Invalid status' });
        update.status = status;
    }
    if (isOnline !== undefined) update.isOnline = isOnline;
    if (lat !== undefined) update.lat = lat;
    if (lng !== undefined) update.lng = lng;

    const technician = await User.findByIdAndUpdate(id, update, { new: true });
    if (!technician) return res.status(404).json({ success: false, message: 'Technician not found' });

    return res.json({
      success: true,
      message: 'Status updated successfully',
      data: {
        id: technician._id,
        status: technician.status,
        isOnline: technician.isOnline,
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * GET /technicians/:id/jobs
 * List jobs assigned to a technician
 */
async function listTechnicianJobs(req, res, next) {
  try {
    const { id } = req.params;
    const { status } = req.query;

    const query = { assignedTechnician: id };
    if (status) query.status = status;

    const jobs = await Job.find(query)
      .sort({ createdAt: -1 })
      .populate('assignedManager', 'name email')
      .lean();

    return res.json({
      success: true,
      data: jobs,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  listTechnicians,
  getTechnicianDetails,
  updateStatus,
  listTechnicianJobs,
};
