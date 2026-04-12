const authService = require('../services/authService');
const User = require('../models/User');

async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'email and password are required' });
    }

    const { token, user } = await authService.loginUser(email, password);

    return res.json({
      success: true,
      data: { token, user },
    });
  } catch (err) {
    res.status(401).json({ success: false, message: err.message });
  }
}

async function register(req, res, next) {
  try {
    const { token, user } = await authService.registerUser(req.body);

    return res.status(201).json({
      success: true,
      message: 'User registered',
      data: { token, user },
    });
  } catch (err) {
    res.status(409).json({ success: false, message: err.message });
  }
}

async function me(req, res) {
  return res.json({
    success: true,
    data: req.authUser.toSafeObject(),
  });
}

module.exports = { login, register, me };
