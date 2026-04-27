const attendanceService = require('../../services/attendanceService');

async function checkIn(req, res, next) {
  try {
    const { lat, lng, address } = req.body;
    const attendance = await attendanceService.checkIn(req.user.id, { lat, lng, address });
    res.json({ success: true, data: attendance });
  } catch (err) {
    next(err);
  }
}

async function checkOut(req, res, next) {
  try {
    const attendance = await attendanceService.checkOut(req.user.id);
    res.json({ success: true, data: attendance });
  } catch (err) {
    next(err);
  }
}

async function getHistory(req, res, next) {
  try {
    const { startDate, endDate } = req.query;
    const history = await attendanceService.getAttendanceHistory(req.user.id, startDate, endDate);
    res.json({ success: true, data: history });
  } catch (err) {
    next(err);
  }
}

async function getAdminAttendance(req, res, next) {
  try {
    const { date, month, year } = req.query;
    const history = await attendanceService.getAllAttendance({ date, month, year });
    
    const formatted = history.map(record => {
      const checkIn = record.checkIn ? new Date(record.checkIn) : null;
      const checkOut = record.checkOut ? new Date(record.checkOut) : null;
      
      let workingHours = '0';
      if (checkIn && checkOut) {
        workingHours = ((checkOut - checkIn) / (1000 * 60 * 60)).toFixed(2);
      } else if (checkIn && !checkOut && record.date === new Date().toISOString().split('T')[0]) {
        workingHours = ((new Date() - checkIn) / (1000 * 60 * 60)).toFixed(2);
      }

      return {
        userId: record.user?._id,
        name: record.user?.name || 'Unknown',
        role: record.user?.role,
        date: record.date,
        loginTime: record.checkIn,
        logoutTime: record.checkOut,
        status: record.status,
        workingHours: workingHours
      };
    });

    res.json({ success: true, data: formatted });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  checkIn,
  checkOut,
  getHistory,
  getAdminAttendance,
};
