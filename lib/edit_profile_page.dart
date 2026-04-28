import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_ui.dart';
import 'profile_model.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _profileModel = ProfileModel.instance;
  final _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _bioController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _profileModel.name);
    _emailController = TextEditingController(text: _profileModel.email);
    _phoneController = TextEditingController(text: _profileModel.phone);
    _bioController = TextEditingController(text: _profileModel.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      await _profileModel.saveProfile(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        bio: _bioController.text.trim(),
      );

      if (!mounted) return;

      showAppSnackBar(
        context,
        'Profil berhasil diperbarui!',
        backgroundColor: const Color(0xFF22C55E),
        icon: Icons.check_circle_rounded,
      );
      Navigator.of(context).pop(true); // Return true to indicate success
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Gagal menyimpan profil: $e',
        backgroundColor: const Color(0xFFEF4444),
        icon: Icons.error_rounded,
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      await _profileModel.saveProfileImage(pickedFile.path);

      if (!mounted) return;
      setState(() {});

      showAppSnackBar(
        context,
        'Foto profil berhasil diperbarui!',
        backgroundColor: const Color(0xFF22C55E),
        icon: Icons.check_circle_rounded,
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Gagal mengambil foto: $e',
        backgroundColor: const Color(0xFFEF4444),
        icon: Icons.error_rounded,
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pilih Sumber Foto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text(
                  'Kamera',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Ambil foto baru'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB)),
                ),
                title: const Text(
                  'Galeri',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('Pilih dari galeri'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF111827),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              // Avatar
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: _profileModel.hasProfileImage()
                            ? null
                            : const LinearGradient(
                                colors: [Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        border: Border.all(
                            color: const Color(0xFFF1F5F9), width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        image: _profileModel.hasProfileImage()
                            ? DecorationImage(
                                image: FileImage(File(_profileModel.profileImagePath!)),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profileModel.hasProfileImage()
                          ? null
                          : const Icon(
                              Icons.person_rounded,
                              size: 48,
                              color: Color(0xFF2563EB),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Form card
              _FormCard(
                children: [
                  _FormField(
                    label: 'Nama Lengkap',
                    controller: _nameController,
                    icon: Icons.person_outline_rounded,
                    hint: 'Masukkan nama lengkap',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                  ),
                  const _FieldDivider(),
                  _FormField(
                    label: 'Email',
                    controller: _emailController,
                    icon: Icons.email_outlined,
                    hint: 'Masukkan email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email tidak boleh kosong';
                      if (!v.contains('@')) return 'Email tidak valid';
                      return null;
                    },
                  ),
                  const _FieldDivider(),
                  _FormField(
                    label: 'No. Telepon',
                    controller: _phoneController,
                    icon: Icons.phone_outlined,
                    hint: 'Masukkan nomor telepon',
                    keyboardType: TextInputType.phone,
                  ),
                  const _FieldDivider(),
                  _FormField(
                    label: 'Bio',
                    controller: _bioController,
                    icon: Icons.notes_rounded,
                    hint: 'Ceritakan sedikit tentang dirimu',
                    maxLines: 3,
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSaving ? null : _handleSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
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

// ─── Reusable widgets ────────────────────────────────────────────────────────

class _FormCard extends StatelessWidget {
  const _FormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: children),
    );
  }
}

class _FormField extends StatelessWidget {
  const _FormField({
    required this.label,
    required this.controller,
    required this.icon,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
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
          hintText: hint,
          prefixIcon: Icon(icon, size: 20, color: const Color(0xFF64748B)),
          border: InputBorder.none,
          labelStyle: const TextStyle(
            fontSize: 13,
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
          hintStyle: const TextStyle(
            fontSize: 14,
            color: Color(0xFFCBD5E1),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

class _FieldDivider extends StatelessWidget {
  const _FieldDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9));
  }
}
