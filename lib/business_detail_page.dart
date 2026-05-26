import 'dart:io';
import 'package:flutter/material.dart';

import 'app_ui.dart';
import 'business_model.dart';
import 'cart_model.dart';
import 'product_detail_page.dart';

class BusinessDetailPage extends StatefulWidget {
  const BusinessDetailPage({super.key, required this.business});

  final Map<String, dynamic> business;

  @override
  State<BusinessDetailPage> createState() => _BusinessDetailPageState();
}

class _BusinessDetailPageState extends State<BusinessDetailPage> {
  final _businessModel = BusinessModel.instance;

  @override
  void initState() {
    super.initState();
    _businessModel.addListener(_refresh);
  }

  @override
  void dispose() {
    _businessModel.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  Map<String, dynamic> get _currentBusiness {
    final targetName = widget.business['name'] as String?;
    if (targetName != null && targetName.isNotEmpty) {
      for (final business in _businessModel.getAllBusinesses()) {
        if ((business['name'] as String? ?? '') == targetName) {
          return business;
        }
      }
    }
    return widget.business;
  }

  String _verificationStatus(Map<String, dynamic> business) {
    return (business['verificationStatus'] as String? ?? 'pending').toLowerCase();
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

  Widget _verificationChip(Map<String, dynamic> business) {
    final status = _verificationStatus(business);
    final color = _verificationColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _verificationLabel(status),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF111827);
    const primary = Color(0xFF6C7BFF);
    final business = _currentBusiness;
    
    // Products are now stored as Maps with full details
    final businessProducts = (business['products'] as List? ?? [])
        .map((product) => product is Map<String, dynamic> ? product : <String, dynamic>{})
        .where((p) => p.isNotEmpty)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                business['name'] as String? ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6C7BFF), Color(0xFF8F7CF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      size: 48,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Info Card
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Bisnis',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (business['businessType'] != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _InfoRow(
                                icon: Icons.business_center_rounded,
                                label: 'Tipe Bisnis',
                                value: business['businessType'] as String? ?? '-',
                              ),
                            ),
                          _InfoRow(
                            icon: Icons.description_rounded,
                            label: 'Deskripsi',
                            value: business['description'] as String? ?? '-',
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.phone_rounded,
                            label: 'Telepon',
                            value: business['phone'] as String? ?? '-',
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.location_on_rounded,
                            label: 'Alamat',
                            value: business['address'] as String? ?? '-',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Warehouse Location Card
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.warehouse_rounded,
                                  color: primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Lokasi Gudang',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _LocationChip(
                            icon: Icons.map_rounded,
                            label: 'Provinsi',
                            value: business['province'] as String? ?? '-',
                          ),
                          const SizedBox(height: 8),
                          _LocationChip(
                            icon: Icons.location_city_rounded,
                            label: 'Kota/Kabupaten',
                            value: business['city'] as String? ?? '-',
                          ),
                          const SizedBox(height: 8),
                          _LocationChip(
                            icon: Icons.place_rounded,
                            label: 'Kecamatan',
                            value: business['district'] as String? ?? '-',
                          ),
                          const SizedBox(height: 8),
                          _LocationChip(
                            icon: Icons.pin_drop_rounded,
                            label: 'Kelurahan',
                            value: business['subDistrict'] as String? ?? '-',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Status Verifikasi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _verificationChip(business),
                              if (_verificationStatus(business) == 'verified')
                                const _MiniInfoChip(
                                  icon: Icons.verified_rounded,
                                  label: 'Bisa jual produk',
                                  color: Color(0xFF16A34A),
                                ),
                              if (_verificationStatus(business) == 'processing')
                                const _MiniInfoChip(
                                  icon: Icons.hourglass_top_rounded,
                                  label: 'Sedang diproses',
                                  color: Color(0xFFF59E0B),
                                ),
                              if (_verificationStatus(business) == 'pending')
                                const _MiniInfoChip(
                                  icon: Icons.lock_rounded,
                                  label: 'Fitur seller masih terkunci',
                                  color: Color(0xFF64748B),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Status ini menentukan apakah toko sudah siap dipakai untuk jualan.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Products Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Produk yang Dijual',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${businessProducts.length} Produk',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  if (businessProducts.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      alignment: Alignment.center,
                      child: const Text(
                        'Tidak ada produk',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: businessProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final product = businessProducts[index];
                        return _BusinessProductCard(
                          product: product,
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  
                  // Reviews Section
                  const Text(
                    'Review Pelanggan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Builder(
                    builder: (context) {
                      final reviews = (business['reviews'] as List? ?? [])
                          .whereType<Map>()
                          .map((review) => Map<String, dynamic>.from(review))
                          .toList();
                      
                      if (reviews.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 48),
                          alignment: Alignment.center,
                          child: const Text(
                            'Belum ada review',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        );
                      }
                      
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: reviews.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final review = reviews[index];
                          return _ReviewCard(review: review);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF6C7BFF),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF111827),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final Map<String, dynamic> review;

  @override
  Widget build(BuildContext context) {
    final rating = review['rating'] as int? ?? 0;
    final comment = review['comment'] as String? ?? '';
    final images = (review['images'] as List? ?? []).cast<String>();
    final date = review['date'] as DateTime?;
    
    return Card(
      elevation: 0,
      color: Colors.white,
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
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6C7BFF), Color(0xFF8F7CF8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pembeli',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      if (date != null)
                        Text(
                          _formatDate(date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                    ],
                  ),
                ),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                      size: 18,
                      color: index < rating
                          ? const Color(0xFFFBBF24)
                          : const Color(0xFFD1D5DB),
                    );
                  }),
                ),
              ],
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                comment,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF374151),
                  height: 1.5,
                ),
              ),
            ],
            if (images.isNotEmpty) ...[
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(images[index]),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 80,
                            color: const Color(0xFFF8FAFC),
                            child: const Icon(
                              Icons.image,
                              color: Color(0xFF94A3B8),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: const Color(0xFF6C7BFF),
          ),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniInfoChip extends StatelessWidget {
  const _MiniInfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }
}

