const express = require('express');
const router = express.Router();
const ServiceWorksheet = require('../../models/ServiceWorksheet');
const Job = require('../../models/Job');
const User = require('../../models/User');
const pdfService = require('../../services/pdfService');
const notificationService = require('../../services/notificationService');
const { authenticate, requireRoles } = require('../../middlewares/auth');

// Helper to get socket.io instance
function getIo(req) {
  return req.app.get('io') || global._socketIo || null;
}

// ─── GET: LIST ALL WORKSHEETS (ADMIN/MANAGER ONLY) ──────────────────────────
router.get('/', authenticate, requireRoles('admin', 'manager'), async (req, res, next) => {
  try {
    const { status, page = 1, limit = 50 } = req.query;
    const query = {};
    if (status) query.status = status;

    const worksheets = await ServiceWorksheet.find(query)
      .populate('technicianId', 'name phone email specialty')
      .populate('jobId', 'title bookingNumber client')
      .sort({ updatedAt: -1 })
      .skip((page - 1) * limit)
      .limit(Number(limit))
      .lean();

    const total = await ServiceWorksheet.countDocuments(query);

    return res.json({
      success: true,
      data: worksheets,
      pagination: {
        total,
        page: Number(page),
        limit: Number(limit),
        totalPages: Math.ceil(total / limit)
      }
    });
  } catch (err) {
    next(err);
  }
});

// ─── GET: FETCH OR INITIALIZE WORKSHEET FOR A JOB ───────────────────────────
router.get('/job/:jobId', authenticate, async (req, res, next) => {
  try {
    const { jobId } = req.params;
    let worksheet = await ServiceWorksheet.findOne({ jobId })
      .populate('technicianId', 'name email phone mobileNumber specialty performance rating profilePhoto')
      .populate('jobId', 'title description location scheduledTime scheduledDate status totalAmount');

    if (worksheet) {
      return res.json({ success: true, data: worksheet });
    }

    // Worksheet doesn't exist, auto-create a draft by pulling data from Job / Booking
    const job = await Job.findById(jobId).populate('assignedTechnician');
    if (!job) {
      return res.status(404).json({ success: false, message: 'Job not found' });
    }

    // Find custom customerId if client is linked
    let customerId = job.customerId || '';
    if (!customerId && job.client) {
      const clientUser = await User.findById(job.client).select('customerId');
      if (clientUser) {
        customerId = clientUser.customerId || '';
      }
    }
    if (!customerId) {
      customerId = `CUS-TEMP-${Math.floor(1000 + Math.random() * 9000)}`;
    }

    worksheet = new ServiceWorksheet({
      jobId: job._id,
      bookingId: job.bookingNumber || job.bookingId || `BOOK-${Math.floor(Date.now() / 1000)}`,
      customerId: customerId,
      technicianId: job.assignedTechnician?._id || req.user.id || req.user._id,
      customerName: job.customerName || 'N/A',
      customerMobile: job.customerPhone || 'N/A',
      customerAddress: job.location || 'N/A',
      serviceType: job.serviceType || 'other',
      serviceCategory: job.serviceName || job.title || 'Field Service',
      jobCreatedDate: job.createdAt || new Date(),
      status: 'draft'
    });

    await worksheet.save();

    return res.json({ success: true, data: worksheet });
  } catch (err) {
    next(err);
  }
});

// ─── PUT: UPDATE WORKSHEET ──────────────────────────────────────────────────
router.put('/job/:jobId', authenticate, async (req, res, next) => {
  try {
    const { jobId } = req.params;
    const updateData = req.body;

    const worksheet = await ServiceWorksheet.findOne({ jobId });
    if (!worksheet) {
      return res.status(404).json({ success: false, message: 'Worksheet not found' });
    }

    // Authorize: Only assigned technician or managers/admins can edit
    if (req.user.role === 'technician' && worksheet.technicianId.toString() !== req.user.id) {
      return res.status(403).json({ success: false, message: 'Access denied: You are not the assigned technician' });
    }

    // Apply updates
    const editableFields = [
      'arrivalTime', 'workStartTime', 'workEndTime',
      'requestedWorkDescription', 'technicianObservations', 'additionalComments',
      'materialsUsed', 'partsInstalled',
      'beforePhotos', 'duringPhotos', 'afterPhotos',
      'customerSignatureUrl', 'technicianSignatureUrl',
      'labourCost', 'status'
    ];

    editableFields.forEach((field) => {
      if (updateData[field] !== undefined) {
        worksheet[field] = updateData[field];
      }
    });

    // Re-calculate costs dynamically
    if (updateData.materialsUsed || updateData.labourCost !== undefined) {
      let matCostSum = 0;
      worksheet.materialsUsed.forEach((item) => {
        item.totalCost = (item.quantity || 1) * (item.unitCost || 0);
        matCostSum += item.totalCost;
      });
      worksheet.materialCost = matCostSum;
      worksheet.totalCost = worksheet.materialCost + (worksheet.labourCost || 0);
    }

    // Handle Submission Action
    if (worksheet.status === 'submitted') {
      // Validation rules check on submit
      if (!worksheet.beforePhotos || worksheet.beforePhotos.length === 0) {
        return res.status(400).json({ success: false, message: 'Validation failed: Minimum 1 before photo is mandatory.' });
      }
      if (!worksheet.afterPhotos || worksheet.afterPhotos.length === 0) {
        return res.status(400).json({ success: false, message: 'Validation failed: Minimum 1 after photo is mandatory.' });
      }
      if (!worksheet.customerSignatureUrl) {
        return res.status(400).json({ success: false, message: 'Validation failed: Customer signature is required.' });
      }
      
      worksheet.submittedAt = new Date();

      // Send Notifications
      const io = getIo(req);
      const job = await Job.findById(jobId);
      
      // Notify Admin
      const admins = await User.find({ role: { $in: ['admin', 'manager'] } }).select('_id');
      for (const admin of admins) {
        await notificationService.createNotification(
          admin._id.toString(),
          'Worksheet Awaiting Approval',
          `Digital worksheet for Booking #${worksheet.bookingId} is awaiting your approval.`,
          'worksheet_submitted',
          io,
          { jobId: jobId }
        );
      }

      // Notify Customer
      if (job && job.client) {
        await notificationService.createNotification(
          job.client.toString(),
          'Worksheet Submitted',
          `Your service report for Booking #${worksheet.bookingId} has been submitted.`,
          'worksheet_submitted',
          io,
          { jobId: jobId }
        );
      }
    }

    await worksheet.save();
    return res.json({ success: true, data: worksheet });
  } catch (err) {
    next(err);
  }
});

