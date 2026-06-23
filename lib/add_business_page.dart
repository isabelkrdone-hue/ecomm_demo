import 'package:flutter/material.dart';
import 'dart:convert';

import 'repository/http.dart';
import 'package:logger/logger.dart';

class AddBusinessPage extends StatefulWidget {
  const AddBusinessPage({super.key});

  @override
  State<AddBusinessPage> createState() => _AddBusinessPageState();
}

class _AddBusinessPageState extends State<AddBusinessPage> {
  // controllers kept per requirements
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Location variables (we store selected ids)
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedSubDistrict;

  // store display lists as pairs {id, name} so dropdown values are ids
  List<Map<String, String>> _provinces = [];
  List<Map<String, String>> _cities = [];
  List<Map<String, String>> _districts = [];
  List<Map<String, String>> _subDistricts = [];

  // Seller category id
  String? _sellerCategoryId;
  final List<Map<String, String>> _sellerCategories = [];
  bool _categoriesLoading = false;

  bool _isSaving = false;
  final Logger _logger = Logger();
  String? _lastApiLog;

  static const int _locationPerPage = 100;

  @override
  void initState() {
    super.initState();
    _loadSellerCategories();
    _loadProvinces();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

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
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return null;
  }

  List<Map<String, String>> _locationOptionsFrom(dynamic data) {
    final options = <Map<String, String>>[];
    for (final item in _extractList(data)) {
      if (item is Map) {
        final id = _firstString(item, const ['id', 'kode', 'code', 'value']);
        final name = _firstString(item, const [
          'nama',
          'name',
          'nama_kota',
          'nama_kabupaten',
          'regency_name',
          'city_name',
        ]);
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

  void _logRegencyOptions(
      String provinceId, List<Map<String, String>> options) {
    final cityNames = <String>[];
    final regencyNames = <String>[];
    final otherNames = <String>[];

    for (final option in options) {
      final name = option['name'] ?? '';
      final normalized = name.toLowerCase();
      if (normalized.startsWith('kota')) {
        cityNames.add(name);
      } else if (normalized.startsWith('kabupaten') ||
          normalized.startsWith('kab.')) {
        regencyNames.add(name);
      } else {
        otherNames.add(name);
      }
    }

    _logger.i(
      'Regencies provinceId=$provinceId total=${options.length} '
      'kota=${cityNames.length} kabupaten=${regencyNames.length} '
      'lainnya=${otherNames.length}',
    );
    _logger.i('Kota: ${cityNames.isEmpty ? '-' : cityNames.join(', ')}');
    _logger.i(
      'Kabupaten: ${regencyNames.isEmpty ? '-' : regencyNames.join(', ')}',
    );
    if (otherNames.isNotEmpty) {
      _logger.i('Regency lainnya: ${otherNames.join(', ')}');
    }
  }

  void _logLocationOptions(
    String label,
    String parentLabel,
    String parentId,
    List<Map<String, String>> options,
  ) {
    _logger.i(
      '$label $parentLabel=$parentId total=${options.length}: '
      '${options.map((option) => option['name']).join(', ')}',
    );
  }

  Future<void> _loadProvinces() async {
    setState(() {});
    try {
      final res = await Http().getProvinces(perPage: _locationPerPage);
      _lastApiLog = 'getProvinces => ${jsonEncode(res)}';
      _logger.i(_lastApiLog);
      final options = _locationOptionsFrom(res['data']);
      _logger.i(
        'Provinces total=${options.length}: '
        '${options.map((option) => option['name']).join(', ')}',
      );
      if (res['success'] == true && options.isNotEmpty) {
        setState(() {
          _provinces = options;
        });
      }
    } catch (e) {
      _logger.w('Failed to fetch provinces: $e');
    }
  }

  Future<void> _loadCities(String provinceId) async {
    try {
      final res = await Http()
          .getRegencies(provinceId: provinceId, perPage: _locationPerPage);
      _lastApiLog =
          'getRegencies(provinceId=$provinceId) => ${jsonEncode(res)}';
      _logger.i(_lastApiLog);
      final options = _locationOptionsFrom(res['data']);
      _logRegencyOptions(provinceId, options);
      if (res['success'] == true) {
        setState(() {
          _cities = options;
        });
      }
    } catch (e) {
      _logger.w('Failed to fetch cities: $e');
    }
  }

  Future<void> _loadDistricts(String regencyId) async {
    try {
      final res = await Http()
          .getDistricts(regencyId: regencyId, perPage: _locationPerPage);
      _lastApiLog = 'getDistricts(regencyId=$regencyId) => ${jsonEncode(res)}';
      _logger.i(_lastApiLog);
      final options = _locationOptionsFrom(res['data']);
      _logLocationOptions('Districts', 'regencyId', regencyId, options);
      if (res['success'] == true) {
        setState(() {
          _districts = options;
        });
      }
    } catch (e) {
      _logger.w('Failed to fetch districts: $e');
    }
  }

  Future<void> _loadSubDistricts(String districtId) async {
    try {
      final res = await Http()
          .getVillages(districtId: districtId, perPage: _locationPerPage);
      _lastApiLog = 'getVillages(districtId=$districtId) => ${jsonEncode(res)}';
      _logger.i(_lastApiLog);
      final options = _locationOptionsFrom(res['data']);
      _logLocationOptions('Villages', 'districtId', districtId, options);
      if (res['success'] == true) {
        setState(() {
          _subDistricts = options;
        });
      }
    } catch (e) {
      _logger.w('Failed to fetch sub-districts: $e');
    }
  }

  Future<void> _loadSellerCategories() async {
    setState(() => _categoriesLoading = true);
    try {
      final res = await Http().getKategoriSeller();
      _lastApiLog = 'getKategoriSeller => ${jsonEncode(res)}';
      _logger.i(_lastApiLog);
      if (res['success'] == true && res['data'] is List) {
        setState(() {
          _sellerCategories.clear();
          for (final item in res['data']) {
            if (item is Map) {
              final id = item['id']?.toString();
              final rawName =
                  item['nama']?.toString() ?? item['name']?.toString();
              if (id != null) {
                _sellerCategories.add({'id': id, 'name': rawName ?? id});
              }
            }
          }
        });
      }
    } catch (e) {
      _logger.w('Failed to fetch seller categories: $e');
    } finally {
      if (mounted) setState(() => _categoriesLoading = false);
    }
  }

  void _onProvinceChanged(String? prov) {
    if (prov == null) return;
    setState(() {
      _selectedProvince = prov;
      _selectedCity = null;
      _selectedDistrict = null;
      _selectedSubDistrict = null;
      _cities = [];
      _districts = [];
      _subDistricts = [];
    });
    _loadCities(prov);
  }

  void _onCityChanged(String? city) {
    if (city == null) return;
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _selectedSubDistrict = null;
      _districts = [];
      _subDistricts = [];
    });
    _loadDistricts(city);
  }

  void _onDistrictChanged(String? district) {
    if (district == null) return;
    setState(() {
      _selectedDistrict = district;
      _selectedSubDistrict = null;
      _subDistricts = [];
    });
    _loadSubDistricts(district);
  }

  void _onSubDistrictChanged(String? sub) {
    if (sub == null) return;
    setState(() => _selectedSubDistrict = sub);
  }

  Future<void> _saveBusiness() async {
    final namaPemilik = _businessNameController.text.trim();
    if (namaPemilik.isEmpty || _businessNameController.text.trim().isEmpty) {
      _showSnack('Nama bisnis wajib diisi');
      return;
    }

    if (_emailController.text.trim().isEmpty) {
      _showSnack('Surel wajib diisi');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showSnack('Kata sandi wajib diisi');
      return;
    }
    if (_confirmPasswordController.text.isEmpty) {
      _showSnack('Konfirmasi kata sandi wajib diisi');
      return;
    }
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      _showSnack('Kata sandi dan konfirmasi tidak cocok');
      return;
    }

    if (_sellerCategoryId == null || _sellerCategoryId!.isEmpty) {
      _showSnack('Pilih kategori seller');
      return;
    }

    if (_selectedProvince == null ||
        _selectedCity == null ||
        _selectedDistrict == null ||
        _selectedSubDistrict == null) {
      _showSnack('Pilih lokasi lengkap');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final result = await Http().registerSeller(
        name: namaPemilik,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
        passwordConfirmation: _confirmPasswordController.text.trim(),
        kategoriSellerId: _sellerCategoryId!,
        namaToko: _businessNameController.text,
        alamat: _addressController.text,
        provinsi: _selectedProvince!,
        kota: _selectedCity!,
        kecamatan: _selectedDistrict!,
        desa: _selectedSubDistrict!,
        deskripsi: _descriptionController.text,
      );

      _logger.i('registerSeller => $result');

      if (result['success'] == true) {
        if (!mounted) return;
        _showSnack('Pendaftaran seller berhasil');
        Navigator.of(context).pop(true);
      } else {
        _showSnack(result['message']?.toString() ?? 'Gagal mendaftar seller');
      }
    } catch (e) {
      _logger.e('registerSeller error: $e');
      _showSnack('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const textColor = Color(0xFF111827);
    const primary = Color(0xFF6C7BFF);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        title: const Text('Tambah Bisnis'),
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
                    'Informasi Bisnis',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lengkapi informasi bisnis Anda',
                    style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  _label('Nama Bisnis'),
                  const SizedBox(height: 8),
                  _textField(
                      controller: _businessNameController,
                      hintText: 'Contoh: Toko Elektronik Jaya'),
                  const SizedBox(height: 16),
                  _label('Deskripsi'),
                  const SizedBox(height: 8),
                  _textField(
                      controller: _descriptionController,
                      hintText: 'Deskripsi bisnis Anda...',
                      maxLines: 3),
                  const SizedBox(height: 16),
                  _label('Surel (Email)'),
                  const SizedBox(height: 8),
                  _textField(
                      controller: _emailController,
                      hintText: 'contoh@domain.com',
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 16),
                  _label('Kata Sandi'),
                  const SizedBox(height: 8),
                  _textField(
                      controller: _passwordController,
                      hintText: 'Minimal 6 karakter',
                      keyboardType: TextInputType.visiblePassword),
                  const SizedBox(height: 16),
                  _label('Konfirmasi Kata Sandi'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: _decoration(hintText: 'Konfirmasi kata sandi'),
                  ),
                  const SizedBox(height: 16),
                  _label('Kategori Seller'),
                  const SizedBox(height: 8),
                  _categoriesLoading
                      ? const SizedBox(
                          height: 48,
                          child: Center(child: CircularProgressIndicator()))
                      : _sellerCategories.isNotEmpty
                          ? DropdownButtonFormField<String>(
                              value: _sellerCategoryId,
                              decoration: _decoration(
                                  hintText: 'Pilih Kategori Seller'),
                              items: _sellerCategories
                                  .map((c) => DropdownMenuItem(
                                      value: c['id'], child: Text(c['name']!)))
                                  .toList(),
                              onChanged: (val) =>
                                  setState(() => _sellerCategoryId = val),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                    'Kategori seller tidak tersedia — coba tekan refresh atau cek koneksi.',
                                    style: TextStyle(
                                        color: Color(0xFFB91C1C),
                                        fontSize: 12)),
                                const SizedBox(height: 8),
                                SizedBox(
                                    width: 160,
                                    height: 40,
                                    child: OutlinedButton.icon(
                                        onPressed: _loadSellerCategories,
                                        icon: const Icon(Icons.refresh),
                                        label: const Text('Muat ulang'))),
                              ],
                            ),
                  const SizedBox(height: 16),
                  _label('Nomor Telepon'),
                  const SizedBox(height: 8),
                  _textField(
                      controller: _phoneController,
                      hintText: '08123456789',
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 16),
                  _label('Alamat Lengkap'),
                  const SizedBox(height: 8),
                  _textField(
                      controller: _addressController,
                      hintText: 'Jalan, Nomor, RT/RW',
                      maxLines: 2),
                  const SizedBox(height: 24),
                  const Text('Lokasi Bisnis',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor)),
                  const SizedBox(height: 16),
                  _label('Provinsi'),
                  const SizedBox(height: 8),
                  _provinces.isNotEmpty
                      ? DropdownButtonFormField<String>(
                          value: _selectedProvince,
                          decoration: _decoration(hintText: 'Pilih Provinsi'),
                          items: _provinces
                              .map((p) => DropdownMenuItem(
                                  value: p['id'], child: Text(p['name'] ?? '')))
                              .toList(),
                          onChanged: _onProvinceChanged,
                        )
                      : Row(children: [
                          const Expanded(
                              child: Text(
                                  'Provinsi tidak tersedia. Periksa koneksi.')),
                          OutlinedButton.icon(
                              onPressed: _loadProvinces,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Muat ulang'))
                        ]),
                  const SizedBox(height: 16),
                  _label('Kota/Kabupaten'),
                  const SizedBox(height: 8),
                  _cities.isNotEmpty
                      ? DropdownButtonFormField<String>(
                          value: _selectedCity,
                          decoration:
                              _decoration(hintText: 'Pilih Kota/Kabupaten'),
                          items: _cities
                              .map((c) => DropdownMenuItem(
                                  value: c['id'], child: Text(c['name'] ?? '')))
                              .toList(),
                          onChanged: _onCityChanged,
                        )
                      : DropdownButtonFormField<String>(
                          value: null,
                          decoration: _decoration(
                              hintText: 'Pilih Provinsi terlebih dahulu'),
                          items: const [],
                          onChanged: null),
                  const SizedBox(height: 16),
                  _label('Kecamatan'),
                  const SizedBox(height: 8),
                  _districts.isNotEmpty
                      ? DropdownButtonFormField<String>(
                          value: _selectedDistrict,
                          decoration: _decoration(hintText: 'Pilih Kecamatan'),
                          items: _districts
                              .map((d) => DropdownMenuItem(
                                  value: d['id'], child: Text(d['name'] ?? '')))
                              .toList(),
                          onChanged: _onDistrictChanged,
                        )
                      : DropdownButtonFormField<String>(
                          value: null,
                          decoration: _decoration(
                              hintText: 'Pilih Kota terlebih dahulu'),
                          items: const [],
                          onChanged: null),
                  const SizedBox(height: 16),
                  _label('Kelurahan'),
                  const SizedBox(height: 8),
                  _subDistricts.isNotEmpty
                      ? DropdownButtonFormField<String>(
                          value: _selectedSubDistrict,
                          decoration: _decoration(hintText: 'Pilih Kelurahan'),
                          items: _subDistricts
                              .map((s) => DropdownMenuItem(
                                  value: s['id'], child: Text(s['name'] ?? '')))
                              .toList(),
                          onChanged: _onSubDistrictChanged,
                        )
                      : DropdownButtonFormField<String>(
                          value: null,
                          decoration: _decoration(
                              hintText: 'Pilih Kecamatan terlebih dahulu'),
                          items: const [],
                          onChanged: null),
                  const SizedBox(height: 16),
                  const SizedBox(height: 24),
                  SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveBusiness,
                          style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16))),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white)))
                              : const Text('Daftar',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF111827)));

  Widget _textField(
      {required TextEditingController controller,
      required String hintText,
      int maxLines = 1,
      TextInputType? keyboardType}) {
    return TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: _decoration(hintText: hintText));
  }

  InputDecoration _decoration({String hintText = ''}) => InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF6C7BFF), width: 1.5)));
}
