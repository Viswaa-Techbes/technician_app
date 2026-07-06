const express = require('express');
const router = express.Router();
const aiService = require('../../services/aiService');
const { authenticate } = require('../../middlewares/authMiddleware');

router.post('/chat', aiService.processChat);
router.post('/handoff', authenticate, aiService.createAiTicketHandoff);

module.exports = router;
