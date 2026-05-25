const express = require('express');
const cors = require('cors');
const path = require('path');

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
const uploadRoutesV2 = require('./routes/v2/uploadRoutesV2');
const analyticsRoutesV2 = require('./routes/v2/analyticsRoutesV2');
// visitor analytics legacy routes are still required for compatibility but
// have been disabled. Keep the import to avoid module resolution errors.
const visitorAnalyticsRoutesV2 = require('./routes/v2/visitorAnalyticsRoutesV2');
const careerRoutesV2 = require('./routes/v2/careerRoutesV2');
const courseRoutesV2 = require('./routes/v2/courseRoutesV2');
const admissionRoutesV2 = require('./routes/v2/admissionRoutesV2');

const errorHandler = require('./middlewares/errorHandler');

const app = express();

app.use(cors({
  origin: '*',
  credentials: true,
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve uploaded files statically
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

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

// Backwards-compatible API aliases used by frontends
app.use('/api/bookings', bookingRoutesV2);
app.use('/api/payments', paymentRoutesV2);
app.use('/api/v2/location', locationRoutesV2);
app.use('/api/v2/admin', adminRoutesV2);
app.use('/api/v2/upload', uploadRoutesV2);
app.use('/api/v2/analytics', analyticsRoutesV2);
// Keep legacy visitor analytics route registered (handlers return 410).
app.use('/api/v2/analytics/visitors', visitorAnalyticsRoutesV2);
app.use('/api/v2/careers', careerRoutesV2);
app.use('/api/v2', courseRoutesV2);
app.use('/api/v2/admission', admissionRoutesV2);

app.use((req, res) => {
  res.status(404).json({ success: false, message: 'Route not found' });
});

app.use(errorHandler);

module.exports = app;
