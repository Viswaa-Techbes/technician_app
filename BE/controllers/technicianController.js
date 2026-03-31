const Task = require('../models/Task');
const User = require('../models/User');
const Expense = require('../models/Expense');
const Review = require('../models/Review');

async function dashboard(req, res, next) {
  try {
    const techId = req.user.id;
    const [tasks, reviews, profile] = await Promise.all([
      Task.find({ assignedTo: techId }).lean(),
      Review.find({ technicianId: techId }).lean(),
      User.findById(techId).lean(),
    ]);

    const completedTasks = tasks.filter(t => t.status === 'completed');
    const totalRating = reviews.reduce((sum, r) => sum + r.rating, 0);
    const avgRating = reviews.length > 0 ? (totalRating / reviews.length).toFixed(1) : 0;

    return res.json({
      success: true,
      data: {
        totalJobs: tasks.length,
        pendingJobs: tasks.filter(t => t.status === 'assigned').length,
        inProgress: tasks.filter(t => t.status === 'inProgress').length,
        completed: completedTasks.length,
        avgRating,
        totalReviews: reviews.length,
        isOnline: profile.isOnline,
        status: profile.status,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function listTasks(req, res, next) {
  try {
    const tasks = await Task.find({ assignedTo: req.user.id })
      .sort({ updatedAt: -1 })
      .populate('assignedBy', 'name email role')
      .lean();

    return res.json({ 
      success: true, 
      data: tasks.map(t => ({
        id: t._id.toString(),
        serviceName: t.serviceName,
        customerName: t.customerName,
        customerPhone: t.customerPhone,
        address: t.address,
        time: t.time,
        status: t.status,
        price: t.price,
        notes: t.notes,
        googleMapsLink: t.googleMapsLink,
        createdAt: t.createdAt,
      }))
    });
  } catch (err) {
    next(err);
  }
}

async function updateTaskStatus(req, res, next) {
  try {
    const { taskId } = req.params;
    const { status, notes, durationSeconds } = req.body;
    
    // Validate status
    const allowed = ['assigned', 'inProgress', 'pendingApproval', 'completed'];
    if (status && !allowed.includes(status)) return res.status(400).json({ success: false, message: 'Invalid status' });

    const update = {};
    if (status) update.status = status;
    if (notes) update.notes = notes;
    if (durationSeconds) update.timerDurationSeconds = durationSeconds;

    const task = await Task.findOneAndUpdate({ _id: taskId, assignedTo: req.user.id }, update, { new: true });
    if (!task) return res.status(404).json({ success: false, message: 'Task not found' });

    return res.json({ success: true, data: task });
  } catch (err) {
    next(err);
  }
}

async function updateLocation(req, res, next) {
  try {
    const { lat, lng, isOnline, status } = req.body;
    const update = {};
    if (lat !== undefined) update.lat = lat;
    if (lng !== undefined) update.lng = lng;
    if (isOnline !== undefined) update.isOnline = isOnline;
    if (status !== undefined) update.status = status;

    const user = await User.findByIdAndUpdate(req.user.id, update, { new: true });
    return res.json({ success: true, data: { id: user._id, isOnline: user.isOnline, status: user.status, lat: user.lat, lng: user.lng } });
  } catch (err) {
    next(err);
  }
}

async function submitExpense(req, res, next) {
  try {
     const { description, amount, projectId, receiptUrl } = req.body;
     const expense = await Expense.create({
        description,
        amount,
        technicianId: req.user.id,
        projectId,
        receiptUrl,
        status: 'pending',
     });
     return res.status(201).json({ success: true, data: expense });
  } catch (err) {
    next(err);
  }
}

async function getMyReviews(req, res, next) {
  try {
    const reviews = await Review.find({ technicianId: req.user.id }).sort({ createdAt: -1 }).lean();
    return res.json({ success: true, data: reviews });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  dashboard,
  listTasks,
  updateTaskStatus,
  updateLocation,
  submitExpense,
  getMyReviews,
};
