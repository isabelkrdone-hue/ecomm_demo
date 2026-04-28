import 'package:flutter/material.dart';

import 'business_model.dart';
import 'indonesia_location_data.dart';
import 'product_data.dart';

class AddBusinessPage extends StatefulWidget {
  const AddBusinessPage({super.key, this.existingBusiness, this.businessIndex});

  final Map<String, dynamic>? existingBusiness;
  final int? businessIndex;

  @override
  State<AddBusinessPage> createState() => _AddBusinessPageState();
}

class _AddBusinessPageState extends State<AddBusinessPage> {
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  // Location variables
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedDistrict;
  String? _selectedSubDistrict;

  List<String> _provinces = [];
  List<String> _cities = [];
  List<String> _districts = [];
  List<String> _subDistricts = [];

  // Product selection
  List<String> _selectedProducts = [];
  
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _provinces = IndonesiaLocationData.getProvinces();
    
    final business = widget.existingBusiness;
    if (business != null) {
      _businessNameController.text = business['name'] as String? ?? '';
      _descriptionController.text = business['description'] as String? ?? '';
      _addressController.text = business['address'] as String? ?? '';
      _phoneController.text = business['phone'] as String? ?? '';
      _selectedProducts = List<String>.from(business['products'] as List? ?? []);
      
      // Set location data
      _selectedProvince = business['province'] as String?;
      if (_selectedProvince != null) {
        _cities = IndonesiaLocationData.getCities(_selectedProvince!);
      }
      
      _selectedCity = business['city'] as String?;
      if (_selectedProvince != null && _selectedCity != null) {
        _districts = IndonesiaLocationData.getDistricts(_selectedProvince!, _selectedCity!);
      }
      
      _selectedDistrict = business['district'] as String?;
      if (_selectedProvince != null && _selectedCity != null && _selectedDistrict != null) {
        _subDistricts = IndonesiaLocationData.getSubDistricts(
          _selectedProvince!,
          _selectedCity!,
          _selectedDistrict!,
        );
      }
      
      _selectedSubDistrict = business['subDistrict'] as String?;
    }
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onProvinceChanged(String? province) {
    if (province == null) return;
    setState(() {
      _selectedProvince = province;
      _selectedCity = null;
      _selectedDistrict = null;
      _selectedSubDistrict = null;
      _cities = IndonesiaLocationData.getCities(province);
      _districts = [];
      _subDistricts = [];
    });
  }

  void _onCityChanged(String? city) {
    if (city == null || _selectedProvince == null) return;
    setState(() {
      _selectedCity = city;
      _selectedDistrict = null;
      _selectedSubDistrict = null;
      _districts = IndonesiaLocationData.getDistricts(_selectedProvince!, city);
      _subDistricts = [];
    });
  }

  void _onDistrictChanged(String? district) {
    if (district == null || _selectedProvince == null || _selectedCity == null) return;
    setState(() {
      _selectedDistrict = district;
      _selectedSubDistrict = null;
      _subDistricts = IndonesiaLocationData.getSubDistricts(
        _selectedProvince!,
        _selectedCity!,
        district,
      );
    });
  }

  void _onSubDistrictChanged(String? subDistrict) {
    if (subDistrict == null) return;
    setState(() {
      _selectedSubDistrict = subDistrict;
    });
  }

