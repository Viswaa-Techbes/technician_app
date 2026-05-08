const VisitorAnalytics = require('../../models/VisitorAnalytics');

function getClientIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.ip || req.socket?.remoteAddress || 'unknown';
}

function parseUserAgent(ua = '') {
  const raw = String(ua).toLowerCase();
  const browser = raw.includes('edg') ? 'Edge' : raw.includes('chrome') ? 'Chrome' : raw.includes('firefox') ? 'Firefox' : raw.includes('safari') ? 'Safari' : 'Unknown';
  const device = /mobile|android|iphone|ipad/.test(raw) ? 'Mobile' : 'Desktop';
  return { browser, device };
}

async function trackVisitor(req, res, next) {
  try {
    const { page = '/', country, state, city, eventType, serviceName, metadata } = req.body || {};
    const { browser, device } = parseUserAgent(req.headers['user-agent']);
    const safeIp = getClientIp(req);

    // Fire-and-forget style write to avoid slowing request path.
    VisitorAnalytics.create({
      ip: safeIp,
      country: country || 'unknown',
      state: state || 'unknown',
      city: city || 'unknown',
      browser,
      device,
      page,
      eventType: eventType || 'page_view',
      serviceName,
      visitedAt: new Date(),
      metadata: metadata || {},
    }).catch(() => {});

    return res.status(202).json({ success: true });
  } catch (err) {
    return next(err);
  }
}

async function getDashboard(req, res, next) {
  try {
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - 7);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [totalVisitors, todayVisitors, topPages, topCities, conversion] = await Promise.all([
      VisitorAnalytics.countDocuments({}),
      VisitorAnalytics.countDocuments({ visitedAt: { $gte: startOfDay } }),
      VisitorAnalytics.aggregate([
        { $group: { _id: '$page', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 },
      ]),
      VisitorAnalytics.aggregate([
        { $group: { _id: '$city', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 },
      ]),
      VisitorAnalytics.aggregate([
        {
          $match: {
            eventType: { $in: ['service_viewed', 'booking_started', 'booking_completed', 'payment_completed'] },
            visitedAt: { $gte: startOfMonth },
          },
        },
        { $group: { _id: '$eventType', count: { $sum: 1 } } },
      ]),
    ]);

    const trends = await VisitorAnalytics.aggregate([
      { $match: { visitedAt: { $gte: startOfWeek } } },
      {
        $group: {
          _id: {
            year: { $year: '$visitedAt' },
            month: { $month: '$visitedAt' },
            day: { $dayOfMonth: '$visitedAt' },
          },
          visitors: { $sum: 1 },
        },
      },
      { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } },
    ]);

    return res.json({
      success: true,
      data: {
        totalVisitors,
        todayVisitors,
        liveVisitors: todayVisitors,
        topPages: topPages.map((x) => ({ page: x._id || '/', visitors: x.count })),
        topCities: topCities.map((x) => ({ city: x._id || 'unknown', visitors: x.count })),
        conversionFunnel: conversion.map((x) => ({ stage: x._id, count: x.count })),
        trafficTrends: trends.map((t) => ({
          date: `${t._id.day}/${t._id.month}`,
          visitors: t.visitors,
        })),
      },
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  trackVisitor,
  getDashboard,
};
