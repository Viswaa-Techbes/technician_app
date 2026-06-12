import '../config/api_config.dart';
import 'api_service.dart';

class CartApiService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await _apiService.get(ApiConfig.cart);

      if (response['success']) {
        final data = response['data']['data'] ?? response['data'];
        return {
          'success': true,
          'cart': data,
          'message': 'Cart loaded successfully',
        };
      }

      return {
        'success': false,
        'cart': null,
        'message': response['message'] ?? 'Failed to load cart',
      };
    } catch (e) {
      return {
        'success': false,
        'cart': null,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> addToCart(
    String serviceId,
    int quantity, {
    String? scheduledDate,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final body = {
        'serviceId': serviceId,
        'quantity': quantity,
        if (scheduledDate != null) 'scheduledDate': scheduledDate,
        ...?additionalData,
      };

      final response = await _apiService.post(ApiConfig.addToCart, body);

      if (response['success']) {
        return {
          'success': true,
          'message': response['message'] ?? 'Item added to cart',
          'data': response['data'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to add item to cart',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> removeFromCart(String itemId) async {
    try {
      final response = await _apiService.delete(
        '${ApiConfig.removeFromCart}/$itemId',
      );

      if (response['success']) {
        return {
          'success': true,
          'message': response['message'] ?? 'Item removed from cart',
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to remove item',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateCartItem(
    String itemId,
    int quantity, {
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      final body = {
        'quantity': quantity,
        ...?additionalData,
      };

      final response = await _apiService.put(
        '${ApiConfig.cart}/$itemId',
        body,
      );

      if (response['success']) {
        return {
          'success': true,
          'message': response['message'] ?? 'Cart updated',
          'data': response['data'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to update cart',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> clearCart() async {
    try {
      final response = await _apiService.post(ApiConfig.clearCart, {});

      if (response['success']) {
        return {
          'success': true,
          'message': response['message'] ?? 'Cart cleared',
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to clear cart',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> checkout(Map<String, dynamic> checkoutData) async {
    try {
      final response = await _apiService.post(
        ApiConfig.createBooking,
        checkoutData,
      );

      if (response['success']) {
        return {
          'success': true,
          'message': response['message'] ?? 'Booking created successfully',
          'bookingId': response['data']?['id'] ?? response['data']?['bookingId'],
          'data': response['data'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to create booking',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}
