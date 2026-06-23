import 'package:flutter/material.dart';

import 'app_ui.dart';
import 'app_ui_skeletons.dart';
import 'cart_model.dart';
import 'shop_image.dart';
import 'payment_page.dart';

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Keranjang'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: AnimatedBuilder(
        animation: CartModel.instance,
        builder: (context, _) {
          final items = CartModel.instance.items;

          if (items.isEmpty) {
            return EmptyStateView(
              icon: Icons.shopping_cart_outlined,
              title: 'Keranjang kamu masih kosong',
              subtitle:
                  'Tambahkan produk favorit dari halaman detail untuk mulai checkout dengan cepat.',
              action: FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Mulai Belanja'),
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final name = item['name']?.toString() ?? '-';
                    final priceValue = item['priceValue'] ?? item['price'];
                    final unitPrice = _parsePrice(priceValue);
                    final price = CartModel.formatPrice(unitPrice);
                    final quantity = _quantityFor(item);
                    final subtotal = unitPrice * quantity;
                    final imageUrl =
                        (item['image'] ?? item['imagePath'] ?? '').toString();
                    final category = item['category']?.toString() ?? '';
                    final businessName = item['businessName']?.toString() ?? '';

                    return Card(
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
                              child: ShopImage(
                                imagePath: imageUrl,
                                width: 84,
                                height: 84,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  if (businessName.isNotEmpty ||
                                      category.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      [
                                        if (businessName.isNotEmpty)
                                          businessName,
                                        if (category.isNotEmpty) category
                                      ].join(' • '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 6),
                                  Text(
                                    '$price / item',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      _quantityButton(
                                        icon: Icons.remove_rounded,
                                        enabled: quantity > 1,
                                        onTap: () => CartModel.instance
                                            .decrementQuantity(index),
                                      ),
                                      Container(
                                        width: 42,
                                        height: 32,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF8FAFC),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          border: Border.all(
                                            color: const Color(0xFFE2E8F0),
                                          ),
                                        ),
                                        child: Text(
                                          '$quantity',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF111827),
                                          ),
                                        ),
                                      ),
                                      _quantityButton(
                                        icon: Icons.add_rounded,
                                        enabled: true,
                                        onTap: () => CartModel.instance
                                            .incrementQuantity(index),
                                      ),
                                      const Spacer(),
                                      TextButton.icon(
                                        onPressed: () {
                                          CartModel.instance.removeAt(index);
                                          showFakeNotification(
                                            context,
                                            '$name dihapus dari cart',
                                            backgroundColor:
                                                const Color(0xFFDC2626),
                                            icon: Icons.delete_outline_rounded,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                        ),
                                        label: const Text('Hapus'),
                                        style: TextButton.styleFrom(
                                          foregroundColor:
                                              const Color(0xFFEF4444),
                                          padding: EdgeInsets.zero,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (quantity > 1) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Subtotal ${CartModel.formatPrice(subtotal)}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          CartModel.instance.formattedTotal,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          showFakeNotification(
                            context,
                            'Membuka halaman checkout',
                            backgroundColor: const Color(0xFF2563EB),
                            icon: Icons.payments_rounded,
                          );
                          Navigator.of(context).push(
                            buildPageRoute(
                              PaymentPage(
                                totalHarga: CartModel.instance.totalPrice,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Checkout',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _quantityButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: SizedBox(
        width: 32,
        height: 32,
        child: IconButton(
          onPressed: enabled ? onTap : null,
          icon: Icon(icon, size: 18),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          style: IconButton.styleFrom(
            backgroundColor: enabled ? Colors.white : const Color(0xFFF1F5F9),
            foregroundColor:
                enabled ? const Color(0xFF111827) : const Color(0xFFCBD5E1),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }

  int _quantityFor(Map<String, dynamic> item) {
    final value = item['quantity'] ?? item['qty'];
    if (value is int) return value < 1 ? 1 : value;
    if (value is num) return value < 1 ? 1 : value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 1) return 1;
    return parsed;
  }

  int _parsePrice(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final text = value?.toString() ?? '';
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }
}
