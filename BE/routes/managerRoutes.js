const express = require('express');
const managerController = require('../controllers/managerController');
const { authenticate, requireRoles } = require('../middlewares/auth');

const router = express.Router();

router.use(authenticate, requireRoles('manager'));

router.get('/dashboard', managerController.dashboard);
router.get('/technicians', managerController.listTechnicians);
router.get('/technicians/:techId/reviews', managerController.getTechnicianReviews);

router.get('/tasks', managerController.listTasks);
router.post('/tasks/assign', managerController.assignTask);

router.get('/expenditures', managerController.listExpenditures);
router.patch('/expenditures/:expenseId', managerController.approveExpenditure);

module.exports = router;
