const express = require('express');
const authController = require('../controllers/authController');
const { authenticate } = require('../middlewares/auth');

const router = express.Router();

// POST /auth/login or /login
router.post('/login', authController.login);

// POST /auth/register or /register
router.post('/register', authController.register);

// GET /auth/me or /me
router.get('/me', authenticate, authController.me);

// POST /auth/fcm-token
router.post('/fcm-token', authenticate, authController.updateFcmToken);

// POST /auth/logout
router.post('/logout', authenticate, authController.logout);

module.exports = router;
