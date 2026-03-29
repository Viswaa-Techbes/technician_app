/// Core domain entity — pure Dart, no Flutter dependencies
class TechnicianEntity {
  final String id;
  final String name;
  final String avatarInitials;
  final String skill;
  final String experience;
  final TechnicianStatus status;
  final int assignedTasksCount;
  final String phone;
  final double rating;

  const TechnicianEntity({
    required this.id,
    required this.name,
    required this.avatarInitials,
    required this.skill,
    required this.experience,
    required this.status,
    required this.assignedTasksCount,
    required this.phone,
    required this.rating,
  });
}

enum TechnicianStatus { available, onJob, offline }

extension TechnicianStatusX on TechnicianStatus {
  String get label {
    switch (this) {
      case TechnicianStatus.available:
        return 'Available';
      case TechnicianStatus.onJob:
        return 'On Job';
      case TechnicianStatus.offline:
        return 'Offline';
    }
  }
}
