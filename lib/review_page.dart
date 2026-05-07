import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'app_ui.dart';
import 'cart_model.dart';
import 'business_model.dart';

class ReviewPage extends StatefulWidget {
  const ReviewPage({
    super.key,
    required this.orderId,
    required this.products,
  });

  final String orderId;
  final List<Map<String, dynamic>> products;

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController _reviewController = TextEditingController();
  final List<String> _selectedImages = [];
  int _rating = 0;
  bool _isSubmitting = false;

  String _asString(dynamic value, {String fallback = '-'}) {
    if (value == null) return fallback;
    if (value is String) return value;
    return value.toString();
  }

  int _asPrice(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();

    final text = value?.toString() ?? '';
    final digitsOnly = text.replaceAll(RegExp(r'[^0-9]'), '');
    return int.tryParse(digitsOnly) ?? 0;
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) {
      showFakeNotification(
        context,
        'Maksimal 5 foto',
        backgroundColor: const Color(0xFFEF4444),
        icon: Icons.warning_rounded,
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImages.add(pickedFile.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      showFakeNotification(
        context,
        'Gagal memilih gambar',
        backgroundColor: const Color(0xFFEF4444),
        icon: Icons.error_rounded,
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      showFakeNotification(
        context,
        'Pilih rating terlebih dahulu',
        backgroundColor: const Color(0xFFEF4444),
        icon: Icons.warning_rounded,
      );
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      showFakeNotification(
        context,
        'Tulis review terlebih dahulu',
        backgroundColor: const Color(0xFFEF4444),
        icon: Icons.warning_rounded,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    // Create review data
    final review = {
      'orderId': widget.orderId,
      'rating': _rating,
      'comment': _reviewController.text.trim(),
      'images': List<String>.from(_selectedImages),
      'date': DateTime.now(),
      'products': widget.products,
    };

    final targetBusinessNames = widget.products
        .map((product) => product['businessName'])
        .whereType<String>()
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet();

    BusinessModel.instance.addReviewToBusinesses(
      businessNames: targetBusinessNames,
      review: review,
    );

    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    showFakeNotification(
      context,
      'Review berhasil dikirim',
      backgroundColor: const Color(0xFF059669),
      icon: Icons.check_circle_rounded,
    );

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Beri Review',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF111827),
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Rating Section
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Berikan Rating',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 2,
                    runSpacing: 2,
                    children: List.generate(5, (index) {
                      return IconButton(
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                          });
                        },
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                          size: 38,
                          color: index < _rating
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFFD1D5DB),
                        ),
                      );
                    }),
                  ),
                  if (_rating > 0)
                    Center(
                      child: Text(
                        _getRatingText(_rating),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Review Text Section
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tulis Review',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'Ceritakan pengalaman Anda dengan produk ini...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFF6C7BFF), width: 2),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Photos Section
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tambah Foto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      Text(
                        '${_selectedImages.length}/5',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ..._selectedImages.asMap().entries.map((entry) {
                        final index = entry.key;
                        final imagePath = entry.value;
                        return _ImagePreview(
                          imagePath: imagePath,
                          onRemove: () => _removeImage(index),
                        );
                      }),
                      if (_selectedImages.length < 5)
                        _AddImageButton(onTap: _pickImage),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Products Review
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Produk yang Direview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...widget.products.map((product) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              _asString(product['image'], fallback: _asString(product['imagePath'], fallback: '')),
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  width: 60,
                                  height: 60,
                                  color: const Color(0xFFF1F5F9),
                                  child: const Icon(
                                    Icons.image_rounded,
                                    color: Color(0xFF94A3B8),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _asString(product['name']),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  CartModel.formatPrice(_asPrice(product['price'] ?? product['priceValue'])),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF6C7BFF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Submit Button
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitReview,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C7BFF),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFE5E7EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Kirim Review',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Sangat Buruk';
      case 2:
        return 'Buruk';
      case 3:
        return 'Cukup';
      case 4:
        return 'Bagus';
      case 5:
        return 'Sangat Bagus';
      default:
        return '';
    }
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({
    required this.imagePath,
    required this.onRemove,
  });

  final String imagePath;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(imagePath),
            width: 80,
            height: 80,
            fit: BoxFit.cover,
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
              child: const Icon(
                Icons.close_rounded,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddImageButton extends StatelessWidget {
  const _AddImageButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE5E7EB),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_rounded,
              size: 32,
              color: Color(0xFF6C7BFF),
            ),
            SizedBox(height: 4),
            Text(
              'Tambah',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
