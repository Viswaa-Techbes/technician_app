const mongoose = require('mongoose');

const visitorAnalyticsSchema = new mongoose.Schema(
  {
    ip: { type: String, trim: true },
    country: { type: String, trim: true, default: 'unknown' },
    state: { type: String, trim: true, default: 'unknown' },
    city: { type: String, trim: true, default: 'unknown' },
    browser: { type: String, trim: true, default: 'unknown' },
    device: { type: String, trim: true, default: 'unknown' },
    page: { type: String, trim: true, default: '/' },
    eventType: {
      type: String,
      enum: ['page_view', 'service_viewed', 'booking_started', 'booking_completed', 'payment_completed'],
      default: 'page_view',
      index: true,
    },
    serviceName: { type: String, trim: true },
    visitedAt: { type: Date, default: Date.now, index: true },
    metadata: { type: mongoose.Schema.Types.Mixed },
  },
  { timestamps: true }
);

visitorAnalyticsSchema.index({ page: 1, visitedAt: -1 });
visitorAnalyticsSchema.index({ city: 1, visitedAt: -1 });
visitorAnalyticsSchema.index({ eventType: 1, visitedAt: -1 });

module.exports = mongoose.model('VisitorAnalytics', visitorAnalyticsSchema, 'visitorAnalytics');
