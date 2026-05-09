const AdmissionPayment = require('../../models/AdmissionPayment');
const AdmissionDocument = require('../../models/AdmissionDocument');
const Admission = require('../../models/Admission');
const admissionService = require('../../services/admissionServiceV2');

function parsePayload(req, partial = false) {
  const body = req.body || {};
  const requiredKeys = ['fullName', 'phone', 'email', 'qualification', 'address', 'selectedPlan'];
  if (!partial) {
    for (const key of requiredKeys) {
      if (!body[key]) {
        throw new Error(`Missing required field: ${key}`);
      }
    }
  }
  const parsed = { ...body };
  if (parsed.dateOfBirth) parsed.dateOfBirth = new Date(parsed.dateOfBirth);
  if (Number.isFinite(parsed.monthlyFamilyIncome)) parsed.monthlyFamilyIncome = Number(parsed.monthlyFamilyIncome);
  if (Number.isFinite(parsed.sslcPercentage)) parsed.sslcPercentage = Number(parsed.sslcPercentage);
  if (Number.isFinite(parsed.hscPercentage)) parsed.hscPercentage = Number(parsed.hscPercentage);
  if (Number.isFinite(parsed.yearOfPassing)) parsed.yearOfPassing = Number(parsed.yearOfPassing);
  if (parsed.internalNote && req.user && req.user.id) {
    parsed.internalNotes = [{ note: parsed.internalNote, addedBy: req.user.id }];
  }
  delete parsed.internalNote;
  return parsed;
}

async function listAdmissions(req, res, next) {
  try {
    const data = await admissionService.listApplications(req.query);
    return res.json({ success: true, ...data });
  } catch (err) {
    return next(err);
  }
}

async function getAdmissionById(req, res, next) {
  try {
    const item = await admissionService.getApplicationById(req.params.id);
    if (!item) return res.status(404).json({ success: false, message: 'Admission not found' });
    return res.json({ success: true, data: item });
  } catch (err) {
    return next(err);
  }
}

async function createAdmission(req, res, next) {
  try {
    const payload = parsePayload(req, false);
    const item = await admissionService.createApplication(payload);
    return res.status(201).json({ success: true, data: item });
  } catch (err) {
    return next(err);
  }
}

async function updateAdmission(req, res, next) {
  try {
    const payload = parsePayload(req, true);
    const item = await admissionService.updateApplication(req.params.id, payload);
    if (!item) return res.status(404).json({ success: false, message: 'Admission not found' });
    return res.json({ success: true, data: item });
  } catch (err) {
    return next(err);
  }
}

async function deleteAdmission(req, res, next) {
  try {
    const item = await admissionService.deleteApplication(req.params.id);
    if (!item) return res.status(404).json({ success: false, message: 'Admission not found' });
    return res.json({ success: true, message: 'Admission deleted' });
  } catch (err) {
    return next(err);
  }
}

async function updateStatus(req, res, next) {
  try {
    const { admissionStatus } = req.body || {};
    const allowed = ['applied', 'under_review', 'approved', 'payment_pending', 'enrolled', 'rejected'];
    if (!allowed.includes(admissionStatus)) {
      return res.status(400).json({ success: false, message: 'Invalid admission status' });
    }
    const item = await admissionService.updateApplication(req.params.id, { admissionStatus });
    if (!item) return res.status(404).json({ success: false, message: 'Admission not found' });
    return res.json({ success: true, data: item });
  } catch (err) {
    return next(err);
  }
}

async function assignCourseOrInternship(req, res, next) {
  try {
    const payload = {
      assignedCourse: req.body?.assignedCourse,
      assignedInternship: req.body?.assignedInternship,
      programType: req.body?.programType,
    };
    const item = await admissionService.updateApplication(req.params.id, payload);
    if (!item) return res.status(404).json({ success: false, message: 'Admission not found' });
    return res.json({ success: true, data: item });
  } catch (err) {
    return next(err);
  }
}

async function upsertPayment(req, res, next) {
  try {
    const parsed = req.body || {};
    if (!Number.isFinite(Number(parsed.totalFees))) {
      return res.status(400).json({ success: false, message: 'totalFees is required' });
    }
    const update = {
      totalFees: Number(parsed.totalFees),
      paidAmount: Number(parsed.paidAmount || 0),
      pendingAmount: Number(parsed.pendingAmount || 0),
      emiStatus: parsed.emiStatus || 'inactive',
      paymentStatus: parsed.paymentStatus || 'pending',
    };

    const $push = {};
    if (parsed.adminNote) $push.adminNotes = { note: parsed.adminNote };
    if (parsed.transaction) $push.transactionLogs = parsed.transaction;

    const payment = await AdmissionPayment.findOneAndUpdate(
      { admissionId: req.params.id },
      {
        $set: update,
        ...(Object.keys($push).length ? { $push } : {}),
      },
      { upsert: true, new: true, runValidators: true }
    );

    await admissionService.updateApplication(req.params.id, { paymentStatus: parsed.paymentStatus });
    return res.json({ success: true, data: payment });
  } catch (err) {
    return next(err);
  }
}

