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

const http = require('http');
const { Server } = require('socket.io');
const connectDB = require('./config/db');
const app = require('./app');

const PORT = Number(process.env.PORT) || 5000;
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
  console.log('New client connected:', socket.id);

  socket.on('join', (userId) => {
    socket.join(userId);
    console.log(`User ${userId} joined room`);
  });

  socket.on('update_location', (data) => {
    // data: { userId, lat, lng }
    io.emit('location_updated', data); // Broadcast to all (ideally filter by manager)
  });

  socket.on('disconnect', () => {
    console.log('Client disconnected');
  });
});

async function start() {
  try {
    await connectDB();
    server.listen(PORT, () => {
      console.log(`API + Realtime listening on http://localhost:${PORT}`);
    });
  } catch (err) {
    console.error('Failed to start server:', err.message || err);
    process.exit(1);
  }
}

start();
