import 'package:flutter/material.dart';

import 'app_ui.dart';
import 'edit_product_page.dart';
import 'product_data.dart';
import 'product_detail_page.dart';
import 'shop_image.dart';

class MyProductsPage extends StatefulWidget {
  const MyProductsPage({super.key});

  @override
  State<MyProductsPage> createState() => _MyProductsPageState();
}

class _MyProductsPageState extends State<MyProductsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> get _allUserProducts {
    return allProducts.where((product) => product['isUserProduct'] == true).toList();
  }

  List<Map<String, dynamic>> get _filteredUserProducts {
    final products = _allUserProducts;

    if (_searchQuery.trim().isEmpty) {
      return products;
    }

    final query = _searchQuery.trim().toLowerCase();
    return products.where((product) {
      final name = (product['name'] as String? ?? '').toLowerCase();
      final category = (product['category'] as String? ?? '').toLowerCase();
      final price = (product['price'] as String? ?? '').toLowerCase();
      final description = (product['description'] as String? ?? '').toLowerCase();
      return name.contains(query) ||
          category.contains(query) ||
          price.contains(query) ||
          description.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  Future<void> _openDetailProduct(Map<String, dynamic> product) async {
    await Navigator.of(context).push(
      buildPageRoute(ProductDetailPage(product: product)),
    );
  }

  Future<void> _openEditProduct(Map<String, dynamic> product) async {
    final productIndex = allProducts.indexOf(product);
    if (productIndex < 0) return;

    await Navigator.of(context).push(
      buildPageRoute(
        EditProductPage(
          product: product,
          productIndex: productIndex,
        ),
      ),
    );

    if (!mounted) return;
    setState(() {});
  }

  Future<void> _deleteProduct(Map<String, dynamic> product) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Produk'),
          content: const Text('Yakin ingin menghapus produk ini?'),
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
        );
      },
    );

    if (shouldDelete != true) return;

    final index = allProducts.indexOf(product);
    if (index < 0) return;

    setState(() {
      allProducts.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF7F8FC);
    const primary = Color(0xFF6C7BFF);
    const textColor = Color(0xFF111827);

    final allUserProducts = _allUserProducts;
    final products = _filteredUserProducts;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Produk Saya',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textColor,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            if (allUserProducts.isEmpty)
              const _EmptyState(message: 'Belum ada produk')
            else if (products.isEmpty)
              const _EmptyState(message: 'Produk tidak ditemukan')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 88,
                              height: 88,
                              child: ShopImage(
                                imagePath: product['image'] as String? ?? '',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        product['name'] as String? ?? '-',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                                const SizedBox(height: 6),
                                Text(
                                  product['price'] as String? ?? '-',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF6C7BFF),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    product['category'] as String? ?? '-',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF475569),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openDetailProduct(product),
                                        icon: const Icon(Icons.visibility_rounded, size: 18),
                                        label: const Text('Detail'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFF0F766E),
                                          side: const BorderSide(color: Color(0xFFB2F5EA)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openEditProduct(product),
                                        icon: const Icon(Icons.edit_rounded, size: 18),
                                        label: const Text('Edit'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: primary,
                                          side: const BorderSide(color: Color(0xFFD7DBFF)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _deleteProduct(product),
                                        icon: const Icon(Icons.delete_rounded, size: 18),
                                        label: const Text('Hapus'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: const Color(0xFFDC2626),
                                          side: const BorderSide(color: Color(0xFFFECACA)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
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
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _updateSearch,
        decoration: InputDecoration(
          hintText: 'Cari produk saya...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _updateSearch('');
                  },
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Hapus pencarian',
                ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.center,
      child: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}
