const express = require('express');
const managerController = require('../controllers/managerController');
const { authenticate, requireRoles } = require('../middlewares/auth');

const router = express.Router();

router.use(authenticate, requireRoles('manager'));

router.get('/dashboard', managerController.dashboard);
router.get('/technicians', managerController.listTechnicians);
router.post('/tasks/assign', managerController.assignTask);

module.exports = router;
