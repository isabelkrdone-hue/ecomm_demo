import 'package:flutter/material.dart';

import 'app_ui.dart';
import 'app_ui_skeletons.dart';
import 'order_detail_page.dart';
import 'order_history_model.dart';

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'Diproses':
        return const Color(0xFFF59E0B);
      case 'Dikirim':
        return const Color(0xFF2563EB);
      case 'Selesai':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _normalizePaymentMethod(String? paymentMethod) {
    return paymentMethod?.trim() ?? '';
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    if (value.length == 1) return value.toUpperCase();
    return value[0].toUpperCase() + value.substring(1).toLowerCase();
  }

  IconData _paymentMethodIcon(String? paymentMethod) {
    final value = _normalizePaymentMethod(paymentMethod).toLowerCase();

    if (value.isEmpty) {
      return Icons.account_balance_wallet;
    }
    if (value.contains('ewallet') || value.contains('e-wallet') || value.contains('wallet') || value.contains('dana') || value.contains('ovo') || value.contains('gopay')) {
      return Icons.account_balance_wallet;
    }
    if (value.contains('bank') || value.contains('transfer') || value == 'bca' || value == 'bni' || value == 'bri' || value == 'mandiri') {
      return Icons.account_balance;
    }
    if (value.contains('kartu') || value.contains('credit') || value.contains('kredit') || value.contains('visa') || value.contains('mastercard') || value.contains('card')) {
      return Icons.credit_card;
    }
    return Icons.account_balance_wallet;
  }

  String _paymentMethodLabel(String? paymentMethod) {
    final value = _normalizePaymentMethod(paymentMethod).toLowerCase();

    switch (value) {
      case 'ewallet':
      case 'e-wallet':
        return 'E-Wallet';
      case 'bca':
        return 'Bank Transfer BCA';
      case 'bni':
        return 'Bank Transfer BNI';
      case 'bri':
        return 'Bank Transfer BRI';
      case 'mandiri':
        return 'Bank Transfer Mandiri';
      case 'visa':
        return 'Kartu Kredit (Visa)';
      case 'mastercard':
        return 'Kartu Kredit (Mastercard)';
      default:
        return value.isEmpty ? 'Tidak diketahui' : _capitalize(_normalizePaymentMethod(paymentMethod));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pesanan Saya',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: OrderHistoryModel.instance,
        builder: (context, _) {
          final orders = OrderHistoryModel.instance.orders;

          if (orders.isEmpty) {
            return EmptyStateView(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada pesanan',
              subtitle: 'Pesanan yang sudah dibayar akan muncul di sini dan statusnya akan ikut bergerak otomatis.',
              action: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Kembali'),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final order = orders[index];
              final status = order['status'] as String? ?? '-';
              final tanggal = order['date'] as DateTime? ?? order['tanggal'] as DateTime? ?? DateTime.now();
              final totalHarga = order['total'] as int? ?? order['totalHarga'] as int? ?? 0;
              final paymentMethodRaw = order['paymentMethod'] as String?;
              final paymentMethodLabel = _paymentMethodLabel(paymentMethodRaw);
              final paymentMethodIcon = _paymentMethodIcon(paymentMethodRaw);

              return TapScale(
                onTap: () {
                  Navigator.of(context).push(
                    buildPageRoute(
                      OrderDetailPage(order: order),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(20),
                child: Card(
                  elevation: 0,
                  color: Colors.white,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.shopping_bag_rounded,
                                color: _statusColor(status),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${OrderHistoryModel.formatDateTime(tanggal)} • $status',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      _StatusChip(
                                        label: status,
                                        backgroundColor: _statusColor(status).withOpacity(0.12),
                                        foregroundColor: _statusColor(status),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Total ${OrderHistoryModel.formatPrice(totalHarga)}',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Icon(
                                        paymentMethodIcon,
                                        size: 16,
                                        color: const Color(0xFF94A3B8),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          paymentMethodLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (order['shippingMethod'] != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.local_shipping_rounded,
                                          size: 16,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            order['shippingMethod'] as String,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF6B7280),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}
