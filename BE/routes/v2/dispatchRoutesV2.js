/**
 * Dispatch Routes V2
 * =================
 * POST /api/v2/dispatch/retry/:jobId          - Admin retries dispatch for a job
 * POST /api/v2/dispatch/override/:jobId       - Admin manually overrides assignment
 * GET  /api/v2/dispatch/status/:jobId         - Get live dispatch status for a job
 * GET  /api/v2/dispatch/active                - All jobs currently in dispatching state
 * POST /api/v2/dispatch/accept/:jobId         - Technician accepts a broadcast job request
 * POST /api/v2/dispatch/reject/:jobId         - Technician rejects a broadcast job request
 * PUT  /api/v2/dispatch/availability          - Technician updates availability (ONLINE/OFFLINE/BUSY)
 * POST /api/v2/dispatch/tech-cancel/:jobId    - Technician cancels an assigned job (penalty applied)
 */

const express = require('express');
const router = express.Router();
const { authenticate: verifyToken, requireRoles } = require('../../middlewares/auth');
const requireAdmin = requireRoles('admin', 'manager');
const dispatchService = require('../../services/dispatchService');
const Job = require('../../models/Job');
const User = require('../../models/User');
const JobRequest = require('../../models/JobRequest');


// Helper to get io
function getIo(req) {
  return req.app.get('io') || global._socketIo || null;
}

// ─── Admin: Retry dispatch for a job ─────────────────────────────────────────
router.post('/retry/:jobId', verifyToken, requireAdmin, async (req, res) => {
  try {
    const io = getIo(req);
    const result = await dispatchService.autoAssignTechnician(req.params.jobId, io);
    res.json({ success: true, result });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Admin: Override assignment ───────────────────────────────────────────────
router.post('/override/:jobId', verifyToken, requireAdmin, async (req, res) => {
  try {
    const { technicianId } = req.body;
    if (!technicianId) return res.status(400).json({ success: false, message: 'technicianId is required' });

    const io = getIo(req);
    const job = await dispatchService.adminOverrideAssignment(
      req.params.jobId,
      technicianId,
      req.user._id || req.user.id,
      io
    );
    res.json({ success: true, job });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Get dispatch status for a job ───────────────────────────────────────────
router.get('/status/:jobId', verifyToken, async (req, res) => {
  try {
    const status = await dispatchService.getDispatchStatus(req.params.jobId);
    res.json({ success: true, data: status });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── All active dispatching jobs ──────────────────────────────────────────────
router.get('/active', verifyToken, requireAdmin, async (req, res) => {
  try {
    const jobs = await Job.find({
      dispatchStatus: { $in: ['pending_dispatch', 'dispatching', 'no_tech_found'] },
    })
      .populate('assignedTechnician', 'name phone rating')
      .populate('client', 'name phone email')
      .sort({ createdAt: -1 })
      .limit(100)
      .lean();

    res.json({ success: true, data: jobs });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Technician: Accept broadcast job request ─────────────────────────────────
router.post('/accept/:jobId', verifyToken, async (req, res) => {
  try {
    const technicianId = req.user._id || req.user.id;
    const io = getIo(req);
    const result = await dispatchService.acceptJobRequest(req.params.jobId, technicianId, io);
    res.json({ success: true, job: result.job });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// ─── Technician: Reject broadcast job request ─────────────────────────────────
router.post('/reject/:jobId', verifyToken, async (req, res) => {
  try {
    const technicianId = req.user._id || req.user.id;
    const { reason } = req.body;
    const io = getIo(req);
    const result = await dispatchService.rejectJobRequest(req.params.jobId, technicianId, reason || '', io);
    res.json({ success: true, result });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// ─── Technician: Update availability status ───────────────────────────────────
router.put('/availability', verifyToken, async (req, res) => {
  try {
    const { status } = req.body; // ONLINE | OFFLINE | BUSY
    const techId = req.user._id || req.user.id;

    if (!['ONLINE', 'OFFLINE', 'BUSY'].includes(status)) {
      return res.status(400).json({ success: false, message: 'Invalid status. Use ONLINE, OFFLINE, or BUSY' });
    }

    // Performance-based suspension check
    const checkUser = await User.findById(techId).select('performanceScore penaltyPoints');
    if (status === 'ONLINE' && checkUser) {
      const penaltyPoints = checkUser.penaltyPoints || 0;
      const performanceScore = checkUser.performanceScore !== undefined ? checkUser.performanceScore : 100;
      if (penaltyPoints >= 3 || performanceScore < 70) {
        return res.status(403).json({
          success: false,
          message: `Your account is temporarily suspended from going ONLINE due to repeated cancellations (${penaltyPoints} penalties) or low performance score (${performanceScore}%).`
        });
      }
    }

    const user = await User.findByIdAndUpdate(
      techId,
      {
        availabilityStatus: status,
        // Legacy isOnline sync
        isOnline: status === 'ONLINE',
        // Clear active job if going offline
        ...(status === 'OFFLINE' ? { activeJobId: null } : {}),
      },
      { new: true }
    ).select('name availabilityStatus isOnline');

    // Emit to admin tracking
    const io = getIo(req);
    if (io) {
      io.to('admin_room').emit('technicianStatusUpdate', {
        technicianId: techId,
        name: user.name,
        availabilityStatus: status,
        isOnline: status === 'ONLINE',
        timestamp: new Date().toISOString(),
      });
    }

    res.json({ success: true, user });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Technician: Update live location ────────────────────────────────────────
router.put('/location', verifyToken, async (req, res) => {
  try {
    const { lat, lng } = req.body;
    const techId = req.user._id || req.user.id;

    if (lat === undefined || lng === undefined) {
      return res.status(400).json({ success: false, message: 'lat and lng are required' });
    }

    await User.findByIdAndUpdate(techId, {
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      locationUpdatedAt: new Date(),
    });

    const io = getIo(req);
    if (io) {
      io.to('admin_room').emit('technicianLocationUpdate', {
        technicianId: techId,
        lat: parseFloat(lat),
        lng: parseFloat(lng),
        timestamp: new Date().toISOString(),
      });
    }

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─── Technician: Cancel assigned job (penalty applied) ───────────────────────
router.post('/tech-cancel/:jobId', verifyToken, async (req, res) => {
  try {
    const technicianId = req.user._id || req.user.id;
    const { reason } = req.body;
    const io = getIo(req);
    const result = await dispatchService.technicianCancelJob(
      req.params.jobId,
      technicianId,
      reason || '',
      io
    );
    res.json({ success: true, ...result });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
});

// ─── Get technician's pending job requests ────────────────────────────────────
router.get('/my-requests', verifyToken, async (req, res) => {
  try {
    const techId = req.user._id || req.user.id;
    const requests = await JobRequest.find({
      technicianId: techId,
      status: 'pending',
      expiresAt: { $gt: new Date() },
    })
      .populate({
        path: 'jobId',
        select: 'customerName serviceName title location bookingDate timeSlot totalAmount amount price',
        populate: { path: 'addressId', select: 'addressLine1 city pincode latitude longitude' },
      })
      .sort({ sentAt: -1 })
      .lean();

    res.json({ success: true, data: requests });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
