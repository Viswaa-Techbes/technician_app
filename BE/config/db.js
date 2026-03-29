const mongoose = require('mongoose');

/**
 * Connects to MongoDB (Atlas or local) using MONGODB_URI from environment.
 */
async function connectDB() {
  const uri = process.env.MONGODB_URI?.trim();
  if (!uri) {
    throw new Error('MONGODB_URI is not set in environment variables');
  }

  if (process.env.NODE_ENV !== 'production') {
    const hint = uri.startsWith('mongodb+srv://')
      ? 'Atlas (mongodb+srv)'
      : uri.includes('127.0.0.1') || uri.includes('localhost')
        ? 'local MongoDB'
        : 'MongoDB';
    console.log(`[db] Connecting to ${hint}`);
  }

  mongoose.set('strictQuery', true);

  try {
    await mongoose.connect(uri, {
      serverSelectionTimeoutMS: 20_000,
      // Prefer IPv4 when resolving Atlas hostnames (helps on some networks).
      family: 4,
    });
  } catch (err) {
    const msg = err?.message ?? String(err);
    if (msg.includes('querySrv') || msg.includes('_mongodb._tcp')) {
      console.error(
        '\n[db] Atlas SRV DNS lookup failed. This is a network/DNS issue, not your password.\n' +
          '  • In Atlas: Database → Connect → Drivers → use the Standard connection string (mongodb://… with host list), not mongodb+srv://\n' +
          '  • Or fix DNS: set Windows DNS to 8.8.8.8 / 1.1.1.1, disable VPN/proxy blocking DNS, allow outbound DNS (port 53)\n' +
          '  • Corporate firewalls sometimes block SRV lookups — try phone hotspot to confirm.\n'
      );
    }
    throw err;
  }

  console.log('MongoDB connected');
}

module.exports = connectDB;
