const express = require('express');
const jobControllerV2 = require('../../controllers/v2/jobControllerV2');
const { authenticate, requireRoles } = require('../../middlewares/auth');

const router = express.Router();

router.use(authenticate);

// Create a new booking (client or admin)
router.post('/', requireRoles('client', 'admin', 'manager'), jobControllerV2.createBooking);
router.post('/create', requireRoles('client', 'admin', 'manager'), jobControllerV2.createBooking); // alias

// List bookings (filtered per role in controller)
router.get('/', jobControllerV2.listBookings);

// Assign a booking to a technician (admin / manager)
router.put('/:id/assign', requireRoles('manager', 'admin'), jobControllerV2.assignById);

// Legacy assign via body
router.post('/assign', requireRoles('manager', 'admin'), jobControllerV2.assignBooking);

// Technician accepts / starts job
router.post('/:id/accept', requireRoles('technician'), jobControllerV2.acceptJob);

// Upload work proof
router.post('/:id/upload', jobControllerV2.uploadWork);

module.exports = router;
