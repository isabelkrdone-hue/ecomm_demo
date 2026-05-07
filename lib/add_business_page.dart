import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'business_model.dart';
import 'indonesia_location_data.dart';

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

  // Business Type
  String? _businessType;
  final List<String> _businessTypes = ['Retail', 'Grosir', 'Manufacturer'];

  // Products with details
  List<Map<String, dynamic>> _products = [];
  
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
      _businessType = business['businessType'] as String?;
      
      // Load products with details
      if (business['products'] != null) {
        _products = List<Map<String, dynamic>>.from(business['products'] as List);
      }
      
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

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      _showAddProductDialog(pickedFile.path);
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                  'Pilih Sumber Gambar',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Color(0xFF6C7BFF)),
                  title: const Text('Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Color(0xFF6C7BFF)),
                  title: const Text('Galeri'),
                  onTap: () {
                    Navigator.pop(context);
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

  void _showAddProductDialog([String? imagePath]) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String? selectedUnit = 'Pcs';
    String? selectedCategory = 'Elektronik';
    String? currentImagePath = imagePath;

    final units = ['Pcs', 'Pack', 'Dus', 'Slop', 'Bal', 'Lusin', 'Kg', 'Liter'];
    final categories = ['Elektronik', 'Fashion', 'Makanan', 'Kecantikan', 'Olahraga', 'Rumah', 'Lainnya'];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'Tambah Produk',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview
                    if (currentImagePath != null)
                      Center(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(currentImagePath!),
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.red,
                                radius: 16,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setDialogState(() {
                                      currentImagePath = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Center(
                        child: InkWell(
                          onTap: () async {
                            Navigator.pop(dialogContext);
                            _showImageSourceDialog();
                          },
                          child: Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: Color(0xFF94A3B8)),
                                SizedBox(height: 8),
                                Text(
                                  'Tambah Foto',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // Product name
                    _label('Nama Produk'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: _decoration(hintText: 'Contoh: Sabun Mandi'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Price
                    _label('Harga'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: _decoration(hintText: 'Contoh: 15000'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Category
                    _label('Kategori'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: _decoration(hintText: 'Pilih Kategori'),
                      items: categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Unit
                    _label('Satuan'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: _decoration(hintText: 'Pilih Satuan'),
                      items: units
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedUnit = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final priceText = priceController.text.trim();
                    
                    if (name.isEmpty || priceText.isEmpty) {
                      _showSnack('Nama dan harga wajib diisi');
                      return;
                    }
                    
                    final price = double.tryParse(priceText);
                    if (price == null) {
                      _showSnack('Harga harus berupa angka');
                      return;
                    }
                    
                    setState(() {
                      _products.add({
                        'name': name,
                        'price': price,
                        'unit': selectedUnit,
                        'category': selectedCategory,
                        'imagePath': currentImagePath,
                      });
                    });
                    
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C7BFF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Tambah'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _editProduct(int index) {
    final product = _products[index];
    final nameController = TextEditingController(text: product['name'] as String);
    final priceController = TextEditingController(text: product['price'].toString());
    String? selectedUnit = product['unit'] as String?;
    String? selectedCategory = product['category'] as String? ?? 'Elektronik';
    String? currentImagePath = product['imagePath'] as String?;

    final units = ['Pcs', 'Pack', 'Dus', 'Slop', 'Bal', 'Lusin', 'Kg', 'Liter'];
    final categories = ['Elektronik', 'Fashion', 'Makanan', 'Kecantikan', 'Olahraga', 'Rumah', 'Lainnya'];

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Text(
                'Edit Produk',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image preview
                    if (currentImagePath != null)
                      Center(
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(currentImagePath!),
                                height: 150,
                                width: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: CircleAvatar(
                                backgroundColor: Colors.red,
                                radius: 16,
                                child: IconButton(
                                  icon: const Icon(Icons.close, size: 16, color: Colors.white),
                                  padding: EdgeInsets.zero,
                                  onPressed: () {
                                    setDialogState(() {
                                      currentImagePath = null;
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Center(
                        child: InkWell(
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _pickImage(ImageSource.gallery).then((_) {
                              // Re-open dialog after picking image
                              _editProduct(index);
                            });
                          },
                          child: Container(
                            height: 150,
                            width: 150,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: const Color(0xFFE2E8F0),
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 48, color: Color(0xFF94A3B8)),
                                SizedBox(height: 8),
                                Text(
                                  'Tambah Foto',
                                  style: TextStyle(color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    
                    // Product name
                    _label('Nama Produk'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: _decoration(hintText: 'Contoh: Sabun Mandi'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Price
                    _label('Harga'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: priceController,
                      keyboardType: TextInputType.number,
                      decoration: _decoration(hintText: 'Contoh: 15000'),
                    ),
                    const SizedBox(height: 16),
                    
                    // Category
                    _label('Kategori'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: _decoration(hintText: 'Pilih Kategori'),
                      items: categories
                          .map((category) => DropdownMenuItem(
                                value: category,
                                child: Text(category),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedCategory = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Unit
                    _label('Satuan'),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedUnit,
                      decoration: _decoration(hintText: 'Pilih Satuan'),
                      items: units
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setDialogState(() {
                          selectedUnit = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final priceText = priceController.text.trim();
                    
                    if (name.isEmpty || priceText.isEmpty) {
                      _showSnack('Nama dan harga wajib diisi');
                      return;
                    }
                    
                    final price = double.tryParse(priceText);
                    if (price == null) {
                      _showSnack('Harga harus berupa angka');
                      return;
                    }
                    
                    setState(() {
                      _products[index] = {
                        'name': name,
                        'price': price,
                        'unit': selectedUnit,
                        'category': selectedCategory,
                        'imagePath': currentImagePath,
                      };
                    });
                    
                    Navigator.pop(dialogContext);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C7BFF),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Simpan'),
                ),
              ],
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

    if (_businessType == null) {
      _showSnack('Pilih tipe bisnis');
      return;
    }

    if (_selectedProvince == null || _selectedCity == null || 
        _selectedDistrict == null || _selectedSubDistrict == null) {
      _showSnack('Pilih lokasi lengkap (Provinsi, Kota, Kecamatan, Kelurahan)');
      return;
    }

    if (_products.isEmpty) {
      _showSnack('Tambah minimal 1 produk');
      return;
    }

    setState(() => _isSaving = true);

    final business = <String, dynamic>{
      'name': name,
      'description': description,
      'address': address,
      'phone': phone,
      'businessType': _businessType,
      'province': _selectedProvince,
      'city': _selectedCity,
      'district': _selectedDistrict,
      'subDistrict': _selectedSubDistrict,
      'products': _products,
      'reviews': widget.existingBusiness?['reviews'] ?? [],
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

                  // Business Type
                  _label('Tipe Bisnis'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _businessType,
                    decoration: _decoration(hintText: 'Pilih Tipe Bisnis'),
                    items: _businessTypes
                        .map((type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _businessType = value;
                      });
                    },
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
                  const SizedBox(height: 8),
                  const Text(
                    'Tambahkan produk dengan foto, harga, dan satuan',
                    style: TextStyle(color: Color(0xFF64748B), height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  
                  // Add Product Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah Produk'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primary,
                        side: const BorderSide(color: primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Products List
                  if (_products.isNotEmpty) ...[
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _products.length,
                      itemBuilder: (context, index) {
                        final product = _products[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: const Color(0xFFF8FAFC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: product['imagePath'] != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.file(
                                      File(product['imagePath'] as String),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE2E8F0),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.image, color: Color(0xFF94A3B8)),
                                  ),
                            title: Text(
                              product['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              'Rp ${(product['price'] as num).toStringAsFixed(0)} / ${product['unit']}',
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: primary),
                                  onPressed: () => _editProduct(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _products.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ] else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF94A3B8)),
                          SizedBox(height: 8),
                          Text(
                            'Belum ada produk',
                            style: TextStyle(color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
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
