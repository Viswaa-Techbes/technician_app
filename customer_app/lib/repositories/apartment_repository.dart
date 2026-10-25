import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../core/network/api_config.dart';
import '../core/network/dio_client.dart';
import '../models/apartment_model.dart';
import '../models/society_ticket_model.dart';

final apartmentRepositoryProvider = Provider((ref) => ApartmentRepository(
      ref.watch(dioClientProvider),
    ));

class ApartmentRepository {
  final DioClient _dioClient;

  ApartmentRepository(this._dioClient);

  /// Fetch logged-in resident's apartment & flat details
  Future<ApartmentResidentData?> getResidentProfile() async {
    try {
      final response = await _dioClient.get(ApiConfig.residentProfile);
      if (response.data != null && response.data['success'] == true) {
        return ApartmentResidentData.fromJson(response.data['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// List complaints / tickets scoped to the user's role and flat/apartment
  Future<List<SocietyTicketModel>> getTickets({
    String? status,
    String? category,
    String? priority,
  }) async {
    final queryParams = <String, dynamic>{};
    if (status != null && status != 'All' && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (category != null && category != 'All' && category.isNotEmpty) {
      queryParams['category'] = category;
    }
    if (priority != null && priority != 'All' && priority.isNotEmpty) {
      queryParams['priority'] = priority;
    }

    final response = await _dioClient.get(
      ApiConfig.apartmentTickets,
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );

    if (response.data != null && response.data['success'] == true) {
      final list = response.data['data'] as List<dynamic>? ?? [];
      return list.map((item) => SocietyTicketModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  /// Get single ticket details (with IDOR check enforced by backend)
  Future<SocietyTicketModel?> getTicketById(String id) async {
    final response = await _dioClient.get(ApiConfig.apartmentTicketDetails(id));
    if (response.data != null && response.data['success'] == true) {
      return SocietyTicketModel.fromJson(response.data['data'] as Map<String, dynamic>);
    }
    return null;
  }

  /// Register a new resident complaint
  Future<SocietyTicketModel> createTicket({
    required String subject,
    required String description,
    required String category,
    required String priority,
    List<String>? attachments,
  }) async {
    final response = await _dioClient.post(
      ApiConfig.apartmentTickets,
      data: {
        'subject': subject.trim(),
        'description': description.trim(),
        'category': category,
        'priority': priority,
        'attachments': attachments ?? [],
      },
    );

    if (response.data != null && response.data['success'] == true) {
      return SocietyTicketModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } else {
      throw Exception(response.data?['message'] ?? 'Failed to submit complaint');
    }
  }

  /// Post a visible discussion reply to the ticket
  Future<SocietyTicketModel> replyToTicket(
    String ticketId, {
    required String text,
    List<String>? images,
  }) async {
    final response = await _dioClient.put(
      ApiConfig.apartmentTicketReply(ticketId),
      data: {
        'text': text.trim(),
        'images': images ?? [],
      },
    );

    if (response.data != null && response.data['success'] == true) {
      return SocietyTicketModel.fromJson(response.data['data'] as Map<String, dynamic>);
    } else {
      throw Exception(response.data?['message'] ?? 'Failed to send reply');
    }
  }

  /// Update complaint status (In-Charge & Admin)
  Future<void> updateTicketStatus(
    String ticketId, {
    required String status,
    String? reason,
  }) async {
    final response = await _dioClient.put(
      ApiConfig.apartmentTicketStatus(ticketId),
      data: {
        'status': status,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );

    if (response.data == null || response.data['success'] != true) {
      throw Exception(response.data?['message'] ?? 'Failed to update status');
    }
  }

  /// Record private internal note (In-Charge & Admin only)
  Future<void> addInternalNote(String ticketId, {required String text}) async {
    final response = await _dioClient.post(
      ApiConfig.apartmentTicketInternalNotes(ticketId),
      data: {
        'text': text.trim(),
      },
    );

    if (response.data == null || response.data['success'] != true) {
      throw Exception(response.data?['message'] ?? 'Failed to record internal note');
    }
  }

  /// Resolve complaint (In-Charge & Admin)
  Future<void> resolveTicket(
    String ticketId, {
    required String resolutionNotes,
    List<String>? resolutionPhotos,
  }) async {
    final response = await _dioClient.put(
      ApiConfig.apartmentTicketResolve(ticketId),
      data: {
        'resolutionNotes': resolutionNotes.trim(),
        'resolutionPhotos': resolutionPhotos ?? [],
      },
    );

    if (response.data == null || response.data['success'] != true) {
      throw Exception(response.data?['message'] ?? 'Failed to resolve ticket');
    }
  }

  /// Reopen complaint with required reason (Resident)
  Future<void> reopenTicket(String ticketId, {required String reason}) async {
    final response = await _dioClient.put(
      ApiConfig.apartmentTicketReopen(ticketId),
      data: {
        'reason': reason.trim(),
      },
    );

    if (response.data == null || response.data['success'] != true) {
      throw Exception(response.data?['message'] ?? 'Failed to reopen ticket');
    }
  }

  /// Upload photo attachment using backend multipart endpoint
  Future<String> uploadPhoto(XFile file) async {
    try {
      final fileName = file.name.isNotEmpty ? file.name : 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await file.readAsBytes();

      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: fileName),
      });

      final response = await _dioClient.post(
        ApiConfig.upload,
        data: formData,
      );

      if (response.data != null && response.data['success'] == true) {
        return response.data['url']?.toString() ??
            response.data['fileUrl']?.toString() ??
            response.data['publicId']?.toString() ??
            '';
      } else {
        throw Exception(response.data?['message'] ?? 'Upload failed');
      }
    } catch (e) {
      throw Exception('Photo upload failed: $e');
    }
  }

  /// List apartments (for In-Charge view)
  Future<List<ApartmentModel>> getApartments() async {
    try {
      final response = await _dioClient.get(ApiConfig.apartments);
      if (response.data != null && response.data['success'] == true) {
        final list = response.data['data'] as List<dynamic>? ?? [];
        return list.map((a) => ApartmentModel.fromJson(a as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
