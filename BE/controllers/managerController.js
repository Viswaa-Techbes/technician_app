const User = require('../models/User');
const Task = require('../models/Task');

async function dashboard(req, res, next) {
  try {
    const managerId = req.user.id;
    const [technicianCount, myTasks, pendingCount] = await Promise.all([
      User.countDocuments({ role: 'technician' }),
      Task.countDocuments({ assignedBy: managerId }),
      Task.countDocuments({ assignedBy: managerId, status: 'pending' }),
    ]);

    return res.json({
      success: true,
      data: {
        techniciansTotal: technicianCount,
        tasksAssignedByMe: myTasks,
        pendingTasks: pendingCount,
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

    const data = technicians.map((u) => ({
      id: u._id.toString(),
      name: u.name,
      email: u.email,
      role: u.role,
    }));

    return res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

/**
 * POST /manager/tasks/assign — create a task assigned to a technician.
 * Body: { title, description?, technicianId }
 */
async function assignTask(req, res, next) {
  try {
    const { title, description = '', technicianId } = req.body;
    if (!title || !technicianId) {
      return res.status(400).json({
        success: false,
        message: 'title and technicianId are required',
      });
    }

    const tech = await User.findOne({ _id: technicianId, role: 'technician' });
    if (!tech) {
      return res.status(404).json({
        success: false,
        message: 'Technician not found',
      });
    }

    const task = await Task.create({
      title: title.trim(),
      description: String(description).trim(),
      assignedTo: technicianId,
      assignedBy: req.user.id,
      status: 'pending',
    });

    await task.populate([
      { path: 'assignedTo', select: 'name email role' },
      { path: 'assignedBy', select: 'name email role' },
    ]);

    return res.status(201).json({
      success: true,
      message: 'Task assigned',
      data: formatTask(task),
    });
  } catch (err) {
    next(err);
  }
}

function formatTask(doc) {
  const t = doc.toObject ? doc.toObject() : doc;
  return {
    id: t._id.toString(),
    title: t.title,
    description: t.description,
    status: t.status,
    assignedTo: t.assignedTo
      ? {
          id: t.assignedTo._id?.toString() ?? t.assignedTo.toString(),
          name: t.assignedTo.name,
          email: t.assignedTo.email,
        }
      : undefined,
    assignedBy: t.assignedBy
      ? {
          id: t.assignedBy._id?.toString() ?? t.assignedBy.toString(),
          name: t.assignedBy.name,
          email: t.assignedBy.email,
        }
      : undefined,
    createdAt: t.createdAt,
    updatedAt: t.updatedAt,
  };
}

module.exports = {
  dashboard,
  listTechnicians,
  assignTask,
  formatTask,
};
