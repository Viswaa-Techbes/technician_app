const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/authRoutes');
const adminRoutes = require('./routes/adminRoutes');
const managerRoutes = require('./routes/managerRoutes');
const technicianRoutes = require('./routes/technicianRoutes');
const jobRoutes = require('./routes/jobRoutes');
const expenseRoutes = require('./routes/expenseRoutes');
const reviewRoutes = require('./routes/reviewRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const leadRoutes = require('./routes/leadRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const attendanceRoutes = require('./routes/attendanceRoutes');

// V2 Routes
const jobRoutesV2 = require('./routes/v2/jobRoutesV2');
const paymentRoutesV2 = require('./routes/v2/paymentRoutesV2');
const attendanceRoutesV2 = require('./routes/v2/attendanceRoutesV2');
const notificationRoutesV2 = require('./routes/v2/notificationRoutesV2');
const bookingRoutesV2 = require('./routes/v2/bookingRoutesV2');
const locationRoutesV2 = require('./routes/v2/locationRoutesV2');
const adminRoutesV2 = require('./routes/v2/adminRoutesV2');

const errorHandler = require('./middlewares/errorHandler');

const app = express();

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.get('/health', (req, res) => {
  res.json({ success: true, status: 'ok', timestamp: new Date().toISOString() });
});

app.use('/auth', authRoutes);
app.use('/', authRoutes);
app.use('/admin', adminRoutes);
app.use('/managers', managerRoutes);
app.use('/manager', managerRoutes); // Alias
app.use('/technicians', technicianRoutes);
app.use('/technician', technicianRoutes); // Alias
app.use('/jobs', jobRoutes);
app.use('/expenses', expenseRoutes);
app.use('/reviews', reviewRoutes);
app.use('/notifications', notificationRoutes);
app.use('/leads', leadRoutes);
app.use('/', paymentRoutes);
app.use('/attendance', attendanceRoutes);

// V2 APIs
app.use('/api/v2/jobs', jobRoutesV2);
app.use('/api/v2/payment', paymentRoutesV2);
app.use('/api/v2/attendance', attendanceRoutesV2);
app.use('/api/v2/notifications', notificationRoutesV2);
app.use('/api/v2/bookings', bookingRoutesV2);
app.use('/api/v2/location', locationRoutesV2);
app.use('/api/v2/admin', adminRoutesV2);

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

app.use(errorHandler);

module.exports = app;
