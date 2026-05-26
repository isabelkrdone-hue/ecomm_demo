import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_ui.dart';
import 'business_model.dart';
import 'notification_service.dart';

class SellerVerificationPage extends StatefulWidget {
  const SellerVerificationPage({super.key, this.businessIndex});

  final int? businessIndex;

  @override
  State<SellerVerificationPage> createState() => _SellerVerificationPageState();
}

class _SellerVerificationPageState extends State<SellerVerificationPage> {
  final BusinessModel _businessModel = BusinessModel.instance;
  final List<String> _selectedDocs = [];
  int? _selectedBusinessIndex;
  bool _isSubmitting = false;

  List<Map<String, dynamic>> get _businesses => _businessModel.getAllBusinesses();

  Map<String, dynamic>? get _selectedBusiness {
    if (_businesses.isEmpty) return null;
    final index = _selectedBusinessIndex ?? widget.businessIndex ?? 0;
    if (index < 0 || index >= _businesses.length) return _businesses.first;
    return _businesses[index];
  }

  String _asString(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  String _status(Map<String, dynamic>? business) {
    return _asString(business?['verificationStatus'], fallback: 'pending').toLowerCase();
  }

  String _statusLabel(String status) {
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

  Color _statusColor(String status) {
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

  List<String> _requiredDocsForBusiness(Map<String, dynamic>? business) {
    final type = _asString(business?['businessType'], fallback: 'Retail').toLowerCase();
    if (type.contains('grosir') || type.contains('distributor')) {
      return const [
        'Foto KTP Pemilik',
        'Foto NPWP / Dokumen Pajak',
        'Foto Izin Usaha / NIB',
        'Surat Distributor / Agen',
      ];
    }
    if (type.contains('manufacturer') || type.contains('manufaktur')) {
      return const [
        'Foto KTP Pemilik',
        'Foto NPWP / Dokumen Pajak',
        'Foto NIB',
        'Dokumen Izin Produksi',
      ];
    }
    return const [
      'Foto KTP Pemilik',
      'Foto NPWP / Dokumen Pajak',
      'Foto Izin Usaha / NIB',
    ];
  }

  Future<void> _pickDocument() async {
    if (_selectedDocs.length >= 5) {
      showFakeNotification(
        context,
        'Maksimal 5 dokumen',
        backgroundColor: const Color(0xFFEF4444),
        icon: Icons.warning_rounded,
      );
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2000,
      maxHeight: 2000,
      imageQuality: 85,
    );

    if (picked == null) return;

    setState(() {
      _selectedDocs.add(picked.path);
    });
  }

  void _removeDocument(int index) {
    setState(() {
      _selectedDocs.removeAt(index);
    });
  }

  Future<void> _submitVerification() async {
    final business = _selectedBusiness;
    if (business == null) {
      showFakeNotification(
        context,
        'Belum ada bisnis yang bisa diverifikasi',
        backgroundColor: const Color(0xFFEF4444),
        icon: Icons.warning_rounded,
      );
      return;
    }

    if (_selectedDocs.isEmpty) {
      showFakeNotification(
        context,
        'Upload minimal 1 dokumen',
        backgroundColor: const Color(0xFFEF4444),
        icon: Icons.warning_rounded,
      );
      return;
    }

    final businessIndex = _businesses.indexOf(business);
    if (businessIndex < 0) return;

    setState(() {
      _isSubmitting = true;
    });

    _businessModel.requestVerification(businessIndex, documents: _selectedDocs);
    _businessModel.markVerificationProcessing(businessIndex);

    showFakeNotification(
      context,
      'Dokumen terkirim, verifikasi diproses',
      backgroundColor: const Color(0xFFF59E0B),
      icon: Icons.hourglass_top_rounded,
    );

    await Future<void>.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    _businessModel.completeVerification(businessIndex);
    setState(() {
      _isSubmitting = false;
    });

    final businessType = _asString(business['businessType'], fallback: '');
    await NotificationService.instance.showBusinessVerifiedNotification(
      businessName: _asString(business['name']),
      businessType: businessType,
    );

    if (!mounted) return;

    showFakeNotification(
      context,
      'Seller berhasil diverifikasi',
      backgroundColor: const Color(0xFF16A34A),
      icon: Icons.verified_rounded,
    );
  }

  @override
  void initState() {
    super.initState();
    _selectedBusinessIndex = widget.businessIndex;
    _businessModel.addListener(_refresh);
  }

  @override
  void dispose() {
    _businessModel.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xFF6C7BFF);
    const textColor = Color(0xFF111827);

    final business = _selectedBusiness;
    final status = _status(business);
    final requiredDocs = _requiredDocsForBusiness(business);
    final verifiedAt = _asString(business?['verifiedAt'], fallback: '');

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Verifikasi Seller',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.verified_user_rounded, color: primary),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Langkah Verifikasi Seller',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Upload dokumen bisnis lalu tunggu simulasi verifikasi selesai.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.4),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatusChip(label: _statusLabel(status), color: _statusColor(status)),
                      if (verifiedAt.isNotEmpty)
                        const _StatusChip(label: 'Auto verified', color: Color(0xFF16A34A)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Toko',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  if (_businesses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: const Text(
                        'Belum ada toko. Tambahkan bisnis terlebih dahulu.',
                        style: TextStyle(color: Color(0xFF64748B)),
                      ),
                    )
                  else
                    DropdownButtonFormField<int>(
                      value: _selectedBusinessIndex ?? widget.businessIndex ?? 0,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      ),
                      items: List.generate(_businesses.length, (index) {
                        final businessItem = _businesses[index];
                        return DropdownMenuItem(
                          value: index,
                          child: Text(businessItem['name'] as String? ?? '-'),
                        );
                      }),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedBusinessIndex = value;
                          _selectedDocs.clear();
                        });
                      },
                    ),
                  if (business != null) ...[
                    const SizedBox(height: 14),
                    _BusinessSummaryCard(business: business),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dokumen yang Dibutuhkan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                  ),
                  const SizedBox(height: 12),
                  ...requiredDocs.map(
                    (doc) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 18, color: Color(0xFF16A34A)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              doc,
                              style: const TextStyle(fontSize: 14, color: Color(0xFF374151), height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upload Dokumen',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textColor),
                      ),
                      Text(
                        '${_selectedDocs.length}/5',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ..._selectedDocs.asMap().entries.map(
                        (entry) => _DocumentPreview(
                          path: entry.value,
                          onRemove: () => _removeDocument(entry.key),
                        ),
                      ),
                      if (_selectedDocs.length < 5) _AddDocButton(onTap: _pickDocument),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isSubmitting ? null : _submitVerification,
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.verified_rounded),
                      label: Text(_isSubmitting ? 'Memproses...' : 'Ajukan Verifikasi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
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
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BusinessSummaryCard extends StatelessWidget {
  const _BusinessSummaryCard({required this.business});

  final Map<String, dynamic> business;

  String _asString(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _asString(business['name']),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 4),
          Text(
            _asString(business['businessType'], fallback: 'Retail'),
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            '${_asString(business['city'])}, ${_asString(business['province'])}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
          ),
        ],
      ),
    );
  }
}

class _DocumentPreview extends StatelessWidget {
  const _DocumentPreview({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.file(
            File(path),
            width: 88,
            height: 88,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 88,
                height: 88,
                color: const Color(0xFFF1F5F9),
                child: const Icon(Icons.insert_drive_file_rounded, color: Color(0xFF94A3B8)),
              );
            },
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddDocButton extends StatelessWidget {
  const _AddDocButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 88,
        height: 88,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_rounded, size: 30, color: Color(0xFF6C7BFF)),
            SizedBox(height: 4),
            Text(
              'Upload',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ),
    );
  }
}