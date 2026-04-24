const jobServiceV2 = require('../../services/jobServiceV2');

async function updateLocation(req, res, next) {
  try {
    const { lat, lng } = req.body;
    const loc = await jobServiceV2.updateLiveLocation(req.user.id, lat, lng);
    
    // Broadcast to global or specific rooms (e.g. clients who have an active job with this tech)
    const io = req.app.get('io');
    io.emit('technicianLocationUpdate', {
      technicianId: req.user.id,
      lat,
      lng
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
