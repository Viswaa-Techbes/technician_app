enum Role {
  admin,
  manager,
  technician,
}

enum Permission {
  viewUsers,
  manageTechnicians,
  assignTasks,
  editSettings,
  viewDashboard,
  viewOwnJobs,
  manageRoleAccess,
  viewReports,
  manageServices,
  trackOperations,
}

const allPermissions = [
  Permission.viewUsers,
  Permission.manageTechnicians,
  Permission.assignTasks,
  Permission.editSettings,
  Permission.viewDashboard,
  Permission.viewOwnJobs,
  Permission.manageRoleAccess,
  Permission.viewReports,
  Permission.manageServices,
  Permission.trackOperations,
];

const defaultRolePermissions = {
  Role.admin: [
    Permission.viewUsers,
    Permission.manageTechnicians,
    Permission.assignTasks,
    Permission.editSettings,
    Permission.viewDashboard,
    Permission.viewOwnJobs,
    Permission.manageRoleAccess,
    Permission.viewReports,
    Permission.manageServices,
    Permission.trackOperations,
  ],
  Role.manager: [
    Permission.viewDashboard,
    Permission.viewUsers,
    Permission.manageTechnicians,
    Permission.assignTasks,
    Permission.viewReports,
    Permission.manageServices,
    Permission.trackOperations,
  ],
  Role.technician: [
    Permission.viewOwnJobs,
  ],
};
