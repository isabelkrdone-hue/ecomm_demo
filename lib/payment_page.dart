import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'address_model.dart';
import 'app_ui.dart';
import 'cart_model.dart';
import 'dashboard_page.dart';
import 'my_address_page.dart';
import 'order_history_model.dart';

const Color _appPrimary = Color(0xFF2563EB);
const Color _appBackground = Color(0xFFF8FAFC);
const Color _appText = Color(0xFF111827);
const Color _appSubText = Color(0xFF6B7280);

enum PaymentMethod {
  eWallet('E-Wallet'),
  bankTransfer('Bank Transfer'),
  creditCard('Kartu Kredit');

  const PaymentMethod(this.label);

  final String label;
}

enum EWalletProvider {
  dana('DANA'),
  ovo('OVO'),
  gopay('GoPay');

  const EWalletProvider(this.label);

  final String label;
}

enum ShippingType {
  instant,
  regular,
}

class ShippingOption {
  final String id;
  final String name;
  final String description;
  final int price;
  final ShippingType type;
  final String emoji;
  final String estimatedTime;

  const ShippingOption({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.type,
    required this.emoji,
    required this.estimatedTime,
  });
}

const List<ShippingOption> shippingOptions = [
  // Instant Delivery
  ShippingOption(
    id: 'gosend',
    name: 'GoSend',
    description: 'Instant delivery by GoSend',
    price: 15000,
    type: ShippingType.instant,
    emoji: '🟢',
    estimatedTime: '30-60 menit',
  ),
  ShippingOption(
    id: 'grabexpress',
    name: 'GrabExpress',
    description: 'Instant delivery by GrabExpress',
    price: 18000,
    type: ShippingType.instant,
    emoji: '🟢',
    estimatedTime: '30-60 menit',
  ),
  // Regular Courier
  ShippingOption(
    id: 'jnt',
    name: 'J&T Express',
    description: 'Reguler',
    price: 9000,
    type: ShippingType.regular,
    emoji: '📦',
    estimatedTime: '2-3 hari',
  ),
  ShippingOption(
    id: 'spx',
    name: 'Shopee Express',
    description: 'Reguler',
    price: 8000,
    type: ShippingType.regular,
    emoji: '🧡',
    estimatedTime: '2-4 hari',
  ),
  ShippingOption(
    id: 'jne',
    name: 'JNE',
    description: 'Reguler',
    price: 10000,
    type: ShippingType.regular,
    emoji: '🔴',
    estimatedTime: '2-3 hari',
  ),
  ShippingOption(
    id: 'pos',
    name: 'POS Indonesia',
    description: 'Reguler',
    price: 7000,
    type: ShippingType.regular,
    emoji: '📮',
    estimatedTime: '3-5 hari',
  ),
  ShippingOption(
    id: 'sicepat',
    name: 'SiCepat',
    description: 'Reguler',
    price: 9500,
    type: ShippingType.regular,
    emoji: '⚡',
    estimatedTime: '2-3 hari',
  ),
];

class CardNumberInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 16 ? digits.substring(0, 16) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if ((i + 1) % 4 == 0 && i != limited.length - 1) {
        buffer.write(' ');
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class ExpiryDateInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 4 ? digits.substring(0, 4) : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limited.length; i++) {
      buffer.write(limited[i]);
      if (i == 1 && i != limited.length - 1) {
        buffer.write('/');
      }
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key, required this.totalHarga});

  final int totalHarga;

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _eWalletNumberController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  PaymentMethod _selectedMethod = PaymentMethod.eWallet;
  EWalletProvider _selectedEWalletProvider = EWalletProvider.dana;
  String? _selectedBank = 'BCA';
  String _virtualAccount = '';
  bool _isProcessing = false;
  ShippingOption? _selectedShipping;

  @override
  void initState() {
    super.initState();
    _generateVirtualAccount();
  }

  @override
  void dispose() {
    _eWalletNumberController.dispose();
    _pinController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryDateController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  void _generateVirtualAccount() {
    final random = Random();
    _virtualAccount = List.generate(10, (_) => random.nextInt(10)).join();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handlePayment() async {
    // Validasi alamat pengiriman
    if (AddressModel.instance.isEmpty) {
      _showError('Silakan tambahkan alamat pengiriman terlebih dahulu.');
      return;
    }

    // Validasi opsi pengiriman
    if (_selectedShipping == null) {
      _showError('Silakan pilih metode pengiriman terlebih dahulu.');
      return;
    }

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      _showError('Lengkapi semua data sebelum melanjutkan.');
      return;
    }

    final cartItems = CartModel.instance.items
        .map((item) => Map<String, dynamic>.from(item))
        .toList();

    if (cartItems.isEmpty) {
      _showError('Keranjang kosong.');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    await Future<void>.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    OrderHistoryModel.instance.addOrder(
      products: cartItems,
      totalPrice: _totalWithShipping,
      paymentMethod: _storedPaymentMethod,
      shippingMethod: _selectedShipping?.name,
      shippingCost: _selectedShipping?.price,
    );
    CartModel.instance.clear();

    setState(() {
      _isProcessing = false;
    });

    showFakeNotification(
      context,
      'Pembayaran berhasil',
      backgroundColor: const Color(0xFF16A34A),
      icon: Icons.check_circle_rounded,
    );

    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      buildPageRoute(const DashboardPage()),
      (route) => false,
    );
  }

  void _handleMethodChanged(PaymentMethod value) {
    setState(() {
      _selectedMethod = value;
      if (value == PaymentMethod.bankTransfer) {
        _selectedBank ??= 'BCA';
        _generateVirtualAccount();
      }
    });
  }

  String get _storedPaymentMethod {
    switch (_selectedMethod) {
      case PaymentMethod.eWallet:
        return 'e-wallet';
      case PaymentMethod.bankTransfer:
        return (_selectedBank ?? 'BCA').toLowerCase();
      case PaymentMethod.creditCard:
        return 'visa';
    }
  }

  String get _selectedPaymentLabel {
    switch (_selectedMethod) {
      case PaymentMethod.eWallet:
        return 'E-Wallet (${_selectedEWalletProvider.label})';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer (${_selectedBank ?? '-'})';
      case PaymentMethod.creditCard:
        return 'Kartu Kredit';
    }
  }

  int get _totalWithShipping {
    return widget.totalHarga + (_selectedShipping?.price ?? 0);
  }

  InputDecoration _inputDecoration({required String label, required String hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD7E3FF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD7E3FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _appPrimary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color primary,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: primary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardBrandChip({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildSectionCard({required Widget child}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    switch (_selectedMethod) {
      case PaymentMethod.eWallet:
        return _buildSectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  icon: Icons.account_balance_wallet_rounded,
                  title: 'E-Wallet Flow',
                  subtitle: 'Pilih DANA, OVO, atau GoPay lalu masukkan nomor akun dan PIN.',
                  primary: _appPrimary,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<EWalletProvider>(
                  value: _selectedEWalletProvider,
                  decoration: _inputDecoration(
                    label: 'Jenis E-Wallet',
                    hint: 'Pilih provider',
                  ),
                  items: EWalletProvider.values
                      .map(
                        (provider) => DropdownMenuItem(
                          value: provider,
                          child: Text(provider.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _selectedEWalletProvider = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _eWalletNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: _inputDecoration(
                    label: 'Nomor E-Wallet',
                    hint: 'Contoh: 08xxxxxxxxxx',
                  ),
                  validator: (value) {
                    final digits = value?.replaceAll(RegExp(r'\s+'), '') ?? '';
                    if (digits.isEmpty) {
                      return 'Nomor e-wallet wajib diisi';
                    }
                    if (digits.length < 8) {
                      return 'Nomor e-wallet tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    label: 'PIN',
                    hint: 'Masukkan PIN',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'PIN wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _handlePayment,
                    style: FilledButton.styleFrom(
                      backgroundColor: _appPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Bayar Sekarang',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case PaymentMethod.bankTransfer:
        return _buildSectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  icon: Icons.account_balance_rounded,
                  title: 'Bank Transfer Flow',
                  subtitle: 'Pilih bank lalu transfer ke virtual account yang tersedia.',
                  primary: _appPrimary,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedBank,
                  decoration: _inputDecoration(
                    label: 'Nama Bank',
                    hint: 'Pilih bank',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'BCA', child: Text('BCA')),
                    DropdownMenuItem(value: 'BRI', child: Text('BRI')),
                    DropdownMenuItem(value: 'Mandiri', child: Text('Mandiri')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedBank = value;
                      _generateVirtualAccount();
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Bank wajib dipilih';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nomor Virtual Account',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        _virtualAccount,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Silakan transfer ke ${_selectedBank ?? '-'} lalu klik tombol konfirmasi.',
                        style: const TextStyle(color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _handlePayment,
                    style: FilledButton.styleFrom(
                      backgroundColor: _appPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Saya Sudah Transfer',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      case PaymentMethod.creditCard:
        return _buildSectionCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  icon: Icons.credit_card_rounded,
                  title: 'Kartu Kredit Flow',
                  subtitle: 'Gunakan kartu Visa atau Mastercard untuk simulasi pembayaran.',
                  primary: _appPrimary,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildCardBrandChip(label: 'VISA', color: const Color(0xFF1A1F71)),
                    const SizedBox(width: 10),
                    _buildCardBrandChip(label: 'Mastercard', color: const Color(0xFFEB001B)),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(16),
                    CardNumberInputFormatter(),
                  ],
                  decoration: _inputDecoration(
                    label: 'Nomor Kartu',
                    hint: '16 digit',
                  ),
                  validator: (value) {
                    final digits = value?.replaceAll(RegExp(r'\s+'), '') ?? '';
                    if (digits.isEmpty) {
                      return 'Nomor kartu wajib diisi';
                    }
                    if (digits.length != 16) {
                      return 'Nomor kartu harus 16 digit';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _cardHolderController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration(
                    label: 'Nama Pemilik Kartu',
                    hint: 'Nama sesuai kartu',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama pemilik kartu wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateController,
                        keyboardType: TextInputType.datetime,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                          ExpiryDateInputFormatter(),
                        ],
                        decoration: _inputDecoration(
                          label: 'Expiry Date',
                          hint: 'MM/YY',
                        ),
                        validator: (value) {
                          final formatted = value?.trim() ?? '';
                          if (formatted.isEmpty) {
                            return 'Expiry date wajib diisi';
                          }
                          if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$').hasMatch(formatted)) {
                            return 'Expiry date tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _cvvController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(3),
                        ],
                        decoration: _inputDecoration(
                          label: 'CVV',
                          hint: '3 digit',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'CVV wajib diisi';
                          }
                          if (value.trim().length < 3) {
                            return 'CVV tidak valid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _handlePayment,
                    style: FilledButton.styleFrom(
                      backgroundColor: _appPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Bayar Sekarang',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const background = _appBackground;
    const primary = _appPrimary;
    const textColor = _appText;
    const subText = _appSubText;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        title: const Text(
          'Payment',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        surfaceTintColor: Colors.white,
      ),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: _isProcessing,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shadowColor: Colors.black12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.payments_rounded,
                            color: primary,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Harga',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                CartModel.formatPrice(widget.totalHarga),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Shipping Address Section
                _buildShippingAddressSection(),
                const SizedBox(height: 16),
                // Shipping Method Section
                _buildShippingMethodSection(),
                const SizedBox(height: 16),
                const Text(
                  'Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  child: Column(
                    children: [
                      RadioListTile<PaymentMethod>(
                        value: PaymentMethod.eWallet,
                        groupValue: _selectedMethod,
                        onChanged: (value) {
                          if (value == null) return;
                          _handleMethodChanged(value);
                        },
                        title: const Text('E-Wallet'),
                        subtitle: const Text('DANA, OVO, GoPay, dan lainnya'),
                        activeColor: primary,
                      ),
                      const Divider(height: 1),
                      RadioListTile<PaymentMethod>(
                        value: PaymentMethod.bankTransfer,
                        groupValue: _selectedMethod,
                        onChanged: (value) {
                          if (value == null) return;
                          _handleMethodChanged(value);
                        },
                        title: const Text('Bank Transfer'),
                        subtitle: const Text('BCA, BRI, Mandiri'),
                        activeColor: primary,
                      ),
                      const Divider(height: 1),
                      RadioListTile<PaymentMethod>(
                        value: PaymentMethod.creditCard,
                        groupValue: _selectedMethod,
                        onChanged: (value) {
                          if (value == null) return;
                          _handleMethodChanged(value);
                        },
                        title: const Text('Kartu Kredit'),
                        subtitle: const Text('Visa / Mastercard'),
                        activeColor: primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildPaymentMethodSection(),
                const SizedBox(height: 16),
                Card(
                  elevation: 0,
                  color: const Color(0xFFF9FAFB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ringkasan',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(color: subText)),
                            Text(
                              CartModel.formatPrice(widget.totalHarga),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ongkos Kirim', style: TextStyle(color: subText)),
                            Text(
                              CartModel.formatPrice(_selectedShipping?.price ?? 0),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(color: subText, fontWeight: FontWeight.w700)),
                            Text(
                              CartModel.formatPrice(_totalWithShipping),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: textColor,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Metode', style: TextStyle(color: subText)),
                            Text(
                              _selectedPaymentLabel,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: FilledButton(
                    onPressed: _handlePayment,
                    style: FilledButton.styleFrom(
                      backgroundColor: primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Bayar Sekarang',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.16),
              child: Center(
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 14),
                        Text(
                          'Memproses pembayaran...',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShippingAddressSection() {
    final addressModel = AddressModel.instance;
    final selectedAddress = addressModel.selectedAddress;

    return Card(
      elevation: 0,
      color: Colors.white,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: _appPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alamat Pengiriman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Produk akan dikirim ke alamat ini',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      buildPageRoute(const MyAddressPage()),
                    );
                    setState(() {});
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                  ),
                  child: const Text(
                    'Ubah',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _appPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (selectedAddress != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            selectedAddress['label'] ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _appPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      selectedAddress['name'] ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      selectedAddress['phone'] ?? '',
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
                            '${selectedAddress['address']}, ${selectedAddress['city']}',
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
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_rounded,
                        color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Belum ada alamat pengiriman. Klik "Ubah" untuk menambahkan.',
                        style: TextStyle(
                          fontSize: 13,
                          color: const Color(0xFFEF4444).withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildShippingMethodSection() {
    return Card(
      elevation: 0,
      color: Colors.white,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    color: _appPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Metode Pengiriman',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Pilih layanan pengiriman',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Instant Delivery Section
            const Text(
              'Pengiriman Instan',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            ...shippingOptions
                .where((option) => option.type == ShippingType.instant)
                .map((option) => _buildShippingOptionTile(option)),
            const SizedBox(height: 16),
            // Regular Courier Section
            const Text(
              'Kurir Reguler',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 10),
            ...shippingOptions
                .where((option) => option.type == ShippingType.regular)
                .map((option) => _buildShippingOptionTile(option)),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingOptionTile(ShippingOption option) {
    final isSelected = _selectedShipping?.id == option.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedShipping = option;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF6FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _appPrimary : const Color(0xFFE5E7EB),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Center(
                child: Text(
                  option.emoji,
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? _appPrimary : const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    option.estimatedTime,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CartModel.formatPrice(option.price),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? _appPrimary : const Color(0xFF111827),
                  ),
                ),
                if (isSelected)
                  const SizedBox(height: 4),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _appPrimary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Dipilih',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
