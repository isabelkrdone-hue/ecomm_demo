import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'product_data.dart';
import 'repository/http.dart';
import 'shop_image.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key, this.existingProduct, this.productIndex});

  final Map<String, dynamic>? existingProduct;
  final int? productIndex;

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  static const List<Map<String, String>> _fallbackCategories = [
    {'id': 'Elektronik', 'name': 'Elektronik'},
    {'id': 'Fashion', 'name': 'Fashion'},
    {'id': 'Makanan', 'name': 'Makanan'},
    {'id': 'Kecantikan', 'name': 'Kecantikan'},
    {'id': 'Olahraga', 'name': 'Olahraga'},
    {'id': 'Rumah', 'name': 'Rumah'},
  ];

  List<Map<String, String>> _categories =
      List<Map<String, String>>.from(_fallbackCategories);
  List<Map<String, String>> _satuanOptions = [];
  List<Map<String, dynamic>> _apiProducts = [];
  List<Map<String, dynamic>> _produkVarianOptions = [];

  String? _selectedApiProductId;
  String? _selectedCategoryId = _fallbackCategories.first['id'];
  String? _selectedSatuanId;
  String? _selectedProdukVarianId;
  Map<String, dynamic>? _selectedProdukVarianDetail;
  String _selectedImage = 'assets/images/placeholder.png';
  bool _isLoadingLookups = false;
  bool _isLoadingProduk = false;
  bool _isLoadingProdukVarian = false;
  bool _isLoadingProdukVarianDetail = false;
  bool _isMutatingProdukVarian = false;
  bool _isSaving = false;
  bool _isPickingImage = false;

  @override
  void initState() {
    super.initState();
    final product = widget.existingProduct;
    if (product != null) {
      _nameController.text = product['name'] as String? ?? '';
      _priceController.text = _digitsOnly(product['price'] as String? ?? '');
      _descriptionController.text = product['description'] as String? ?? '';
      _selectedCategoryId = product['kategori_produk_id']?.toString() ??
          product['category']?.toString() ??
          _selectedCategoryId;
      _selectedSatuanId = product['satuan_id']?.toString();
      _selectedApiProductId = product['api_id']?.toString();
      _selectedProdukVarianId = product['produk_varian_id']?.toString();
      if (product['produk_varian_detail'] is Map) {
        _selectedProdukVarianDetail =
            Map<String, dynamic>.from(product['produk_varian_detail'] as Map);
      }
      _selectedImage = product['image'] as String? ?? _selectedImage;
    }
    _loadInitialApiData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');

  List<dynamic> _extractList(dynamic value) {
    if (value is List) return value;
    if (value is Map) {
      final nested =
          value['data'] ?? value['items'] ?? value['rows'] ?? value['results'];
      if (nested is List) return nested;
    }
    return [];
  }

  String? _firstString(Map item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value != null &&
          value is! Map &&
          value is! List &&
          value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  String? _nestedName(dynamic value, List<String> keys) {
    if (value is Map) return _firstString(value, keys);
    if (value != null && value.toString().trim().isNotEmpty) {
      return value.toString();
    }
    return null;
  }

  List<Map<String, String>> _optionsFrom(
    dynamic data, {
    required List<String> nameKeys,
  }) {
    final options = <Map<String, String>>[];
    for (final item in _extractList(data)) {
      if (item is Map) {
        final id = _firstString(
          item,
          const ['id', 'uuid', 'kode', 'code', 'value'],
        );
        final name = _firstString(item, nameKeys);
        if (id != null && name != null) {
          options.add({'id': id, 'name': name});
        }
      } else {
        final value = item.toString().trim();
        if (value.isNotEmpty) options.add({'id': value, 'name': value});
      }
    }
    return options;
  }

  String? _validValue(List<Map<String, String>> options, String? value) {
    if (value == null) return null;
    if (options.any((option) => option['id'] == value)) return value;
    for (final option in options) {
      if (option['name'] == value) return option['id'];
    }
    return null;
  }

  String _nameFor(List<Map<String, String>> options, String? id) {
    for (final option in options) {
      if (option['id'] == id) return option['name'] ?? id ?? '';
    }
    return id ?? '';
  }

  void _ensureOption(
    List<Map<String, String>> options,
    String? id,
    String? name,
  ) {
    if (id == null || id.trim().isEmpty) return;
    if (options.any((option) => option['id'] == id)) return;
    options
        .add({'id': id, 'name': name?.trim().isNotEmpty == true ? name! : id});
  }

  String _formatPrice(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final remain = text.length - i - 1;
      if (remain > 0 && remain % 3 == 0) buffer.write('.');
    }
    return 'Rp ${buffer.toString()}';
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _loadInitialApiData() async {
    setState(() {
      _isLoadingLookups = true;
      _isLoadingProduk = true;
    });

    await Future.wait([
      _loadKategoriProduk(),
      _loadSatuan(),
    ]);
    if (!mounted) return;
    setState(() => _isLoadingLookups = false);

    await _loadProduk();

    if (!mounted) return;
    setState(() => _isLoadingProduk = false);

    await _loadProdukVarian(produkId: _selectedApiProductId);
  }

  Future<void> _loadKategoriProduk() async {
    try {
      final res = await Http().getKategoriProduk();
      final options = _optionsFrom(
        res['data'],
        nameKeys: const [
          'nama',
          'name',
          'nama_kategori_produk',
          'nama_kategori',
          'kategori',
          'title',
        ],
      );
      if (!mounted) return;
      setState(() {
        _categories = options.isNotEmpty
            ? options
            : List<Map<String, String>>.from(_fallbackCategories);
        _selectedCategoryId = _validValue(_categories, _selectedCategoryId) ??
            _categories.first['id'];
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = List<Map<String, String>>.from(_fallbackCategories);
        _selectedCategoryId = _validValue(_categories, _selectedCategoryId) ??
            _categories.first['id'];
      });
    }
  }

  Future<void> _loadSatuan() async {
    try {
      final res = await Http().getSatuan();
      final options = _optionsFrom(
        res['data'],
        nameKeys: const [
          'nama',
          'name',
          'nama_satuan',
          'nama_unit',
          'satuan',
          'unit',
          'title',
          'kode',
        ],
      );
      if (!mounted) return;
      setState(() {
        _satuanOptions = options;
        _selectedSatuanId = _validValue(_satuanOptions, _selectedSatuanId) ??
            (_satuanOptions.isNotEmpty ? _satuanOptions.first['id'] : null);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _satuanOptions = []);
    }
  }

  Future<void> _loadProduk() async {
    try {
      final res = await Http().getProduk();
      final products = <Map<String, dynamic>>[];
      for (final item in _extractList(res['data'])) {
        if (item is Map) {
          final parsed = _productFromApi(item);
          if (parsed != null) products.add(parsed);
        }
      }
      if (products.isEmpty) return;

      if (!mounted) return;
      setState(() {
        _apiProducts = products;
        _selectedApiProductId = _validApiProductId(_selectedApiProductId);
      });

      for (final product in products) {
        if (!_hasProduct(product)) allProducts.add(product);
      }
    } catch (_) {
      // Local product entry remains usable when the remote API is unavailable.
    }
  }

  Map<String, dynamic>? _productFromApi(Map item) {
    final name = _firstString(
      item,
      const ['nama', 'name', 'nama_produk', 'product_name', 'title'],
    );
    if (name == null) return null;

    final kategoriId = _firstString(
      item,
      const ['kategori_produk_id', 'category_id', 'kategori_id'],
    );
    final satuanId = _firstString(item, const ['satuan_id', 'unit_id']);
    final categoryName = _nestedName(
          item['kategori_produk'] ?? item['kategori'] ?? item['category'],
          const ['nama', 'name', 'title'],
        ) ??
        _nameFor(_categories, kategoriId);

    final satuanName = _nestedName(
          item['satuan'] ?? item['unit'],
          const ['nama', 'name', 'kode', 'title'],
        ) ??
        _nameFor(_satuanOptions, satuanId);
    final priceValue = item['harga'] ??
        item['harga_jual'] ??
        item['price'] ??
        item['harga_produk'];

    _ensureOption(_categories, kategoriId, categoryName);
    _ensureOption(_satuanOptions, satuanId, satuanName);

    return {
      if (item['id'] != null) 'api_id': item['id'].toString(),
      'name': name,
      'price': _formatApiPrice(priceValue),
      'price_value': _priceIntFromApi(priceValue),
      'category': categoryName.isNotEmpty ? categoryName : 'Lainnya',
      if (kategoriId != null) 'kategori_produk_id': kategoriId,
      if (satuanId != null) 'satuan_id': satuanId,
      if (satuanName.isNotEmpty) 'satuan': satuanName,
      'image': _imageFromApi(item) ?? 'assets/images/placeholder.png',
      'description': _firstString(
            item,
            const ['deskripsi', 'description', 'keterangan', 'detail'],
          ) ??
          '',
      'isApiProduct': true,
    };
  }

  bool _hasProduct(Map<String, dynamic> product) {
    final apiId = product['api_id']?.toString();
    return allProducts.any((existing) {
      if (apiId != null && existing['api_id']?.toString() == apiId) {
        return true;
      }
      return existing['name']?.toString() == product['name']?.toString() &&
          existing['category']?.toString() == product['category']?.toString();
    });
  }

  String? _validApiProductId(String? value) {
    if (value == null) return null;
    return _apiProducts.any((product) => product['api_id']?.toString() == value)
        ? value
        : null;
  }

  Map<String, dynamic>? _apiProductById(String? id) {
    if (id == null) return null;
    for (final product in _apiProducts) {
      if (product['api_id']?.toString() == id) return product;
    }
    return null;
  }

  void _applyApiProduct(String? id) {
    final product = _apiProductById(id);
    if (product == null) return;

    setState(() {
      _selectedApiProductId = id;
      _nameController.text = product['name']?.toString() ?? '';
      _priceController.text = product['price_value']?.toString() ??
          _digitsOnly(product['price']?.toString() ?? '');
      _descriptionController.text = product['description']?.toString() ?? '';
      _selectedCategoryId =
          _validValue(_categories, product['kategori_produk_id']?.toString()) ??
              _selectedCategoryId;
      _selectedSatuanId =
          _validValue(_satuanOptions, product['satuan_id']?.toString()) ??
              _selectedSatuanId;
      _selectedProdukVarianId = null;
      _selectedProdukVarianDetail = null;
      _selectedImage =
          product['image']?.toString() ?? 'assets/images/placeholder.png';
    });
    _loadProdukVarian(produkId: id);
  }

  Future<void> _loadProdukVarian({String? produkId}) async {
    if (!mounted) return;
    setState(() => _isLoadingProdukVarian = true);

    try {
      final res = await Http().getProdukVarian(produkId: produkId);
      final variants = <Map<String, dynamic>>[];
      for (final item in _extractList(res['data'])) {
        if (item is Map) {
          final parsed = _produkVarianFromApi(item);
          if (parsed != null) variants.add(parsed);
        }
      }

      if (!mounted) return;
      setState(() {
        _produkVarianOptions = variants;
        _selectedProdukVarianId = _validProdukVarianId(_selectedProdukVarianId);
        if (_selectedProdukVarianId == null) {
          _selectedProdukVarianDetail = null;
        }
      });

      if (_selectedProdukVarianId != null &&
          _selectedProdukVarianDetail == null) {
        await _loadProdukVarianDetail(_selectedProdukVarianId);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _produkVarianOptions = [];
        _selectedProdukVarianId = null;
        _selectedProdukVarianDetail = null;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingProdukVarian = false);
      }
    }
  }

  Map<String, dynamic>? _produkVarianFromApi(Map item) {
    final id = _firstString(
      item,
      const ['id', 'uuid', 'produk_varian_id', 'variant_id', 'value'],
    );
    if (id == null) return null;

    final name = _firstString(
          item,
          const [
            'nama',
            'name',
            'nama_varian',
            'variant_name',
            'varian',
            'title',
            'sku',
            'kode',
          ],
        ) ??
        'Varian $id';

    final productId = _firstString(
      item,
      const ['produk_id', 'product_id', 'api_produk_id'],
    );
    final productName = _nestedName(
      item['produk'] ?? item['product'],
      const ['nama', 'name', 'nama_produk', 'title'],
    );
    final priceValue =
        item['harga'] ?? item['harga_jual'] ?? item['price'] ?? item['amount'];

    return {
      ...Map<String, dynamic>.from(item),
      'id': id,
      'name': name,
      if (productId != null) 'produk_id': productId,
      if (productName != null) 'produk_name': productName,
      if (priceValue != null) 'price': _formatApiPrice(priceValue),
    };
  }

  String? _validProdukVarianId(String? value) {
    if (value == null) return null;
    return _produkVarianOptions
            .any((variant) => variant['id']?.toString() == value)
        ? value
        : null;
  }

  Map<String, dynamic>? _produkVarianById(String? id) {
    if (id == null) return null;
    for (final variant in _produkVarianOptions) {
      if (variant['id']?.toString() == id) return variant;
    }
    return null;
  }

  Future<void> _applyProdukVarian(String? id) async {
    setState(() {
      _selectedProdukVarianId = id;
      _selectedProdukVarianDetail = id == null ? null : _produkVarianById(id);
    });

    if (id != null) await _loadProdukVarianDetail(id);
  }

  Future<void> _loadProdukVarianDetail(String? id) async {
    if (id == null) return;
    setState(() => _isLoadingProdukVarianDetail = true);

    try {
      final res = await Http().getProdukVarianDetail(id);
      final detail = _detailMapFromResponse(res['data']) ??
          _produkVarianById(id) ??
          <String, dynamic>{'id': id};
      if (!mounted) return;
      setState(() => _selectedProdukVarianDetail = detail);
    } catch (_) {
      if (!mounted) return;
      setState(() => _selectedProdukVarianDetail = _produkVarianById(id));
    } finally {
      if (mounted) {
        setState(() => _isLoadingProdukVarianDetail = false);
      }
    }
  }

  String? _produkIdForVarian([Map<String, dynamic>? variant]) {
    return _selectedApiProductId ??
        variant?['produk_id']?.toString() ??
        _selectedProdukVarianDetail?['produk_id']?.toString();
  }

  Future<void> _showProdukVarianForm({
    Map<String, dynamic>? variant,
  }) async {
    final editingVariant = variant;
    final isEdit = editingVariant != null;
    final editId = editingVariant?['id']?.toString() ?? _selectedProdukVarianId;
    final produkId = _produkIdForVarian(editingVariant);
    if (produkId == null || produkId.trim().isEmpty) {
      _showSnack('Pilih Produk API dulu sebelum mengelola varian');
      return;
    }
    if (isEdit && (editId == null || editId.trim().isEmpty)) {
      _showSnack('ID varian tidak ditemukan');
      return;
    }

    final namaController = TextEditingController(
      text: editingVariant == null ? '' : _variantName(editingVariant),
    );
    final qtyController = TextEditingController(
      text: editingVariant == null
          ? ''
          : (_variantQty(editingVariant)?.toString() ?? ''),
    );
    final hargaController = TextEditingController(
      text: editingVariant == null
          ? ''
          : (_variantHarga(editingVariant)?.toStringAsFixed(0) ?? ''),
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: !_isMutatingProdukVarian,
      builder: (dialogContext) {
        var submitting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final nama = namaController.text.trim();
              final qty = int.tryParse(qtyController.text.trim());
              final harga = double.tryParse(hargaController.text.trim());

              if (nama.isEmpty) {
                _showSnack('Nama varian wajib diisi');
                return;
              }
              if (qty == null || qty < 0) {
                _showSnack('Qty harus berupa angka');
                return;
              }
              if (harga == null || harga <= 0) {
                _showSnack('Harga varian harus berupa angka');
                return;
              }

              setDialogState(() => submitting = true);
              if (mounted) {
                setState(() => _isMutatingProdukVarian = true);
              }

              Http().logger.i(
                    'SUBMIT PRODUK VARIAN FORM: '
                    'mode=${editingVariant != null ? 'update' : 'create'}, '
                    'id=$editId, produkId=$produkId, nama=$nama, '
                    'qty=$qty, harga=$harga',
                  );

              final response = editingVariant != null
                  ? await Http().updateProdukVarian(
                      id: editId!,
                      produkId: produkId,
                      namaVarian: nama,
                      qty: qty,
                      harga: harga,
                      isActive: _variantIsActive(editingVariant),
                    )
                  : await Http().createProdukVarian(
                      produkId: produkId,
                      namaVarian: nama,
                      qty: qty,
                      harga: harga,
                    );

              if (mounted) {
                setState(() => _isMutatingProdukVarian = false);
              }

              if (response['success'] == false) {
                setDialogState(() => submitting = false);
                _showSnack(response['message']?.toString() ??
                    'Gagal menyimpan varian produk');
                return;
              }

              final data = _detailMapFromResponse(response['data']) ??
                  <String, dynamic>{
                    if (editingVariant != null) 'id': editId,
                    'produk_id': produkId,
                    'nama_varian': nama,
                    'qty': qty,
                    'harga': harga,
                  };

              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop(data);
            }

            return AlertDialog(
              title: Text(isEdit ? 'Edit Varian Produk' : 'Tambah Varian'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: namaController,
                      decoration: _decoration(hintText: 'Nama varian'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtyController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _decoration(hintText: 'Qty'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: hargaController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: _decoration(
                        hintText: 'Harga varian',
                        prefixText: 'Rp ',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: submitting ? null : submit,
                  child: submitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Update' : 'Simpan'),
                ),
              ],
            );
          },
        );
      },
    );

    Future<void>.delayed(const Duration(milliseconds: 350), () {
      namaController.dispose();
      qtyController.dispose();
      hargaController.dispose();
    });

    if (result == null || !mounted) return;

    final resultId = result['id']?.toString() ??
        result['produk_varian_id']?.toString() ??
        editId;

    setState(() {
      _selectedProdukVarianId = resultId;
      _selectedProdukVarianDetail = result;
    });
    await _loadProdukVarian(produkId: produkId);
    if (resultId != null) {
      await _applyProdukVarian(resultId);
    }

    if (!mounted) return;
    _showSnack(isEdit ? 'Varian berhasil diupdate' : 'Varian berhasil dibuat');
  }

  Future<void> _deleteSelectedProdukVarian() async {
    final id = _selectedProdukVarianId;
    if (id == null) {
      _showSnack('Pilih varian yang mau dihapus');
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Varian'),
          content: const Text('Yakin ingin menghapus variasi produk ini?'),
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

    setState(() => _isMutatingProdukVarian = true);
    final response = await Http().deleteProdukVarian(id);
    if (!mounted) return;
    setState(() => _isMutatingProdukVarian = false);

    if (response['success'] == false) {
      _showSnack(response['message']?.toString() ?? 'Gagal menghapus varian');
      return;
    }

    setState(() {
      _selectedProdukVarianId = null;
      _selectedProdukVarianDetail = null;
    });
    await _loadProdukVarian(produkId: _selectedApiProductId);

    if (!mounted) return;
    _showSnack('Varian berhasil dihapus');
  }

  String _variantName(Map<String, dynamic> variant) {
    return _firstString(
          variant,
          const ['nama_varian', 'name', 'nama', 'variant_name', 'varian'],
        ) ??
        '';
  }

  int? _variantQty(Map<String, dynamic> variant) {
    final value = variant['qty'] ?? variant['stok'] ?? variant['stock'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  double? _variantHarga(Map<String, dynamic> variant) {
    final value = variant['harga'] ?? variant['harga_jual'] ?? variant['price'];
    if (value is num) return value.toDouble();
    return _priceIntFromApi(value)?.toDouble();
  }

  bool _variantIsActive(Map<String, dynamic> variant) {
    final value = variant['is_active'] ?? variant['isActive'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value != '0' && value.toLowerCase() != 'false';
    return true;
  }

  Map<String, dynamic>? _detailMapFromResponse(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    final list = _extractList(data);
    if (list.isNotEmpty && list.first is Map) {
      return Map<String, dynamic>.from(list.first as Map);
    }
    return null;
  }

  String _produkVarianLabel(Map<String, dynamic> variant) {
    final name = _firstString(
          variant,
          const [
            'name',
            'nama',
            'nama_varian',
            'variant_name',
            'varian',
            'title',
          ],
        ) ??
        variant['id']?.toString() ??
        '';
    final productName = variant['produk_name']?.toString() ??
        _nestedName(
          variant['produk'] ?? variant['product'],
          const ['nama', 'name', 'nama_produk', 'title'],
        ) ??
        '';
    final price = variant['price']?.toString() ?? '';
    final sku = _firstString(variant, const ['sku', 'kode', 'code']) ?? '';

    final suffix = [
      if (productName.isNotEmpty) productName,
      if (sku.isNotEmpty) sku,
      if (price.isNotEmpty) price,
    ].join(' / ');

    return suffix.isEmpty ? name : '$name - $suffix';
  }

  String _formatApiPrice(dynamic value) {
    final parsed = _priceIntFromApi(value);
    if (parsed != null) return _formatPrice(parsed);
    final raw = value?.toString() ?? '';
    return raw.trim().isEmpty ? 'Rp 0' : raw;
  }

  int? _priceIntFromApi(dynamic value) {
    if (value is num) return value.toInt();

    final raw = value?.toString().trim() ?? '';
    if (raw.isEmpty) return null;

    final normalized = raw.replaceAll(RegExp(r'[^0-9.,]'), '');
    final decimal = double.tryParse(normalized.replaceAll(',', ''));
    if (decimal != null) return decimal.toInt();

    final digits = _digitsOnly(raw);
    return int.tryParse(digits);
  }

  String? _imageFromApi(Map item) {
    final direct = _firstString(item, const [
      'image_url',
      'thumbnail_url',
      'gambar_url',
      'foto_url',
      'image',
      'thumbnail',
      'foto',
    ]);
    if (direct != null) return direct;

    for (final key in const ['gambar_utama', 'gambar', 'image', 'foto']) {
      final value = item[key];
      if (value is Map) {
        final nested = _firstString(value, const [
          'image_url',
          'thumbnail_url',
          'url',
          'path',
          'filename',
        ]);
        if (nested != null) return nested;
      }
      if (value is List && value.isNotEmpty && value.first is Map) {
        final nested = _firstString(value.first as Map, const [
          'image_url',
          'thumbnail_url',
          'url',
          'path',
          'filename',
        ]);
        if (nested != null) return nested;
      }
    }

    return null;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() => _isPickingImage = true);
      final XFile? picked =
          await _imagePicker.pickImage(source: source, imageQuality: 85);
      if (!mounted) return;
      if (picked != null) {
        setState(() {
          _selectedImage = picked.path;
        });
      }
    } catch (_) {
      if (!mounted) return;
      _showSnack('Gagal memilih gambar');
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pilih Gambar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.photo_camera_rounded),
                  title: const Text('Kamera'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded),
                  title: const Text('Galeri'),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _saveProduct() async {
    final name = _nameController.text.trim();
    final priceText = _priceController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty || priceText.isEmpty || description.isEmpty) {
      _showSnack('Semua field wajib diisi');
      return;
    }

    if (_selectedCategoryId == null) {
      _showSnack('Kategori wajib dipilih');
      return;
    }

    if (_satuanOptions.isNotEmpty && _selectedSatuanId == null) {
      _showSnack('Satuan wajib dipilih');
      return;
    }

    final priceValue = int.tryParse(priceText);
    if (priceValue == null || priceValue <= 0) {
      _showSnack('Harga harus berupa angka');
      return;
    }

    setState(() => _isSaving = true);

    final product = <String, dynamic>{
      if (_selectedApiProductId != null) 'api_id': _selectedApiProductId,
      'name': name,
      'price': _formatPrice(priceValue),
      'category': _nameFor(_categories, _selectedCategoryId),
      'kategori_produk_id': _selectedCategoryId,
      if (_selectedSatuanId != null) 'satuan_id': _selectedSatuanId,
      if (_selectedSatuanId != null)
        'satuan': _nameFor(_satuanOptions, _selectedSatuanId),
      if (_selectedProdukVarianId != null)
        'produk_varian_id': _selectedProdukVarianId,
      if (_selectedProdukVarianId != null)
        'produk_varian': _produkVarianLabel(
          _produkVarianById(_selectedProdukVarianId) ??
              _selectedProdukVarianDetail ??
              <String, dynamic>{'id': _selectedProdukVarianId},
        ),
      if (_selectedProdukVarianDetail != null)
        'produk_varian_detail': _selectedProdukVarianDetail,
      'image': _selectedImage,
      'description': description,
      'isUserProduct': true,
      if (_selectedApiProductId != null) 'isApiProduct': true,
    };

    if (widget.existingProduct != null &&
        widget.productIndex != null &&
        widget.productIndex! >= 0 &&
        widget.productIndex! < allProducts.length) {
      allProducts[widget.productIndex!] = product;
    } else {
      allProducts.add(product);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF111827);
    const primary = Color(0xFF6C7BFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: Text(
            widget.existingProduct == null ? 'Jual Produk' : 'Edit Produk'),
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 0,
            color: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jual produk kamu',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLoadingProduk
                        ? 'Memuat produk dari server...'
                        : 'Produk akan langsung tersimpan di memory dan muncul di dashboard.',
                    style:
                        const TextStyle(color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  _label('Produk API'),
                  const SizedBox(height: 8),
                  _apiProductDropdownField(),
                  const SizedBox(height: 16),
                  _label('Nama Produk'),
                  const SizedBox(height: 8),
                  _textField(
                      controller: _nameController,
                      hintText: 'Contoh: Sepatu Running'),
                  const SizedBox(height: 16),
                  _label('Harga'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _priceController,
                    hintText: 'Contoh: 250000',
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    prefixText: 'Rp ',
                  ),
                  const SizedBox(height: 16),
                  _label('Kategori'),
                  const SizedBox(height: 8),
                  _apiDropdownField(
                    value: _validValue(_categories, _selectedCategoryId),
                    options: _categories,
                    hintText: 'Pilih kategori',
                    loading: _isLoadingLookups,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedCategoryId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  _label('Satuan'),
                  const SizedBox(height: 8),
                  _apiDropdownField(
                    value: _validValue(_satuanOptions, _selectedSatuanId),
                    options: _satuanOptions,
                    hintText: 'Pilih satuan',
                    emptyText: 'Satuan belum tersedia dari API',
                    loading: _isLoadingLookups,
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _selectedSatuanId = value);
                    },
                  ),
                  const SizedBox(height: 16),
                  _label('Varian Produk'),
                  const SizedBox(height: 8),
                  _produkVarianDropdownField(),
                  const SizedBox(height: 10),
                  _produkVarianActionButtons(),
                  _produkVarianDetailView(),
                  const SizedBox(height: 16),
                  _label('Deskripsi'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _descriptionController,
                    hintText: 'Tulis deskripsi produk...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  _label('Gambar Produk'),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _showImageSourceSheet,
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: AspectRatio(
                              aspectRatio: 1.55,
                              child: _isPickingImage
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : ShopImage(
                                      imagePath: _selectedImage,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.55),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Tap gambar untuk pilih dari kamera atau galeri',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveProduct,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.existingProduct == null
                                  ? 'Tambah Produk'
                                  : 'Simpan Perubahan',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? prefixText,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: _decoration(hintText: hintText, prefixText: prefixText),
    );
  }

  Widget _apiProductDropdownField() {
    final hasOptions = _apiProducts.isNotEmpty;

    return DropdownButtonFormField<String>(
      value: hasOptions ? _validApiProductId(_selectedApiProductId) : null,
      isExpanded: true,
      decoration: _decoration(
        hintText: _isLoadingProduk ? 'Memuat produk...' : 'Pilih produk API',
        helperText: !_isLoadingProduk && !hasOptions
            ? 'Produk belum tersedia dari API'
            : null,
      ),
      icon: _isLoadingProduk
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.keyboard_arrow_down_rounded),
      items: _apiProducts
          .where((product) => product['api_id'] != null)
          .map(
            (product) => DropdownMenuItem(
              value: product['api_id'].toString(),
              child: Text(
                _apiProductLabel(product),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _isLoadingProduk || !hasOptions ? null : _applyApiProduct,
    );
  }

  String _apiProductLabel(Map<String, dynamic> product) {
    final name = product['name']?.toString() ?? '';
    final price = product['price']?.toString() ?? '';
    final satuan = product['satuan']?.toString() ?? '';

    final suffix = [
      if (price.isNotEmpty) price,
      if (satuan.isNotEmpty) satuan,
    ].join(' / ');

    return suffix.isEmpty ? name : '$name - $suffix';
  }

  Widget _produkVarianDropdownField() {
    final hasOptions = _produkVarianOptions.isNotEmpty;
    final value = _validProdukVarianId(_selectedProdukVarianId);

    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      decoration: _decoration(
        hintText: _isLoadingProdukVarian ? 'Memuat varian...' : 'Pilih varian',
        helperText: !_isLoadingProdukVarian && !hasOptions
            ? 'Varian produk belum tersedia dari API'
            : null,
      ),
      icon: _isLoadingProdukVarian
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.keyboard_arrow_down_rounded),
      items: [
        const DropdownMenuItem(
          value: '',
          child: Text('Tanpa varian'),
        ),
        ..._produkVarianOptions.map(
          (variant) => DropdownMenuItem(
            value: variant['id']?.toString(),
            child: Text(
              _produkVarianLabel(variant),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: _isLoadingProdukVarian || !hasOptions
          ? null
          : (value) =>
              _applyProdukVarian(value?.isEmpty == true ? null : value),
    );
  }

  Widget _produkVarianActionButtons() {
    final selectedVariant = _produkVarianById(_selectedProdukVarianId) ??
        _selectedProdukVarianDetail;
    final hasSelectedVariant =
        _selectedProdukVarianId != null && selectedVariant != null;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        OutlinedButton.icon(
          onPressed:
              _isMutatingProdukVarian ? null : () => _showProdukVarianForm(),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Tambah'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF6C7BFF),
            side: const BorderSide(color: Color(0xFFD7DBFF)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _isMutatingProdukVarian || !hasSelectedVariant
              ? null
              : () => _showProdukVarianForm(
                    variant: selectedVariant,
                  ),
          icon: const Icon(Icons.edit_rounded, size: 18),
          label: const Text('Edit'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF0F766E),
            side: const BorderSide(color: Color(0xFF99F6E4)),
          ),
        ),
        OutlinedButton.icon(
          onPressed: _isMutatingProdukVarian || !hasSelectedVariant
              ? null
              : _deleteSelectedProdukVarian,
          icon: _isMutatingProdukVarian
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.delete_rounded, size: 18),
          label: const Text('Hapus'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFFDC2626),
            side: const BorderSide(color: Color(0xFFFECACA)),
          ),
        ),
      ],
    );
  }

  Widget _produkVarianDetailView() {
    if (_selectedProdukVarianId == null) return const SizedBox.shrink();

    final detail = _selectedProdukVarianDetail;
    final rows = detail == null
        ? const <MapEntry<String, String>>[]
        : _detailRows(detail);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: _isLoadingProdukVarianDetail && rows.isEmpty
          ? const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'Memuat detail varian...',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detail Varian',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 10),
                if (rows.isEmpty)
                  const Text(
                    'Detail varian tidak tersedia',
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  )
                else
                  ...rows.map(
                    (row) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 96,
                            child: Text(
                              row.key,
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              row.value,
                              style: const TextStyle(
                                color: Color(0xFF111827),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
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

  List<MapEntry<String, String>> _detailRows(Map<String, dynamic> detail) {
    const preferredKeys = [
      'nama',
      'name',
      'nama_varian',
      'variant_name',
      'sku',
      'kode',
      'qty',
      'harga',
      'harga_jual',
      'price',
      'stok',
      'stock',
      'berat',
      'weight',
      'warna',
      'color',
      'ukuran',
      'size',
      'deskripsi',
      'description',
    ];

    final rows = <MapEntry<String, String>>[];
    final usedKeys = <String>{};

    void addRow(String key, dynamic value) {
      final text = _detailValue(value);
      if (text == null || usedKeys.contains(key)) return;
      rows.add(MapEntry(_detailLabel(key), text));
      usedKeys.add(key);
    }

    for (final key in preferredKeys) {
      if (detail.containsKey(key)) addRow(key, detail[key]);
    }

    for (final entry in detail.entries) {
      if (rows.length >= 8) break;
      addRow(entry.key, entry.value);
    }

    return rows.take(8).toList();
  }

  String? _detailValue(dynamic value) {
    if (value == null) return null;
    if (value is Map) {
      return _firstString(value, const [
        'nama',
        'name',
        'title',
        'value',
        'kode',
        'sku',
      ]);
    }
    if (value is List) {
      final parts = value
          .map(_detailValue)
          .where((part) => part != null && part.trim().isNotEmpty)
          .cast<String>()
          .toList();
      return parts.isEmpty ? null : parts.join(', ');
    }

    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  String _detailLabel(String key) {
    const labels = {
      'nama': 'Nama',
      'name': 'Nama',
      'nama_varian': 'Nama',
      'variant_name': 'Nama',
      'sku': 'SKU',
      'kode': 'Kode',
      'qty': 'Qty',
      'harga': 'Harga',
      'harga_jual': 'Harga',
      'price': 'Harga',
      'stok': 'Stok',
      'stock': 'Stok',
      'berat': 'Berat',
      'weight': 'Berat',
      'warna': 'Warna',
      'color': 'Warna',
      'ukuran': 'Ukuran',
      'size': 'Ukuran',
      'deskripsi': 'Deskripsi',
      'description': 'Deskripsi',
      'produk_id': 'Produk ID',
    };
    return labels[key] ??
        key
            .split('_')
            .where((part) => part.isNotEmpty)
            .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
            .join(' ');
  }

  Widget _apiDropdownField({
    required String? value,
    required List<Map<String, String>> options,
    required String hintText,
    required bool loading,
    required ValueChanged<String?> onChanged,
    String? emptyText,
  }) {
    final hasOptions = options.isNotEmpty;

    return DropdownButtonFormField<String>(
      value: hasOptions ? value : null,
      isExpanded: true,
      decoration: _decoration(
        hintText: loading ? 'Memuat data...' : hintText,
        helperText: !loading && !hasOptions ? emptyText : null,
      ),
      icon: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.keyboard_arrow_down_rounded),
      items: options
          .map(
            (option) => DropdownMenuItem(
              value: option['id'],
              child: Text(
                option['name'] ?? option['id'] ?? '',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: loading || !hasOptions ? null : onChanged,
    );
  }

  InputDecoration _decoration({
    String hintText = '',
    String? prefixText,
    String? helperText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixText: prefixText,
      helperText: helperText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF6C7BFF), width: 1.5),
      ),
    );
  }
}
