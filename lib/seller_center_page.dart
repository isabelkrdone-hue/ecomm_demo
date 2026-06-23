import 'package:flutter/material.dart';

import 'add_business_page.dart';
import 'add_product_page.dart';
import 'app_ui.dart';
import 'business_detail_page.dart';
import 'business_model.dart';
import 'cart_model.dart';
import 'order_history_model.dart';
import 'product_data.dart';
import 'seller_verification_page.dart';
import 'shop_image.dart';

class SellerCenterPage extends StatefulWidget {
  const SellerCenterPage({super.key});

  @override
  State<SellerCenterPage> createState() => _SellerCenterPageState();
}

class _SellerCenterPageState extends State<SellerCenterPage> {
  final _businessModel = BusinessModel.instance;
  final _orderModel = OrderHistoryModel.instance;

  @override
  void initState() {
    super.initState();
    _businessModel.addListener(_refresh);
    _orderModel.addListener(_refresh);
  }

  @override
  void dispose() {
    _businessModel.removeListener(_refresh);
    _orderModel.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  List<Map<String, dynamic>> get _businesses => _businessModel.getAllBusinesses();
  List<Map<String, dynamic>> get _products {
    final items = <Map<String, dynamic>>[];
    for (final p in allProducts) {
      if (p['isUserProduct'] == true) items.add(Map<String, dynamic>.from(p));
    }
    items.addAll(_businessModel.getAllBusinessProducts());
    return items;
  }
  List<Map<String, dynamic>> get _orders => _orderModel.orders.toList();

  int get _revenue => _orders.fold<int>(0, (sum, o) {
        final v = o['totalHarga'] ?? o['total'] ?? 0;
        if (v is int) return sum + v;
        if (v is num) return sum + v.toInt();
        return sum + (int.tryParse(v.toString()) ?? 0);
      });

  Map<String, int> get _categoryCounts {
    final counts = <String, int>{};
    for (final product in _products) {
      final category = product['category'] as String? ?? 'Lainnya';
      counts[category] = (counts[category] ?? 0) + 1;
    }
    return counts;
  }

  Future<void> _openAddProduct() async {
    await Navigator.of(context).push(buildPageRoute(const AddProductPage()));
    _refresh();
  }

  Future<void> _openAddStore() async {
    await Navigator.of(context).push(buildPageRoute(const AddBusinessPage()));
    _refresh();
  }

  Future<void> _openVerification([int? businessIndex]) async {
    await Navigator.of(context).push(
      buildPageRoute(
        SellerVerificationPage(businessIndex: businessIndex),
      ),
    );
    _refresh();
  }

  int? _firstUnverifiedBusinessIndex() {
    for (var i = 0; i < _businesses.length; i++) {
      if (!_businessModel.isVerified(_businesses[i])) return i;
    }
    return _businesses.isEmpty ? null : 0;
  }

  bool get _hasVerifiedBusiness => _businessModel.hasVerifiedBusiness;

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF2563EB);
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          title: const Text('Seller Center', style: TextStyle(fontWeight: FontWeight.w700)),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF111827),
          elevation: 0,
          bottom: const TabBar(
            isScrollable: true,
            labelColor: primary,
            unselectedLabelColor: Color(0xFF64748B),
            indicatorColor: primary,
            tabs: [
              Tab(text: 'Produk', icon: Icon(Icons.inventory_2_rounded)),
              Tab(text: 'Toko', icon: Icon(Icons.store_rounded)),
              Tab(text: 'Pesanan', icon: Icon(Icons.receipt_long_rounded)),
              Tab(text: 'Statistik', icon: Icon(Icons.bar_chart_rounded)),
            ],
          ),
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF4F46E5)]),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Kelola toko, produk, dan pesanan', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 10),
                    Row(children: [_stat('Toko', '${_businesses.length}'), const SizedBox(width: 8), _stat('Produk', '${_products.length}')]),
                    const SizedBox(height: 8),
                    Row(children: [_stat('Pesanan', '${_orders.length}'), const SizedBox(width: 8), _stat('Omzet', CartModel.formatPrice(_revenue))]),
                    const SizedBox(height: 10),
                    if (!_hasVerifiedBusiness)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.lock_rounded, color: Colors.white, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Beberapa fitur seller terkunci sampai toko terverifikasi.',
                                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openVerification(_firstUnverifiedBusinessIndex()),
                        icon: const Icon(Icons.verified_user_rounded),
                        label: const Text('Verifikasi Seller'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white70),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(children: [_productsTab(), _storesTab(), _ordersTab(), _statsTab()]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.14), borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11))]),
      ),
    );
  }

  Widget _empty(String title, String subtitle, VoidCallback onTap) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.store_rounded, size: 48, color: Color(0xFF2563EB)),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
            const SizedBox(height: 14),
            ElevatedButton(onPressed: onTap, child: const Text('Mulai Sekarang')),
          ]),
        ),
      );

  Widget _productsTab() {
    if (_products.isEmpty) return _empty('Belum ada produk', 'Upload produk supaya muncul di dashboard.', _openAddProduct);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final p = _products[i];
        final price = p['price'];
        final priceText = price is num ? CartModel.formatPrice(price.toInt()) : (price?.toString() ?? 'Rp 0');
        return Card(
          elevation: 0,
          child: ListTile(
            leading: ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 56, height: 56, child: ShopImage(imagePath: (p['imagePath'] ?? p['image'] ?? 'assets/images/placeholder.png').toString(), fit: BoxFit.cover))),
            title: Text(p['name'] as String? ?? '-', maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    _verificationBadgeForProduct(p),
                  ],
                ),
                const SizedBox(height: 6),
                Text('${p['category'] ?? 'Lainnya'} • ${p['businessName'] ?? 'Toko kamu'}', maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
            trailing: Text(priceText, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
          ),
        );
      },
    );
  }

  Widget _storesTab() {
    if (_businesses.isEmpty) return _empty('Belum ada toko', 'Buat toko dulu untuk kelola produk.', _openAddStore);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _businesses.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final b = _businesses[i];
        return Card(
          elevation: 0,
          child: ListTile(
            onTap: () => Navigator.of(context).push(buildPageRoute(BusinessDetailPage(business: b))),
            leading: const CircleAvatar(child: Icon(Icons.store_rounded)),
            title: Text(b['name'] as String? ?? '-'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${b['city'] ?? ''}, ${b['province'] ?? ''} • ${(b['products'] as List? ?? []).length} produk'),
                const SizedBox(height: 6),
                _verificationChip(b),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _openEditStore(b, i);
                if (v == 'verify') _openVerification(i);
                if (v == 'delete') _deleteStore(i);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'verify', child: Text('Verifikasi')),
                PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditStore(Map<String, dynamic> business, int index) async {
    // AddBusinessPage no longer accepts existingBusiness/businessIndex.
    // Open the AddBusinessPage for creating a new store instead.
    await Navigator.of(context).push(buildPageRoute(const AddBusinessPage()));
    _refresh();
  }

  Future<void> _deleteStore(int index) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus toko?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok == true) _businessModel.deleteBusiness(index);
  }

  Widget _ordersTab() {
    if (_orders.isEmpty) return _empty('Belum ada pesanan', 'Pesanan dari checkout akan muncul di sini.', () {});
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final o = _orders[i];
        final total = o['totalHarga'] ?? o['total'] ?? 0;
        final totalText = total is num ? CartModel.formatPrice(total.toInt()) : total.toString();
        return Card(
          elevation: 0,
          child: ListTile(
            title: Text(o['id'] as String? ?? '-'),
            subtitle: Text('${o['status'] ?? '-'} • ${(o['products'] as List? ?? []).length} produk\n${OrderHistoryModel.formatDateTime((o['date'] as DateTime?) ?? DateTime.now())}'),
            trailing: Text(totalText, style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF2563EB))),
          ),
        );
      },
    );
  }

  Widget _statsTab() {
    final cats = _categoryCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(children: [_statCard('Toko', '${_businesses.length}', Icons.store_rounded), const SizedBox(width: 12), _statCard('Produk', '${_products.length}', Icons.inventory_2_rounded)]),
        const SizedBox(height: 12),
        Row(children: [_statCard('Pesanan', '${_orders.length}', Icons.receipt_long_rounded), const SizedBox(width: 12), _statCard('Omzet', CartModel.formatPrice(_revenue), Icons.payments_rounded)]),
        const SizedBox(height: 16),
        const Text('Kategori Terbanyak', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: cats.map((e) => Chip(label: Text('${e.key} (${e.value})'))).toList()),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [Icon(icon, color: const Color(0xFF2563EB)), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)), Text(label, style: const TextStyle(color: Color(0xFF64748B)))]))]),
        ),
      ),
    );
  }

  Widget _verificationChip(Map<String, dynamic> business) {
    final status = (business['verificationStatus'] as String? ?? 'pending').toLowerCase();
    Color color;
    String label;
    switch (status) {
      case 'verified':
        color = const Color(0xFF16A34A);
        label = 'Terverifikasi';
        break;
      case 'processing':
        color = const Color(0xFFF59E0B);
        label = 'Sedang diverifikasi';
        break;
      case 'rejected':
        color = const Color(0xFFDC2626);
        label = 'Ditolak';
        break;
      default:
        color = const Color(0xFF64748B);
        label = 'Menunggu verifikasi';
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }

  Widget _verificationBadgeForProduct(Map<String, dynamic> product) {
    final businessName = (product['businessName'] as String? ?? '').trim();
    final business = businessName.isEmpty ? null : _businessModel.getBusinessByName(businessName);
    final status = (business?['verificationStatus'] as String? ?? 'pending').toLowerCase();

    Color color;
    String label;
    switch (status) {
      case 'verified':
        color = const Color(0xFF16A34A);
        label = 'Terverifikasi';
        break;
      case 'processing':
        color = const Color(0xFFF59E0B);
        label = 'Proses verifikasi';
        break;
      default:
        color = const Color(0xFF64748B);
        label = businessName.isEmpty ? 'Produk Pribadi' : 'Menunggu verifikasi';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
