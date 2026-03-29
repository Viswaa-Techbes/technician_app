const Task = require('../models/Task');
const { TASK_STATUSES } = require('../models/Task');

async function dashboard(req, res, next) {
  try {
    const techId = req.user.id;
    const [total, pending, inProgress, completed] = await Promise.all([
      Task.countDocuments({ assignedTo: techId }),
      Task.countDocuments({ assignedTo: techId, status: 'pending' }),
      Task.countDocuments({ assignedTo: techId, status: 'in_progress' }),
      Task.countDocuments({ assignedTo: techId, status: 'completed' }),
    ]);

    return res.json({
      success: true,
      data: {
        totalTasks: total,
        pending,
        inProgress,
        completed,
      },
    });
  } catch (err) {
    next(err);
  }
}

async function listTasks(req, res, next) {
  try {
    const tasks = await Task.find({ assignedTo: req.user.id })
      .sort({ updatedAt: -1 })
      .populate('assignedBy', 'name email role')
      .lean();

    const data = tasks.map((t) => ({
      id: t._id.toString(),
      title: t.title,
      description: t.description,
      status: t.status,
      assignedBy: t.assignedBy
        ? {
            id: t.assignedBy._id.toString(),
            name: t.assignedBy.name,
            email: t.assignedBy.email,
          }
        : null,
      createdAt: t.createdAt,
      updatedAt: t.updatedAt,
    }));

    return res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
}

/**
 * PATCH /technician/tasks/:taskId/status
 * Body: { status: 'pending' | 'in_progress' | 'completed' | 'cancelled' }
 */
async function updateTaskStatus(req, res, next) {
  try {
    const { taskId } = req.params;
    const { status } = req.body;

    if (!status || !TASK_STATUSES.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `status must be one of: ${TASK_STATUSES.join(', ')}`,
      });
    }

    const task = await Task.findOne({
      _id: taskId,
      assignedTo: req.user.id,
    });

    if (!task) {
      return res.status(404).json({ success: false, message: 'Task not found' });
    }

    task.status = status;
    await task.save();

    await task.populate('assignedBy', 'name email role');

    return res.json({
      success: true,
      message: 'Task status updated',
      data: {
        id: task._id.toString(),
        title: task.title,
        description: task.description,
        status: task.status,
        assignedBy: task.assignedBy
          ? {
              id: task.assignedBy._id.toString(),
              name: task.assignedBy.name,
              email: task.assignedBy.email,
            }
          : null,
        updatedAt: task.updatedAt,
      },
    });
  } catch (err) {
    next(err);
  }
}

module.exports = {
  dashboard,
  listTasks,
  updateTaskStatus,
};