class _BusinessProductCard extends StatelessWidget {
  const _BusinessProductCard({required this.product});

  final Map<String, dynamic> product;

  void _addToCart(BuildContext context) {
    final priceValue = product['price'];
    final priceText = priceValue is num
        ? CartModel.formatPrice(priceValue.toInt())
        : (priceValue?.toString() ?? 'Rp 0');

    CartModel.instance.addToCart({
      'name': product['name'],
      'price': priceText,
      'image': product['imagePath'] ?? 'assets/images/placeholder.png',
      'category': product['category'] ?? 'Lainnya',
      'description': product['description'] ?? 'Produk berkualitas',
      'businessName': product['businessName'],
    });

    showFakeNotification(
      context,
      '${product['name']} ditambahkan ke keranjang',
      backgroundColor: const Color(0xFF059669),
      icon: Icons.shopping_cart_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = product['imagePath'] as String?;
    final priceValue = product['price'];
    final priceText = priceValue is num
        ? CartModel.formatPrice(priceValue.toInt())
        : (priceValue?.toString() ?? 'Rp 0');
    final category = product['category'] as String? ?? '';
    final description = product['description'] as String? ?? 'Produk berkualitas';
    final businessName = product['businessName'] as String? ?? '';
    final business = businessName.isEmpty ? null : BusinessModel.instance.getBusinessByName(businessName);
    final status = (business?['verificationStatus'] as String? ?? 'pending').toLowerCase();
    final statusColor = status == 'verified'
        ? const Color(0xFF16A34A)
        : status == 'processing'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF64748B);
    final statusLabel = status == 'verified'
        ? 'Terverifikasi'
        : status == 'processing'
            ? 'Proses verifikasi'
            : businessName.isEmpty
                ? 'Produk Pribadi'
                : 'Menunggu verifikasi';

    final detailProduct = {
      'name': product['name'],
      'price': priceText,
      'image': imagePath ?? 'assets/images/placeholder.png',
      'category': category.isNotEmpty ? category : 'Lainnya',
      'description': description,
      'businessName': businessName,
    };

    return TapScale(
      onTap: () {
        Navigator.of(context).push(
          buildPageRoute(ProductDetailPage(product: detailProduct)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 96,
                  height: 96,
                  child: imagePath != null && imagePath.isNotEmpty
                      ? Image.file(
                          File(imagePath),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: const Color(0xFFF8FAFC),
                              child: const Icon(
                                Icons.image,
                                size: 36,
                                color: Color(0xFF94A3B8),
                              ),
                            );
                          },
                        )
                      : Container(
                          color: const Color(0xFFF8FAFC),
                          child: const Icon(
                            Icons.inventory_2_outlined,
                            size: 36,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (businessName.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          businessName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4338CA),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Produk Pribadi',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      product['name'] as String? ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (category.isNotEmpty)
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      priceText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6C7BFF),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                buildPageRoute(ProductDetailPage(product: detailProduct)),
                              );
                            },
                            icon: const Icon(Icons.visibility_rounded, size: 16),
                            label: const Text('Detail'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2563EB),
                              side: const BorderSide(color: Color(0xFFD7DBFF)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _addToCart(context),
                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                            label: const Text('Tambah'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
