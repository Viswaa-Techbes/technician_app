import 'package:customer_app/core/api/api_client.dart';
import 'package:customer_app/core/api/api_endpoints.dart';
import 'package:customer_app/features/booking/models/booking_models.dart';

class BookingRepository {
  final ApiClient _api = ApiClient.instance;

  Future<List<CctvCameraType>> getCameraTypes() async {
    final response = await _api.get<dynamic>(ApiEndpoints.cctvCameraTypes);
    final list = _unwrapList(response);
    return list.map((e) => CctvCameraType.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CctvAddon>> getAddons() async {
    final response = await _api.get<dynamic>(ApiEndpoints.cctvAddons);
    final list = _unwrapList(response);
    return list.map((e) => CctvAddon.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CctvPriceResult> calculatePrice({
    required String cameraTypeId,
    required int cameraCount,
    required String installationArea,
    required double wireLength,
    required List<String> addonIds,
  }) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.calculatePrice,
      data: {
        'cameraTypeId': cameraTypeId,
        'cameraCount': cameraCount,
        'installationArea': installationArea,
        'wireLength': wireLength,
        'addonIds': addonIds,
      },
    );
    return CctvPriceResult.fromJson(response);
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.createBooking,
      data: bookingData,
    );
    return response['data'] as Map<String, dynamic>? ?? response;
  }

  List<dynamic> _unwrapList(dynamic response) {
    if (response is List) return response;
    if (response is Map && response['data'] is List) return response['data'] as List;
    return [];
  }
}
