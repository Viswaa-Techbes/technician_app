const mongoose = require('mongoose');

const attendanceSchema = new mongoose.Schema({
  userId: { 
    type: mongoose.Schema.Types.ObjectId, 
    ref: 'User', 
    required: true 
  },
  date: { 
    type: String, 
    required: true,
    // Format: YYYY-MM-DD
  },
  loginTime: { 
    type: Date, 
    required: true 
  },
  logoutTime: { 
    type: Date 
  },
  status: { 
    type: String, 
    enum: ['present', 'absent', 'late'], 
    default: 'present' 
  },
  workingHours: { 
    type: Number, 
    default: 0 
  }
}, { timestamps: true });

attendanceSchema.index({ userId: 1, date: 1 }, { unique: true });

module.exports = mongoose.model('Attendance', attendanceSchema);
