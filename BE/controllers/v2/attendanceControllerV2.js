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

module.exports = {
  checkIn,
  checkOut,
  getHistory,
};
