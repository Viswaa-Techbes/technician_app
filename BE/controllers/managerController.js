const User = require('../models/User');
const Task = require('../models/Task');
const Expense = require('../models/Expense');
const Review = require('../models/Review');

async function dashboard(req, res, next) {
  try {
    const managerId = req.user.id;
    const [techs, tasks, expenses] = await Promise.all([
      User.find({ role: 'technician' }).lean(),
      Task.find({ assignedBy: managerId }).lean(),
      Expense.find({ status: 'pending' }).lean(),
    ]);

    return res.json({
      success: true,
      data: {
        totalTechnicians: techs.length,
        onlineTechnicians: techs.filter(t => t.isOnline).length,
        jobsAssigned: tasks.length,
        jobsInProgress: tasks.filter(t => t.status === 'inProgress').length,
        pendingCompletionApprovals: tasks.filter(t => t.status === 'pendingApproval').length,
        pendingExpenses: expenses.length,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function listTechnicians(req, res, next) {
  try {
    const technicians = await User.find({ role: 'technician' })
      .sort({ name: 1 })
      .lean();

    return res.json({ 
      success: true, 
      data: technicians.map(u => ({
        id: u._id.toString(),
        name: u.name,
        email: u.email,
        status: u.status,
        isOnline: u.isOnline,
        lat: u.lat,
        lng: u.lng,
        phoneNumber: u.phoneNumber,
        specialty: u.specialty,
      }))
    });
  } catch (err) {
    next(err);
  }
}

async function listTasks(req, res, next) {
  try {
    const tasks = await Task.find({ assignedBy: req.user.id })
      .sort({ createdAt: -1 })
      .populate('assignedTo', 'name email role status')
      .lean();

    return res.json({ success: true, data: tasks.map(formatTask) });
  } catch (err) {
    next(err);
  }
}

async function assignTask(req, res, next) {
  try {
    const { serviceName, address, technicianId, customerName, customerPhone, time, price, description } = req.body;
    
    if (!serviceName || !address) {
      return res.status(400).json({ success: false, message: 'serviceName and address are required' });
    }

    let techName = '';
    if (technicianId) {
       const tech = await User.findOne({ _id: technicianId, role: 'technician' });
       if (!tech) return res.status(404).json({ success: false, message: 'Technician not found' });
       techName = tech.name;
    }

    const task = await Task.create({
      serviceName,
      address,
      description,
      customerName,
      customerPhone,
      time,
      price,
      assignedTo: technicianId,
      technicianName: techName,
      assignedBy: req.user.id,
      status: 'assigned',
    });

    return res.status(201).json({ success: true, data: formatTask(task) });
  } catch (err) {
    next(err);
  }
}

async function listExpenditures(req, res, next) {
  try {
    const expenses = await Expense.find()
      .populate('technicianId', 'name email')
      .populate('projectId', 'serviceName')
      .sort({ createdAt: -1 })
      .lean();
    return res.json({ success: true, data: expenses });
  } catch (err) {
    next(err);
  }
}

async function approveExpenditure(req, res, next) {
  try {
    const { expenseId } = req.params;
    const { status } = req.body; // 'approved' or 'rejected'

    const expense = await Expense.findByIdAndUpdate(expenseId, { status }, { new: true });
    if (!expense) return res.status(404).json({ success: false, message: 'Expense not found' });

    return res.json({ success: true, data: expense });
  } catch (err) {
    next(err);
  }
}

async function getTechnicianReviews(req, res, next) {
  try {
    const { techId } = req.params;
    const reviews = await Review.find({ technicianId: techId }).sort({ createdAt: -1 }).lean();
    return res.json({ success: true, data: reviews });
  } catch (err) {
    next(err);
  }
}

function formatTask(t) {
  return {
    id: t._id.toString(),
    serviceName: t.serviceName,
    description: t.description,
    status: t.status,
    address: t.address,
    customerName: t.customerName,
    technicianName: t.technicianName,
    price: t.price,
    assignedTo: t.assignedTo,
    createdAt: t.createdAt,
  };
}

module.exports = {
  dashboard,
  listTechnicians,
  listTasks,
  assignTask,
  listExpenditures,
  approveExpenditure,
  getTechnicianReviews,
};
