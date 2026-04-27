const express = require('express');
const attendanceControllerV2 = require('../../controllers/v2/attendanceControllerV2');
const { authenticate, requireRoles } = require('../../middlewares/auth');

const router = express.Router();

// Publicly mark attendance on login (handled internally or via endpoint)
router.post('/mark', authenticate, attendanceControllerV2.handleMarkAttendance);
router.post('/logout', authenticate, attendanceControllerV2.handleLogoutAttendance);

// Admin reporting
router.get('/today', authenticate, requireRoles('admin'), attendanceControllerV2.getTodayAttendance);
router.get('/range', authenticate, requireRoles('admin'), attendanceControllerV2.getAttendanceRange);
router.get('/month', authenticate, requireRoles('admin'), attendanceControllerV2.getMonthlyAttendance);

// Legacy/Compatibility: GET base returns today's attendance for admin
router.get('/', authenticate, requireRoles('admin'), attendanceControllerV2.getTodayAttendance);

module.exports = router;
