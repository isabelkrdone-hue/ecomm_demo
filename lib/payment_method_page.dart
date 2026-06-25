import 'package:flutter/material.dart';

import 'app_ui.dart';
import 'repository/http.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  final Http _http = Http();
  final List<_PaymentMethodEntry> _methods = [];
  bool _isLoading = true;
  String? _loadError;
  bool _accessDenied = false;
  String? _selectedMethodKey;
  final Set<PaymentSection> _expandedSections = <PaymentSection>{};

  @override
  void initState() {
    super.initState();
    _loadMethods();
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
      if (value != null &&
          value is! Map &&
          value is! List &&
          value.toString().trim().isNotEmpty) {
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
      if (value is num) return value != 0;
      final normalized = value.toString().trim().toLowerCase();
      if (normalized.isEmpty) continue;
      return normalized == '1' || normalized == 'true' || normalized == 'yes';
    }
    return false;
  }

  Map<String, dynamic>? _detailMapFromResponse(dynamic data) {
    if (data is Map) {
      for (final key in const [
        'data',
        'item',
        'result',
        'metode_pembayaran',
        'payment_method',
      ]) {
        final nested = data[key];
        if (nested is Map) {
          return Map<String, dynamic>.from(nested);
        }
        if (nested is List && nested.isNotEmpty && nested.first is Map) {
          return Map<String, dynamic>.from(nested.first as Map);
        }
      }
      return Map<String, dynamic>.from(data);
    }

    if (data is List && data.isNotEmpty && data.first is Map) {
      return Map<String, dynamic>.from(data.first as Map);
    }

    return null;
  }

  PaymentType _paymentTypeFromItem(Map item) {
    final rawType = _firstString(item, const [
      'type',
      'jenis',
      'kategori',
      'category',
      'payment_type',
      'tipe',
    ]);
    final label = _firstString(item, const [
      'nama',
      'name',
      'label',
      'title',
      'payment_method_name',
      'metode_pembayaran',
      'metode',
    ]);

    final normalized = [
      rawType,
      label,
      _firstString(item, const ['bank', 'provider']),
    ].whereType<String>().join(' ').toLowerCase();

    if (normalized.contains('bank') || normalized.contains('transfer')) {
      return PaymentType.bank;
    }
    if (normalized.contains('card') ||
        normalized.contains('kartu') ||
        normalized.contains('credit') ||
        normalized.contains('debit')) {
      return PaymentType.card;
    }
    if (normalized.contains('ewallet') ||
        normalized.contains('e-wallet') ||
        normalized.contains('wallet') ||
        normalized.contains('gopay') ||
        normalized.contains('ovo') ||
        normalized.contains('dana') ||
        normalized.contains('shopeepay') ||
        normalized.contains('qris')) {
      return PaymentType.ewallet;
    }

    return PaymentType.other;
  }

  PaymentSection _paymentSectionFromItem(Map item) {
    final rawType = _firstString(item, const [
      'type',
      'jenis',
      'kategori',
      'category',
      'payment_type',
      'tipe',
    ]);
    final label = _firstString(item, const [
          'nama',
          'name',
          'label',
          'title',
          'payment_method_name',
          'metode_pembayaran',
          'metode',
        ]) ??
        '';
    final bank = _firstString(item, const ['bank', 'provider']) ?? '';
    final normalized = [
      rawType,
      label,
      bank,
    ].whereType<String>().join(' ').toLowerCase();

    if (normalized.contains('qris')) {
      return PaymentSection.qris;
    }
    if (normalized.contains('card') ||
        normalized.contains('kartu') ||
        normalized.contains('credit') ||
        normalized.contains('debit')) {
      return PaymentSection.card;
    }
    if (normalized.contains('bank') ||
        normalized.contains('transfer') ||
        normalized.contains('virtual account') ||
        normalized.contains('va ') ||
        normalized.contains('va-') ||
        normalized.contains('va_') ||
        normalized.contains('va_bank') ||
        normalized.contains('va bank')) {
      return PaymentSection.vaBank;
    }
    if (normalized.contains('ewallet') ||
        normalized.contains('e-wallet') ||
        normalized.contains('wallet') ||
        normalized.contains('gopay') ||
        normalized.contains('ovo') ||
        normalized.contains('dana') ||
        normalized.contains('shopeepay')) {
      return PaymentSection.ewallet;
    }

    return PaymentSection.other;
  }

  IconData _paymentIcon(PaymentType type, Map item) {
    final label = _firstString(item, const [
          'nama',
          'name',
          'label',
          'title',
          'payment_method_name',
          'metode_pembayaran',
          'metode',
        ]) ??
        '';
    final normalized = label.toLowerCase();

    if (type == PaymentType.bank) {
      return Icons.account_balance_rounded;
    }
    if (type == PaymentType.card) {
      return Icons.credit_card_rounded;
    }
    if (normalized.contains('qris')) {
      return Icons.qr_code_2_rounded;
    }
    if (normalized.contains('gopay') ||
        normalized.contains('ovo') ||
        normalized.contains('dana') ||
        normalized.contains('shopeepay') ||
        normalized.contains('qris')) {
      return Icons.account_balance_wallet_rounded;
    }
    return type == PaymentType.other
        ? Icons.payments_rounded
        : Icons.account_balance_wallet_rounded;
  }

  Color _paymentColor(PaymentType type, Map item) {
    final label = _firstString(item, const [
          'nama',
          'name',
          'label',
          'title',
          'payment_method_name',
          'metode_pembayaran',
          'metode',
        ]) ??
        '';
    final normalized = label.toLowerCase();

    if (type == PaymentType.bank) {
      return const Color(0xFF2563EB);
    }
    if (type == PaymentType.card) {
      return const Color(0xFF7C3AED);
    }
    if (normalized.contains('qris')) {
      return const Color(0xFF0EA5E9);
    }
    if (normalized.contains('gopay') || normalized.contains('qris')) {
      return const Color(0xFF00AED6);
    }
    if (normalized.contains('ovo')) {
      return const Color(0xFF4C3494);
    }
    if (normalized.contains('dana')) {
      return const Color(0xFF0EA5E9);
    }
    if (normalized.contains('shopeepay')) {
      return const Color(0xFFF97316);
    }
    return type == PaymentType.other
        ? const Color(0xFF64748B)
        : const Color(0xFF10B981);
  }

  String _paymentDetailText(Map item) {
    final detail = _firstString(item, const [
      'detail',
      'description',
      'keterangan',
      'catatan',
    ]);
    final number = _firstString(item, const [
      'nomor',
      'no_rekening',
      'rekening',
      'account_number',
      'account_no',
      'number',
      'phone',
      'phone_number',
      'telepon',
    ]);
    final owner = _firstString(item, const [
      'atas_nama',
      'account_name',
      'pemilik',
      'owner',
      'nama_pemilik',
    ]);
    final pieces = <String>[
      if (detail != null) detail,
      if (number != null) number,
      if (owner != null) owner,
    ];

    if (pieces.isEmpty) {
      return 'Detail pembayaran belum tersedia';
    }
    return pieces.join(' • ');
  }

  String _paymentLabel(Map item, PaymentType type) {
    final label = _firstString(item, const [
      'nama',
      'name',
      'label',
      'title',
      'payment_method_name',
      'metode_pembayaran',
      'metode',
    ]);
    if (label != null) return label;

    final bank = _firstString(item, const ['bank', 'provider']);
    if (bank != null) return bank;

    switch (type) {
      case PaymentType.ewallet:
        return 'E-Wallet';
      case PaymentType.bank:
        return 'Transfer Bank';
      case PaymentType.card:
        return 'Kartu';
      case PaymentType.other:
        return 'Metode Pembayaran';
    }
  }

  PaymentType _paymentTypeFromLabel(String value) {
    final normalized = value.toLowerCase();
    if (normalized.contains('bank') || normalized.contains('transfer')) {
      return PaymentType.bank;
    }
    if (normalized.contains('card') ||
        normalized.contains('kartu') ||
        normalized.contains('credit') ||
        normalized.contains('debit')) {
      return PaymentType.card;
    }
    if (normalized.contains('ewallet') ||
        normalized.contains('e-wallet') ||
        normalized.contains('wallet') ||
        normalized.contains('gopay') ||
        normalized.contains('ovo') ||
        normalized.contains('dana') ||
        normalized.contains('shopeepay') ||
        normalized.contains('qris')) {
      return PaymentType.ewallet;
    }
    return PaymentType.other;
  }

  _PaymentMethodEntry _mapPaymentMethod(Map item) {
    final type = _paymentTypeFromItem(item);
    final label = _paymentLabel(item, type);
    final fallbackType =
        type == PaymentType.other ? _paymentTypeFromLabel(label) : type;
    final apiId = _firstString(item, const [
      'id',
      'uuid',
      'payment_method_id',
      'metode_pembayaran_id',
      'value',
      'code',
    ]);

    return _PaymentMethodEntry(
      apiId: apiId,
      type: fallbackType,
      section: _paymentSectionFromItem(item),
      label: label,
      detail: _paymentDetailText(item),
      icon: _paymentIcon(fallbackType, item),
      color: _paymentColor(fallbackType, item),
      raw: Map<String, dynamic>.from(item),
    );
  }

  List<_PaymentMethodEntry> _methodsFromResponse(dynamic data) {
    final methods = <_PaymentMethodEntry>[];
    for (final item in _extractList(data)) {
      if (item is Map) {
        methods.add(_mapPaymentMethod(item));
      }
    }
    return methods;
  }

  String _responseMessage(dynamic res) {
    final message = res is Map ? res['message'] : null;
    if (message == null) return 'Terjadi kesalahan.';
    if (message is String && message.trim().isNotEmpty) return message;
    return message.toString();
  }

  void _syncSelectedMethod() {
    if (_methods.isEmpty) {
      _selectedMethodKey = null;
      return;
    }

    final currentKey = _selectedMethodKey;
    if (currentKey != null &&
        _methods.any((method) => method.key == currentKey)) {
      return;
    }

    _selectedMethodKey = _methods.first.key;
  }

  Future<void> _loadMethods({bool showLoader = true}) async {
    if (mounted && showLoader) {
      setState(() {
        _isLoading = true;
        _loadError = null;
        _accessDenied = false;
      });
    }

    try {
      final res = await _http.getMetodePembayaran(
        isActive: true,
        perPage: 100,
      );
      if (!mounted) return;

      if (res['success'] == true) {
        final methods = _methodsFromResponse(res['data']);
        setState(() {
          _methods
            ..clear()
            ..addAll(methods);
          _loadError = null;
          _accessDenied = false;
          _syncSelectedMethod();
        });
      } else {
        final message = _responseMessage(res);
        final normalizedMessage = message.toLowerCase();
        final forbidden = normalizedMessage.contains('forbidden') ||
            normalizedMessage.contains('403');

        if (forbidden) {
          setState(() {
            _methods.clear();
            _loadError = null;
            _accessDenied = true;
            _selectedMethodKey = null;
          });
          return;
        }

        if (_methods.isEmpty) {
          setState(() {
            _loadError = message;
          });
        }
        showAppSnackBar(
          context,
          message,
          backgroundColor: const Color(0xFFEF4444),
          icon: Icons.error_outline_rounded,
        );
      }
    } catch (e) {
      if (!mounted) return;
      final message = 'Gagal memuat metode pembayaran: $e';
      if (_methods.isEmpty) {
        setState(() {
          _loadError = message;
        });
      }
      showAppSnackBar(
        context,
        message,
        backgroundColor: const Color(0xFFEF4444),
        icon: Icons.error_outline_rounded,
      );
    } finally {
      if (mounted && showLoader) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showMethodDetail(_PaymentMethodEntry method) async {
    Map<String, dynamic> detailData = method.raw;
    String? detailError;

    if (method.apiId != null && method.apiId!.trim().isNotEmpty) {
      final res = await _http.getMetodePembayaranDetail(method.apiId!);
      if (!mounted) return;

      if (res['success'] == true) {
        detailData = _detailMapFromResponse(res['data']) ?? method.raw;
      } else {
        detailError = _responseMessage(res);
      }
    }

    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        final label = _firstString(detailData, const [
              'nama',
              'name',
              'label',
              'title',
              'payment_method_name',
              'metode_pembayaran',
              'metode',
            ]) ??
            method.label;
        final typeText = _typeLabel(method.type);
        final detailText = _paymentDetailText(detailData);
        final bank = _firstString(detailData, const [
          'bank',
          'provider',
          'nama_bank',
          'bank_name',
        ]);
        final number = _firstString(detailData, const [
          'nomor',
          'no_rekening',
          'rekening',
          'account_number',
          'account_no',
          'number',
          'phone',
          'phone_number',
          'telepon',
        ]);
        final owner = _firstString(detailData, const [
          'atas_nama',
          'account_name',
          'pemilik',
          'owner',
          'nama_pemilik',
        ]);
        final statusText = _paymentStatusText(detailData);
        final note = _firstString(detailData, const [
          'catatan',
          'keterangan',
          'note',
          'description',
        ]);

        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: 20 + MediaQuery.of(ctx).viewInsets.bottom,
            ),
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
                  Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: method.color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Icon(method.icon, color: method.color, size: 26),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              typeText,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (detailError != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Text(
                        detailError,
                        style: const TextStyle(
                          color: Color(0xFFB91C1C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _detailSectionTitle('Informasi Utama'),
                  const SizedBox(height: 12),
                  _detailInfoCard(
                    children: [
                      _detailRow('ID', method.apiId ?? '-'),
                      _detailRow('Detail', detailText),
                      _detailRow('Bank / Provider', bank ?? '-'),
                      _detailRow('Nomor', number ?? '-'),
                      _detailRow('Atas Nama', owner ?? '-'),
                      _detailRow('Status', statusText),
                      if (note != null) _detailRow('Catatan', note),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Tutup',
                        style: TextStyle(fontWeight: FontWeight.w700),
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

  String _typeLabel(PaymentType type) {
    switch (type) {
      case PaymentType.ewallet:
        return 'E-Wallet';
      case PaymentType.bank:
        return 'Transfer Bank';
      case PaymentType.card:
        return 'Kartu';
      case PaymentType.other:
        return 'Lainnya';
    }
  }

  String _paymentStatusText(Map item) {
    final status = _firstString(item, const ['status', 'state']);
    if (status != null && status.trim().isNotEmpty) {
      return status;
    }

    final isActive = _firstBool(item, const ['is_active', 'active']);
    return isActive ? 'Aktif' : 'Nonaktif';
  }

  Widget _detailSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111827),
      ),
    );
  }

  Widget _detailInfoCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF111827),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMethodSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
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
              const Text(
                'Tambah Metode Pembayaran',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 20),
              _AddMethodOption(
                icon: Icons.account_balance_wallet_rounded,
                color: const Color(0xFF10B981),
                label: 'E-Wallet',
                subtitle: 'GoPay, OVO, DANA, dll.',
                onTap: () {
                  Navigator.pop(ctx);
                  showAppSnackBar(
                    context,
                    'Fitur tambah E-Wallet segera hadir!',
                    icon: Icons.account_balance_wallet_rounded,
                  );
                },
              ),
              const SizedBox(height: 12),
              _AddMethodOption(
                icon: Icons.account_balance_rounded,
                color: const Color(0xFF2563EB),
                label: 'Transfer Bank',
                subtitle: 'BCA, BNI, BRI, Mandiri, dll.',
                onTap: () {
                  Navigator.pop(ctx);
                  showAppSnackBar(
                    context,
                    'Fitur tambah Bank segera hadir!',
                    icon: Icons.account_balance_rounded,
                  );
                },
              ),
              const SizedBox(height: 12),
              _AddMethodOption(
                icon: Icons.credit_card_rounded,
                color: const Color(0xFF7C3AED),
                label: 'Kartu Kredit / Debit',
                subtitle: 'Visa, Mastercard, dll.',
                onTap: () {
                  Navigator.pop(ctx);
                  showAppSnackBar(
                    context,
                    'Fitur tambah Kartu segera hadir!',
                    icon: Icons.credit_card_rounded,
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isSectionExpanded(PaymentSection section) {
    return _expandedSections.contains(section);
  }

  void _toggleSection(PaymentSection section) {
    setState(() {
      if (_expandedSections.contains(section)) {
        _expandedSections.remove(section);
      } else {
        _expandedSections.add(section);
      }
    });
  }

  String _sectionTitle(PaymentSection section) {
    switch (section) {
      case PaymentSection.ewallet:
        return 'E-Wallet';
      case PaymentSection.vaBank:
        return 'VA Bank';
      case PaymentSection.qris:
        return 'QRIS';
      case PaymentSection.card:
        return 'Kartu Kredit';
      case PaymentSection.other:
        return 'Lainnya';
    }
  }

  String _sectionSubtitle(PaymentSection section) {
    switch (section) {
      case PaymentSection.ewallet:
        return 'GoPay, OVO, DANA, dan sejenisnya';
      case PaymentSection.vaBank:
        return 'Virtual account dan transfer bank';
      case PaymentSection.qris:
        return 'Pembayaran scan QR';
      case PaymentSection.card:
        return 'Kartu kredit dan debit';
      case PaymentSection.other:
        return 'Metode lain yang tersedia';
    }
  }

  IconData _sectionIcon(PaymentSection section) {
    switch (section) {
      case PaymentSection.ewallet:
        return Icons.account_balance_wallet_rounded;
      case PaymentSection.vaBank:
        return Icons.account_balance_rounded;
      case PaymentSection.qris:
        return Icons.qr_code_2_rounded;
      case PaymentSection.card:
        return Icons.credit_card_rounded;
      case PaymentSection.other:
        return Icons.more_horiz_rounded;
    }
  }

  Color _sectionColor(PaymentSection section) {
    switch (section) {
      case PaymentSection.ewallet:
        return const Color(0xFF10B981);
      case PaymentSection.vaBank:
        return const Color(0xFF2563EB);
      case PaymentSection.qris:
        return const Color(0xFF0EA5E9);
      case PaymentSection.card:
        return const Color(0xFF7C3AED);
      case PaymentSection.other:
        return const Color(0xFF64748B);
    }
  }

  List<_PaymentMethodEntry> _sectionItems(PaymentSection section) {
    return _methods.where((method) => method.section == section).toList();
  }

  Widget _buildMethodItem(
    _PaymentMethodEntry item, {
    required bool isFirst,
    required bool isLast,
  }) {
    final isSelected = item.key == _selectedMethodKey;

    return Column(
      children: [
        TapScale(
          onTap: () {
            setState(() {
              _selectedMethodKey = item.key;
            });
          },
          borderRadius: BorderRadius.only(
            topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
            topRight: isFirst ? const Radius.circular(20) : Radius.zero,
            bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
            bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
                topRight: isFirst ? const Radius.circular(20) : Radius.zero,
                bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
                bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    item.icon,
                    color: item.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.detail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF2563EB),
                    size: 22,
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _showMethodDetail(item),
                  icon: const Icon(Icons.info_outline_rounded, size: 18),
                  color: const Color(0xFF2563EB),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  tooltip: 'Lihat detail',
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Padding(
            padding: EdgeInsets.only(left: 74),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFF1F5F9),
            ),
          ),
      ],
    );
  }

  Widget _buildCollapsibleGroup(PaymentSection section) {
    final items = _sectionItems(section);
    if (items.isEmpty) return const SizedBox.shrink();

    final isExpanded = _isSectionExpanded(section);
    final count = items.length;
    final color = _sectionColor(section);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(
          children: [
            TapScale(
              onTap: () => _toggleSection(section),
              borderRadius: BorderRadius.circular(22),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isExpanded ? const Color(0xFFF8FAFC) : Colors.white,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _sectionIcon(section),
                        color: color,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _sectionTitle(section),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF111827),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _sectionSubtitle(section),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOut,
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Column(
                  children: List.generate(items.length, (index) {
                    final item = items[index];
                    return _buildMethodItem(
                      item,
                      isFirst: index == 0,
                      isLast: index == items.length - 1,
                    );
                  }),
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOutCubic,
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(height: 14),
          Text(
            'Memuat metode pembayaran...',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Gagal memuat metode pembayaran',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? 'Silakan coba lagi beberapa saat.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => _loadMethods(),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Coba Lagi',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDeniedView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 40,
                color: Color(0xFFF97316),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Metode pembayaran belum tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Akun ini belum punya akses ke daftar metode pembayaran dari server.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return const _EmptyPaymentView();
  }

  Widget _buildBody() {
    if (_accessDenied && _methods.isEmpty) {
      return _buildAccessDeniedView();
    }

    if (_isLoading && _methods.isEmpty) {
      return _buildLoadingView();
    }

    if (_loadError != null && _methods.isEmpty) {
      return _buildErrorView();
    }

    if (_methods.isEmpty) {
      return _buildEmptyView();
    }

    return RefreshIndicator(
      onRefresh: () => _loadMethods(showLoader: false),
      color: const Color(0xFF2563EB),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'Tap kategori untuk membuka daftar metode pembayaran.',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          _buildCollapsibleGroup(PaymentSection.ewallet),
          _buildCollapsibleGroup(PaymentSection.vaBank),
          _buildCollapsibleGroup(PaymentSection.qris),
          _buildCollapsibleGroup(PaymentSection.card),
          _buildCollapsibleGroup(PaymentSection.other),
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
          'Metode Pembayaran',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF111827),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMethodSheet,
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }
}

enum PaymentType { ewallet, bank, card, other }

enum PaymentSection { ewallet, vaBank, qris, card, other }

class _PaymentMethodEntry {
  const _PaymentMethodEntry({
    required this.apiId,
    required this.type,
    required this.section,
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
    required this.raw,
  });

  final String? apiId;
  final PaymentType type;
  final PaymentSection section;
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> raw;

  String get key => apiId ?? '${type.name}|$label|$detail';
}

class _EmptyPaymentView extends StatelessWidget {
  const _EmptyPaymentView();

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
            child: const Icon(
              Icons.payment_rounded,
              size: 40,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Metode Pembayaran',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Data metode pembayaran dari server belum tersedia.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}

class _AddMethodOption extends StatelessWidget {
  const _AddMethodOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
