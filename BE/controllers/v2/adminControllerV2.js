const User = require('../../models/User');
const Lead = require('../../models/Lead');
const { signToken } = require('../../utils/jwt');

async function createUser(req, res, next) {
  try {
    const { name, mobileNumber, password, role } = req.body;
    
    if (!name || !mobileNumber || !password || !role) {
      return res.status(400).json({ success: false, message: 'All fields are required' });
    }

    if (!['technician', 'manager'].includes(role)) {
      return res.status(400).json({ success: false, message: 'Invalid role' });
    }

    const existing = await User.findOne({ mobileNumber, isDeleted: false });
    if (existing) {
      return res.status(409).json({ success: false, message: 'User already exists with this mobile number' });
    }

    const user = await User.create({
      name,
      mobileNumber,
      password,
      role,
      status: 'offline',
      isOnline: false,
      sessionActive: false
    });

    return res.status(201).json({
      success: true,
      message: `${role.charAt(0).toUpperCase() + role.slice(1)} created successfully`,
      data: {
        name: user.name,
        mobileNumber: user.mobileNumber,
        role: user.role,
        password: password // Returning raw password as requested for sharing
      }
    });
  } catch (err) {
    next(err);
  }
}

async function updateUser(req, res, next) {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    // Remove sensitive fields that shouldn't be updated this way
    delete updates.password;
    delete updates.role;
    delete updates.isDeleted;

    const user = await User.findOneAndUpdate(
      { _id: id, isDeleted: false },
      updates,
      { new: true, runValidators: true }
    );

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    return res.json({ success: true, data: user.toSafeObject() });
  } catch (err) {
    next(err);
  }
}

async function deleteUser(req, res, next) {
  try {
    const { id } = req.params;
    
    const user = await User.findByIdAndUpdate(id, { isDeleted: true }, { new: true });
    
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    return res.json({ success: true, message: 'User deleted successfully (soft delete)' });
  } catch (err) {
    next(err);
  }
}

async function updateLead(req, res, next) {
  try {
    const { id } = req.params;
    const updates = req.body;
    
    const lead = await Lead.findOneAndUpdate(
      { _id: id, isDeleted: false },
      updates,
      { new: true, runValidators: true }
    );

    if (!lead) {
      return res.status(404).json({ success: false, message: 'Lead not found' });
    }

    return res.json({ success: true, data: lead });
  } catch (err) {
    next(err);
  }
}

async function deleteLead(req, res, next) {
  try {
    const { id } = req.params;
    
    const lead = await Lead.findByIdAndUpdate(id, { isDeleted: true }, { new: true });
    
    if (!lead) {
      return res.status(404).json({ success: false, message: 'Lead not found' });
    }

    return res.json({ success: true, message: 'Lead deleted successfully (soft delete)' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  createUser,
  updateUser,
  deleteUser,
  updateLead,
  deleteLead
};
