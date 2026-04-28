const express = require('express');
const jobControllerV2 = require('../../controllers/v2/jobControllerV2');
const { authenticate, optionalAuthenticate, requireRoles } = require('../../middlewares/auth');

const router = express.Router();

// Public booking creation (works for guests AND logged-in users)
router.post('/', optionalAuthenticate, jobControllerV2.createBooking);
router.post('/create', optionalAuthenticate, jobControllerV2.createBooking); // alias

// List bookings — requires login (role-filtered in controller)
router.get('/', authenticate, jobControllerV2.listBookings);

// Assign a booking to a technician (admin / manager only)
router.put('/:id/assign', authenticate, requireRoles('manager', 'admin'), jobControllerV2.assignById);

// Legacy assign via body
router.post('/assign', authenticate, requireRoles('manager', 'admin'), jobControllerV2.assignBooking);

// Technician accepts / starts job
router.post('/:id/accept', authenticate, requireRoles('technician'), jobControllerV2.acceptJob);

// Upload work proof
router.post('/:id/upload', authenticate, jobControllerV2.uploadWork);

module.exports = router;
