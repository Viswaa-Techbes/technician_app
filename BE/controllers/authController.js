const authService = require('../services/authService');

async function login(req, res, next) {
  try {
    const { mobileNumber, password } = req.body;
    if (!mobileNumber || !password) {
      return res.status(400).json({ success: false, message: 'mobileNumber and password are required' });
    }

    const { token, user } = await authService.loginUser(mobileNumber, password);

    return res.json({
      success: true,
      token,
      user,
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
      token,
      user,
      data: { token, user },
    });
  } catch (err) {
    const duplicateField = err?.keyPattern ? Object.keys(err.keyPattern)[0] : null;
    const isDuplicate =
      err?.code === 11000 || err.message?.toLowerCase().includes('already registered');
    const statusCode = isDuplicate ? 409 : 400;
    const message = isDuplicate
      ? duplicateField === 'mobileNumber'
        ? 'Mobile number already registered'
        : duplicateField === 'email'
          ? 'Email already registered'
          : err.message
      : err.message;

    res.status(statusCode).json({ success: false, message });
  }
}

async function me(req, res) {
  return res.json({
    success: true,
    data: req.authUser.toSafeObject(),
  });
}

module.exports = { login, register, me };
