const express = require('express');
const router = express.Router();
const { authenticate, requireRoles } = require('../../middlewares/auth');
const { requirePermission } = require('../../middlewares/rbac');
const {
  getSummary,
  getRevenue,
  getJobsBreakdown,
  getTechnicianPerformance,
  getBookingFunnel,
} = require('../../controllers/v2/analyticsControllerV2');

// All analytics routes require admin or manager role + canViewReports permission
router.use(authenticate, requireRoles('admin', 'manager'), requirePermission('canViewReports'));

router.get('/summary', getSummary);
router.get('/revenue', getRevenue);
router.get('/jobs', getJobsBreakdown);
router.get('/technicians', getTechnicianPerformance);
router.get('/funnel', getBookingFunnel);

module.exports = router;
