import 'package:flutter/material.dart';

import 'address_model.dart';
import 'app_ui.dart';
import 'repository/http.dart';

class MyAddressPage extends StatefulWidget {
  const MyAddressPage({super.key});

  @override
  State<MyAddressPage> createState() => _MyAddressPageState();
}

class _MyAddressPageState extends State<MyAddressPage> {
  final AddressModel _addressModel = AddressModel.instance;

  void _showAddressForm({Map<String, String>? existing, int? editIndex}) {
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
            if (editIndex != null) {
              _addressModel.updateAddress(editIndex, newAddress);
            } else {
              _addressModel.addAddress(newAddress);
            }
            setState(() {});
            Navigator.of(ctx).pop();
            showAppSnackBar(
              context,
              editIndex != null
                  ? 'Alamat berhasil diperbarui!'
                  : 'Alamat baru berhasil ditambahkan!',
              backgroundColor: const Color(0xFF22C55E),
              icon: Icons.check_circle_rounded,
            );
          },
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
            onPressed: () {
              _addressModel.removeAddress(index);
              setState(() {});
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
        child: _addressModel.isEmpty
            ? const _EmptyAddressView()
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                itemCount: _addressModel.addresses.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final addr = _addressModel.addresses[index];
                  final isSelected = index == _addressModel.selectedIndex;

                  return GestureDetector(
                    onTap: () {
                      _addressModel.setSelected(index);
                      setState(() {});
                    },
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
                              const Spacer(),
                              // Action buttons
                              IconButton(
                                onPressed: () => _showAddressForm(
                                    existing: addr, editIndex: index),
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                color: const Color(0xFF64748B),
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              IconButton(
                                onPressed: () => _deleteAddress(index),
                                icon: const Icon(Icons.delete_outline_rounded,
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
                                  '${addr['address']}, ${addr['city']}',
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

  String? _selectedProvince;
  String? _selectedRegency;
  String? _selectedDistrict;
  String? _selectedVillage;

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
    _selectedProvince = existing?['province_id'];
    _selectedRegency = existing?['regency_id'];
    _selectedDistrict = existing?['district_id'];
    _selectedVillage = existing?['village_id'];
    _loadInitialLocations();
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
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
