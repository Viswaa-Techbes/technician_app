const express = require('express');
const adminControllerV2 = require('../../controllers/v2/adminControllerV2');
const { authenticate, requireRoles } = require('../../middlewares/auth');

const router = express.Router();

// All routes here require admin role
router.use(authenticate, requireRoles('admin'));

router.post('/create-user', adminControllerV2.createUser);
router.put('/update-user/:id', adminControllerV2.updateUser);
router.delete('/delete-user/:id', adminControllerV2.deleteUser);

router.put('/leads/:id', adminControllerV2.updateLead);
router.delete('/leads/:id', adminControllerV2.deleteLead);

module.exports = router;
