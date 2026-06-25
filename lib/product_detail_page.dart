import 'package:flutter/material.dart';

import 'app_ui.dart';
import 'business_detail_page.dart';
import 'business_model.dart';
import 'cart_model.dart';
import 'checkout_page.dart';
import 'shop_image.dart';

class ProductDetailPage extends StatelessWidget {
  const ProductDetailPage({super.key, required this.product});

  final Map<String, dynamic> product;

  int _priceValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    final digits = value?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    return int.tryParse(digits) ?? 0;
  }

  String _priceLabel(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value;
    return CartModel.formatPrice(_priceValue(value));
  }

  Map<String, dynamic>? _businessByName(String? name) {
    final target = name?.trim() ?? '';
    if (target.isEmpty) return null;
    return BusinessModel.instance.getBusinessByName(target);
  }

  String _verificationStatus(Map<String, dynamic>? business) {
    return (business?['verificationStatus'] as String? ?? 'pending')
        .toLowerCase();
  }

  String _locationLabel(Map<String, dynamic>? business) {
    if (business == null) return 'Lokasi belum tersedia';
    final regency = (business['regency'] ?? business['city'] ?? '').toString();
    if (regency.trim().isNotEmpty) return regency.trim();
    final city = (business['city'] ?? '').toString().trim();
    if (city.isNotEmpty) return city;
    return 'Lokasi belum tersedia';
  }

  Color _verificationColor(String status) {
    switch (status) {
      case 'verified':
        return const Color(0xFF16A34A);
      case 'processing':
        return const Color(0xFFF59E0B);
      case 'rejected':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _verificationLabel(String status) {
    switch (status) {
      case 'verified':
        return 'Terverifikasi';
      case 'processing':
        return 'Sedang diverifikasi';
      case 'rejected':
        return 'Ditolak';
      default:
        return 'Menunggu verifikasi';
    }
  }

  void _addToCart(BuildContext context) {
    CartModel.instance.addToCart(product);
    showFakeNotification(
      context,
      'Produk ditambahkan ke cart',
      backgroundColor: const Color(0xFF2563EB),
      icon: Icons.add_shopping_cart_rounded,
    );
  }

  void _checkoutNow(BuildContext context) {
    Navigator.of(context).push(
      buildPageRoute(
        CheckoutPage(
          items: [product],
          clearCartOnConfirm: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String name = product['name'] as String? ?? '-';
    final priceValue = product['price'];
    final String price = _priceLabel(priceValue);
    final String imageUrl =
        (product['image'] as String? ?? product['imagePath'] as String? ?? '');
    final String description = product['description'] as String? ??
        (product['businessName'] != null
            ? 'Produk dari ${product['businessName']}'
            : 'Deskripsi produk belum tersedia.');
    final String category = product['category'] as String? ?? 'Lainnya';
    final businessName = product['businessName'] as String?;
    final business = _businessByName(businessName);
    final status = _verificationStatus(business);
    final statusColor = _verificationColor(status);
    final statusLabel = _verificationLabel(status);
    final locationLabel = _locationLabel(business);

    return Scaffold(
      backgroundColor: const Color(0xFF07111B),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Detail Produk',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          _headerAction(
            icon: Icons.share_outlined,
            onTap: () {
              showFakeNotification(
                context,
                'Fitur share belum dihubungkan',
                backgroundColor: const Color(0xFF334155),
                icon: Icons.share_outlined,
              );
            },
          ),
          const SizedBox(width: 8),
          _headerAction(
            icon: Icons.favorite_border_rounded,
            onTap: () {
              showFakeNotification(
                context,
                'Ditambahkan ke favorit',
                backgroundColor: const Color(0xFF334155),
                icon: Icons.favorite_rounded,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0C1724).withOpacity(0.96),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.22),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _addToCart(context),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                  label: const Text('Add to Cart'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.18)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _checkoutNow(context),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  label: const Text('Checkout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF29B2F),
                    foregroundColor: const Color(0xFF07111B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0A1A29), Color(0xFF13283D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.28),
                          blurRadius: 28,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: AspectRatio(
                            aspectRatio: 1.02,
                            child: Hero(
                              tag: 'product-image-$name',
                              child: ShopImage(
                                imagePath: imageUrl,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 16,
                          child: _pill(
                            label: category,
                            background: Colors.white.withOpacity(0.14),
                            foreground: Colors.white,
                          ),
                        ),
                        Positioned(
                          right: 16,
                          top: 16,
                          child: _pill(
                            label: statusLabel,
                            background: statusColor.withOpacity(0.18),
                            foreground: Colors.white,
                          ),
                        ),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.26),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.10),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.location_on_outlined,
                                            size: 14,
                                            color: Colors.white70,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              locationLabel,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF29B2F),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: Text(
                                    price,
                                    style: const TextStyle(
                                      color: Color(0xFF07111B),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFF8FAFC),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                statusLabel,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFF29B2F),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _miniInfoChip(category, Icons.category_outlined),
                            _miniInfoChip(
                              businessName?.isNotEmpty == true
                                  ? businessName!
                                  : 'No seller',
                              Icons.storefront_rounded,
                            ),
                            _miniInfoChip(locationLabel, Icons.place_outlined),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Seller',
                    trailing: business != null ? 'Lihat toko' : null,
                    onTrailingTap: business == null
                        ? null
                        : () {
                            Navigator.of(context).push(
                              buildPageRoute(
                                BusinessDetailPage(business: business),
                              ),
                            );
                          },
                    child: business == null
                        ? const Text(
                            'Informasi seller belum tersedia.',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              height: 1.6,
                            ),
                          )
                        : InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                buildPageRoute(
                                  BusinessDetailPage(business: business),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6C7BFF),
                                        Color(0xFF8F7CF8),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.storefront_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        business['name'] as String? ?? '-',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFFF8FAFC),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        locationLabel,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF94A3B8),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                _verificationBadge(statusLabel, statusColor),
                              ],
                            ),
                          ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Description',
                    child: Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFFCBD5E1),
                        height: 1.7,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  _sectionCard(
                    title: 'Quick Details',
                    child: Column(
                      children: [
                        _detailRow('Product', name),
                        const SizedBox(height: 12),
                        _detailRow('Category', category),
                        const SizedBox(height: 12),
                        _detailRow(
                          'Seller',
                          businessName?.isNotEmpty == true
                              ? businessName!
                              : 'Unknown',
                        ),
                        const SizedBox(height: 12),
                        _detailRow('Location', locationLabel),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerAction({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: Material(
        color: Colors.white.withOpacity(0.08),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    String? title,
    String? trailing,
    VoidCallback? onTrailingTap,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1724),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Row(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                if (trailing != null)
                  InkWell(
                    onTap: onTrailingTap,
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      child: Text(
                        trailing,
                        style: const TextStyle(
                          color: Color(0xFFF29B2F),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          if (title != null) const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _miniInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFF29B2F)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verificationBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 92,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _pill({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
