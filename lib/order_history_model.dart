import 'dart:collection';
import 'dart:math';

import 'package:flutter/material.dart';

import 'app_ui.dart';
import 'cart_model.dart';
import 'notification_service.dart';

class OrderHistoryModel extends ChangeNotifier {
  OrderHistoryModel._privateConstructor();

  static final OrderHistoryModel instance = OrderHistoryModel._privateConstructor();

  final List<Map<String, dynamic>> _orders = <Map<String, dynamic>>[];
  final Map<String, int> _statusTokens = <String, int>{};
  final Random _random = Random();

  UnmodifiableListView<Map<String, dynamic>> get orders =>
      UnmodifiableListView(_orders);

  Map<String, dynamic>? getOrderById(String orderId) {
    for (final order in _orders) {
      if (order['id'] == orderId) {
        return order;
      }
    }
    return null;
  }

  String addOrder({
    required List<Map<String, dynamic>> products,
    required int totalPrice,
    required String paymentMethod,
    String? shippingMethod,
    int? shippingCost,
  }) {
    final now = DateTime.now();
    final orderId = _generateOrderId(now);
    final normalizedPaymentMethod = paymentMethod.trim().isEmpty
        ? 'e-wallet'
        : paymentMethod.trim();
    final order = <String, dynamic>{
      'id': orderId,
      'date': now,
      'tanggal': now,
      'total': totalPrice,
      'totalHarga': totalPrice,
      'status': 'Diproses',
      'paymentMethod': normalizedPaymentMethod,
      'shippingMethod': shippingMethod,
      'shippingCost': shippingCost ?? 0,
      'products': products
          .map((product) => Map<String, dynamic>.from(product))
          .toList(),
      'nomorResi': _generateReceiptNumber(),
    };

    
    _orders.insert(0, order);
    notifyListeners();
    showGlobalFakeNotification(
      'Pesanan kamu sedang diproses',
      icon: Icons.hourglass_top_rounded,
    );
    _simulateStatusProgress(orderId);
    return orderId;
  }

  void _simulateStatusProgress(String orderId) {
    final token = (_statusTokens[orderId] ?? 0) + 1;
    _statusTokens[orderId] = token;
    _progressOrder(orderId, token);
  }

  Future<void> _progressOrder(String orderId, int token) async {
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!_isActive(orderId, token)) return;

    _updateOrderStatus(orderId, 'Dikirim');
    showGlobalFakeNotification(
      'Pesanan kamu sedang dikirim',
      icon: Icons.local_shipping_rounded,
    );

    await Future<void>.delayed(const Duration(seconds: 3));
    if (!_isActive(orderId, token)) return;

    _updateOrderStatus(orderId, 'Selesai');
    showGlobalFakeNotification(
      'Pesanan telah sampai',
      icon: Icons.verified_rounded,
      backgroundColor: const Color(0xFF16A34A),
    );
    
    // Show Android notification
    NotificationService.instance.showOrderStatusNotification(
      orderId: orderId,
      status: 'Selesai',
      message: 'Pesanan #$orderId telah berhasil dikirim. Terima kasih telah berbelanja!',
    );
    
    _statusTokens.remove(orderId);
  }

  bool _isActive(String orderId, int token) => _statusTokens[orderId] == token;

  void _updateOrderStatus(String orderId, String newStatus) {
    final order = getOrderById(orderId);
    if (order == null) return;

    final currentStatus = order['status'] as String? ?? '';
    if (currentStatus == 'Selesai') {
      _statusTokens.remove(orderId);
      return;
    }

    order['status'] = newStatus;
    notifyListeners();

    if (newStatus == 'Selesai') {
      _statusTokens.remove(orderId);
    }
  }

  String _generateOrderId(DateTime dateTime) {
    final millis = dateTime.millisecondsSinceEpoch.toRadixString(36).toUpperCase();
    return 'ORD-$millis';
  }

  String _generateReceiptNumber() {
    final digits = List.generate(8, (_) => _random.nextInt(10)).join();
    return 'RESI-$digits';
  }

  static String formatDateTime(DateTime dateTime) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final day = dateTime.day.toString().padLeft(2, '0');
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day $month $year, $hour:$minute';
  }

  static String formatPrice(int value) => CartModel.formatPrice(value);
}
