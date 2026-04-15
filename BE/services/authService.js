const User = require('../models/User');
const { signToken } = require('../utils/jwt');

async function loginUser(mobileNumber, password) {
  const normalizedMobile = mobileNumber.trim();
  const user = await User.findOne({ mobileNumber: normalizedMobile }).select('+password');
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
  const { name, mobileNumber, email, password, role = 'technician', phone, specialty, assignedManager } = userData;

  if (!mobileNumber || !password) {
    throw new Error('mobileNumber and password are required');
  }

  const normalizedMobile = mobileNumber.trim();
  const normalizedEmail = typeof email === 'string' ? email.trim().toLowerCase() : '';

  const existing = await User.findOne({ mobileNumber: normalizedMobile });
  if (existing) {
    throw new Error('Mobile number already registered');
  }

  if (normalizedEmail) {
    const existingEmailUser = await User.findOne({ email: normalizedEmail });
    if (existingEmailUser) {
      throw new Error('Email already registered');
    }
  }

  const user = await User.create({
    name: (name ?? '').trim(),
    mobileNumber: normalizedMobile,
    ...(normalizedEmail ? { email: normalizedEmail } : {}),
    password,
    role,
    phone: phone ?? normalizedMobile,
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
