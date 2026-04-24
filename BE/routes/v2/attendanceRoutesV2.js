const express = require('express');
const attendanceControllerV2 = require('../../controllers/v2/attendanceControllerV2');
const { authenticate } = require('../../middlewares/auth');

const router = express.Router();

router.post('/check-in', authenticate, attendanceControllerV2.checkIn);
router.post('/check-out', authenticate, attendanceControllerV2.checkOut);
router.get('/history', authenticate, attendanceControllerV2.getHistory);

module.exports = router;
