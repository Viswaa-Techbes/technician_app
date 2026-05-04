const jobServiceV2 = require('../../services/jobServiceV2');

async function updateLocation(req, res, next) {
  try {
    const { lat, lng, isOnline } = req.body;
    const loc = await jobServiceV2.updateLiveLocation(req.user.id, lat, lng);
    
    // Also update User model for basic tracking
    const User = require('../../models/User');
    await User.findByIdAndUpdate(req.user.id, {
      lat,
      lng,
      ...(isOnline !== undefined && { isOnline }),
      lastSeen: new Date()
    });

    // Broadcast to global or specific rooms (e.g. clients who have an active job with this tech)
    const io = req.app.get('io');
    io.emit('technicianLocationUpdate', {
      technicianId: req.user.id,
      lat,
      lng,
      isOnline: isOnline ?? true
    });

    res.json({ success: true, data: loc });
  } catch (err) {
    next(err);
  }
}

async function getLiveLocation(req, res, next) {
  try {
    const { technicianId } = req.params;
    const loc = await jobServiceV2.getTechnicianLocation(technicianId);
    if (!loc) return res.status(404).json({ success: false, message: 'Location not found' });
    
    res.json({ success: true, data: loc });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  updateLocation,
  getLiveLocation,
};
