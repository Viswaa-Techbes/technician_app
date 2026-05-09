const VisitorAnalytics = require('../../models/VisitorAnalytics');

// Simple in-memory cache for aggregated endpoints to reduce DB load
const _cache = {
  dashboard: { ts: 0, ttl: 8_000, data: null },
};

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
    const { page = '/', country, state, city, eventType, serviceName, domain, sessionId, referral, os, metadata } = req.body || {};
    const { browser, device } = parseUserAgent(req.headers['user-agent']);
    const safeIp = getClientIp(req);

    // Fire-and-forget style write to avoid slowing request path.
    const doc = await VisitorAnalytics.create({
      domain: domain || serviceName || 'unknown',
      sessionId: sessionId || 'unknown',
      referral: referral || '',
      os: os || 'unknown',
      ip: safeIp,
      country: country || 'unknown',
      state: state || 'unknown',
      city: city || 'unknown',
      browser,
      device,
      page,
      eventType: eventType || 'page_view',
      visitedAt: new Date(),
      metadata: metadata || {},
    });

    return res.status(202).json({ success: true });
  } catch (err) {
    return next(err);
  }
}

async function getDashboard(req, res, next) {
  try {
    const { domain } = req.query;
    const cacheKey = domain ? `dashboard_${domain}` : 'dashboard_all';
    const nowTs = Date.now();
    if (_cache[cacheKey] && (nowTs - _cache[cacheKey].ts) < _cache[cacheKey].ttl) {
      return res.json({ success: true, data: _cache[cacheKey].data });
    }
    
    const now = new Date();
    const startOfDay = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const startOfWeek = new Date(now);
    startOfWeek.setDate(now.getDate() - 7);
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const matchDomain = domain ? { domain } : {};

    const [totalVisitors, todayVisitors, topPages, topCities, conversion, leadsCount, returningAgg] = await Promise.all([
      VisitorAnalytics.countDocuments(matchDomain),
      VisitorAnalytics.countDocuments({ ...matchDomain, visitedAt: { $gte: startOfDay } }),
      VisitorAnalytics.aggregate([
        { $match: matchDomain },
        { $group: { _id: '$page', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 },
      ]),
      VisitorAnalytics.aggregate([
        { $match: matchDomain },
        { $group: { _id: '$city', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 10 },
      ]),
      VisitorAnalytics.aggregate([
        {
          $match: {
            ...matchDomain,
            eventType: { $in: ['service_viewed', 'booking_started', 'booking_completed', 'payment_completed'] },
            visitedAt: { $gte: startOfMonth },
          },
        },
        { $group: { _id: '$eventType', count: { $sum: 1 } } },
      ]),
      VisitorAnalytics.countDocuments({ ...matchDomain, eventType: 'lead_submitted' }),
      VisitorAnalytics.aggregate([
        { $match: matchDomain },
        { $group: { _id: '$sessionId', count: { $sum: 1 } } },
        { $match: { count: { $gt: 1 }, _id: { $ne: 'unknown' } } },
        { $count: "returning" }
      ])
    ]);

    const trends = await VisitorAnalytics.aggregate([
      { $match: { ...matchDomain, visitedAt: { $gte: startOfWeek } } },
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
    const payload = {
      totalVisitors,
      todayVisitors,
      liveVisitors: todayVisitors,
      leads: leadsCount,
      returningVisitors: returningAgg[0]?.returning || 0,
      topPages: topPages.map((x) => ({ page: x._id || '/', visitors: x.count })),
      topCities: topCities.map((x) => ({ city: x._id || 'unknown', visitors: x.count })),
      conversionFunnel: conversion.map((x) => ({ stage: x._id, count: x.count })),
      trafficTrends: trends.map((t) => ({ date: `${t._id.day}/${t._id.month}`, visitors: t.visitors })),
    };
    
    _cache[cacheKey] = { ts: Date.now(), ttl: 8_000, data: payload };
    return res.json({ success: true, data: payload });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  trackVisitor,
  getDashboard,
};

// City-level detail: top pages & trends for a specific city
async function getCityDetail(req, res, next) {
  try {
    const city = req.params.city || 'unknown';
    const now = new Date();
    // support optional query range: ?from=YYYY-MM-DD&to=YYYY-MM-DD
    const fromQ = req.query.from;
    const toQ = req.query.to;
    const startOfWeek = fromQ ? new Date(fromQ) : new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7);
    const endDate = toQ ? new Date(toQ) : now;

    const [topPages, trends] = await Promise.all([
      VisitorAnalytics.aggregate([
        { $match: { city: city, visitedAt: { $gte: startOfWeek, $lte: endDate } } },
        { $group: { _id: '$page', count: { $sum: 1 } } },
        { $sort: { count: -1 } },
        { $limit: 50 },
      ]),
      VisitorAnalytics.aggregate([
        { $match: { city: city, visitedAt: { $gte: startOfWeek, $lte: endDate } } },
        { $group: { _id: { year: { $year: '$visitedAt' }, month: { $month: '$visitedAt' }, day: { $dayOfMonth: '$visitedAt' } }, count: { $sum: 1 } } },
        { $sort: { '_id.year': 1, '_id.month': 1, '_id.day': 1 } },
      ]),
    ]);

    const trendFormatted = trends.map(t => ({ date: `${t._id.day}/${t._id.month}`, visitors: t.count }));

    // Additional aggregates: avg session duration, unique visitors, returning vs new
    const extraAgg = await VisitorAnalytics.aggregate([
      { $match: { city: city, visitedAt: { $gte: startOfWeek, $lte: endDate } } },
      {
        $group: {
          _id: null,
          avgSession: { $avg: '$metadata.sessionDuration' },
          total: { $sum: 1 },
          uniqueIPs: { $addToSet: '$ip' },
        },
      },
    ]);

    const extras = (extraAgg && extraAgg[0]) ? {
      avgSessionDuration: extraAgg[0].avgSession || 0,
      totalHits: extraAgg[0].total || 0,
      uniqueVisitors: (extraAgg[0].uniqueIPs || []).length,
    } : { avgSessionDuration: 0, totalHits: 0, uniqueVisitors: 0 };

    return res.json({ success: true, data: { city, topPages: topPages.map(p => ({ page: p._id, visitors: p.count })), trends: trendFormatted, extras } });
  } catch (err) { return next(err); }
}

module.exports.getCityDetail = getCityDetail;
