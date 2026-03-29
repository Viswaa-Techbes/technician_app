import '../../domain/entities/technician_entity.dart';

/// Data model — maps JSON from API to domain entity
class TechnicianModel {
  final String id;
  final String name;
  final String skill;
  final String experience;
  final String status;
  final int assignedTasksCount;
  final String phone;
  final double rating;

  const TechnicianModel({
    required this.id,
    required this.name,
    required this.skill,
    required this.experience,
    required this.status,
    required this.assignedTasksCount,
    required this.phone,
    required this.rating,
  });

  factory TechnicianModel.fromJson(Map<String, dynamic> json) {
    return TechnicianModel(
      id: json['_id'] as String? ?? json['id'] as String,
      name: json['name'] as String,
      skill: json['skill'] as String,
      experience: json['experience'] as String,
      status: json['status'] as String,
      assignedTasksCount: (json['assignedTasksCount'] as num?)?.toInt() ?? 0,
      phone: json['phone'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }

  TechnicianEntity toEntity() {
    final initials = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0] : '').join().toUpperCase();

    TechnicianStatus parsedStatus;
    switch (status.toLowerCase()) {
      case 'on job':
      case 'onjob':
        parsedStatus = TechnicianStatus.onJob;
        break;
      case 'offline':
        parsedStatus = TechnicianStatus.offline;
        break;
      default:
        parsedStatus = TechnicianStatus.available;
    }

    return TechnicianEntity(
      id: id,
      name: name,
      avatarInitials: initials.isEmpty ? name.substring(0, 1).toUpperCase() : initials,
      skill: skill,
      experience: experience,
      status: parsedStatus,
      assignedTasksCount: assignedTasksCount,
      phone: phone,
      rating: rating,
    );
  }
}
