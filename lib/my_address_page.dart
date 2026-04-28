import 'package:flutter/material.dart';

import 'address_model.dart';
import 'app_ui.dart';

class MyAddressPage extends StatefulWidget {
  const MyAddressPage({super.key});

  @override
  State<MyAddressPage> createState() => _MyAddressPageState();
}

class _MyAddressPageState extends State<MyAddressPage> {
  final AddressModel _addressModel = AddressModel.instance;

  void _showAddressForm({Map<String, String>? existing, int? editIndex}) {
    final labelCtrl = TextEditingController(text: existing?['label'] ?? '');
    final nameCtrl = TextEditingController(text: existing?['name'] ?? '');
    final phoneCtrl = TextEditingController(text: existing?['phone'] ?? '');
    final addressCtrl = TextEditingController(text: existing?['address'] ?? '');
    final cityCtrl = TextEditingController(text: existing?['city'] ?? '');
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
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
                    editIndex != null ? 'Edit Alamat' : 'Tambah Alamat',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _BottomSheetField(
                    controller: labelCtrl,
                    label: 'Label (contoh: Rumah, Kantor)',
                    icon: Icons.label_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Label tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _BottomSheetField(
                    controller: nameCtrl,
                    label: 'Nama Penerima',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Nama tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _BottomSheetField(
                    controller: phoneCtrl,
                    label: 'No. Telepon',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  _BottomSheetField(
                    controller: addressCtrl,
                    label: 'Alamat Lengkap',
                    icon: Icons.location_on_outlined,
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Alamat tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  _BottomSheetField(
                    controller: cityCtrl,
                    label: 'Kota & Kode Pos',
                    icon: Icons.location_city_outlined,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        final newAddress = {
                          'label': labelCtrl.text.trim(),
                          'name': nameCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'city': cityCtrl.text.trim(),
                        };
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
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        editIndex != null ? 'Simpan Perubahan' : 'Tambah Alamat',
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
                padding:
                    const EdgeInsets.fromLTRB(16, 12, 16, 100),
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
                                icon: const Icon(Icons.edit_outlined,
                                    size: 18),
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
