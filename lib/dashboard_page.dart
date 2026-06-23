import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_ui.dart';
import 'app_ui_skeletons.dart';
import 'business_detail_page.dart';
import 'business_model.dart';
import 'cart_model.dart';
import 'shop_image.dart';
import 'cart_page.dart';
import 'login_page.dart';
import 'profile_page.dart';
import 'product_data.dart';
import 'product_detail_page.dart';
import 'promo_detail_page.dart';
import 'add_product_page.dart';
import 'repository/http.dart';
import 'sessions.dart';

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
    const background = Colors.white;
    const primary = Color(0xFFFF6B00);

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
          unselectedItemColor: const Color(0xFF111827),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.explore_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag_outlined),
              label: 'Troli',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              label: 'Alibaba ...',
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
  List<Map<String, dynamic>> filteredBusinessProducts = [];

  final Set<int> _favoriteIndexes = <int>{1, 3};
  int selectedCategoryIndex = 0;
  String selectedCategory = 'Semua';
  String selectedFilterCategory = 'Semua';
  RangeValues selectedPriceRange =
      const RangeValues(0, 10000000); // Wider range to include all products
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    BusinessModel.instance.addListener(_onBusinessDataChanged);
    _loadAllProducts();
    _applyAllFilters();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    });
  }

  @override
  void didUpdateWidget(_DashboardHomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload products when widget updates
    setState(() {
      _loadAllProducts();
      _applyAllFilters();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when returning to this page
    _loadAllProducts();
    _applyAllFilters();
  }

  List<Map<String, dynamic>> _buildCombinedProducts() {
    final combinedProducts = List<Map<String, dynamic>>.from(allProducts);

    final businesses = BusinessModel.instance.getAllBusinesses();

    for (final business in businesses) {
      final products = business['products'] as List? ?? [];

      for (final product in products) {
        if (product is Map<String, dynamic>) {
          final price = product['price'];

          final priceText = price is num
              ? 'Rp ${price.toStringAsFixed(0)}'
              : (price?.toString() ?? 'Rp 0');

          combinedProducts.add({
            'name': product['name'],
            'price': priceText,
            'image': product['image'] ??
                product['imagePath'] ??
                'assets/images/placeholder.png',
            'category': product['category'] ?? 'Lainnya',
            'description':
                product['description'] ?? 'Produk dari ${business['name']}',
            'isBusinessProduct': true,
            'businessName': business['name'],
            'businessCity': business['city'],
            'businessProvince': business['province'],
            'unit': product['unit'] ?? 'Pcs',
          });
        }
      }
    }

    return combinedProducts;
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

  bool _isVerified(Map<String, dynamic> business) {
    return _verificationStatus(business) == 'verified';
  }

  int get _verifiedBusinessCount {
    return BusinessModel.instance.getAllBusinesses().where(_isVerified).length;
  }

  void _loadAllProducts() {
    filteredProducts = _buildCombinedProducts();
  }

  @override
  void dispose() {
    BusinessModel.instance.removeListener(_onBusinessDataChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final logger = Logger();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
      await Sessions.clearLoginSession();
      Http().clearToken();
      logger.i(
        'Dashboard logout: cleared isLoggedIn, token, userId, name, email, '
        'phone, roleId, role, and Authorization header',
      );
    } catch (e) {
      logger.w('Dashboard logout: failed to clear local session: $e');
    }
    if (!context.mounted) return;
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
    _loadAllProducts();
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

  int _parsePrice(dynamic price) {
    if (price is num) return price.toInt();
    final value = (price?.toString() ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(value) ?? 0;
  }

  String _priceText(dynamic price) {
    if (price is num) {
      return 'Rp ${price.toStringAsFixed(0)}';
    }
    if (price == null) return 'Rp 0';
    return price.toString();
  }

  String _textValue(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    return value.toString();
  }

  String _formatPrice(int price) {
    if (price >= 1000000) {
      final millions = price / 1000000;
      return '${millions.toStringAsFixed(millions == millions.toInt() ? 0 : 1)}jt';
    } else if (price >= 1000) {
      final thousands = price / 1000;
      return '${thousands.toStringAsFixed(0)}rb';
    } else {
      return price.toString();
    }
  }

  void _applyAllFilters() {
    final query = _searchQuery.trim().toLowerCase();
    final combinedProducts = _buildCombinedProducts();

    setState(() {
      filteredProducts = combinedProducts.where((product) {
        final name = (product['name'] as String? ?? '').toLowerCase();
        final businessName =
            (product['businessName'] as String? ?? '').toLowerCase();
        final category = product['category']?.toString() ?? 'Semua';
        final categoryKey = category.trim().toLowerCase();
        final selectedCategoryKey = selectedCategory.trim().toLowerCase();
        final selectedFilterCategoryKey =
            selectedFilterCategory.trim().toLowerCase();
        final price = _parsePrice(product['price']);

        final matchSearch = query.isEmpty ||
            name.contains(query) ||
            businessName.contains(query) ||
            category.toLowerCase().contains(query);

        // When searching, be more lenient with filters
        if (query.isNotEmpty) {
          // Only apply category filter if specifically selected (not default)
          final matchCategory = selectedCategoryKey == 'semua' ||
              categoryKey == selectedCategoryKey;
          return matchSearch && matchCategory;
        } else {
          // When not searching, apply all filters normally
          final matchCategory = selectedCategoryKey == 'semua' ||
              categoryKey == selectedCategoryKey;
          final matchFilterCategory = selectedFilterCategoryKey == 'semua' ||
              categoryKey == selectedFilterCategoryKey;
          final matchPrice = price >= selectedPriceRange.start &&
              price <= selectedPriceRange.end;
          return matchSearch &&
              matchCategory &&
              matchFilterCategory &&
              matchPrice;
        }
      }).toList();

      final allBusinesses = BusinessModel.instance.getAllBusinesses();
      if (query.isEmpty) {
        filteredBusinesses = [];
        filteredBusinessProducts = [];
      } else {
        filteredBusinesses = allBusinesses.where((business) {
          final name = (business['name'] as String? ?? '').toLowerCase();
          final description =
              (business['description'] as String? ?? '').toLowerCase();
          final city = (business['city'] as String? ?? '').toLowerCase();
          final province =
              (business['province'] as String? ?? '').toLowerCase();

          bool hasMatchingProduct = false;
          final products = business['products'] as List? ?? [];
          for (final product in products) {
            if (product is Map<String, dynamic>) {
              final productName =
                  (product['name'] as String? ?? '').toLowerCase();
              final productCategory =
                  (product['category'] as String? ?? '').toLowerCase();
              if (productName.contains(query) ||
                  productCategory.contains(query)) {
                hasMatchingProduct = true;
                break;
              }
            }
          }

          return name.contains(query) ||
              description.contains(query) ||
              city.contains(query) ||
              province.contains(query) ||
              hasMatchingProduct;
        }).toList();

        filteredBusinessProducts = [];
        for (final business in allBusinesses) {
          final products = business['products'] as List? ?? [];
          for (final product in products) {
            if (product is Map<String, dynamic>) {
              final productName =
                  (product['name'] as String? ?? '').toLowerCase();
              final productCategory =
                  (product['category'] as String? ?? '').toLowerCase();
              final businessName =
                  (business['name'] as String? ?? '').toLowerCase();
              if (productName.contains(query) ||
                  productCategory.contains(query) ||
                  businessName.contains(query)) {
                final productWithBusiness = Map<String, dynamic>.from(product);

                productWithBusiness['image'] =
                    product['image'] ?? product['imagePath'];

                productWithBusiness['businessName'] = business['name'];
                productWithBusiness['businessCity'] = business['city'];

                filteredBusinessProducts.add(productWithBusiness);
              }
            }
          }
        }
      }
    });
  }

  void _onBusinessDataChanged() {
    if (!mounted) return;
    _loadAllProducts();
    _applyAllFilters();
  }

  void _searchProducts(String query) {
    _searchQuery = query;
    _applyAllFilters();
  }

  void _filterByCategory(String category) {
    final index = _availableProductCategories().indexOf(category);
    setState(() {
      selectedCategory = category;
      selectedFilterCategory = category;
      if (index != -1) {
        selectedCategoryIndex = index;
      }
    });
    _applyAllFilters();
  }

  List<String> _availableProductCategories() {
    final categories = <String>['Semua'];
    final seen = <String>{'semua'};

    for (final product in _buildCombinedProducts()) {
      final category = product['category']?.toString().trim() ?? '';
      if (category.isEmpty) continue;
      final key = category.toLowerCase();
      if (seen.contains(key)) continue;
      categories.add(category);
      seen.add(key);
    }

    if (categories.length == 1) {
      for (final category in _categories) {
        final name = category['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        final key = name.toLowerCase();
        if (seen.contains(key)) continue;
        categories.add(name);
        seen.add(key);
      }
    }

    return categories;
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
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(28)),
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
                        min: 0,
                        max: 10000000,
                        divisions: 20,
                        activeColor: const Color(0xFF6C7BFF),
                        onChanged: (values) {
                          setModalState(() {
                            tempRange = values;
                          });
                        },
                      ),
                      Text(
                        'Rentang Rp ${_formatPrice(tempRange.start.toInt())} - Rp ${_formatPrice(tempRange.end.toInt())}',
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
                              final categoryIndex = _categories.indexWhere(
                                  (item) => item['name'] == tempCategory);
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
    final producerSections = _producerSections();

    return Scaffold(
      backgroundColor: Colors.white,
      body: _isLoading
          ? const DashboardSkeleton()
          : ListView(
              padding: EdgeInsets.fromLTRB(
                12,
                MediaQuery.of(context).padding.top + 10,
                12,
                24,
              ),
              children: [
                _buildProducerTabs(),
                const SizedBox(height: 16),
                _buildAlibabaSearchBar(context),
                const SizedBox(height: 18),
                _buildProducerCategoryBar(),
                const SizedBox(height: 12),
                if (filteredProducts.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 44),
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
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: producerSections.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 22),
                    itemBuilder: (context, index) =>
                        _buildProducerSection(producerSections[index]),
                  ),
              ],
            ),
    );
  }

  Widget _buildProducerTabs() {
    const tabs = ['Mode AI', 'Produk', 'Produsen', 'Global'];

    return Row(
      children: List.generate(tabs.length, (index) {
        final isActive = tabs[index] == 'Produsen';
        return Padding(
          padding: EdgeInsets.only(right: index == tabs.length - 1 ? 0 : 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tabs[index],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isActive ? 70 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B00),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAlibabaSearchBar(BuildContext context) {
    return Container(
      height: 58,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFF6B00), width: 1.6),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _openAddProductPage,
            icon: const Icon(Icons.camera_alt_outlined, size: 28),
            tooltip: 'Jual Produk',
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: _searchProducts,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'sistem suara yamaha',
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          IconButton(
            onPressed: () => _showFilterSheet(context),
            icon: const Icon(Icons.mic_none_rounded, size: 30),
            tooltip: 'Filter',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: SizedBox(
              width: 70,
              height: 46,
              child: ElevatedButton(
                onPressed: () => _searchProducts(_searchController.text),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: const Color(0xFFFF7A18),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Icon(Icons.auto_awesome_rounded, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducerCategoryBar() {
    final categories = _availableProductCategories();

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 22),
        itemBuilder: (context, index) {
          if (index == categories.length) {
            return const Center(
              child: Icon(Icons.keyboard_arrow_down_rounded, size: 30),
            );
          }
          final title = categories[index];
          final isActive = selectedCategory == title ||
              (selectedCategory == 'Semua' && title == 'Semua');
          return InkWell(
            onTap: () => _filterByCategory(title),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w700,
                    color: isActive
                        ? const Color(0xFF111827)
                        : const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: isActive ? 76 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Map<String, dynamic>> _producerSections() {
    final sections = <Map<String, dynamic>>[];
    final businesses = BusinessModel.instance.getAllBusinesses();
    final products = filteredProducts;

    if (businesses.isNotEmpty) {
      for (final business in businesses) {
        final name = business['name'] as String? ?? 'Produsen';
        final businessProducts = products
            .where((product) => product['businessName'] == name)
            .take(3)
            .toList();
        if (businessProducts.isEmpty) continue;
        sections.add({
          'business': business,
          'products': businessProducts,
        });
      }
    }

    final usedCount = sections.fold<int>(
      0,
      (total, section) => total + ((section['products'] as List?)?.length ?? 0),
    );
    final remaining = products.skip(usedCount).toList();

    for (var i = 0; i < remaining.length; i += 3) {
      final chunk = remaining.skip(i).take(3).toList();
      if (chunk.isEmpty) continue;
      sections.add({
        'business': {
          'name': i == 0
              ? 'Shenzhen Home Design Houseware Ltd'
              : 'Guangzhou High Hip-Hop Amusement Eq...',
          'verificationStatus': 'verified',
          'city': i == 0 ? 'Shenzhen' : 'Guangzhou',
          'province': 'China',
          'products': chunk,
        },
        'products': chunk,
      });
    }

    for (var i = 0; i < sections.length; i++) {
      sections[i]['isFirst'] = i == 0;
    }

    return sections;
  }

  Widget _buildProducerSection(Map<String, dynamic> section) {
    final business = Map<String, dynamic>.from(section['business'] as Map);
    final products =
        List<Map<String, dynamic>>.from(section['products'] as List);
    final firstSection = section['isFirst'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (firstSection)
          const Padding(
            padding: EdgeInsets.only(left: 92, bottom: 14),
            child: Text(
              'Desain kustom dalam 3 hari · Pengiriman tepat waktu 100.0%',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        _buildProducerProductRow(products),
        const SizedBox(height: 14),
        _buildProducerInfo(business),
        const SizedBox(height: 8),
        Text(
          firstSection
              ? 'Desain kustom dalam 3 hari · Waktu respons ≤3h'
              : 'Layanan ODM tersedia · Kustomisasi Minor',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildProducerProductRow(List<Map<String, dynamic>> products) {
    return Row(
      children: List.generate(3, (index) {
        final product =
            index < products.length ? products[index] : products.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 8),
            child: _buildMiniProductCard(product),
          ),
        );
      }),
    );
  }

  Widget _buildMiniProductCard(Map<String, dynamic> product) {
    final price = _priceText(product['price']);
    final unit = _textValue(
      product['unit'] ?? product['satuan'] ?? product['category'],
      fallback: 'Buah',
    );

    return TapScale(
      onTap: () {
        Navigator.of(context).push(
          buildPageRoute(ProductDetailPage(product: product)),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: ShopImage(
                    imagePath: _textValue(
                      product['image'],
                      fallback: 'assets/images/placeholder.png',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                left: 7,
                bottom: 7,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.center_focus_weak_rounded,
                    color: Color(0xFF4B5563),
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '10 $unit (MOQ)',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducerInfo(Map<String, dynamic> business) {
    final status = _verificationStatus(business);
    final verified = status == 'verified';

    return TapScale(
      onTap: () {
        final realBusiness = _businessByName(business['name'] as String?);
        if (realBusiness == null) return;
        Navigator.of(context).push(
          buildPageRoute(BusinessDetailPage(business: realBusiness)),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Color(0xFFFF6B00),
              size: 28,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  business['name'] as String? ?? 'Produsen',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (verified) ...[
                      const Text(
                        'Verified',
                        style: TextStyle(
                          color: Color(0xFF0284C7),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Expanded(
                      child: Text(
                        '16 thn · 40+ pekerja · 1,900+ m² · Rp2,1 M+',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildHeroHeader(BuildContext context) {
    final businesses = BusinessModel.instance.getAllBusinesses();
    final productCount = filteredProducts.length;
    final verifiedCount = _verifiedBusinessCount;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'My Shop',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Temukan produk, toko, dan seller terverifikasi dalam satu tampilan modern.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _heroStatCard(
                      'Produk', '$productCount', Icons.inventory_2_rounded)),
              const SizedBox(width: 10),
              Expanded(
                  child: _heroStatCard(
                      'Toko', '${businesses.length}', Icons.store_rounded)),
              const SizedBox(width: 10),
              Expanded(
                  child: _heroStatCard(
                      'Verified', '$verifiedCount', Icons.verified_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(Map<String, dynamic> business) {
    final status = _verificationStatus(business);
    final color = _verificationColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _verificationLabel(status),
        style:
            TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
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
          hintText: 'Cari produk, bisnis, atau kategori...',
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              color:
                  isActive ? const Color(0xFF6C7BFF) : const Color(0xFFE5E7EB),
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
                  color: isActive ? Colors.white : const Color(0xFF6B7280),
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    constraints:
                        const BoxConstraints(minWidth: 18, minHeight: 18),
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
    final businessName = product['businessName'] as String?;
    final business = _businessByName(businessName);
    final status = _verificationStatus(business);
    final statusColor = _verificationColor(status);
    final statusLabel = _verificationLabel(status);

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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
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
                                    Icon(Icons.delete_rounded,
                                        size: 18, color: Colors.redAccent),
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
              if (businessName != null && businessName.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                const SizedBox(height: 6),
              ],
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
                padding:
                    const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
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

  Widget _buildBusinessCard(
      BuildContext context, Map<String, dynamic> business) {
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildStatusChip(business),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(business['products'] as List? ?? []).length} Produk',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
