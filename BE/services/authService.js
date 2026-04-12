const User = require('../models/User');
const { signToken } = require('../utils/jwt');

async function loginUser(email, password) {
  const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+password');
  if (!user) {
    throw new Error('Invalid credentials');
  }

  const ok = await user.comparePassword(password);
  if (!ok) {
    throw new Error('Invalid credentials');
  }

  const token = signToken(user._id, user.role);
  return { token, user: user.toSafeObject() };
}

async function registerUser(userData) {
  const { name, email, password, role = 'technician', phone, specialty, assignedManager } = userData;

  const existing = await User.findOne({ email: email.toLowerCase().trim() });
  if (existing) {
    throw new Error('Email already registered');
  }

  const user = await User.create({
    name: name.trim(),
    email: email.toLowerCase().trim(),
    password,
    role,
    phone,
    specialty,
    assignedManager,
  });

  const token = signToken(user._id, user.role);
  return { token, user: user.toSafeObject() };
}

module.exports = {
  loginUser,
  registerUser,
};
