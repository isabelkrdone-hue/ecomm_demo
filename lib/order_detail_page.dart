import 'package:flutter/material.dart';

import 'order_history_model.dart';

class OrderDetailPage extends StatelessWidget {
  const OrderDetailPage({super.key, this.order, this.orderId});

  final Map<String, dynamic>? order;
  final String? orderId;

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

  int _statusIndex(String status) {
    switch (status) {
      case 'Diproses':
        return 1;
      case 'Dikirim':
        return 2;
      case 'Selesai':
        return 3;
      default:
        return 0;
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

  Map<String, dynamic>? _resolveOrder() {
    if (order != null) return order;
    if (orderId == null) return null;
    return OrderHistoryModel.instance.getOrderById(orderId!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
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
          final orderData = _resolveOrder();
          if (orderData == null) {
            return const Center(
              child: Text(
                'Pesanan tidak ditemukan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            );
          }

          final products = (orderData['products'] as List<dynamic>? ?? const [])
              .cast<Map<String, dynamic>>();
          final status = orderData['status'] as String? ?? '-';
          final tanggal = orderData['date'] as DateTime? ?? orderData['tanggal'] as DateTime? ?? DateTime.now();
          final totalHarga = orderData['total'] as int? ?? orderData['totalHarga'] as int? ?? 0;
          final nomorResi = orderData['nomorResi'] as String? ?? '-';
          final nomorPesanan = orderData['id'] as String? ?? '-';
          final paymentMethodRaw = orderData['paymentMethod'] as String?;
          final paymentMethodLabel = _paymentMethodLabel(paymentMethodRaw);
          final paymentMethodIcon = _paymentMethodIcon(paymentMethodRaw);
          final currentIndex = _statusIndex(status);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                elevation: 0,
                color: Colors.white,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
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
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _statusColor(status).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Icon(
                              Icons.receipt_long_rounded,
                              color: _statusColor(status),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Nomor Pesanan',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  nomorPesanan,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  OrderHistoryModel.formatDateTime(tanggal),
                                  style: const TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
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
                      const SizedBox(height: 16),
                      _InfoRow(label: 'Nomor Resi', value: nomorResi),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Status',
                        value: status,
                        valueColor: _statusColor(status),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        label: 'Total',
                        value: OrderHistoryModel.formatPrice(totalHarga),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.white,
                shadowColor: Colors.black12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Metode Pembayaran',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              paymentMethodIcon,
                              color: const Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Metode Pembayaran',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  paymentMethodLabel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Produk Dibeli',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (products.isEmpty)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Produk tidak tersedia',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                )
              else
                ...products.map(
                  (product) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                product['image'] as String? ?? '',
                                width: 72,
                                height: 72,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 72,
                                    height: 72,
                                    color: const Color(0xFFF1F5F9),
                                    alignment: Alignment.center,
                                    child: const Icon(
                                      Icons.image_rounded,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'] as String? ?? '-',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    product['price'] as String? ?? '-',
                                    style: const TextStyle(
                                      color: Color(0xFF2563EB),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'Tracking Pesanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _TrackingStep(
                title: 'Pesanan dibuat',
                isCompleted: currentIndex >= 1,
                isActive: currentIndex == 0,
              ),
              _TrackingStep(
                title: 'Diproses',
                isCompleted: currentIndex > 1,
                isActive: currentIndex == 1,
              ),
              _TrackingStep(
                title: 'Dikirim',
                isCompleted: currentIndex > 2,
                isActive: currentIndex == 2,
              ),
              _TrackingStep(
                title: 'Selesai',
                isCompleted: currentIndex == 3,
                isActive: currentIndex == 3,
                isLast: true,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF6B7280), fontWeight: FontWeight.w600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF111827),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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

class _TrackingStep extends StatelessWidget {
  const _TrackingStep({
    required this.title,
    required this.isCompleted,
    required this.isActive,
    this.isLast = false,
  });

  final String title;
  final bool isCompleted;
  final bool isActive;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final Color activeColor = isCompleted || isActive
        ? const Color(0xFF2563EB)
        : const Color(0xFFCBD5E1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted || isActive
                    ? const Color(0xFFEFF6FF)
                    : const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: activeColor, width: 1.5),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check_rounded
                    : isActive
                        ? Icons.hourglass_top_rounded
                        : Icons.circle_outlined,
                size: 18,
                color: activeColor,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 44,
                color: isCompleted ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 18),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isCompleted || isActive ? const Color(0xFFF8FAFC) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isCompleted || isActive ? const Color(0xFFD7E3FF) : const Color(0xFFE5E7EB),
              ),
            ),
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isCompleted || isActive ? const Color(0xFF111827) : const Color(0xFF64748B),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
