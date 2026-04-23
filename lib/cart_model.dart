import 'dart:collection';

import 'package:flutter/foundation.dart';

class CartModel extends ChangeNotifier {
  CartModel._privateConstructor();

  static final CartModel instance = CartModel._privateConstructor();

  final List<Map<String, dynamic>> _items = [];

  UnmodifiableListView<Map<String, dynamic>> get items =>
      UnmodifiableListView(_items);

  int get count => _items.length;

  int get totalPrice => _items.fold<int>(
        0,
        (sum, item) => sum + _parsePrice(item['priceValue'] ?? item['price']),
      );

  String get formattedTotal => formatPrice(totalPrice);

  void addToCart(Map<String, dynamic> product) {
    final copiedProduct = Map<String, dynamic>.from(product);
    copiedProduct['priceValue'] = _parsePrice(copiedProduct['price']);
    _items.add(copiedProduct);
    notifyListeners();
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
