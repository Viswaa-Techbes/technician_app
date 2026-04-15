const Notification = require('../models/Notification');

/**
 * Create and persist a notification
 * @param {string} userId - Recipient ID
 * @param {string} title - Notification title
 * @param {string} message - Notification content
 * @param {string} type - Notification type enum
 * @param {object} io - Socket.io instance (optional)
 */
async function createNotification(userId, title, message, type = 'general', io = null) {
  try {
    const notification = await Notification.create({
      userId,
      title,
      message,
      type,
    });

    if (io) {
      io.to(userId.toString()).emit('notification', {
        id: notification._id,
        title,
        message,
        type,
        createdAt: notification.createdAt,
      });
    }

    return notification;
  } catch (err) {
    console.error('Failed to create notification:', err);
  }
}

module.exports = {
  createNotification,
};
