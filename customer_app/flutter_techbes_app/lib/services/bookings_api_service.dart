import '../config/api_config.dart';
import 'api_service.dart';

class BookingsApiService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getUserBookings() async {
    try {
      final response = await _apiService.get(ApiConfig.userBookings);

      if (response['success']) {
        final data = response['data']['data'] ?? response['data'];
        final bookingsList = data is List ? data : (data['bookings'] ?? []);

        return {
          'success': true,
          'bookings': bookingsList,
          'message': 'Bookings loaded successfully',
        };
      }

      return {
        'success': false,
        'bookings': [],
        'message': response['message'] ?? 'Failed to load bookings',
      };
    } catch (e) {
      return {
        'success': false,
        'bookings': [],
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getBookingById(String bookingId) async {
    try {
      final response = await _apiService.get(
        '${ApiConfig.bookings}/$bookingId',
      );

      if (response['success']) {
        final data = response['data']['data'] ?? response['data'];
        return {
          'success': true,
          'booking': data,
          'message': 'Booking loaded successfully',
        };
      }

      return {
        'success': false,
        'booking': null,
        'message': response['message'] ?? 'Failed to load booking',
      };
    } catch (e) {
      return {
        'success': false,
        'booking': null,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    try {
      final response = await _apiService.post(
        ApiConfig.createBooking,
        bookingData,
      );

      if (response['success']) {
        final data = response['data']['data'] ?? response['data'];
        return {
          'success': true,
          'booking': data,
          'bookingId': data['id'] ?? data['bookingId'],
          'message': response['message'] ?? 'Booking created successfully',
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

  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    try {
      final response = await _apiService.post(
        '${ApiConfig.bookings}/$bookingId/cancel',
        {},
      );

      if (response['success']) {
        return {
          'success': true,
          'message': response['message'] ?? 'Booking cancelled successfully',
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to cancel booking',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _apiService.get(ApiConfig.userProfile);

      if (response['success']) {
        final data = response['data']['data'] ?? response['data'];
        return {
          'success': true,
          'profile': data,
          'message': 'Profile loaded successfully',
        };
      }

      return {
        'success': false,
        'profile': null,
        'message': response['message'] ?? 'Failed to load profile',
      };
    } catch (e) {
      return {
        'success': false,
        'profile': null,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateUserProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await _apiService.put(
        ApiConfig.userProfile,
        profileData,
      );

      if (response['success']) {
        final data = response['data']['data'] ?? response['data'];
        return {
          'success': true,
          'profile': data,
          'message': response['message'] ?? 'Profile updated successfully',
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to update profile',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUserAddresses() async {
    try {
      final response = await _apiService.get(ApiConfig.userAddresses);

      if (response['success']) {
        final data = response['data']['data'] ?? response['data'];
        final addressesList = data is List ? data : (data['addresses'] ?? []);

        return {
          'success': true,
          'addresses': addressesList,
          'message': 'Addresses loaded successfully',
        };
      }

      return {
        'success': false,
        'addresses': [],
        'message': response['message'] ?? 'Failed to load addresses',
      };
    } catch (e) {
      return {
        'success': false,
        'addresses': [],
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> addAddress(Map<String, dynamic> addressData) async {
    try {
      final response = await _apiService.post(
        ApiConfig.userAddresses,
        addressData,
      );

      if (response['success']) {
        return {
          'success': true,
          'address': response['data']['data'] ?? response['data'],
          'message': response['message'] ?? 'Address added successfully',
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to add address',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getUserPayments() async {
    try {
      final response = await _apiService.get(ApiConfig.userPayments);

      if (response['success']) {
        final data = response['data']['data'] ?? response['data'];
        final paymentsList = data is List ? data : (data['payments'] ?? []);

        return {
          'success': true,
          'payments': paymentsList,
          'message': 'Payments loaded successfully',
        };
      }

      return {
        'success': false,
        'payments': [],
        'message': response['message'] ?? 'Failed to load payments',
      };
    } catch (e) {
      return {
        'success': false,
        'payments': [],
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> submitReview(
    String bookingId,
    Map<String, dynamic> reviewData,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConfig.reviews,
        {
          'bookingId': bookingId,
          ...reviewData,
        },
      );

      if (response['success']) {
        return {
          'success': true,
          'review': response['data']['data'] ?? response['data'],
          'message': response['message'] ?? 'Review submitted successfully',
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Failed to submit review',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An error occurred: ${e.toString()}',
      };
    }
  }
}
