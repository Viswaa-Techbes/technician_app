const express = require('express');
const jobControllerV2 = require('../../controllers/v2/jobControllerV2');
const { authenticate, requireRoles } = require('../../middlewares/auth');

const router = express.Router();

router.use(authenticate);

router.post('/create', requireRoles('client', 'admin'), jobControllerV2.createBooking);
router.get('/', jobControllerV2.listBookings);
router.post('/assign', requireRoles('manager', 'admin'), jobControllerV2.assignBooking);

module.exports = router;
