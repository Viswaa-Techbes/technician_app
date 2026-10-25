class TicketMessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String text;
  final List<String> images;
  final DateTime createdAt;

  TicketMessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.text,
    required this.images,
    required this.createdAt,
  });

  factory TicketMessageModel.fromJson(Map<String, dynamic> json) {
    String senderName = 'Support';
    String senderRole = 'support';
    String senderId = '';

    if (json['sender'] is Map<String, dynamic>) {
      final s = json['sender'] as Map<String, dynamic>;
      senderName = s['name']?.toString() ?? 'User';
      senderRole = s['role']?.toString() ?? 'user';
      senderId = s['_id']?.toString() ?? s['id']?.toString() ?? '';
    } else if (json['sender'] != null) {
      senderId = json['sender'].toString();
    }

    final rawImages = json['images'] as List<dynamic>? ?? [];
    final imgList = rawImages.map((e) => e.toString()).toList();

    return TicketMessageModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      text: json['text']?.toString() ?? '',
      images: imgList,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class TicketStatusHistoryModel {
  final String status;
  final String changedByName;
  final String reason;
  final DateTime timestamp;

  TicketStatusHistoryModel({
    required this.status,
    required this.changedByName,
    required this.reason,
    required this.timestamp,
  });

  factory TicketStatusHistoryModel.fromJson(Map<String, dynamic> json) {
    return TicketStatusHistoryModel(
      status: json['status']?.toString() ?? 'New',
      changedByName: json['changedByName']?.toString() ?? 'System',
      reason: json['reason']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class InternalNoteModel {
  final String id;
  final String text;
  final String addedByName;
  final DateTime createdAt;

  InternalNoteModel({
    required this.id,
    required this.text,
    required this.addedByName,
    required this.createdAt,
  });

  factory InternalNoteModel.fromJson(Map<String, dynamic> json) {
    return InternalNoteModel(
      id: json['_id']?.toString() ?? '',
      text: json['text']?.toString() ?? '',
      addedByName: json['addedByName']?.toString() ?? 'Staff',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class SocietyTicketModel {
  final String id;
  final String ticketId;
  final String subject;
  final String description;
  final String category;
  final String priority;
  final String status;
  final String flatNumber;
  final String block;
  final String apartmentName;
  final String apartmentId;
  final String raisedByName;
  final String raisedByPhone;
  final String raisedByType;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final String? assignedStaffName;
  final String? assignedStaffPhone;
  final String? resolutionNotes;
  final List<String> resolutionPhotos;
  final List<String> attachments;
  final List<TicketMessageModel> messages;
  final List<TicketStatusHistoryModel> statusHistory;
  final List<InternalNoteModel> internalNotes;
  final int ageingDays;
  final bool isOverdue;
  final bool isReopened;

  SocietyTicketModel({
    required this.id,
    required this.ticketId,
    required this.subject,
    required this.description,
    required this.category,
    required this.priority,
    required this.status,
    required this.flatNumber,
    required this.block,
    required this.apartmentName,
    required this.apartmentId,
    required this.raisedByName,
    required this.raisedByPhone,
    required this.raisedByType,
    required this.createdAt,
    this.resolvedAt,
    this.closedAt,
    this.assignedStaffName,
    this.assignedStaffPhone,
    this.resolutionNotes,
    required this.resolutionPhotos,
    required this.attachments,
    required this.messages,
    required this.statusHistory,
    required this.internalNotes,
    this.ageingDays = 0,
    this.isOverdue = false,
    this.isReopened = false,
  });

  factory SocietyTicketModel.fromJson(Map<String, dynamic> json) {
    String aptId = '';
    String aptName = json['apartmentName']?.toString() ?? '';

    if (json['apartmentId'] is Map<String, dynamic>) {
      final a = json['apartmentId'] as Map<String, dynamic>;
      aptId = a['_id']?.toString() ?? '';
      if (aptName.isEmpty) aptName = a['name']?.toString() ?? '';
    } else if (json['apartmentId'] != null) {
      aptId = json['apartmentId'].toString();
    }

    final rawAttachments = json['attachments'] as List<dynamic>? ?? [];
    final attachList = rawAttachments.map((e) => e.toString()).toList();

    final rawResPhotos = json['resolutionPhotos'] as List<dynamic>? ?? [];
    final resPhotoList = rawResPhotos.map((e) => e.toString()).toList();

    final rawMessages = json['messages'] as List<dynamic>? ?? [];
    final messageList = rawMessages
        .map((m) => TicketMessageModel.fromJson(m as Map<String, dynamic>))
        .toList();

    final rawHistory = json['statusHistory'] as List<dynamic>? ?? [];
    final historyList = rawHistory
        .map((h) => TicketStatusHistoryModel.fromJson(h as Map<String, dynamic>))
        .toList();

    final rawNotes = json['internalNotes'] as List<dynamic>? ?? [];
    final notesList = rawNotes
        .map((n) => InternalNoteModel.fromJson(n as Map<String, dynamic>))
        .toList();

    return SocietyTicketModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      ticketId: json['ticketId']?.toString() ?? (json['_id']?.toString().substring(0, 8).toUpperCase() ?? 'TKT'),
      subject: json['subject']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? 'Other',
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'New',
      flatNumber: json['flatNumber']?.toString() ?? '',
      block: json['block']?.toString() ?? '',
      apartmentName: aptName,
      apartmentId: aptId,
      raisedByName: json['raisedByName']?.toString() ?? '',
      raisedByPhone: json['raisedByPhone']?.toString() ?? '',
      raisedByType: json['raisedByType']?.toString() ?? 'resident',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      resolvedAt: json['resolvedAt'] != null ? DateTime.tryParse(json['resolvedAt'].toString()) : null,
      closedAt: json['closedAt'] != null ? DateTime.tryParse(json['closedAt'].toString()) : null,
      assignedStaffName: json['assignedStaffName']?.toString() ??
          (json['assignedStaff'] is Map ? json['assignedStaff']['name']?.toString() : null),
      assignedStaffPhone: json['assignedStaffPhone']?.toString() ??
          (json['assignedStaff'] is Map ? json['assignedStaff']['mobileNumber']?.toString() : null),
      resolutionNotes: json['resolutionNotes']?.toString(),
      resolutionPhotos: resPhotoList,
      attachments: attachList,
      messages: messageList,
      statusHistory: historyList,
      internalNotes: notesList,
      ageingDays: int.tryParse(json['ageingDays']?.toString() ?? '0') ?? 0,
      isOverdue: json['isOverdue'] == true,
      isReopened: json['isReopened'] == true || (json['status'] == 'Reopened'),
    );
  }
}
