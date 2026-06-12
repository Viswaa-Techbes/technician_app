import 'package:customer_app/core/api/api_client.dart';
import 'package:customer_app/core/api/api_endpoints.dart';
import 'package:customer_app/features/dashboard/models/dashboard_models.dart';

class DashboardRepository {
  final ApiClient _api = ApiClient.instance;

  Future<DashboardData> getDashboardData() async {
    final response = await _api.get<Map<String, dynamic>>(ApiEndpoints.dashboard);
    // The response shape from backend is { success: true, data: { metrics: ..., profile: ... } }
    // our ApiClient automatically extracts 'data' or returns the whole response if not present.
    // Let's inspect api_client.dart to make sure how it maps the response.
    return DashboardData.fromJson(response);
  }

  Future<UserAddress> createAddress(UserAddress address) async {
    final response = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.userAddress,
      data: address.toJson(),
    );
    return UserAddress.fromJson(response);
  }

  Future<UserAddress> updateAddress(String id, UserAddress address) async {
    final response = await _api.put<Map<String, dynamic>>(
      '${ApiEndpoints.userAddress}/$id',
      data: address.toJson(),
    );
    return UserAddress.fromJson(response);
  }

  Future<void> deleteAddress(String id) async {
    await _api.delete('${ApiEndpoints.userAddress}/$id');
  }
}
