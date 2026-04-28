import 'package:flutter/material.dart';

import 'app_ui.dart';

class PaymentMethodPage extends StatefulWidget {
  const PaymentMethodPage({super.key});

  @override
  State<PaymentMethodPage> createState() => _PaymentMethodPageState();
}

class _PaymentMethodPageState extends State<PaymentMethodPage> {
  int _selectedIndex = 0;

  final List<_PaymentItem> _methods = [
    const _PaymentItem(
      type: PaymentType.ewallet,
      label: 'GoPay',
      detail: '081234567890',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF00AED6),
    ),
    const _PaymentItem(
      type: PaymentType.ewallet,
      label: 'OVO',
      detail: '081234567890',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFF4C3494),
    ),
    const _PaymentItem(
      type: PaymentType.bank,
      label: 'Bank BCA',
      detail: '1234567890',
      icon: Icons.account_balance_rounded,
      color: Color(0xFF0066AE),
    ),
    const _PaymentItem(
      type: PaymentType.card,
      label: 'Visa •••• 4291',
      detail: 'Berlaku hingga 12/27',
      icon: Icons.credit_card_rounded,
      color: Color(0xFF1A56DB),
    ),
  ];

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

  void _deleteMethod(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text(
          'Hapus Metode?',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Metode pembayaran ini akan dihapus.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                if (_selectedIndex >= index && _selectedIndex > 0) {
                  _selectedIndex--;
                }
                _methods.removeAt(index);
              });
              Navigator.of(ctx).pop();
              showAppSnackBar(
                context,
                'Metode pembayaran dihapus.',
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
      body: SafeArea(
        child: _methods.isEmpty
            ? const _EmptyPaymentView()
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  // Group: E-Wallet
                  _buildGroup(
                    'E-Wallet',
                    Icons.account_balance_wallet_rounded,
                    PaymentType.ewallet,
                  ),
                  // Group: Bank Transfer
                  _buildGroup(
                    'Transfer Bank',
                    Icons.account_balance_rounded,
                    PaymentType.bank,
                  ),
                  // Group: Card
                  _buildGroup(
                    'Kartu',
                    Icons.credit_card_rounded,
                    PaymentType.card,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGroup(String title, IconData icon, PaymentType type) {
    final items = _methods
        .asMap()
        .entries
        .where((e) => e.value.type == type)
        .toList();

    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF64748B)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: items.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == _selectedIndex;
              final isLast = entry == items.last;

              return Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFEFF6FF)
                            : Colors.transparent,
                        borderRadius: BorderRadius.only(
                          topLeft: index == items.first.key
                              ? const Radius.circular(20)
                              : Radius.zero,
                          topRight: index == items.first.key
                              ? const Radius.circular(20)
                              : Radius.zero,
                          bottomLeft: isLast
                              ? const Radius.circular(20)
                              : Radius.zero,
                          bottomRight: isLast
                              ? const Radius.circular(20)
                              : Radius.zero,
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
                            const Icon(Icons.check_circle_rounded,
                                color: Color(0xFF2563EB), size: 22),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _deleteMethod(index),
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18),
                            color: const Color(0xFFEF4444),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Padding(
                      padding: EdgeInsets.only(left: 74),
                      child: Divider(
                          height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Models & Helpers ─────────────────────────────────────────────────────────

enum PaymentType { ewallet, bank, card }

class _PaymentItem {
  const _PaymentItem({
    required this.type,
    required this.label,
    required this.detail,
    required this.icon,
    required this.color,
  });

  final PaymentType type;
  final String label;
  final String detail;
  final IconData icon;
  final Color color;
}

// ─── Reusable widgets ────────────────────────────────────────────────────────

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
            child: const Icon(Icons.payment_rounded,
                size: 40, color: Color(0xFF2563EB)),
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
            'Tambahkan metode pembayaran\nuntuk mempercepat proses checkout.',
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
