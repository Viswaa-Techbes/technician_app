const User = require('../models/User');
const { signToken } = require('../utils/jwt');

/**
 * POST /auth/register — create user (testing / bootstrap admin).
 * Body: { name, email, password, role? }
 */
async function register(req, res, next) {
  try {
    const { name, email, password, role = 'technician' } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'name, email, and password are required',
      });
    }

    const existing = await User.findOne({ email: email.toLowerCase() });
    if (existing) {
      return res.status(409).json({ success: false, message: 'Email already registered' });
    }

    const user = await User.create({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password,
      role,
    });

    const token = signToken(user._id, user.role);

    return res.status(201).json({
      success: true,
      message: 'User registered',
      data: {
        token,
        user: user.toSafeObject(),
      },
    });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /auth/login — returns JWT + user (any role).
 */
async function login(req, res, next) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'email and password are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+password');
    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const ok = await user.comparePassword(password);
    if (!ok) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const token = signToken(user._id, user.role);
    user.password = undefined;

    return res.json({
      success: true,
      data: {
        token,
        user: user.toSafeObject(),
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = { register, login };
