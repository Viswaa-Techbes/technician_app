const User = require('../models/User');
const Task = require('../models/Task');
const { signToken } = require('../utils/jwt');

/**
 * POST /admin/login — same as auth login but only succeeds if role is admin.
 */
async function adminLogin(req, res, next) {
  try {
    const { email, password } = req.body;
    if (!email || !password) {
      return res.status(400).json({ success: false, message: 'email and password are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase().trim() }).select('+password');
    if (!user || user.role !== 'admin') {
      return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
    }

    const ok = await user.comparePassword(password);
    if (!ok) {
      return res.status(401).json({ success: false, message: 'Invalid admin credentials' });
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

async function dashboard(req, res, next) {
  try {
    const [userCounts, taskCounts] = await Promise.all([
      User.aggregate([
        { $group: { _id: '$role', count: { $sum: 1 } } },
      ]),
      Task.aggregate([
        { $group: { _id: '$status', count: { $sum: 1 } } },
      ]),
    ]);

    const usersByRole = userCounts.reduce((acc, row) => {
      acc[row._id] = row.count;
      return acc;
    }, {});

    const tasksByStatus = taskCounts.reduce((acc, row) => {
      acc[row._id] = row.count;
      return acc;
    }, {});

    return res.json({
      success: true,
      data: {
        usersByRole,
        tasksByStatus,
        totalUsers: Object.values(usersByRole).reduce((a, b) => a + b, 0),
        totalTasks: Object.values(tasksByStatus).reduce((a, b) => a + b, 0),
      },
    });
  } catch (err) {
    next(err);
  }
}

async function listUsers(req, res, next) {
  try {
    const users = await User.find().sort({ createdAt: -1 }).lean();
    const safe = users.map((u) => ({
      id: u._id.toString(),
      name: u.name,
      email: u.email,
      role: u.role,
      createdAt: u.createdAt,
      updatedAt: u.updatedAt,
    }));
    return res.json({ success: true, data: safe });
  } catch (err) {
    next(err);
  }
}

async function createManager(req, res, next) {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'name, email, and password are required',
      });
    }

    const existing = await User.findOne({ email: email.toLowerCase().trim() });
    if (existing) {
      return res.status(409).json({ success: false, message: 'Email already registered' });
    }

    const user = await User.create({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password,
      role: 'manager',
    });

    return res.status(201).json({
      success: true,
      message: 'Manager created',
      data: user.toSafeObject(),
    });
  } catch (err) {
    next(err);
  }
}

async function createTechnician(req, res, next) {
  try {
    const { name, email, password } = req.body;
    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'name, email, and password are required',
      });
    }

    const existing = await User.findOne({ email: email.toLowerCase().trim() });
    if (existing) {
      return res.status(409).json({ success: false, message: 'Email already registered' });
    }

    const user = await User.create({
      name: name.trim(),
      email: email.toLowerCase().trim(),
      password,
      role: 'technician',
    });

    return res.status(201).json({
      success: true,
      message: 'Technician created',
      data: user.toSafeObject(),
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  adminLogin,
  dashboard,
  listUsers,
  createManager,
  createTechnician,
};
