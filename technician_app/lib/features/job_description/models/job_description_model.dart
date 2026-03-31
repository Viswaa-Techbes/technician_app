class JobDescription {
  final String? id;
  final String projectId;
  final String title;
  final String description;
  final List<String> fileUrls;
  final DateTime createdAt;

  const JobDescription({
    this.id,
    required this.projectId,
    required this.title,
    required this.description,
    required this.fileUrls,
    required this.createdAt,
  });

  factory JobDescription.fromJson(Map<String, dynamic> json) {
    return JobDescription(
      id: json['id']?.toString(),
      projectId: json['projectId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      fileUrls: (json['fileUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'fileUrls': fileUrls,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
