import '../config/api_config.dart';
import '../models/models.dart';
import 'api_service.dart';

class ServicesApiService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getAllServices() async {
    try {
      final response = await _apiService.get(
        ApiConfig.services,
        includeAuth: false,
      );

      if (response['success']) {
        final data = response['data'];
        final servicesList = data['data'] ?? data['services'] ?? data;
        
        List<Service> services = [];
        if (servicesList is List) {
          services = (servicesList as List)
              .map((json) => Service.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        return {
          'success': true,
          'services': services,
          'message': 'Services loaded successfully',
        };
      }

      return {
        'success': false,
        'services': [],
        'message': response['message'] ?? 'Failed to load services',
      };
    } catch (e) {
      return {
        'success': false,
        'services': [],
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getServiceById(String serviceId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.services}/$serviceId',
        includeAuth: false,
      );

      if (response['success']) {
        final data = response['data']['data'] ?? response['data'];
        final service = Service.fromJson(data);

        return {
          'success': true,
          'service': service,
          'message': 'Service loaded successfully',
        };
      }

      return {
        'success': false,
        'service': null,
        'message': response['message'] ?? 'Failed to load service',
      };
    } catch (e) {
      return {
        'success': false,
        'service': null,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getCategories() async {
    try {
      final response = await _apiService.get(
        ApiConfig.categories,
        includeAuth: false,
      );

      if (response['success']) {
        final data = response['data'];
        final categoriesList = data['data'] ?? data['categories'] ?? data;

        List<String> categories = [];
        if (categoriesList is List) {
          categories = (categoriesList as List)
              .map((item) => item is Map ? item['name'] ?? item.toString() : item.toString())
              .cast<String>()
              .toList();
        }

        return {
          'success': true,
          'categories': categories,
          'message': 'Categories loaded successfully',
        };
      }

      return {
        'success': false,
        'categories': [],
        'message': response['message'] ?? 'Failed to load categories',
      };
    } catch (e) {
      return {
        'success': false,
        'categories': [],
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> searchServices(String query) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.services}?search=$query',
        includeAuth: false,
      );

      if (response['success']) {
        final data = response['data'];
        final servicesList = data['data'] ?? data['services'] ?? data;

        List<Service> services = [];
        if (servicesList is List) {
          services = (servicesList as List)
              .map((json) => Service.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        return {
          'success': true,
          'services': services,
          'message': 'Search completed',
        };
      }

      return {
        'success': false,
        'services': [],
        'message': response['message'] ?? 'Search failed',
      };
    } catch (e) {
      return {
        'success': false,
        'services': [],
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}
