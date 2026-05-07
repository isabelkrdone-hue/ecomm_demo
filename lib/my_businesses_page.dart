import 'package:flutter/material.dart';

import 'add_business_page.dart';
import 'app_ui.dart';
import 'business_model.dart';

class MyBusinessesPage extends StatefulWidget {
  const MyBusinessesPage({super.key});

  @override
  State<MyBusinessesPage> createState() => _MyBusinessesPageState();
}

class _MyBusinessesPageState extends State<MyBusinessesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> get _allBusinesses {
    return BusinessModel.instance.getAllBusinesses();
  }

  List<Map<String, dynamic>> get _filteredBusinesses {
    final businesses = _allBusinesses;

    if (_searchQuery.trim().isEmpty) {
      return businesses;
    }

    final query = _searchQuery.trim().toLowerCase();
    return businesses.where((business) {
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

  Future<void> _openAddBusinessPage() async {
    final result = await Navigator.of(context).push(
      buildPageRoute(const AddBusinessPage()),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _openEditBusiness(Map<String, dynamic> business, int index) async {
    final result = await Navigator.of(context).push(
      buildPageRoute(
        AddBusinessPage(
          existingBusiness: business,
          businessIndex: index,
        ),
      ),
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteBusiness(int index) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Bisnis'),
          content: const Text('Yakin ingin menghapus bisnis ini?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    setState(() {
      BusinessModel.instance.deleteBusiness(index);
    });
  }

  void _showBusinessDetail(Map<String, dynamic> business) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: ListView(
                controller: scrollController,
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
                  Text(
                    business['name'] as String? ?? '',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    icon: Icons.description_rounded,
                    title: 'Deskripsi',
                    content: business['description'] as String? ?? '-',
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    icon: Icons.phone_rounded,
                    title: 'Nomor Telepon',
                    content: business['phone'] as String? ?? '-',
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    icon: Icons.location_on_rounded,
                    title: 'Alamat Lengkap',
                    content: business['address'] as String? ?? '-',
                  ),
                  const SizedBox(height: 16),
                  _DetailSection(
                    icon: Icons.map_rounded,
                    title: 'Lokasi Gudang',
                    content:
                        '${business['subDistrict'] ?? ''}, ${business['district'] ?? ''}, ${business['city'] ?? ''}, ${business['province'] ?? ''}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Produk yang Dijual',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: (business['products'] as List? ?? []).map((product) {
                      final productName = product is Map<String, dynamic>
                          ? (product['name'] as String? ?? '-')
                          : product.toString();
                      return Chip(
                        label: Text(productName),
                        backgroundColor: const Color(0xFFEEF2FF),
                        labelStyle: const TextStyle(
                          color: Color(0xFF4338CA),
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
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

    final businesses = _filteredBusinesses;
    final allBusinesses = _allBusinesses;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Bisnis Saya',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        actions: [
          IconButton(
            onPressed: _openAddBusinessPage,
            icon: const Icon(Icons.add_business_rounded),
            tooltip: 'Tambah Bisnis',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (allBusinesses.isNotEmpty) ...[
              _buildSearchBar(),
              const SizedBox(height: 16),
            ],
            if (allBusinesses.isEmpty)
              _EmptyState(
                onAddPressed: _openAddBusinessPage,
              )
            else if (businesses.isEmpty)
              const _EmptyState(
                message: 'Bisnis tidak ditemukan',
                showAddButton: false,
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: businesses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final business = businesses[index];
                  final actualIndex = allBusinesses.indexOf(business);
                  return _BusinessCard(
                    business: business,
                    onTap: () => _showBusinessDetail(business),
                    onEdit: () => _openEditBusiness(business, actualIndex),
                    onDelete: () => _deleteBusiness(actualIndex),
                  );
                },
              ),
          ],
        ),
      ),
      floatingActionButton: allBusinesses.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _openAddBusinessPage,
              backgroundColor: primary,
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Tambah Bisnis',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            )
          : null,
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
          hintText: 'Cari bisnis...',
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

class _BusinessCard extends StatelessWidget {
  const _BusinessCard({
    required this.business,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final Map<String, dynamic> business;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C7BFF), Color(0xFF8F7CF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.business_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          business['name'] as String? ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 18,
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                business['description'] as String? ?? '-',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF475569),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.phone_rounded,
                    size: 16,
                    color: Color(0xFF6C7BFF),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    business['phone'] as String? ?? '-',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${(business['products'] as List? ?? []).length} Produk',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
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
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Edit'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6C7BFF),
                        side: const BorderSide(color: Color(0xFFD7DBFF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.delete_rounded, size: 18),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    this.message = 'Belum ada bisnis',
    this.showAddButton = true,
    this.onAddPressed,
  });

  final String message;
  final bool showAddButton;
  final VoidCallback? onAddPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 32),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.business_rounded,
              size: 48,
              color: Color(0xFF6C7BFF),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
            ),
          ),
          if (showAddButton) ...[
            const SizedBox(height: 12),
            const Text(
              'Mulai tambahkan bisnis Anda untuk mengelola produk dan gudang',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Tambah Bisnis'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C7BFF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.icon,
    required this.title,
    required this.content,
  });

  final IconData icon;
  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: const Color(0xFF6C7BFF),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  content,
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
      ),
    );
  }
}
