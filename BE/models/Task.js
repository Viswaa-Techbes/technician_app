const mongoose = require('mongoose');

const TASK_STATUSES = ['assigned', 'inProgress', 'pendingApproval', 'completed', 'cancelled'];

const taskSchema = new mongoose.Schema(
  {
    serviceName: {
      type: String,
      required: [true, 'Service Name is required'],
      trim: true,
    },
    description: {
      type: String,
      default: '',
      trim: true,
    },
    customerName: {
      type: String,
      default: 'Client',
    },
    customerPhone: {
      type: String,
      default: '',
    },
    address: {
      type: String,
      required: [true, 'Address is required'],
    },
    time: {
      type: String,
      default: 'ASAP',
    },
    status: {
      type: String,
      enum: TASK_STATUSES,
      default: 'assigned',
    },
    price: {
      type: Number,
      default: 0.0,
    },
    assignedTo: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: false, // Can be unassigned initially
    },
    technicianName: {
      type: String,
    },
    assignedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: [true, 'assignedBy (manager) is required'],
    },
    notes: {
      type: String,
      default: '',
    },
    latitude: Number,
    longitude: Number,
    googleMapsLink: String,
    fileAttachments: [String],
    timerDurationSeconds: {
      type: Number,
      default: 0,
    },
  },
  { timestamps: true }
);

taskSchema.index({ assignedTo: 1, status: 1 });
taskSchema.index({ assignedBy: 1, createdAt: -1 });

module.exports = mongoose.model('Task', taskSchema);
module.exports.TASK_STATUSES = TASK_STATUSES;
