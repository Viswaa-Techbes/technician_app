const express = require('express');
const adminController = require('../controllers/adminController');
const { authenticate, requireRoles } = require('../middlewares/auth');

const router = express.Router();

router.post('/login', adminController.adminLogin);

router.use(authenticate, requireRoles('admin'));

router.get('/dashboard', adminController.dashboard);
router.get('/users', adminController.listUsers);
router.post('/create-manager', adminController.createManager);
router.post('/create-technician', adminController.createTechnician);

module.exports = router;
