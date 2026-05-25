console.log("Starting server...");

const path = require('path');
const dns = require('dns');

// Helps some Windows / Node 17+ setups where IPv6-first DNS causes odd connection behaviour.
if (typeof dns.setDefaultResultOrder === 'function') {
  dns.setDefaultResultOrder('ipv4first');
}

// Global Error Handlers for Stability on Render
process.on('uncaughtException', err => {
  console.error("CRITICAL: Uncaught Exception:", err.message);
  console.error(err.stack);
});

process.on('unhandledRejection', (reason, promise) => {
  console.error("CRITICAL: Unhandled Rejection at:", promise, "reason:", reason);
});

// Load BE/.env
require('dotenv').config({
  path: path.join(__dirname, '.env')
});

const http = require('http');
const { Server } = require('socket.io');
const connectDB = require('./config/db');
const app = require('./app');

const PORT = process.env.PORT || 5000;
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Store io in app to use in controllers if needed
app.set('io', io);

io.on('connection', (socket) => {
  console.log('Socket Client connected:', socket.id);

  socket.on('join', (userId) => {
    socket.join(userId);
    console.log(`User ${userId} joined room`);
  });

  socket.on('update_location', (data) => {
    io.emit('technicianLocationUpdate', {
        technicianId: data.userId,
        lat: data.lat,
        lng: data.lng,
        name: data.name,
        isOnline: true
    });
  });

  socket.on('disconnect', () => {
    console.log('Socket Client disconnected');
  });
});

async function start() {
  // Start listening IMMEDIATELY so Render detects the open port
  server.listen(PORT, '0.0.0.0', async () => {
    console.log(`--------------------------------------------------`);
    console.log(`SERVER IS LIVE ON PORT ${PORT}`);
    console.log(`Environment: ${process.env.NODE_ENV || 'production'}`);
    console.log(`Binds to: 0.0.0.0:${PORT}`);
    console.log(`--------------------------------------------------`);

    try {
      console.log("Connecting to Database...");
      await connectDB();
      console.log("Database connected successfully.");
    } catch (err) {
      console.error('CRITICAL: Failed to connect to database:', err.message || err);
      // We don't exit here so the process stays alive and Render doesn't restart it immediately
      // This allows us to see the error in logs more easily.
    }

    try {
      console.log("Validating SMTP Email Configuration...");
      const { verifySmtpConfig } = require('./services/emailService');
      await verifySmtpConfig();
    } catch (err) {
      console.error('SMTP Validation Error during startup:', err.message || err);
    }
  });
}

start();
