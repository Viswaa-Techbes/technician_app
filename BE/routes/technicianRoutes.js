const express = require('express');
const technicianController = require('../controllers/technicianController');
const { authenticate, requireRoles } = require('../middlewares/auth');

const router = express.Router();

router.use(authenticate, requireRoles('technician'));

router.get('/dashboard', technicianController.dashboard);
router.get('/tasks', technicianController.listTasks);
router.patch('/tasks/:taskId/status', technicianController.updateTaskStatus);

router.patch('/location', technicianController.updateLocation);
router.post('/expenditures', technicianController.submitExpense);
router.get('/reviews', technicianController.getMyReviews);

module.exports = router;
