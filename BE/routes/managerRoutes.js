const express = require('express');
const managerController = require('../controllers/managerController');
const { authenticate, requireRoles } = require('../middlewares/auth');

const router = express.Router();

router.use(authenticate, requireRoles('manager'));

router.get('/dashboard', managerController.dashboard);
router.get('/technicians', managerController.listTechnicians);
router.get('/tasks', managerController.listTasks);
router.post('/tasks/assign', managerController.assignTask);
router.patch('/tasks/:taskId/status', managerController.updateTaskStatus);

module.exports = router;
