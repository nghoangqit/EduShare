import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../database/database_helper.dart';

class CartProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  List<CartItem> _items = [];
  bool _loading = false;

  List<CartItem> get items => _items;
  bool get loading => _loading;

  int get totalCount => _items.fold(0, (sum, i) => sum + i.quantity);

  double get totalPrice => _items.fold(0, (sum, i) => sum + i.totalPrice);

  bool contains(String productId) =>
      _items.any((i) => i.product.id == productId);

  int quantityFor(String productId) {
    for (final item in _items) {
      if (item.product.id == productId) return item.quantity;
    }
    return 0;
  }

  Future<void> loadCart() async {
    _loading = true;
    notifyListeners();

    final rows = await _db.getCartWithProducts();
    _items = rows.map((row) {
      final product = Product.fromMap(row);
      return CartItem(product: product, quantity: row['quantity'] as int);
    }).toList();

    _loading = false;
    notifyListeners();
  }

  Future<bool> addItem(Product product) async {
    if (product.isOutOfStock) return false;
    final currentQuantity = quantityFor(product.id);
    if (currentQuantity >= product.stockQuantity) {
      return false;
    }
    await _db.insertProduct(product, isFeatured: product.isFeatured);
    await _db.addToCart(product.id);
    await loadCart();
    return true;
  }

  Future<void> removeItem(String productId) async {
    await _db.removeFromCart(productId);
    _items.removeWhere((i) => i.product.id == productId);
    notifyListeners();
  }

  Future<int> updateQuantity(String productId, int quantity) async {
    final idx = _items.indexWhere((i) => i.product.id == productId);
    if (idx == -1) return 0;

    final maxQuantity = _items[idx].product.stockQuantity;
    final normalizedQuantity = quantity <= 0
        ? 0
        : quantity > maxQuantity
        ? maxQuantity
        : quantity;

    await _db.updateCartQuantity(productId, normalizedQuantity);
    if (normalizedQuantity <= 0) {
      _items.removeWhere((i) => i.product.id == productId);
    } else {
      _items[idx].quantity = normalizedQuantity;
    }
    notifyListeners();
    return normalizedQuantity;
  }

  Future<void> clearCart() async {
    await _db.clearCart();
    _items.clear();
    notifyListeners();
  }
}
