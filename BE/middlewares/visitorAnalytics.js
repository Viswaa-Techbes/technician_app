const VisitorAnalytics = require('../models/VisitorAnalytics');

function extractIp(req) {
  const forwarded = req.headers['x-forwarded-for'];
  if (typeof forwarded === 'string' && forwarded.length > 0) {
    return forwarded.split(',')[0].trim();
  }
  return req.ip || req.socket?.remoteAddress || 'unknown';
}

function parseUserAgent(ua = '') {
  const lower = String(ua).toLowerCase();
  const browser = lower.includes('edg') ? 'Edge' : lower.includes('chrome') ? 'Chrome' : lower.includes('firefox') ? 'Firefox' : lower.includes('safari') ? 'Safari' : 'Unknown';
  const device = /mobile|android|iphone|ipad/.test(lower) ? 'Mobile' : 'Desktop';
  return { browser, device };
}

function visitorAnalyticsMiddleware(req, res, next) {
  const shouldTrack =
    req.method === 'GET' &&
    !req.path.startsWith('/health') &&
    !req.path.startsWith('/uploads') &&
    !req.path.startsWith('/api/v2/analytics/visitors');

  if (!shouldTrack) return next();

  const { browser, device } = parseUserAgent(req.headers['user-agent']);
  const ip = extractIp(req);
  const page = req.originalUrl || req.path || '/';

  setImmediate(() => {
    VisitorAnalytics.create({
      ip,
      browser,
      device,
      page,
      visitedAt: new Date(),
      country: 'unknown',
      state: 'unknown',
      city: 'unknown',
      eventType: 'page_view',
    }).catch(() => {});
  });

  return next();
}

module.exports = { visitorAnalyticsMiddleware };
