import 'package:flutter/material.dart';

import 'cart_model.dart';

const Color _checkoutPrimary = Color(0xFF2563EB);
const Color _checkoutBackground = Color(0xFFF8FAFC);
const Color _checkoutText = Color(0xFF111827);
const Color _checkoutBorder = Color(0xFFD7E3FF);

class CheckoutPage extends StatelessWidget {
  const CheckoutPage({super.key});

  Future<void> _handleConfirm(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Pesanan berhasil'),
          content: const Text('Checkout berhasil dibuat. Terima kasih sudah berbelanja.'),
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

    CartModel.instance.clear();
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
          final items = CartModel.instance.items;

          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Keranjang kosong',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildInfoCard(
                title: 'Alamat Pengiriman',
                content: 'Jl. Contoh No. 123, Jakarta',
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
              ...items.map(
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
                    subtitle: Text(item['price'] as String? ?? '-'),
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
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        CartModel.instance.formattedTotal,
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
