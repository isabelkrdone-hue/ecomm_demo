import 'dart:collection';

import 'package:flutter/foundation.dart';

class CartModel extends ChangeNotifier {
  CartModel._privateConstructor();

  static final CartModel instance = CartModel._privateConstructor();

  final List<Map<String, dynamic>> _items = [];

  UnmodifiableListView<Map<String, dynamic>> get items =>
      UnmodifiableListView(_items);

  int get count => _items.fold<int>(
        0,
        (sum, item) => sum + _quantityFor(item),
      );

  int get totalPrice => _items.fold<int>(
        0,
        (sum, item) =>
            sum +
            (_parsePrice(item['priceValue'] ?? item['price']) *
                _quantityFor(item)),
      );

  String get formattedTotal => formatPrice(totalPrice);

  void addToCart(Map<String, dynamic> product) {
    final copiedProduct = Map<String, dynamic>.from(product);
    copiedProduct['name'] = _asString(copiedProduct['name'], fallback: '-');
    copiedProduct['price'] = _asPriceLabel(copiedProduct['price']);
    copiedProduct['image'] = _asString(
      copiedProduct['image'] ?? copiedProduct['imagePath'],
      fallback: 'assets/images/placeholder.png',
    );
    copiedProduct['category'] =
        _asString(copiedProduct['category'], fallback: 'Lainnya');
    copiedProduct['description'] =
        _asString(copiedProduct['description'], fallback: '');
    copiedProduct['businessName'] =
        _asString(copiedProduct['businessName'], fallback: '');
    copiedProduct['priceValue'] =
        _parsePrice(copiedProduct['priceValue'] ?? copiedProduct['price']);
    copiedProduct['quantity'] = _quantityFor(copiedProduct);

    final existingIndex = _items.indexWhere(
      (item) =>
          item['name'] == copiedProduct['name'] &&
          item['businessName'] == copiedProduct['businessName'] &&
          item['category'] == copiedProduct['category'] &&
          item['priceValue'] == copiedProduct['priceValue'],
    );
    if (existingIndex != -1) {
      _items[existingIndex]['quantity'] =
          _quantityFor(_items[existingIndex]) + _quantityFor(copiedProduct);
      notifyListeners();
      return;
    }

    _items.add(copiedProduct);
    notifyListeners();
  }

  void setQuantity(int index, int quantity) {
    if (index < 0 || index >= _items.length) return;
    if (quantity < 1) return;
    _items[index]['quantity'] = quantity;
    notifyListeners();
  }

  void incrementQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    setQuantity(index, _quantityFor(_items[index]) + 1);
  }

  void decrementQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    final quantity = _quantityFor(_items[index]);
    if (quantity <= 1) return;
    setQuantity(index, quantity - 1);
  }

  void removeAt(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
  }

  int _parsePrice(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value?.toString() ?? '';
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  int _quantityFor(Map<String, dynamic> item) {
    final value = item['quantity'] ?? item['qty'];
    if (value is int) return value < 1 ? 1 : value;
    if (value is num) return value < 1 ? 1 : value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 1) return 1;
    return parsed;
  }

  String _asString(dynamic value, {required String fallback}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  String _asPriceLabel(dynamic value) {
    final parsed = _parsePrice(value);
    return formatPrice(parsed);
  }

  static String formatPrice(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();

    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      buffer.write(digits[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString()}';
  }
}
