import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_ui.dart';
import 'app_ui_skeletons.dart';
import 'business_detail_page.dart';
import 'business_model.dart';
import 'cart_model.dart';
import 'shop_image.dart';
import 'cart_page.dart';
import 'login_page.dart';
import 'order_history_page.dart';
import 'profile_page.dart';
import 'product_data.dart';
import 'product_detail_page.dart';
import 'promo_detail_page.dart';
import 'add_product_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final List<Widget> pages;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    pages = const [
      _DashboardHomeTab(key: ValueKey('dashboard_home')),
      CartPage(key: ValueKey('cart_page')),
      ProfilePage(key: ValueKey('profile_page')),
    ];
  }

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF7F8FC);
    const primary = Color(0xFF6C7BFF);

    return Scaffold(
      backgroundColor: background,
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: primary,
          unselectedItemColor: const Color(0xFF94A3B8),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart),
              label: 'Cart',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

}

class _DashboardHomeTab extends StatefulWidget {
  const _DashboardHomeTab({super.key});

  @override
  State<_DashboardHomeTab> createState() => _DashboardHomeTabState();
}

class _DashboardHomeTabState extends State<_DashboardHomeTab> {
  final TextEditingController _searchController = TextEditingController();
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Semua', 'icon': Icons.apps_rounded},
    {'name': 'Elektronik', 'icon': Icons.devices_rounded},
    {'name': 'Fashion', 'icon': Icons.checkroom_rounded},
    {'name': 'Makanan', 'icon': Icons.restaurant_rounded},
    {'name': 'Kecantikan', 'icon': Icons.face_retouching_natural_rounded},
    {'name': 'Olahraga', 'icon': Icons.fitness_center_rounded},
    {'name': 'Rumah', 'icon': Icons.home_outlined},
  ];

  List<Map<String, dynamic>> filteredProducts = [];
  List<Map<String, dynamic>> filteredBusinesses = [];

  final Set<int> _favoriteIndexes = <int>{1, 3};
  int selectedCategoryIndex = 0;
  String selectedCategory = 'Semua';
  String selectedFilterCategory = 'Semua';
  RangeValues selectedPriceRange = const RangeValues(50000, 1000000);
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    filteredProducts = List<Map<String, dynamic>>.from(allProducts);
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      buildPageRoute(const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _openAddProductPage() async {
    await Navigator.of(context).push(
      buildPageRoute(const AddProductPage()),
    );
    if (!mounted) return;
    _applyAllFilters();
  }

  Future<void> _editUserProduct(Map<String, dynamic> product) async {
    final productIndex = allProducts.indexOf(product);
    if (productIndex < 0) return;

    await Navigator.of(context).push(
      buildPageRoute(
        AddProductPage(
          existingProduct: product,
          productIndex: productIndex,
        ),
      ),
    );
    if (!mounted) return;
    _applyAllFilters();
  }

  Future<void> _deleteUserProduct(Map<String, dynamic> product) async {
    final productIndex = allProducts.indexOf(product);
    if (productIndex < 0) return;

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

    allProducts.removeAt(productIndex);
    _applyAllFilters();
  }

  int _parsePrice(String price) {
    final value = price.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(value) ?? 0;
  }

  void _applyAllFilters() {
    final query = _searchQuery.trim().toLowerCase();

    setState(() {
      filteredProducts = allProducts.where((product) {
        final name = (product['name'] as String? ?? '').toLowerCase();
        final category = product['category'] as String? ?? 'Semua';
        final price = _parsePrice(product['price'] as String? ?? '0');

        final matchSearch = query.isEmpty || name.contains(query);
        final matchCategory = selectedCategory == 'Semua' || category == selectedCategory;
        final matchFilterCategory =
            selectedFilterCategory == 'Semua' || category == selectedFilterCategory;
        final matchPrice =
            price >= selectedPriceRange.start && price <= selectedPriceRange.end;

        return matchSearch && matchCategory && matchFilterCategory && matchPrice;
      }).toList();
      
      // Filter businesses based on search query
      final allBusinesses = BusinessModel.instance.getAllBusinesses();
      if (query.isEmpty) {
        filteredBusinesses = [];
      } else {
        filteredBusinesses = allBusinesses.where((business) {
          final name = (business['name'] as String? ?? '').toLowerCase();
          final description = (business['description'] as String? ?? '').toLowerCase();
          final city = (business['city'] as String? ?? '').toLowerCase();
          final province = (business['province'] as String? ?? '').toLowerCase();
          return name.contains(query) ||
              description.contains(query) ||
              city.contains(query) ||
              province.contains(query);
        }).toList();
      }
    });
  }

  void _searchProducts(String query) {
    _searchQuery = query;
    _applyAllFilters();
  }

  void _filterByCategory(String category) {
    final index = _categories.indexWhere((item) => item['name'] == category);
    setState(() {
      selectedCategory = category;
      selectedFilterCategory = category;
      if (index != -1) {
        selectedCategoryIndex = index;
      }
    });
    _applyAllFilters();
  }

  void _showFilterSheet(BuildContext context) {
    const categories = [
      'Semua',
      'Elektronik',
      'Fashion',
      'Makanan',
      'Kecantikan',
      'Olahraga',
      'Rumah',
    ];

    String tempCategory = selectedFilterCategory;
    RangeValues tempRange = selectedPriceRange;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.62,
              minChildSize: 0.45,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Filter Produk',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Kategori',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: List.generate(categories.length, (index) {
                          final isSelected = tempCategory == categories[index];
                          return ChoiceChip(
                            label: Text(categories[index]),
                            selected: isSelected,
                            onSelected: (_) {
                              setModalState(() {
                                tempCategory = categories[index];
                              });
                            },
                            selectedColor: const Color(0xFFDDE3FF),
                            backgroundColor: const Color(0xFFF8FAFC),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF1D4ED8)
                                  : const Color(0xFF475569),
                              fontWeight: FontWeight.w600,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF6C7BFF)
                                  : const Color(0xFFE2E8F0),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Range Harga',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 12),
                      RangeSlider(
                        values: tempRange,
                        min: 50000,
                        max: 1000000,
                        divisions: 19,
                        activeColor: const Color(0xFF6C7BFF),
                        onChanged: (values) {
                          setModalState(() {
                            tempRange = values;
                          });
                        },
                      ),
                      Text(
                        'Rentang Rp ${(tempRange.start ~/ 1000)}.000 - Rp ${(tempRange.end ~/ 1000)}.000',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              selectedFilterCategory = tempCategory;
                              selectedCategory = tempCategory;
                              final categoryIndex = _categories.indexWhere((item) => item['name'] == tempCategory);
                              if (categoryIndex != -1) {
                                selectedCategoryIndex = categoryIndex;
                              }
                              selectedPriceRange = tempRange;
                            });
                            _applyAllFilters();
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text(
                            'Terapkan',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    const background = Color(0xFFF7F8FC);
    const primary = Color(0xFF6C7BFF);
    const textColor = Color(0xFF111827);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'My Shop',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        actions: [
          _buildCartIcon(),
          IconButton(
            onPressed: _openAddProductPage,
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Jual Produk',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                buildPageRoute(const OrderHistoryPage()),
              );
            },
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Pesanan',
          ),
          IconButton(
            onPressed: () => _handleLogout(context),
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoading
          ? const DashboardSkeleton()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _buildSearchBar(context),
                const SizedBox(height: 16),
                // Business search results
                if (filteredBusinesses.isNotEmpty) ...[
                  _buildSectionHeader('Bisnis Ditemukan', trailing: '${filteredBusinesses.length}'),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredBusinesses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final business = filteredBusinesses[index];
                      return _buildBusinessCard(context, business);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
                _buildPromoBanner(context),
                const SizedBox(height: 24),
                _buildSectionHeader('Kategori'),
                const SizedBox(height: 12),
                SizedBox(
                  height: 102,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return _buildCategoryItem(
                        context: context,
                        index: index,
                        name: category['name'] as String,
                        icon: category['icon'] as IconData,
                        isActive: index == selectedCategoryIndex,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionHeader('Produk', trailing: 'Lihat Semua'),
                const SizedBox(height: 12),
                if (filteredProducts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 42),
                    alignment: Alignment.center,
                    child: const Text(
                      'Produk tidak ditemukan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                      ),
                ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filteredProducts.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.60,
                        ),
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          final isFavorite = _favoriteIndexes.contains(index);
                          return _buildProductCard(
                            context: context,
                            index: index,
                            product: product,
                            name: product['name'] as String,
                            price: product['price'] as String,
                            imageUrl: product['image'] as String,
                            isFavorite: isFavorite,
                          );
                        },
                      );
                    },
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _handleLogout(context),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: primary,
                      side: const BorderSide(color: Color(0xFFD7DBFF)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
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
        onChanged: _searchProducts,
        decoration: InputDecoration(
          hintText: 'Cari produk, brand, atau kategori...',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_searchController.text.isNotEmpty)
                IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _searchProducts('');
                  },
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Hapus pencarian',
                ),
              IconButton(
                onPressed: () => _showFilterSheet(context),
                icon: const Icon(Icons.tune_rounded),
                tooltip: 'Filter',
              ),
            ],
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return TapScale(
      onTap: () {
        Navigator.of(context).push(
          buildPageRoute(const PromoDetailPage()),
        );
      },
      borderRadius: BorderRadius.circular(24),
      child: Hero(
        tag: 'promo-banner-hero',
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C7BFF), Color(0xFF8F7CF8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C7BFF).withOpacity(0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Promo Spesial Hari Ini',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Diskon hingga 50% untuk produk pilihan.\nBelanja lebih hemat sekarang!',
                        style: TextStyle(
                          color: Colors.white70,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {String? trailing}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF111827),
          ),
        ),
        if (trailing != null)
          Text(
            trailing,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6C7BFF),
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryItem({
    required BuildContext context,
    required int index,
    required String name,
    required IconData icon,
    required bool isActive,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          _filterByCategory(name);
          showFakeNotification(
            context,
            'Kategori $name dipilih',
            backgroundColor: const Color(0xFF2563EB),
            icon: Icons.tune_rounded,
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 96,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF6C7BFF) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isActive ? const Color(0xFF6C7BFF) : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.18)
                      : const Color(0xFFF8FAFC),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isActive
                      ? Colors.white
                      : const Color(0xFF6B7280),
                  size: 22,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : const Color(0xFF4B5563),
                ),
              ),
        ],
          ),
        ),
      ),
    );
  }

  Widget _buildCartIcon() {
    return AnimatedBuilder(
      animation: CartModel.instance,
      builder: (context, _) {
        final count = CartModel.instance.count;
        return IconButton(
          onPressed: () {
            Navigator.of(context).push(
              buildPageRoute(const CartPage()),
            );
          },
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.shopping_cart_outlined),
              if (count > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          tooltip: 'Cart',
        );
      },
    );
  }

  Widget _buildProductCard({
    required BuildContext context,
    required int index,
    required Map<String, dynamic> product,
    required String name,
    required String price,
    required String imageUrl,
    required bool isFavorite,
  }) {
    final isUserProduct = product['isUserProduct'] == true;

    return TapScale(
      onTap: () {
        Navigator.of(context).push(
          buildPageRoute(ProductDetailPage(product: product)),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Card(
        elevation: 0,
        color: Colors.white,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: AspectRatio(
                      aspectRatio: 1.05,
                      child: ShopImage(
                        imagePath: imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (isUserProduct)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111827).withOpacity(0.78),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Produk Kamu',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isUserProduct)
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            onSelected: (value) {
                              if (value == 'edit') {
                                _editUserProduct(product);
                              } else if (value == 'delete') {
                                _deleteUserProduct(product);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem<String>(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_rounded, size: 18),
                                    SizedBox(width: 10),
                                    Text('Edit'),
                                  ],
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
                                    SizedBox(width: 10),
                                    Text('Hapus'),
                                  ],
                                ),
                              ),
                            ],
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Icon(
                                Icons.more_vert_rounded,
                                size: 18,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                if (isFavorite) {
                                  _favoriteIndexes.remove(index);
                                } else {
                                  _favoriteIndexes.add(index);
                                }
                              });
                            },
                            icon: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? Colors.redAccent
                                  : const Color(0xFF6B7280),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF6C7BFF),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tap untuk detail',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusinessCard(BuildContext context, Map<String, dynamic> business) {
    return TapScale(
      onTap: () {
        Navigator.of(context).push(
          buildPageRoute(BusinessDetailPage(business: business)),
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
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C7BFF), Color(0xFF8F7CF8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.business_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business['name'] as String? ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          size: 14,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${business['city'] ?? ''}, ${business['province'] ?? ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(business['products'] as List? ?? []).length} Produk',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4338CA),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Color(0xFF94A3B8),
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
