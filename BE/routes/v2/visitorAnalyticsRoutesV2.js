const express = require('express');
const { authenticate, requireRoles } = require('../../middlewares/auth');
const { trackVisitor, getDashboard, getCityDetail } = require('../../controllers/v2/visitorAnalyticsControllerV2');

const router = express.Router();

// Public ingestion endpoint
router.post('/track', trackVisitor);

// Admin-only analytics dashboard data
router.get('/dashboard', authenticate, requireRoles('admin'), getDashboard);
router.get('/city/:city', authenticate, requireRoles('admin'), getCityDetail);

module.exports = router;
