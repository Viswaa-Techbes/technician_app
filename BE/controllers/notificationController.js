const Notification = require('../models/Notification');

/**
 * GET /notifications
 * Get current user notifications
 */
async function getNotifications(req, res, next) {
  try {
    const notifications = await Notification.find({ userId: req.user.id })
      .sort({ createdAt: -1 })
      .limit(50);

    return res.json({
      success: true,
      data: notifications,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /notifications/:id/read
 * Mark notification as read
 */
async function markAsRead(req, res, next) {
  try {
    const { id } = req.params;
    const notification = await Notification.findOneAndUpdate(
      { _id: id, userId: req.user.id },
      { isRead: true },
      { new: true }
    );

    if (!notification) {
      return res.status(404).json({ success: false, message: 'Notification not found' });
    }

    return res.json({
      success: true,
      data: notification,
    });
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /notifications/read-all
 * Mark all notifications for current user as read
 */
async function markAllAsRead(req, res, next) {
  try {
    const result = await Notification.updateMany(
      { userId: req.user.id, isRead: false },
      { isRead: true }
    );
    return res.json({
      success: true,
      message: 'All notifications marked as read',
      modifiedCount: result.modifiedCount,
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  getNotifications,
  markAsRead,
  markAllAsRead,
};
