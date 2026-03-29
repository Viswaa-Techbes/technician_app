const path = require('path');
const dns = require('dns');

// Helps some Windows / Node 17+ setups where IPv6-first DNS causes odd connection behaviour.
if (typeof dns.setDefaultResultOrder === 'function') {
  dns.setDefaultResultOrder('ipv4first');
}

// Load BE/.env regardless of current working directory (fixes nodemon run from repo root).
// override: true ensures values in .env win over stale Windows/system MONGODB_URI (e.g. localhost).
require('dotenv').config({
  path: path.join(__dirname, '.env'),
  override: true,
});

const connectDB = require('./config/db');
const app = require('./app');

const PORT = Number(process.env.PORT) || 5000;

async function start() {
  try {
    await connectDB();
    app.listen(PORT, () => {
      console.log(`API listening on http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error('Failed to start server:', err.message || err);
    process.exit(1);
  }
}

start();
