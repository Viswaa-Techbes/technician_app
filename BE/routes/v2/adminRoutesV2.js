const express = require('express');
const adminControllerV2 = require('../../controllers/v2/adminControllerV2');
const { authenticate, requireRoles } = require('../../middlewares/auth');

const router = express.Router();

// Middleware to log API hits as requested
router.use((req, res, next) => {
  console.log(`[API V2] HIT: ${req.method} ${req.originalUrl}`);
  next();
});

// All routes require admin role
router.use(authenticate, requireRoles('admin'));

// Dashboard
router.get('/dashboard', adminControllerV2.getDashboard);

// Leads
router.get('/leads', adminControllerV2.getLeads);
router.post('/leads', adminControllerV2.createLead);
router.put('/leads/:id', adminControllerV2.updateLead);
router.delete('/leads/:id', adminControllerV2.deleteLead);

// Users (Technicians & Managers)
router.get('/users', adminControllerV2.getUsers);
router.post('/users', adminControllerV2.createUser);
router.put('/users/:id', adminControllerV2.updateUser);
router.delete('/users/:id', adminControllerV2.deleteUser);
router.put('/users/:id/password', adminControllerV2.changeUserPassword);

// Legacy aliases or specific routes if needed
router.post('/create-user', adminControllerV2.createUser); // Alias for compatibility

// Jobs
router.get('/jobs', adminControllerV2.getJobs);
router.post('/jobs', adminControllerV2.createJob);
router.put('/jobs/:id', adminControllerV2.updateJob);
router.delete('/jobs/:id', adminControllerV2.deleteJob);

// Bookings (v2 Service Requests)
router.get('/bookings', adminControllerV2.getBookings);
router.put('/bookings/:id/assign', adminControllerV2.assignBooking);
router.patch('/service-requests/:id', adminControllerV2.updateServiceRequest);
router.delete('/service-requests/:id', adminControllerV2.deleteServiceRequest);

// Requests & Approvals
router.get('/completion-requests', adminControllerV2.getCompletionRequests);
router.put('/completion-requests/:id', adminControllerV2.updateCompletionRequest);
router.get('/payment-requests', adminControllerV2.getPaymentRequests);
router.put('/payment-requests/:id', adminControllerV2.updatePaymentRequest);

// Tracking & Reports
router.get('/tracking', adminControllerV2.getTracking);
router.get('/reviews', adminControllerV2.getReviews);
router.get('/attendance', adminControllerV2.getAttendance);

module.exports = router;
