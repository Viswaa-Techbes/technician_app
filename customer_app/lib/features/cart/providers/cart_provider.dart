import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:customer_app/core/api/api_client.dart';
import 'package:customer_app/core/api/api_endpoints.dart';
import 'package:customer_app/core/storage/secure_storage.dart';
import 'package:customer_app/features/cart/models/cart_item.dart';

final cartProvider = StateNotifierProvider<CartNotifier, AsyncValue<List<CartItem>>>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<AsyncValue<List<CartItem>>> {
  static const _cartStorageKey = 'techbes_cctv_cart';
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final _api = ApiClient.instance;

  CartNotifier() : super(const AsyncValue.loading()) {
    loadCart();
  }

  Future<void> loadCart() async {
    state = const AsyncValue.loading();
    try {
      // 1. Load from local cache first
      final cached = await _storage.read(key: _cartStorageKey);
      List<CartItem> localItems = [];
      if (cached != null && cached.isNotEmpty) {
        try {
          final List decoded = json.decode(cached);
          localItems = decoded.map((e) => CartItem.fromJson(e)).toList();
        } catch (e) {
          debugPrint('Error parsing cached cart: $e');
        }
      }

      state = AsyncValue.data(localItems);

      // 2. Sync with backend if logged in
      final token = await SecureStorage.getToken();
      if (token != null && token.isNotEmpty) {
        await syncWithBackend();
      }
    } catch (err, stack) {
      state = AsyncValue.error(err, stack);
    }
  }

  Future<void> syncWithBackend() async {
    try {
      final response = await _api.get<Map<String, dynamic>>(ApiEndpoints.getCart);
      if (response['success'] == true && response['data'] != null) {
        final List itemsJson = response['data']['items'] ?? [];
        final items = itemsJson.map((e) => CartItem.fromJson(e)).toList();
        
        // Save to cache
        await _storage.write(key: _cartStorageKey, value: json.encode(items.map((e) => e.toJson()).toList()));
        state = AsyncValue.data(items);
      }
    } catch (e) {
      debugPrint('[Cart Sync] Error: $e');
      // Fallback to local data is already set, so we do not overwrite state with error
    }
  }

  Future<void> addCartItem({
    required String serviceSlug,
    required String serviceName,
    String? categoryId,
    required String subcategoryId,
    required Map<String, dynamic> input,
    required Map<String, dynamic> price,
    String? notes,
  }) async {
    final currentItems = state.value ?? [];
    
    // Create local item
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final newItem = CartItem(
      id: id,
      serviceSlug: serviceSlug,
      serviceName: serviceName,
      categoryId: categoryId,
      subcategoryId: subcategoryId,
      input: input,
      price: price,
      notes: notes,
    );

    final updated = [newItem, ...currentItems];
    state = AsyncValue.data(updated);

    // Save to cache
    await _storage.write(key: _cartStorageKey, value: json.encode(updated.map((e) => e.toJson()).toList()));

    // Sync to backend if logged in
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await _api.post<Map<String, dynamic>>(
          ApiEndpoints.addCart,
          data: {'item': newItem.toJson(), 'replaceExisting': false},
        );
        if (response['success'] == true && response['data'] != null) {
          final List itemsJson = response['data']['items'] ?? [];
          final items = itemsJson.map((e) => CartItem.fromJson(e)).toList();
          await _storage.write(key: _cartStorageKey, value: json.encode(items.map((e) => e.toJson()).toList()));
          state = AsyncValue.data(items);
        }
      } catch (e) {
        debugPrint('[Cart Add Sync] Error: $e');
      }
    }
  }

  Future<void> removeCartItem(String itemId) async {
    final currentItems = state.value ?? [];
    final updated = currentItems.filter((item) => item.id != itemId);
    state = AsyncValue.data(updated);

    // Save to cache
    await _storage.write(key: _cartStorageKey, value: json.encode(updated.map((e) => e.toJson()).toList()));

    // Sync to backend if logged in
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await _api.delete<Map<String, dynamic>>(ApiEndpoints.deleteCartItem(itemId));
        if (response['success'] == true && response['data'] != null) {
          final List itemsJson = response['data']['items'] ?? [];
          final items = itemsJson.map((e) => CartItem.fromJson(e)).toList();
          await _storage.write(key: _cartStorageKey, value: json.encode(items.map((e) => e.toJson()).toList()));
          state = AsyncValue.data(items);
        }
      } catch (e) {
        debugPrint('[Cart Remove Sync] Error: $e');
      }
    }
  }

  Future<void> clearCart() async {
    state = const AsyncValue.data([]);
    await _storage.delete(key: _cartStorageKey);

    // Sync to backend if logged in
    final token = await SecureStorage.getToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await _api.delete<Map<String, dynamic>>(ApiEndpoints.clearCart);
        if (response['success'] == true && response['data'] != null) {
          state = const AsyncValue.data([]);
        }
      } catch (e) {
        debugPrint('[Cart Clear Sync] Error: $e');
      }
    }
  }
}

extension _IterableFilter<T> on Iterable<T> {
  List<T> filter(bool Function(T) test) {
    final result = <T>[];
    for (var element in this) {
      if (test(element)) {
        result.add(element);
      }
    }
    return result;
  }
}
