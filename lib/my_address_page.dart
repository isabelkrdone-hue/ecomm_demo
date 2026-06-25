import 'package:flutter/material.dart';

import 'address_model.dart';
import 'address_location_resolver.dart';
import 'app_ui.dart';
import 'repository/http.dart';

class MyAddressPage extends StatefulWidget {
  const MyAddressPage({super.key});

  @override
  State<MyAddressPage> createState() => _MyAddressPageState();
}

class _MyAddressPageState extends State<MyAddressPage> {
  final List<Map<String, String>> _addresses = [];
  final AddressModel _addressCache = AddressModel.instance;
  int _selectedIndex = 0;
  bool _loadingAddresses = false;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
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

  bool _firstBool(Map item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;
      if (value is bool) return value;
      final normalized = value.toString().trim().toLowerCase();
      if (normalized.isEmpty) continue;
      return normalized == '1' || normalized == 'true' || normalized == 'yes';
    }
    return false;
  }

  bool _looksLikeLocationId(String? value) {
    if (value == null) return false;
    final normalized = value.trim();
    if (normalized.isEmpty) return false;
    return RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-5][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
        ).hasMatch(normalized) ||
        RegExp(r'^\d+$').hasMatch(normalized);
  }

  Map<String, String> _mapAddressFromApi(Map item) {
    final id = _firstString(item, const ['id', 'uuid']);
    final penerima = _firstString(item, const ['penerima', 'name', 'nama']);
    final phone =
        _firstString(item, const ['phone', 'phone_number', 'telepon']);
    final alamat = _firstString(item, const ['alamat', 'address', 'detail']);
    final provinsi = _firstString(item, const ['provinsi', 'province']);
    final kota = _firstString(item, const ['kota', 'city', 'kabupaten']);
    final kecamatan = _firstString(item, const ['kecamatan', 'district']);
    final desa = _firstString(item, const ['desa', 'village', 'kelurahan']);
    final kodePos =
        _firstString(item, const ['kode_pos', 'kodePos', 'postal_code']);

    final String provinceId =
        _firstString(item, const ['province_id', 'provinsi_id']) ??
            (_looksLikeLocationId(provinsi) ? provinsi! : '');
    final String regencyId =
        _firstString(item, const ['regency_id', 'kota_id']) ??
            (_looksLikeLocationId(kota) ? kota! : '');
    final String districtId =
        _firstString(item, const ['district_id', 'kecamatan_id']) ??
            (_looksLikeLocationId(kecamatan) ? kecamatan! : '');
    final String villageId =
        _firstString(item, const ['village_id', 'desa_id']) ??
            (_looksLikeLocationId(desa) ? desa! : '');

    final cityParts = <String>[
      if (kota != null && kota.isNotEmpty) kota,
      if (provinsi != null && provinsi.isNotEmpty) provinsi,
    ];

    return {
      if (id != null) 'id': id,
      'label': _firstString(item, const ['label', 'nama_label']) ?? 'Alamat',
      'name': penerima ?? '',
      'phone': phone ?? '',
      'address': alamat ?? '',
      'city': cityParts.join(', '),
      'province_id': provinceId,
      'province': provinsi ?? '',
      'regency_id': regencyId,
      'regency': kota ?? '',
      'district_id': districtId,
      'district': kecamatan ?? '',
      'village_id': villageId,
      'village': desa ?? '',
      'postal_code': kodePos ?? '',
      'is_default': _firstBool(item, const ['is_default']).toString(),
      'is_active': _firstBool(item, const ['is_active']).toString(),
    };
  }

  List<Map<String, String>> _addressesFromResponse(dynamic data) {
    final addresses = <Map<String, String>>[];
    for (final item in _extractList(data)) {
      if (item is Map) {
        addresses.add(_mapAddressFromApi(item));
      }
    }
    return addresses;
  }

  String? _addressIdAt(int index) {
    if (index < 0 || index >= _addresses.length) return null;
    final id = _addresses[index]['id'];
    if (id == null || id.trim().isEmpty) return null;
    return id;
  }

  String _responseMessage(dynamic res) {
    final message = res is Map ? res['message'] : null;
    if (message == null) return 'Terjadi kesalahan.';
    if (message is String && message.trim().isNotEmpty) return message;
    return message.toString();
  }

  String _addressLine(Map<String, String> addr) {
    final parts = <String>[
      if ((addr['address'] ?? '').isNotEmpty) addr['address']!,
      if ((addr['village'] ?? '').isNotEmpty) addr['village']!,
      if ((addr['district'] ?? '').isNotEmpty) addr['district']!,
      if ((addr['regency'] ?? '').isNotEmpty) addr['regency']!,
      if ((addr['province'] ?? '').isNotEmpty) addr['province']!,
      if ((addr['postal_code'] ?? '').isNotEmpty) addr['postal_code']!,
    ];
    return parts.join(', ');
  }

  Future<void> _loadAddresses() async {
    if (mounted) {
      setState(() => _loadingAddresses = true);
    }

    try {
      final res = await Http().getAlamatPengiriman();
      if (!mounted) return;

      if (res['success'] == true) {
        final addresses =
            await AddressLocationResolver.instance.resolveAddresses(
          _addressesFromResponse(res['data']),
        );
        if (!mounted) return;
        _addresses
          ..clear()
          ..addAll(addresses);

        if (_addresses.isEmpty) {
          _selectedIndex = 0;
          _addressCache.replaceAddresses(<Map<String, String>>[]);
          setState(() {});
          return;
        }

        final selectedDefaultIndex = _addresses.indexWhere(
          (item) => item['is_default'] == 'true' || item['is_default'] == '1',
        );
        if (selectedDefaultIndex >= 0) {
          _selectedIndex = selectedDefaultIndex;
        } else if (_selectedIndex >= _addresses.length) {
          _selectedIndex = 0;
        }
        _addressCache.replaceAddresses(_addresses);
        _addressCache.setSelected(_selectedIndex);
      }
      setState(() {});
    } finally {
      if (mounted) {
        setState(() => _loadingAddresses = false);
      }
    }
  }

  Future<void> _saveAddress(
    Map<String, String> newAddress, {
    int? editIndex,
  }) async {
    final isDefault = newAddress['is_default'] == 'true';
    final penerima = newAddress['name'] ?? '';
    final phone = newAddress['phone'] ?? '';
    final alamat = newAddress['address'] ?? '';
    final provinsiId = newAddress['province_id'] ?? '';
    final kotaId = newAddress['regency_id'] ?? '';
    final kecamatanId = newAddress['district_id'] ?? '';
    final desaId = newAddress['village_id'] ?? '';
    final kodePos = newAddress['postal_code'] ?? '';

    final existingId = editIndex != null ? _addressIdAt(editIndex) : null;

    if (editIndex != null && existingId == null) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'ID alamat tidak ditemukan.',
        backgroundColor: const Color(0xFFEF4444),
        icon: Icons.error_outline_rounded,
      );
      return;
    }

    final res = editIndex != null
        ? await Http().updateAlamatPengiriman(
            id: existingId!,
            penerima: penerima,
            phone: phone,
            alamat: alamat,
            provinsi: provinsiId,
            kota: kotaId,
            kecamatan: kecamatanId,
            desa: desaId,
            kodePos: kodePos,
            isDefault: isDefault,
            isActive: true,
          )
        : await Http().createAlamatPengiriman(
            penerima: penerima,
            phone: phone,
            alamat: alamat,
            provinsi: provinsiId,
            kota: kotaId,
            kecamatan: kecamatanId,
            desa: desaId,
            kodePos: kodePos,
            isDefault: isDefault,
            isActive: true,
          );

    if (!mounted) return;

    if (res['success'] == true) {
      await _loadAddresses();
      if (!mounted) return;
      showAppSnackBar(
        context,
        editIndex != null
            ? 'Alamat berhasil diperbarui!'
            : 'Alamat baru berhasil ditambahkan!',
        backgroundColor: const Color(0xFF22C55E),
        icon: Icons.check_circle_rounded,
      );
      return;
    }
    showAppSnackBar(
      context,
      _responseMessage(res),
      backgroundColor: const Color(0xFFEF4444),
      icon: Icons.error_outline_rounded,
    );
  }

  Future<void> _showAddressForm({
    Map<String, String>? existing,
    int? editIndex,
  }) async {
    if (editIndex != null) {
      final id = _addressIdAt(editIndex);
      if (id != null) {
        final detail = await Http().getAlamatPengirimanDetail(id);
        if (!mounted) return;
        if (detail['success'] == true && detail['data'] is Map) {
          existing = await AddressLocationResolver.instance.resolveAddress(
            _mapAddressFromApi(
              Map<String, dynamic>.from(detail['data'] as Map),
            ),
          );
        }
      }
    }

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return _AddressFormSheet(
          existing: existing,
          editIndex: editIndex,
          onSubmit: (newAddress) {
            Navigator.of(ctx).pop();
            _saveAddress(newAddress, editIndex: editIndex);
          },
        );
      },
    );
  }

  Future<void> _showAddressDetail(int index) async {
    if (index < 0 || index >= _addresses.length) return;

    var address = Map<String, String>.from(_addresses[index]);
    final id = _addressIdAt(index);
    if (id != null) {
      final detail = await Http().getAlamatPengirimanDetail(id);
      if (!mounted) return;
      if (detail['success'] == true && detail['data'] is Map) {
        address = await AddressLocationResolver.instance.resolveAddress(
          _mapAddressFromApi(
            Map<String, dynamic>.from(detail['data'] as Map),
          ),
        );
      }
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final isSelected = index == _selectedIndex;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      address['label'] ?? 'Detail Alamat',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Utama',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'Penerima', value: address['name'] ?? '-'),
              _DetailRow(label: 'Telepon', value: address['phone'] ?? '-'),
              _DetailRow(label: 'Alamat', value: _addressLine(address)),
              _DetailRow(label: 'Provinsi', value: address['province'] ?? '-'),
              _DetailRow(
                  label: 'Kota/Kabupaten', value: address['regency'] ?? '-'),
              _DetailRow(label: 'Kecamatan', value: address['district'] ?? '-'),
              _DetailRow(label: 'Kelurahan', value: address['village'] ?? '-'),
              _DetailRow(
                label: 'Kode Pos',
                value: address['postal_code']?.isNotEmpty == true
                    ? address['postal_code']!
                    : '-',
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showAddressForm(existing: address, editIndex: index);
                      },
                      child: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        setState(() => _selectedIndex = index);
                        _addressCache.setSelected(index);
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Pilih'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _deleteAddress(index);
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                  ),
                  child: const Text('Hapus alamat'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteAddress(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Hapus Alamat?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Alamat ini akan dihapus secara permanen.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final id = _addressIdAt(index);
              if (id != null) {
                final res = await Http().deleteAlamatPengiriman(id);
                if (res['success'] == true) {
                  await _loadAddresses();
                } else {
                  if (!mounted) return;
                  Navigator.of(ctx).pop();
                  showAppSnackBar(
                    context,
                    _responseMessage(res),
                    backgroundColor: const Color(0xFFEF4444),
                    icon: Icons.error_outline_rounded,
                  );
                  return;
                }
              }

              if (!mounted) return;
              Navigator.of(ctx).pop();
              showAppSnackBar(
                context,
                'Alamat berhasil dihapus.',
                backgroundColor: const Color(0xFFEF4444),
                icon: Icons.delete_rounded,
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Alamat Saya',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF111827),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddressForm(),
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Alamat',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: _loadingAddresses
            ? const Center(child: CircularProgressIndicator())
            : _addresses.isEmpty
                ? const _EmptyAddressView()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: _addresses.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final addr = _addresses[index];
                      final isSelected = index == _selectedIndex;

                      return GestureDetector(
                        onTap: () => _showAddressDetail(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? const Color(0xFF2563EB)
                                  : const Color(0xFFE5E7EB),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Label chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFFEFF6FF)
                                          : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      addr['label'] ?? '',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? const Color(0xFF2563EB)
                                            : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Utama',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                  ],
                                  const Spacer(),
                                  // Action buttons
                                  IconButton(
                                    onPressed: () => _showAddressForm(
                                        existing: addr, editIndex: index),
                                    icon: const Icon(Icons.edit_outlined,
                                        size: 18),
                                    color: const Color(0xFF64748B),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                  IconButton(
                                    onPressed: () => _deleteAddress(index),
                                    icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 18),
                                    color: const Color(0xFFEF4444),
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                addr['name'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                addr['phone'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.location_on_outlined,
                                      size: 16, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _addressLine(addr),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF475569),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
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
    );
  }
}

// ─── Reusable widgets ────────────────────────────────────────────────────────

class _AddressFormSheet extends StatefulWidget {
  const _AddressFormSheet({
    required this.onSubmit,
    this.existing,
    this.editIndex,
  });

  final Map<String, String>? existing;
  final int? editIndex;
  final ValueChanged<Map<String, String>> onSubmit;

  @override
  State<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends State<_AddressFormSheet> {
  static const int _locationPerPage = 100;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _postalCodeCtrl;

  String? _selectedProvince;
  String? _selectedRegency;
  String? _selectedDistrict;
  String? _selectedVillage;
  bool _isDefault = false;

  List<Map<String, String>> _provinces = [];
  List<Map<String, String>> _regencies = [];
  List<Map<String, String>> _districts = [];
  List<Map<String, String>> _villages = [];

  bool _loadingProvinces = false;
  bool _loadingRegencies = false;
  bool _loadingDistricts = false;
  bool _loadingVillages = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _labelCtrl = TextEditingController(text: existing?['label'] ?? '');
    _nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    _phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    _addressCtrl = TextEditingController(text: existing?['address'] ?? '');
    _postalCodeCtrl =
        TextEditingController(text: existing?['postal_code'] ?? '');
    _selectedProvince = existing?['province_id'];
    _selectedRegency = existing?['regency_id'];
    _selectedDistrict = existing?['district_id'];
    _selectedVillage = existing?['village_id'];
    _isDefault =
        existing?['is_default'] == 'true' || existing?['is_default'] == '1';
    _loadInitialLocations();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _postalCodeCtrl.dispose();
    super.dispose();
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

  String _nameFor(List<Map<String, String>> options, String? id) {
    if (id == null) return '';
    for (final option in options) {
      if (option['id'] == id) return option['name'] ?? '';
    }
    return '';
  }

  String? _validValue(List<Map<String, String>> options, String? value) {
    if (value == null) return null;
    return options.any((option) => option['id'] == value) ? value : null;
  }

  Future<void> _loadInitialLocations() async {
    await _loadProvinces();
    if (!mounted) return;
    if (_selectedProvince != null) await _loadRegencies(_selectedProvince!);
    if (!mounted) return;
    if (_selectedRegency != null) await _loadDistricts(_selectedRegency!);
    if (!mounted) return;
    if (_selectedDistrict != null) await _loadVillages(_selectedDistrict!);
  }

  Future<void> _loadProvinces() async {
    setState(() => _loadingProvinces = true);
    try {
      final res = await Http().getProvinces(perPage: _locationPerPage);
      final options = _locationOptionsFrom(res['data']);
      if (!mounted) return;
      setState(() {
        _provinces = options;
        _selectedProvince = _validValue(options, _selectedProvince);
      });
    } finally {
      if (mounted) setState(() => _loadingProvinces = false);
    }
  }

  Future<void> _loadRegencies(String provinceId) async {
    setState(() => _loadingRegencies = true);
    try {
      final res = await Http()
          .getRegencies(provinceId: provinceId, perPage: _locationPerPage);
      final options = _locationOptionsFrom(res['data']);
      if (!mounted) return;
      setState(() {
        _regencies = options;
        _selectedRegency = _validValue(options, _selectedRegency);
      });
    } finally {
      if (mounted) setState(() => _loadingRegencies = false);
    }
  }

  Future<void> _loadDistricts(String regencyId) async {
    setState(() => _loadingDistricts = true);
    try {
      final res = await Http()
          .getDistricts(regencyId: regencyId, perPage: _locationPerPage);
      final options = _locationOptionsFrom(res['data']);
      if (!mounted) return;
      setState(() {
        _districts = options;
        _selectedDistrict = _validValue(options, _selectedDistrict);
      });
    } finally {
      if (mounted) setState(() => _loadingDistricts = false);
    }
  }

  Future<void> _loadVillages(String districtId) async {
    setState(() => _loadingVillages = true);
    try {
      final res = await Http()
          .getVillages(districtId: districtId, perPage: _locationPerPage);
      final options = _locationOptionsFrom(res['data']);
      if (!mounted) return;
      setState(() {
        _villages = options;
        _selectedVillage = _validValue(options, _selectedVillage);
      });
    } finally {
      if (mounted) setState(() => _loadingVillages = false);
    }
  }

  void _onProvinceChanged(String? provinceId) {
    setState(() {
      _selectedProvince = provinceId;
      _selectedRegency = null;
      _selectedDistrict = null;
      _selectedVillage = null;
      _regencies = [];
      _districts = [];
      _villages = [];
    });
    if (provinceId != null) _loadRegencies(provinceId);
  }

  void _onRegencyChanged(String? regencyId) {
    setState(() {
      _selectedRegency = regencyId;
      _selectedDistrict = null;
      _selectedVillage = null;
      _districts = [];
      _villages = [];
    });
    if (regencyId != null) _loadDistricts(regencyId);
  }

  void _onDistrictChanged(String? districtId) {
    setState(() {
      _selectedDistrict = districtId;
      _selectedVillage = null;
      _villages = [];
    });
    if (districtId != null) _loadVillages(districtId);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final provinceName = _nameFor(_provinces, _selectedProvince);
    final regencyName = _nameFor(_regencies, _selectedRegency);
    final districtName = _nameFor(_districts, _selectedDistrict);
    final villageName = _nameFor(_villages, _selectedVillage);
    final locationSummary = [
      villageName,
      districtName,
      regencyName,
      provinceName,
    ].where((value) => value.isNotEmpty).join(', ');

    widget.onSubmit({
      'label': _labelCtrl.text.trim(),
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'address': _addressCtrl.text.trim(),
      'city': locationSummary,
      'province_id': _selectedProvince ?? '',
      'province': provinceName,
      'regency_id': _selectedRegency ?? '',
      'regency': regencyName,
      'district_id': _selectedDistrict ?? '',
      'district': districtName,
      'village_id': _selectedVillage ?? '',
      'village': villageName,
      'postal_code': _postalCodeCtrl.text.trim(),
      'is_default': _isDefault.toString(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.editIndex != null ? 'Edit Alamat' : 'Tambah Alamat',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),
              _BottomSheetField(
                controller: _labelCtrl,
                label: 'Label (contoh: Rumah, Kantor)',
                icon: Icons.label_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Label tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),
              _BottomSheetField(
                controller: _nameCtrl,
                label: 'Nama Penerima',
                icon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),
              _BottomSheetField(
                controller: _phoneCtrl,
                label: 'No. Telepon',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _BottomSheetDropdown(
                value: _validValue(_provinces, _selectedProvince),
                label: _loadingProvinces ? 'Memuat provinsi...' : 'Provinsi',
                icon: Icons.map_outlined,
                items: _provinces,
                onChanged: _loadingProvinces ? null : _onProvinceChanged,
                validator: (v) => v == null ? 'Pilih provinsi' : null,
              ),
              const SizedBox(height: 12),
              _BottomSheetDropdown(
                value: _validValue(_regencies, _selectedRegency),
                label: _loadingRegencies
                    ? 'Memuat kota/kabupaten...'
                    : 'Kota/Kabupaten',
                icon: Icons.location_city_outlined,
                items: _regencies,
                onChanged: _selectedProvince == null || _loadingRegencies
                    ? null
                    : _onRegencyChanged,
                validator: (v) => v == null ? 'Pilih kota/kabupaten' : null,
              ),
              const SizedBox(height: 12),
              _BottomSheetDropdown(
                value: _validValue(_districts, _selectedDistrict),
                label: _loadingDistricts ? 'Memuat kecamatan...' : 'Kecamatan',
                icon: Icons.account_balance_outlined,
                items: _districts,
                onChanged: _selectedRegency == null || _loadingDistricts
                    ? null
                    : _onDistrictChanged,
                validator: (v) => v == null ? 'Pilih kecamatan' : null,
              ),
              const SizedBox(height: 12),
              _BottomSheetDropdown(
                value: _validValue(_villages, _selectedVillage),
                label: _loadingVillages ? 'Memuat kelurahan...' : 'Kelurahan',
                icon: Icons.place_outlined,
                items: _villages,
                onChanged: _selectedDistrict == null || _loadingVillages
                    ? null
                    : (value) => setState(() => _selectedVillage = value),
                validator: (v) => v == null ? 'Pilih kelurahan' : null,
              ),
              const SizedBox(height: 12),
              _BottomSheetField(
                controller: _addressCtrl,
                label: 'Detail Alamat',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Detail alamat tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),
              _BottomSheetField(
                controller: _postalCodeCtrl,
                label: 'Kode Pos',
                icon: Icons.local_post_office_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                value: _isDefault,
                onChanged: (value) => setState(() => _isDefault = value),
                title: const Text(
                  'Jadikan alamat utama',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Dipakai sebagai alamat default'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    widget.editIndex != null
                        ? 'Simpan Perubahan'
                        : 'Tambah Alamat',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyAddressView extends StatelessWidget {
  const _EmptyAddressView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.location_on_outlined,
                size: 40, color: Color(0xFF2563EB)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Alamat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tambahkan alamat pengirimanmu\nagar belanja makin mudah.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _BottomSheetDropdown extends StatelessWidget {
  const _BottomSheetDropdown({
    required this.value,
    required this.label,
    required this.icon,
    required this.items,
    required this.onChanged,
    this.validator,
  });

  final String? value;
  final String label;
  final IconData icon;
  final List<Map<String, String>> items;
  final ValueChanged<String?>? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item['id'],
              child: Text(item['name'] ?? ''),
            ),
          )
          .toList(),
      onChanged: onChanged,
      validator: validator,
      isExpanded: true,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
      ),
    );
  }
}

class _BottomSheetField extends StatelessWidget {
  const _BottomSheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFF111827),
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