  void _showProductSelector() {
    final tempSelected = List<String>.from(_selectedProducts);

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Pilih Produk',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: allProducts.length,
                          itemBuilder: (context, index) {
                            final product = allProducts[index];
                            final productName = product['name'] as String;
                            final isSelected = tempSelected.contains(productName);

                            return CheckboxListTile(
                              title: Text(productName),
                              subtitle: Text(product['category'] as String? ?? ''),
                              value: isSelected,
                              onChanged: (value) {
                                setModalState(() {
                                  if (value == true) {
                                    tempSelected.add(productName);
                                  } else {
                                    tempSelected.remove(productName);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedProducts = tempSelected;
                            });
                            Navigator.of(sheetContext).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C7BFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            'Pilih (${tempSelected.length})',
                            style: const TextStyle(fontWeight: FontWeight.w700),
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

  Future<void> _saveBusiness() async {
    final name = _businessNameController.text.trim();
    final description = _descriptionController.text.trim();
    final address = _addressController.text.trim();
    final phone = _phoneController.text.trim();

    if (name.isEmpty || description.isEmpty || address.isEmpty || phone.isEmpty) {
      _showSnack('Semua field wajib diisi');
      return;
    }

    if (_selectedProvince == null || _selectedCity == null || 
        _selectedDistrict == null || _selectedSubDistrict == null) {
      _showSnack('Pilih lokasi lengkap (Provinsi, Kota, Kecamatan, Kelurahan)');
      return;
    }

    if (_selectedProducts.isEmpty) {
      _showSnack('Pilih minimal 1 produk');
      return;
    }

    setState(() => _isSaving = true);

    final business = <String, dynamic>{
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'province': _selectedProvince,
      'city': _selectedCity,
      'district': _selectedDistrict,
      'subDistrict': _selectedSubDistrict,
      'products': _selectedProducts,
      'createdAt': DateTime.now().toIso8601String(),
    };

    if (widget.existingBusiness != null && widget.businessIndex != null) {
      BusinessModel.instance.updateBusiness(widget.businessIndex!, business);
    } else {
      BusinessModel.instance.addBusiness(business);
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
        title: Text(widget.existingBusiness == null ? 'Tambah Bisnis' : 'Edit Bisnis'),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Informasi Bisnis',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Lengkapi informasi bisnis Anda',
                    style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 24),
                  
                  // Business Name
                  _label('Nama Bisnis'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _businessNameController,
                    hintText: 'Contoh: Toko Elektronik Jaya',
                  ),
                  const SizedBox(height: 16),

                  // Description
                  _label('Deskripsi'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _descriptionController,
                    hintText: 'Deskripsi bisnis Anda...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  _label('Nomor Telepon'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _phoneController,
                    hintText: '08123456789',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Address
                  _label('Alamat Lengkap'),
                  const SizedBox(height: 8),
                  _textField(
                    controller: _addressController,
                    hintText: 'Jalan, Nomor, RT/RW',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Location Section
                  const Text(
                    'Lokasi Gudang',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 16),

                  // Province
                  _label('Provinsi'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    decoration: _decoration(hintText: 'Pilih Provinsi'),
                    items: _provinces
                        .map((province) => DropdownMenuItem(
                              value: province,
                              child: Text(province),
                            ))
                        .toList(),
                    onChanged: _onProvinceChanged,
                  ),
                  const SizedBox(height: 16),

                  // City
                  _label('Kota/Kabupaten'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCity,
                    decoration: _decoration(hintText: 'Pilih Kota/Kabupaten'),
                    items: _cities
                        .map((city) => DropdownMenuItem(
                              value: city,
                              child: Text(city),
                            ))
                        .toList(),
                    onChanged: _cities.isEmpty ? null : _onCityChanged,
                  ),
                  const SizedBox(height: 16),

                  // District (Kecamatan)
                  _label('Kecamatan'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    decoration: _decoration(hintText: 'Pilih Kecamatan'),
                    items: _districts
                        .map((district) => DropdownMenuItem(
                              value: district,
                              child: Text(district),
                            ))
                        .toList(),
                    onChanged: _districts.isEmpty ? null : _onDistrictChanged,
                  ),
                  const SizedBox(height: 16),

                  // Sub-district (Kelurahan)
                  _label('Kelurahan'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSubDistrict,
                    decoration: _decoration(hintText: 'Pilih Kelurahan'),
                    items: _subDistricts
                        .map((subDistrict) => DropdownMenuItem(
                              value: subDistrict,
                              child: Text(subDistrict),
                            ))
                        .toList(),
                    onChanged: _subDistricts.isEmpty ? null : _onSubDistrictChanged,
                  ),
                  const SizedBox(height: 24),

                  // Products Section
                  const Text(
                    'Produk Bisnis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 16),
                  _label('Produk yang Dijual'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _showProductSelector,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedProducts.isEmpty
                                  ? 'Pilih produk yang dijual'
                                  : '${_selectedProducts.length} produk dipilih',
                              style: TextStyle(
                                color: _selectedProducts.isEmpty
                                    ? const Color(0xFF94A3B8)
                                    : textColor,
                                fontWeight: _selectedProducts.isEmpty
                                    ? FontWeight.w400
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedProducts.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedProducts.map((product) {
                        return Chip(
                          label: Text(product),
                          backgroundColor: const Color(0xFFEEF2FF),
                          labelStyle: const TextStyle(
                            color: Color(0xFF4338CA),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () {
                            setState(() {
                              _selectedProducts.remove(product);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveBusiness,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              widget.existingBusiness == null ? 'Tambah Bisnis' : 'Simpan Perubahan',
                              style: const TextStyle(fontWeight: FontWeight.w700),
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
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: _decoration(hintText: hintText),
    );
  }

  InputDecoration _decoration({String hintText = ''}) {
    return InputDecoration(
      hintText: hintText,
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