// ─── POST: APPROVE WORKSHEET (ADMIN/MANAGER ONLY) ───────────────────────────
router.post('/job/:jobId/approve', authenticate, requireRoles('admin', 'manager'), async (req, res, next) => {
  try {
    const { jobId } = req.params;
    const worksheet = await ServiceWorksheet.findOne({ jobId });
    if (!worksheet) {
      return res.status(404).json({ success: false, message: 'Worksheet not found' });
    }

    const job = await Job.findById(jobId).populate('assignedTechnician');
    if (!job) {
      return res.status(404).json({ success: false, message: 'Job not found' });
    }

    // Update status
    worksheet.status = 'approved';
    worksheet.approvedAt = new Date();

    // Automatically generate and upload PDF report
    const pdfUrl = await pdfService.generateWorksheetPdf(worksheet, job);
    worksheet.pdfUrl = pdfUrl;
    await worksheet.save();

    // Sync PDF URL to Job attachments (so it can be retrieved by standard customer report queries)
    if (!job.attachments) {
      job.attachments = [];
    }
    // Prepend PDF URL to attachments array
    job.attachments.unshift(pdfUrl);
    await job.save();

    // Send Notifications
    const io = getIo(req);

    // Notify Technician
    if (worksheet.technicianId) {
      await notificationService.createNotification(
        worksheet.technicianId.toString(),
        'Worksheet Approved',
        `Your worksheet for Booking #${worksheet.bookingId} has been approved by the admin.`,
        'worksheet_approved',
        io,
        { jobId: jobId }
      );
    }

    // Notify Customer
    if (job.client) {
      await notificationService.createNotification(
        job.client.toString(),
        'Service Worksheet Approved & PDF Ready',
        `Your service report PDF for Booking #${worksheet.bookingId} is now ready to download.`,
        'worksheet_approved',
        io,
        { jobId: jobId }
      );
    }

    return res.json({ success: true, message: 'Worksheet approved and PDF generated successfully', data: worksheet });
  } catch (err) {
    next(err);
  }
});

// ─── POST: REJECT WORKSHEET (ADMIN/MANAGER ONLY) ─────────────────────────────
router.post('/job/:jobId/reject', authenticate, requireRoles('admin', 'manager'), async (req, res, next) => {
  try {
    const { jobId } = req.params;
    const { reason = 'Review remarks not provided' } = req.body;

    const worksheet = await ServiceWorksheet.findOne({ jobId });
    if (!worksheet) {
      return res.status(404).json({ success: false, message: 'Worksheet not found' });
    }

    // Set back to in_progress so technician can fix details
    worksheet.status = 'in_progress';
    worksheet.additionalComments = `${worksheet.additionalComments || ''}\n[REJECTION REMARKS]: ${reason}`.trim();
    await worksheet.save();

    // Send Notification to Technician
    const io = getIo(req);
    if (worksheet.technicianId) {
      await notificationService.createNotification(
        worksheet.technicianId.toString(),
        'Worksheet Rejected',
        `Your worksheet for Booking #${worksheet.bookingId} was rejected. Reason: ${reason}`,
        'worksheet_rejected',
        io,
        { jobId: jobId }
      );
    }

    return res.json({ success: true, message: 'Worksheet rejected. Status set back to IN_PROGRESS.', data: worksheet });
  } catch (err) {
    next(err);
  }
});

module.exports = router;
