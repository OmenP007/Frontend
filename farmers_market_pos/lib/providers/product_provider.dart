import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// ── Categories ────────────────────────────────────────────────────────────
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final data = await api.getCategories(rootOnly: false);
  return data.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Products by category ──────────────────────────────────────────────────
final selectedCategoryProvider = StateProvider<CategoryModel?>((ref) => null);

final productsProvider = FutureProvider<List<ProductModel>>((ref) async {
  final api      = ref.watch(apiServiceProvider);
  final category = ref.watch(selectedCategoryProvider);
  final res = await api.getProducts(categoryId: category?.id);
  final items = res['data'] as List<dynamic>;
  return items.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
});

// ── Cart ──────────────────────────────────────────────────────────────────
class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(ProductModel product) {
    final idx = state.indexWhere((i) => i.product.id == product.id);
    if (idx >= 0) {
      final updated = List<CartItem>.from(state);
      updated[idx] = state[idx].copyWith(quantity: state[idx].quantity + 1);
      state = updated;
    } else {
      state = [...state, CartItem(product: product, quantity: 1)];
    }
  }

  void removeItem(int productId) {
    state = state.where((i) => i.product.id != productId).toList();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    state = state
        .map((i) => i.product.id == productId ? i.copyWith(quantity: quantity) : i)
        .toList();
  }

  void clear() => state = [];

  double get subtotal => state.fold(0.0, (sum, i) => sum + i.subtotal);
  int    get itemCount => state.fold(0, (sum, i) => sum + i.quantity);
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

// ── Checkout state ────────────────────────────────────────────────────────
class CheckoutState {
  final String paymentMethod; // 'cash' | 'credit'
  final double? customInterestRate;
  final bool isProcessing;
  final String? error;
  final Map<String, dynamic>? result;

  const CheckoutState({
    this.paymentMethod     = 'cash',
    this.customInterestRate,
    this.isProcessing      = false,
    this.error,
    this.result,
  });

  CheckoutState copyWith({
    String? paymentMethod,
    double? customInterestRate,
    bool? isProcessing,
    String? error,
    Map<String, dynamic>? result,
  }) => CheckoutState(
    paymentMethod:      paymentMethod      ?? this.paymentMethod,
    customInterestRate: customInterestRate ?? this.customInterestRate,
    isProcessing:       isProcessing       ?? this.isProcessing,
    error:              error,
    result:             result             ?? this.result,
  );
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final ApiService _api;

  CheckoutNotifier(this._api) : super(const CheckoutState());

  void setPaymentMethod(String method) =>
      state = state.copyWith(paymentMethod: method);

  void setInterestRate(double? rate) =>
      state = state.copyWith(customInterestRate: rate);

  Future<bool> submit({
    required int farmerId,
    required List<CartItem> cartItems,
    String? notes,
  }) async {
    state = state.copyWith(isProcessing: true, error: null);
    try {
      final items = cartItems.map((i) => {
        'product_id': i.product.id,
        'quantity':   i.quantity,
      }).toList();

      final res = await _api.createTransaction(
        farmerId:      farmerId,
        paymentMethod: state.paymentMethod,
        items:         items,
        interestRate:  state.customInterestRate,
        notes:         notes,
      );
      state = state.copyWith(isProcessing: false, result: res);
      return true;
    } catch (e) {
      state = state.copyWith(isProcessing: false, error: e.toString());
      return false;
    }
  }

  void reset() => state = const CheckoutState();
}

final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>((ref) {
  return CheckoutNotifier(ref.watch(apiServiceProvider));
});
