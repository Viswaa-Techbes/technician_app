const express = require('express');
const authController = require('../controllers/authController');
const { authenticate } = require('../middlewares/auth');

const router = express.Router();

// POST /auth/login
router.post('/login', authController.login);

// POST /auth/register
router.post('/register', authController.register);

// GET /auth/me (for token verification and profile)
router.get('/me', authenticate, authController.me);

module.exports = router;
