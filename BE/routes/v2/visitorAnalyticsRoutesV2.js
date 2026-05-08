const express = require('express');
const { authenticate, requireRoles } = require('../../middlewares/auth');
const { trackVisitor, getDashboard } = require('../../controllers/v2/visitorAnalyticsControllerV2');

const router = express.Router();

// Public ingestion endpoint
router.post('/track', trackVisitor);

// Admin-only analytics dashboard data
router.get('/dashboard', authenticate, requireRoles('admin'), getDashboard);

module.exports = router;
