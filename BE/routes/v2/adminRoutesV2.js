const express = require('express');
const adminControllerV2 = require('../../controllers/v2/adminControllerV2');
const cctvControllerV2 = require('../../controllers/v2/cctvControllerV2');
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

// Services Management: CCTV catalog and pricing
router.get('/services/cctv/categories', cctvControllerV2.listCategories);
router.post('/services/cctv/categories', cctvControllerV2.categoryAdmin.create);
router.put('/services/cctv/categories/:id', cctvControllerV2.categoryAdmin.update);
router.delete('/services/cctv/categories/:id', cctvControllerV2.categoryAdmin.remove);
router.get('/services/cctv/subcategories', cctvControllerV2.listSubcategories);
router.post('/services/cctv/subcategories', cctvControllerV2.subcategoryAdmin.create);
router.put('/services/cctv/subcategories/:id', cctvControllerV2.subcategoryAdmin.update);
router.delete('/services/cctv/subcategories/:id', cctvControllerV2.subcategoryAdmin.remove);
router.get('/services/cctv/camera-types', cctvControllerV2.listCameraTypes);
router.post('/services/cctv/camera-types', cctvControllerV2.cameraTypeAdmin.create);
router.put('/services/cctv/camera-types/:id', cctvControllerV2.cameraTypeAdmin.update);
router.delete('/services/cctv/camera-types/:id', cctvControllerV2.cameraTypeAdmin.remove);
router.get('/services/cctv/addons', cctvControllerV2.listAddons);
router.post('/services/cctv/addons', cctvControllerV2.addonAdmin.create);
router.put('/services/cctv/addons/:id', cctvControllerV2.addonAdmin.update);
router.delete('/services/cctv/addons/:id', cctvControllerV2.addonAdmin.remove);
router.get('/services/cctv/pricing-config', cctvControllerV2.getPricingConfig);
router.put('/services/cctv/pricing-config', cctvControllerV2.upsertPricingConfig);

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
