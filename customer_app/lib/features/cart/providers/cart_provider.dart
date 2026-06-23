import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String id;
  final int serviceId;
  final String slug;
  final String title;
  final double priceValue;
  final int qty;
  final Map<String, dynamic>? config;

  CartItem({
    required this.id,
    required this.serviceId,
    required this.slug,
    required this.title,
    required this.priceValue,
    required this.qty,
    this.config,
  });

  CartItem copyWith({
    int? qty,
    double? priceValue,
  }) {
    return CartItem(
      id: id,
      serviceId: serviceId,
      slug: slug,
      title: title,
      priceValue: priceValue ?? this.priceValue,
      qty: qty ?? this.qty,
      config: config,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(CartItem item) {
    // If CCTV or custom configured item, always add as a separate item to keep configurations distinct
    if (item.config != null) {
      state = [...state, item];
      return;
    }

    final index = state.indexWhere((element) => element.serviceId == item.serviceId);
    if (index != -1) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index) state[i].copyWith(qty: state[i].qty + 1) else state[i]
      ];
    } else {
      state = [...state, item];
    }
  }

  void removeItem(String itemId) {
    state = state.where((element) => element.id != itemId).toList();
  }

  void updateQuantity(String itemId, int qty) {
    if (qty <= 0) {
      removeItem(itemId);
      return;
    }
    state = [
      for (final item in state)
        if (item.id == itemId) item.copyWith(qty: qty) else item
    ];
  }

  void clearCart() {
    state = [];
  }

  double get subtotal {
    return state.fold(0, (sum, item) => sum + (item.priceValue * item.qty));
  }

  double get gstTax {
    return subtotal * 0.18; // 18% GST
  }

  double get totalAmount {
    return subtotal + gstTax;
  }

  double get advanceAmount {
    // 50% advance payment required for rollout scheduling
    return totalAmount * 0.5;
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});
