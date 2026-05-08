const AdmissionPayment = require('../../models/AdmissionPayment');
const AdmissionDocument = require('../../models/AdmissionDocument');
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
