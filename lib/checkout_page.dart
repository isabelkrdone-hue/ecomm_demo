import 'package:flutter/material.dart';

import 'cart_model.dart';

const Color _checkoutPrimary = Color(0xFF2563EB);
const Color _checkoutBackground = Color(0xFFF8FAFC);
const Color _checkoutText = Color(0xFF111827);
const Color _checkoutBorder = Color(0xFFD7E3FF);

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({
    super.key,
    this.items,
    this.clearCartOnConfirm = true,
  });

  final List<Map<String, dynamic>>? items;
  final bool clearCartOnConfirm;

  List<Map<String, dynamic>> get _checkoutItems =>
      items ?? CartModel.instance.items;

  int _priceValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final digits = value?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    return int.tryParse(digits) ?? 0;
  }

  String _priceLabel(Map<String, dynamic> item) {
    final raw = item['price'];
    if (raw is String && raw.trim().isNotEmpty) {
      return raw;
    }
    return CartModel.formatPrice(_priceValue(item['priceValue'] ?? raw));
  }

  int _totalPrice(List<Map<String, dynamic>> items) {
    return items.fold<int>(
      0,
      (sum, item) => sum + _priceValue(item['priceValue'] ?? item['price']),
    );
  }

  Future<void> _handleConfirm(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pesanan berhasil'),
          content: const Text(
            'Checkout berhasil dibuat. Terima kasih sudah berbelanja.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

    if (clearCartOnConfirm) {
      CartModel.instance.clear();
    }

    if (context.mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _checkoutBackground,
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: _checkoutText,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: CartModel.instance,
        builder: (context, _) {
          final checkoutItems = _checkoutItems;
          if (checkoutItems.isEmpty) {
            return const Center(
              child: Text(
                'Keranjang kosong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            );
          }

          final total = _totalPrice(checkoutItems);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoCard(
                title: 'Alamat Pengiriman',
                content: 'Alamat utama tersimpan di profil',
                icon: Icons.location_on_outlined,
              ),
              const SizedBox(height: 12),
              _buildInfoCard(
                title: 'Metode Pembayaran',
                content: 'COD / Transfer Bank',
                icon: Icons.payments_outlined,
              ),
              const SizedBox(height: 20),
              const Text(
                'Ringkasan Pesanan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              ...checkoutItems.map(
                (item) => Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: _checkoutBorder),
                  ),
                  child: ListTile(
                    title: Text(
                      item['name'] as String? ?? '-',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(_priceLabel(item)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: const BorderSide(color: _checkoutBorder),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Bayar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        CartModel.formatPrice(total),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _checkoutPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () => _handleConfirm(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _checkoutPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Konfirmasi Pesanan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: _checkoutBorder),
      ),
      child: ListTile(
        leading: Icon(icon, color: _checkoutPrimary),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(content),
      ),
    );
  }
}
