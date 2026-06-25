import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_ui.dart';
import 'app_ui_skeletons.dart';
import 'business_detail_page.dart';
import 'business_model.dart';
import 'cart_model.dart';
import 'address_model.dart';
import 'shop_image.dart';
import 'cart_page.dart';
import 'login_page.dart';
import 'my_address_page.dart';
import 'profile_page.dart';
import 'product_data.dart';
import 'product_detail_page.dart';
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
          selectedItemColor: const Color(0xFF2563EB),
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
              label: 'Akun',
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
    AddressModel.instance.addListener(_onAddressDataChanged);
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
    AddressModel.instance.removeListener(_onAddressDataChanged);
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
            category.toLowerCase().contains(query) ||
            (product['description'] as String? ?? '')
                .toLowerCase()
                .contains(query) ||
            (product['businessCity'] as String? ?? '')
                .toLowerCase()
                .contains(query) ||
            (product['businessProvince'] as String? ?? '')
                .toLowerCase()
                .contains(query);
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

  void _onAddressDataChanged() {
    if (!mounted) return;
    setState(() {});
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
    final minPriceController =
        TextEditingController(text: tempRange.start.round().toString());
    final maxPriceController =
        TextEditingController(text: tempRange.end.round().toString());

    int? parsePriceInput(String value) {
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.isEmpty) return null;
      return int.tryParse(digits);
    }

    void syncControllersFromRange() {
      minPriceController.text = tempRange.start.round().toString();
      maxPriceController.text = tempRange.end.round().toString();
    }

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
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: minPriceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Harga min',
                                prefixText: 'Rp ',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                final parsed = parsePriceInput(value);
                                if (parsed == null) return;
                                setModalState(() {
                                  final nextMin =
                                      parsed.clamp(0, 10000000).toInt();
                                  final currentMax =
                                      tempRange.end.round().toInt();
                                  final nextMax = nextMin > currentMax
                                      ? nextMin
                                      : currentMax;
                                  tempRange = RangeValues(
                                    nextMin.toDouble(),
                                    nextMax.toDouble(),
                                  );
                                  syncControllersFromRange();
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: maxPriceController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                labelText: 'Harga max',
                                prefixText: 'Rp ',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE2E8F0),
                                  ),
                                ),
                              ),
                              onChanged: (value) {
                                final parsed = parsePriceInput(value);
                                if (parsed == null) return;
                                setModalState(() {
                                  final nextMax =
                                      parsed.clamp(0, 10000000).toInt();
                                  final currentMin =
                                      tempRange.start.round().toInt();
                                  final nextMin = nextMax < currentMin
                                      ? nextMax
                                      : currentMin;
                                  tempRange = RangeValues(
                                    nextMin.toDouble(),
                                    nextMax.toDouble(),
                                  );
                                  syncControllersFromRange();
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      RangeSlider(
                        values: tempRange,
                        min: 0,
                        max: 10000000,
                        divisions: 20,
                        activeColor: const Color(0xFF6C7BFF),
                        onChanged: (values) {
                          setModalState(() {
                            tempRange = values;
                            syncControllersFromRange();
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
    ).whenComplete(() {
      minPriceController.dispose();
      maxPriceController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
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
                _buildMarketplaceHeader(context),
                const SizedBox(height: 18),
                _buildSearchBar(context),
                const SizedBox(height: 16),
                _buildSectionHeader('Categories'),
                const SizedBox(height: 12),
                _buildCategoryRail(),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  'Most Views',
                  trailing: 'See all',
                ),
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
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredProducts.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.54,
                    ),
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return _buildProductCard(
                        context: context,
                        index: index,
                        product: product,
                        name: product['name'] as String? ?? 'Produk',
                        price: _priceText(product['price']),
                        imageUrl: _textValue(
                          product['image'],
                          fallback: 'assets/images/placeholder.png',
                        ),
                        isFavorite: _favoriteIndexes.contains(index),
                      );
                    },
                  ),
              ],
            ),
    );
  }

  Widget _buildProducerTabs() {
    const tabs = ['Ikhtisar', 'Produk', 'Toko', 'Global'];

    return Row(
      children: List.generate(tabs.length, (index) {
        final isActive = tabs[index] == 'Toko';
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

  Widget _buildLegacySearchBar(BuildContext context) {
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

  Widget _buildCategoryRail() {
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final name = category['name'] as String? ?? '';
          final icon = category['icon'] as IconData? ?? Icons.apps_rounded;
          final isActive = selectedCategory == name;
          return _buildCategoryItem(
            context: context,
            index: index,
            name: name,
            icon: icon,
            isActive: isActive,
          );
        },
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
          hintText: 'Cari produk, toko, atau kategori...',
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

  Widget _buildMarketplaceHeader(BuildContext context) {
    final selectedAddress = AddressModel.instance.selectedAddress;
    final locationName = _deliveryLocationText(selectedAddress);
    final productCount = filteredProducts.length;

    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              Navigator.of(context).push(
                buildPageRoute(const MyAddressPage()),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Delivery to',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_rounded,
                        size: 17,
                        color: Color(0xFF111827),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          locationName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF111827),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '$productCount products available',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _circleActionButton(
          icon: Icons.notifications_none_rounded,
          hasBadge: true,
          onTap: () {},
        ),
        const SizedBox(width: 10),
        _circleActionButton(
          icon: Icons.search_rounded,
          onTap: () => _showFilterSheet(context),
        ),
      ],
    );
  }

  Widget _circleActionButton({
    required IconData icon,
    required VoidCallback onTap,
    bool hasBadge = false,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: const Color(0xFFF0F2F6),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                icon,
                color: const Color(0xFF111827),
                size: 24,
              ),
            ),
          ),
        ),
        if (hasBadge)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFFEF4444),
                shape: BoxShape.circle,
              ),
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
        borderRadius: BorderRadius.circular(999),
        onTap: () {
          _filterByCategory(name);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 84,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE5E7EB)),
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
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withOpacity(0.14)
                      : const Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isActive ? Colors.white : const Color(0xFF111827),
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

  String _deliveryLocationText(Map<String, String>? address) {
    if (address == null) return 'Tambah alamat utama';

    final city = _compactLocationName(
      (address['regency'] ?? address['city'] ?? '').trim(),
    );
    final label = (address['label'] ?? '').trim();
    final addressLine = (address['address'] ?? '').trim();

    if (city.isNotEmpty) return city;
    if (label.isNotEmpty) return label;
    if (addressLine.isNotEmpty) return addressLine;
    return 'Tambah alamat utama';
  }

  String _compactLocationName(String value) {
    if (value.isEmpty) return '';

    final cleaned = value
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll(
          RegExp(r'^(Kota|Kabupaten|Kab\.|Kab)\s+', caseSensitive: false),
          '',
        )
        .trim();

    if (cleaned.isNotEmpty) {
      return cleaned;
    }

    final parts = value.split(',');
    if (parts.isNotEmpty) {
      final firstPart = parts.first
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(
            RegExp(r'^(Kota|Kabupaten|Kab\.|Kab)\s+', caseSensitive: false),
            '',
          )
          .trim();
      if (firstPart.isNotEmpty) return firstPart;
    }

    return value;
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

    return TapScale(
      onTap: () {
        Navigator.of(context).push(
          buildPageRoute(ProductDetailPage(product: product)),
        );
      },
      borderRadius: BorderRadius.circular(22),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ShopImage(
                        imagePath: imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
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
                            icon: const CircleAvatar(
                              radius: 14,
                              backgroundColor: Colors.white,
                              child: Icon(
                                Icons.more_horiz_rounded,
                                size: 18,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isFavorite) {
                                _favoriteIndexes.remove(index);
                              } else {
                                _favoriteIndexes.add(index);
                              }
                            });
                          },
                          child: CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white,
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 16,
                              color: isFavorite
                                  ? Colors.redAccent
                                  : const Color(0xFF111827),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
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
                _textValue(
                  product['businessName'] ?? product['businessCity'],
                  fallback: 'Popular item',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
