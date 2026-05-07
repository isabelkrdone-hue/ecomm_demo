import 'package:flutter/material.dart';

import 'add_business_page.dart';
import 'add_product_page.dart';
import 'app_ui.dart';
import 'business_detail_page.dart';
import 'business_model.dart';
import 'cart_model.dart';
import 'order_history_model.dart';
import 'product_data.dart';
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
                    const SizedBox(height: 14),
                    Row(children: [Expanded(child: ElevatedButton.icon(onPressed: _openAddProduct, icon: const Icon(Icons.add_box_rounded), label: const Text('Tambah Produk'), style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: primary))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: _openAddStore, icon: const Icon(Icons.store_rounded), label: const Text('Kelola Toko'), style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white70))))]),
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
            subtitle: Text('${p['category'] ?? 'Lainnya'} • ${p['businessName'] ?? 'Toko kamu'}'),
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
            subtitle: Text('${b['city'] ?? ''}, ${b['province'] ?? ''} • ${(b['products'] as List? ?? []).length} produk'),
            trailing: PopupMenuButton<String>(
              onSelected: (v) {
                if (v == 'edit') _openEditStore(b, i);
                if (v == 'delete') _deleteStore(i);
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Hapus')),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openEditStore(Map<String, dynamic> business, int index) async {
    await Navigator.of(context).push(buildPageRoute(AddBusinessPage(existingBusiness: business, businessIndex: index)));
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
}

class MyBusinessesPage extends StatelessWidget {
  const MyBusinessesPage({super.key});

  @override
  Widget build(BuildContext context) => const SellerCenterPage();
}
