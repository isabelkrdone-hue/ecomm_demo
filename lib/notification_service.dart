import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'app_keys.dart';
import 'app_ui.dart';
import 'order_detail_page.dart';
import 'seller_center_page.dart';

class NotificationService {
  NotificationService._privateConstructor();
  static final NotificationService instance = NotificationService._privateConstructor();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    _initialized = true;
  }

  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload ?? '';
    final context = rootNavigatorKey.currentContext;
    if (context == null || payload.isEmpty) return;

    if (payload.startsWith('verification:')) {
      Navigator.of(context).push(
        buildPageRoute(const SellerCenterPage()),
      );
      return;
    }

    Navigator.of(context).push(
      buildPageRoute(
        OrderDetailPage(orderId: payload),
      ),
    );
  }

  Future<void> showOrderCompletedNotification({
    required String orderId,
    required String title,
    required String body,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'order_channel',
      'Order Notifications',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      orderId.hashCode,
      title,
      body,
      details,
      payload: orderId,
    );
  }

  Future<void> showOrderStatusNotification({
    required String orderId,
    required String status,
    String? message,
  }) async {
    await initialize();

    String title;
    String body;

    switch (status) {
      case 'Diproses':
        title = 'Pesanan Sedang Diproses';
        body = message ?? 'Pesanan Anda sedang diproses oleh penjual';
        break;
      case 'Dikirim':
        title = 'Pesanan Sedang Dikirim';
        body = message ?? 'Pesanan Anda sedang dalam perjalanan';
        break;
      case 'Selesai':
        title = '✅ Pesanan Telah Sampai!';
        body = message ?? 'Pesanan Anda telah berhasil dikirim. Terima kasih!';
        break;
      default:
        title = 'Update Pesanan';
        body = message ?? 'Status pesanan Anda telah diperbarui';
    }

    await showOrderCompletedNotification(
      orderId: orderId,
      title: title,
      body: body,
    );
  }

  Future<void> showBusinessVerifiedNotification({
    required String businessName,
    String? businessType,
  }) async {
    await initialize();

    const androidDetails = AndroidNotificationDetails(
      'verification_channel',
      'Verification Notifications',
      channelDescription: 'Notifications for seller verification updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      enableVibration: true,
      playSound: true,
      styleInformation: BigTextStyleInformation(''),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final typeText = (businessType ?? '').trim();
    final body = typeText.isEmpty
        ? '$businessName berhasil lolos verifikasi'
        : '$businessName ($typeText) berhasil lolos verifikasi';

    await _notifications.show(
      businessName.hashCode,
      'Seller terverifikasi',
      body,
      details,
      payload: 'verification:$businessName',
    );
  }

  Future<void> requestPermissions() async {
    await initialize();

    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }

    final iosPlugin = _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    
    if (iosPlugin != null) {
      await iosPlugin.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
}