async function addDocument(req, res, next) {
  try {
    const payload = req.body || {};
    const allowedTypes = ['aadhaar', 'resume', 'certificate', 'passport_photo', 'other'];
    if (!allowedTypes.includes(payload.documentType) || !payload.fileUrl) {
      return res.status(400).json({ success: false, message: 'Invalid document payload' });
    }
    const doc = await AdmissionDocument.create({
      admissionId: req.params.id,
      ...payload,
      uploadedBy: req.user.id,
    });
    return res.status(201).json({ success: true, data: doc });
  } catch (err) {
    return next(err);
  }
}

// Bulk assign multiple admissions (admin-only)
async function bulkAssign(req, res, next) {
  try {
    const { ids = [], assignedCourse, assignedInternship } = req.body || {};
    const programType = req.body?.programType;
    if (!Array.isArray(ids) || ids.length === 0) return res.status(400).json({ success: false, message: 'ids required' });
    const updates = { };
    if (assignedCourse) updates.assignedCourse = assignedCourse;
    if (assignedInternship) updates.assignedInternship = assignedInternship;
    if (programType) updates.programType = programType;

    const results = [];
    for (const id of ids) {
      const item = await admissionService.updateApplication(id, updates);
      if (item) {
        // push internal note about assignment for history
        const note = `Assigned${assignedCourse ? ' course:'+assignedCourse : ''}${assignedInternship ? ' internship:'+assignedInternship : ''}`;
        await Admission.findByIdAndUpdate(id, { $push: { internalNotes: { note, addedBy: req.user.id } } }).catch(() => {});
        results.push(id);
      }
    }
    return res.json({ success: true, assigned: results.length, ids: results });
  } catch (err) { return next(err); }
}

// Activity stream for a specific admission
async function getActivity(req, res, next) {
  try {
    const id = req.params.id;
    const item = await admissionService.getApplicationById(id);
    if (!item) return res.status(404).json({ success: false, message: 'Admission not found' });
    const notes = (item.internalNotes || []).map(n => ({ message: n.note, timestamp: n.addedAt, addedBy: n.addedBy }));
    return res.json({ success: true, data: notes });
  } catch (err) { return next(err); }
}

// Payment ledger list
async function getPayments(req, res, next) {
  try {
    const id = req.params.id;
    const payments = await AdmissionPayment.find({ admissionId: id }).sort({ createdAt: -1 }).lean();
    return res.json({ success: true, data: payments });
  } catch (err) { return next(err); }
}

// Assignment history — derive from internalNotes
async function getAssignmentHistory(req, res, next) {
  try {
    const id = req.params.id;
    const item = await admissionService.getApplicationById(id);
    if (!item) return res.status(404).json({ success: false, message: 'Admission not found' });
    const hist = (item.internalNotes || []).filter(n => /assign/i.test(n.note || '')).map(n => ({ assignedTo: n.note, note: n.note, date: n.addedAt }));
    // include current assignment
    if (item.assignedCourse || item.assignedInternship) {
      hist.unshift({ assignedTo: item.assignedCourse || item.assignedInternship, note: `Current: ${item.assignedCourse||''} ${item.assignedInternship||''}`, date: item.updatedAt });
    }
    return res.json({ success: true, data: hist });
  } catch (err) { return next(err); }
}

module.exports = {
  listAdmissions,
  getAdmissionById,
  createAdmission,
  updateAdmission,
  deleteAdmission,
  updateStatus,
  assignCourseOrInternship,
  upsertPayment,
  addDocument,
};

// verify payment (admin manual verify)
async function verifyPayment(req, res, next) {
  try {
    const id = req.params.id;
    const payment = await AdmissionPayment.findOne({ admissionId: id });
    if (!payment) return res.status(404).json({ success: false, message: 'Payment record not found' });
    const total = Number(payment.totalFees || 0);
    payment.paymentStatus = 'paid';
    payment.paidAmount = total;
    payment.pendingAmount = 0;
    payment.transactionLogs = payment.transactionLogs || [];
    payment.transactionLogs.push({ amount: total, mode: 'admin_verify', transactionId: `admin-${Date.now()}`, status: 'success', note: 'Verified by admin' });
    await payment.save();
    await admissionService.updateApplication(id, { paymentStatus: 'paid' });
    return res.json({ success: true, data: payment });
  } catch (err) { return next(err); }
}

module.exports.verifyPayment = verifyPayment;

// Bulk preview for admissions
async function bulkPreview(req, res, next) {
  try {
    const { ids = [] } = req.body || {};
    if (!Array.isArray(ids) || ids.length === 0) return res.status(400).json({ success: false, message: 'ids required' });
    const items = await Admission.find({ _id: { $in: ids } }).select('fullName _id assignedCourse assignedInternship admissionStatus paymentStatus programType').lean();
    return res.json({ success: true, data: items });
  } catch (err) { return next(err); }
}

module.exports.bulkPreview = bulkPreview;
