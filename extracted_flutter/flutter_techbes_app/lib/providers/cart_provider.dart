import 'package:flutter/material.dart';
import 'package:techbes_app/models/models.dart';
import '../services/cart_api_service.dart';
import '../services/bookings_api_service.dart';

class CartProvider extends ChangeNotifier {
  final CartApiService _cartApiService = CartApiService();
  final BookingsApiService _bookingsApiService = BookingsApiService();

  List<CartItem> _items = [];
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get itemCount => _items.length;

  double get totalPrice {
    return _items.fold(0, (sum, item) => sum + item.totalPrice);
  }

  Future<void> addToCart(Service service, DateTime scheduledDate) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _cartApiService.addToCart(
        service.id,
        1,
        scheduledDate: scheduledDate.toIso8601String(),
      );

      if (result['success']) {
        // Add to local cart
        final existingItem = _items.firstWhere(
          (item) => item.service.id == service.id,
          orElse: () => CartItem(
            id: '',
            service: service,
            scheduledDate: scheduledDate,
          ),
        );

        if (existingItem.id.isEmpty) {
          _items.add(CartItem(
            id: service.id,
            service: service,
            scheduledDate: scheduledDate,
          ));
        } else {
          existingItem.quantity++;
        }
      } else {
        _error = result['message'] ?? 'Failed to add item to cart';
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> removeFromCart(String itemId) async {
    try {
      final result = await _cartApiService.removeFromCart(itemId);

      if (result['success']) {
        _items.removeWhere((item) => item.id == itemId);
      } else {
        _error = result['message'] ?? 'Failed to remove item';
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
    }

    notifyListeners();
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    try {
      final result = await _cartApiService.updateCartItem(itemId, quantity);

      if (result['success']) {
        final item = _items.firstWhere((item) => item.id == itemId);
        item.quantity = quantity;
      } else {
        _error = result['message'] ?? 'Failed to update quantity';
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
    }

    notifyListeners();
  }

  void updateScheduledDate(String itemId, DateTime date) {
    final item = _items.firstWhere((item) => item.id == itemId);
    item.scheduledDate = date;
    notifyListeners();
  }

  void updateNotes(String itemId, String notes) {
    final item = _items.firstWhere((item) => item.id == itemId);
    item.notes = notes;
    notifyListeners();
  }

  Future<void> clearCart() async {
    try {
      final result = await _cartApiService.clearCart();

      if (result['success']) {
        _items.clear();
      } else {
        _error = result['message'] ?? 'Failed to clear cart';
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
    }

    notifyListeners();
  }

  Future<Map<String, dynamic>> checkout(String userId) async {
    if (_items.isEmpty) {
      return {
        'success': false,
        'message': 'Cart is empty',
      };
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final checkoutData = {
        'items': _items
            .map((item) => {
                  'serviceId': item.service.id,
                  'quantity': item.quantity,
                  'scheduledDate': item.scheduledDate.toIso8601String(),
                  'notes': item.notes,
                  'amount': item.totalPrice,
                })
            .toList(),
        'totalAmount': totalPrice,
        'userId': userId,
      };

      final result = await _cartApiService.checkout(checkoutData);

      if (result['success']) {
        // Create local booking for tracking
        for (final item in _items) {
          _bookings.add(
            Booking(
              id: result['bookingId'] ?? DateTime.now().toString(),
              userId: userId,
              service: item.service,
              quantity: item.quantity,
              scheduledDate: item.scheduledDate,
              notes: item.notes,
              bookedAt: DateTime.now(),
              status: 'confirmed',
              totalAmount: item.totalPrice,
            ),
          );
        }

        _items.clear();
        _isLoading = false;
        notifyListeners();

        return {
          'success': true,
          'message': result['message'] ?? 'Booking created successfully',
          'bookingId': result['bookingId'],
        };
      } else {
        _error = result['message'] ?? 'Failed to create booking';
        _isLoading = false;
        notifyListeners();

        return {
          'success': false,
          'message': _error,
        };
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
      _isLoading = false;
      notifyListeners();

      return {
        'success': false,
        'message': _error,
      };
    }
  }

  Future<void> loadUserBookings(String userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _bookingsApiService.getUserBookings();

      if (result['success']) {
        final bookingsList = result['bookings'] ?? [];
        _bookings = (bookingsList as List)
            .map((json) => Booking(
                  id: json['id'] ?? '',
                  userId: userId,
                  service: Service(
                    id: json['serviceId'] ?? '',
                    name: json['serviceName'] ?? 'Unknown Service',
                    category: json['category'] ?? '',
                    description: json['description'] ?? '',
                    longDescription: '',
                    price: (json['amount'] ?? 0).toDouble(),
                    rating: json['rating'] ?? 0.0,
                    reviewCount: 0,
                    imageUrl: json['imageUrl'] ?? '',
                    features: [],
                  ),
                  quantity: json['quantity'] ?? 1,
                  scheduledDate: json['scheduledDate'] != null
                      ? DateTime.parse(json['scheduledDate'])
                      : DateTime.now(),
                  notes: json['notes'] ?? '',
                  bookedAt: json['bookedAt'] != null
                      ? DateTime.parse(json['bookedAt'])
                      : DateTime.now(),
                  status: json['status'] ?? 'pending',
                  totalAmount: (json['amount'] ?? 0).toDouble(),
                ))
            .toList();
      } else {
        _error = result['message'] ?? 'Failed to load bookings';
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> cancelBooking(String bookingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _bookingsApiService.cancelBooking(bookingId);

      if (result['success']) {
        final booking = _bookings.firstWhere((b) => b.id == bookingId);
        // Update local booking status
        _bookings[_bookings.indexOf(booking)] = Booking(
          id: booking.id,
          userId: booking.userId,
          service: booking.service,
          quantity: booking.quantity,
          scheduledDate: booking.scheduledDate,
          notes: booking.notes,
          bookedAt: booking.bookedAt,
          status: 'cancelled',
          totalAmount: booking.totalAmount,
        );
      } else {
        _error = result['message'] ?? 'Failed to cancel booking';
      }
    } catch (e) {
      _error = 'An error occurred: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  List<Booking> getUserBookings(String userId) {
    return _bookings.where((b) => b.userId == userId).toList();
  }
}
