const Attendance = require('../../models/Attendance');
const User = require('../../models/User');
const moment = require('moment');

/**
 * Mark Attendance (Login)
 */
async function markAttendance(userId) {
  try {
    const today = moment().format('YYYY-MM-DD');
    const user = await User.findById(userId);
    if (!user) return;

    const existing = await Attendance.findOne({ userId, date: today });
    if (!existing) {
      await Attendance.create({
        userId,
        name: user.name,
        role: user.role,
        date: today,
        loginTime: new Date(),
        status: 'present'
      });
      console.log(`[Attendance] Marked present for ${user.name} on ${today}`);
    }
  } catch (err) {
    console.error('[Attendance] Mark login error:', err.message);
  }
}

/**
 * Mark Logout
 */
async function markLogout(userId) {
  try {
    const today = moment().format('YYYY-MM-DD');
    const record = await Attendance.findOne({ userId, date: today });
    
    if (record && !record.logoutTime) {
      const now = new Date();
      const loginTime = record.loginTime;
      const hours = (now - loginTime) / (1000 * 60 * 60);
      
      record.logoutTime = now;
      record.workingHours = parseFloat(hours.toFixed(2));
      await record.save();
      console.log(`[Attendance] Marked logout for ${record.name}. Hours: ${record.workingHours}`);
    }
  } catch (err) {
    console.error('[Attendance] Mark logout error:', err.message);
  }
}

/**
 * Admin: Get Today's Attendance (with Absent logic)
 */
async function getTodayAttendance(req, res, next) {
  try {
    const today = moment().format('YYYY-MM-DD');
    
    // 1. Get all staff (technicians and managers)
    const staff = await User.find({ 
      role: { $in: ['technician', 'manager'] },
      isDeleted: { $ne: true }
    }).select('name role status isOnline').lean();

    // 2. Get today's attendance records
    const records = await Attendance.find({ date: today }).lean();
    const recordMap = new Map(records.map(r => [r.userId.toString(), r]));

    // 3. Merge and identify absents
    const results = staff.map(u => {
      const record = recordMap.get(u._id.toString());
      if (record) {
        return {
          id: record._id,
          userId: u._id,
          name: u.name,
          role: u.role,
          date: today,
          status: 'present',
          loginTime: record.loginTime,
          logoutTime: record.logoutTime,
          workingHours: record.workingHours
        };
      } else {
        return {
          id: `absent-${u._id}`,
          userId: u._id,
          name: u.name,
          role: u.role,
          date: today,
          status: 'absent',
          loginTime: null,
          logoutTime: null,
          workingHours: 0
        };
      }
    });

    return res.json({ success: true, data: results });
  } catch (err) {
    next(err);
  }
}

/**
 * Admin: Get Monthly Stats
 */
async function getMonthlyAttendance(req, res, next) {
  try {
    const { month, year } = req.query; // Expecting month (1-12) and year (YYYY)
    if (!month || !year) {
      return res.status(400).json({ success: false, message: 'month and year are required' });
    }

    const startOfMonth = moment(`${year}-${month}-01`, 'YYYY-MM-DD');
    const endOfMonth = startOfMonth.clone().endOf('month');

    const records = await Attendance.find({
      date: { 
        $gte: startOfMonth.format('YYYY-MM-DD'), 
        $lte: endOfMonth.format('YYYY-MM-DD') 
      }
    }).lean();

    // Group by user
    const stats = records.reduce((acc, r) => {
      const uid = r.userId.toString();
      if (!acc[uid]) {
        acc[uid] = { name: r.name, role: r.role, presentDays: 0, totalHours: 0 };
      }
      acc[uid].presentDays += 1;
      acc[uid].totalHours += r.workingHours || 0;
      return acc;
    }, {});

    return res.json({ success: true, data: Object.values(stats) });
  } catch (err) {
    next(err);
  }
}

/**
 * Get Attendance Range for a User (for Calendar)
 */
async function getAttendanceRange(req, res, next) {
  try {
    const { userId, month, year } = req.query;
    if (!userId || !month || !year) {
      return res.status(400).json({ success: false, message: 'userId, month and year are required' });
    }

    const startOfMonth = moment(`${year}-${month}-01`, 'YYYY-MM-DD');
    const endOfMonth = startOfMonth.clone().endOf('month');

    // 1. Get existing records
    const records = await Attendance.find({
      userId,
      date: { 
        $gte: startOfMonth.format('YYYY-MM-DD'), 
        $lte: endOfMonth.format('YYYY-MM-DD') 
      }
    }).lean();

    const recordMap = new Map(records.map(r => [r.date, r]));

    // 2. Generate full month list with absent logic
    const results = [];
    let current = startOfMonth.clone();
    while (current.isSameOrBefore(endOfMonth)) {
      const d = current.format('YYYY-MM-DD');
      const rec = recordMap.get(d);
      results.push({
        date: d,
        status: rec ? 'present' : 'absent',
        loginTime: rec?.loginTime || null,
        logoutTime: rec?.logoutTime || null,
        workingHours: rec?.workingHours || 0
      });
      current.add(1, 'day');
    }

    return res.json({ success: true, data: results });
  } catch (err) {
    next(err);
  }
}

// Export for routes
async function handleMarkAttendance(req, res, next) {
  try {
    await markAttendance(req.user.id);
    return res.json({ success: true, message: 'Attendance marked' });
  } catch (err) {
    next(err);
  }
}

async function handleLogoutAttendance(req, res, next) {
  try {
    await markLogout(req.user.id);
    return res.json({ success: true, message: 'Logout recorded' });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  markAttendance,
  markLogout,
  getTodayAttendance,
  getMonthlyAttendance,
  getAttendanceRange,
  handleMarkAttendance,
  handleLogoutAttendance
};
