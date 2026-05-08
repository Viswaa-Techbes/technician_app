const express = require('express');
const { authenticate, requireRoles } = require('../../middlewares/auth');
const controller = require('../../controllers/v2/admissionControllerV2');

const router = express.Router();

// Admin-only admission management
router.use(authenticate, requireRoles('admin'));

router.get('/', controller.listAdmissions);
router.post('/', controller.createAdmission);
router.get('/:id', controller.getAdmissionById);
router.put('/:id', controller.updateAdmission);
router.delete('/:id', controller.deleteAdmission);

router.patch('/:id/status', controller.updateStatus);
router.patch('/:id/assignment', controller.assignCourseOrInternship);
router.put('/:id/payment', controller.upsertPayment);
router.post('/:id/documents', controller.addDocument);

module.exports = router;
