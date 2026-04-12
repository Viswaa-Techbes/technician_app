const express = require('express');
const adminController = require('../controllers/adminController');
const { authenticate, requireRoles } = require('../middlewares/auth');

const router = express.Router();

// Public Admin Auth
router.post('/login', adminController.adminLogin);

// Protected Admin Routes
router.use(authenticate, requireRoles('admin'));

router.get('/dashboard', adminController.dashboard);
router.get('/users', adminController.listUsers);
router.get('/technicians', adminController.listTechnicians);
router.get('/jobs', adminController.listJobs);
router.post('/jobs', adminController.createJob);
router.post('/managers', adminController.createManager);
router.post('/technicians', adminController.createTechnician);

module.exports = router;
