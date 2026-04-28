import 'package:flutter/material.dart';

import 'app_ui.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int? _expandedIndex;

  final List<_FaqItem> _faqs = const [
    _FaqItem(
      question: 'Bagaimana cara melacak pesanan saya?',
      answer:
          'Kamu bisa melacak pesanan melalui menu "Riwayat Pesanan" di halaman Profil. Pilih pesanan yang ingin dilacak, lalu tap tombol "Lacak Pesanan" untuk melihat status pengirimannya secara real-time.',
      category: 'Pesanan',
    ),
    _FaqItem(
      question: 'Apakah saya bisa membatalkan pesanan?',
      answer:
          'Pembatalan pesanan hanya bisa dilakukan sebelum pesanan diproses oleh penjual (status "Menunggu Konfirmasi"). Buka detail pesanan dan tap "Batalkan Pesanan". Refund akan diproses dalam 1-3 hari kerja.',
      category: 'Pesanan',
    ),
    _FaqItem(
      question: 'Metode pembayaran apa saja yang tersedia?',
      answer:
          'Kami menerima berbagai metode pembayaran:\n• E-Wallet: GoPay, OVO, DANA, ShopeePay\n• Transfer Bank: BCA, BNI, BRI, Mandiri\n• Kartu Kredit/Debit: Visa, Mastercard\n• COD (bayar di tempat) untuk area tertentu.',
      category: 'Pembayaran',
    ),
    _FaqItem(
      question: 'Bagaimana jika pembayaran saya gagal?',
      answer:
          'Jika pembayaran gagal, pesananmu otomatis dibatalkan dan saldo akan dikembalikan. Kamu bisa mencoba lagi dengan metode pembayaran yang berbeda, atau pastikan saldo e-wallet/rekeningmu mencukupi.',
      category: 'Pembayaran',
    ),
    _FaqItem(
      question: 'Berapa lama waktu pengiriman?',
      answer:
          'Estimasi waktu pengiriman tergantung lokasi:\n• Same Day: 2-8 jam (Jabodetabek)\n• Next Day: 1 hari kerja\n• Reguler: 2-5 hari kerja\n• Kargo: 5-14 hari kerja\n\nWaktu dapat bervariasi tergantung kurir dan kondisi.',
      category: 'Pengiriman',
    ),
    _FaqItem(
      question: 'Bagaimana cara mengajukan retur barang?',
      answer:
          'Retur bisa diajukan dalam 7 hari setelah barang diterima jika:\n• Barang rusak/cacat\n• Barang tidak sesuai deskripsi\n• Barang salah kirim\n\nBuka detail pesanan → "Ajukan Komplain" dan ikuti petunjuknya.',
      category: 'Retur & Refund',
    ),
    _FaqItem(
      question: 'Bagaimana cara mengubah password akun?',
      answer:
          'Untuk mengubah password:\n1. Buka menu Edit Profile\n2. Tap "Ubah Password"\n3. Masukkan password lama dan password baru\n4. Konfirmasi dan simpan.\n\nPastikan password baru minimal 8 karakter.',
      category: 'Akun',
    ),
    _FaqItem(
      question: 'Bagaimana cara menghubungi penjual?',
      answer:
          'Kamu bisa menghubungi penjual langsung melalui fitur chat yang ada di halaman toko atau halaman detail produk. Tap ikon chat/pesan untuk memulai percakapan.',
      category: 'Lainnya',
    ),
  ];

  List<_FaqItem> get _filteredFaqs {
    if (_searchQuery.isEmpty) return _faqs;
    return _faqs
        .where((faq) =>
            faq.question.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            faq.answer.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            faq.category.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFaqs;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Bantuan',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: const Color(0xFF111827),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          children: [
            // Header banner
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2563EB), Color(0xFF4F46E5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ada yang bisa\nkami bantu?',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Temukan jawaban dari pertanyaanmu\ndi bawah ini.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      size: 36,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Quick contact
            Row(
              children: [
                Expanded(
                  child: _QuickContactCard(
                    icon: Icons.chat_bubble_outline_rounded,
                    label: 'Live Chat',
                    subtitle: 'Online 24 jam',
                    color: const Color(0xFF10B981),
                    onTap: () => showAppSnackBar(
                      context,
                      'Membuka Live Chat...',
                      icon: Icons.chat_bubble_rounded,
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickContactCard(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    subtitle: 'Balas dalam 1x24 jam',
                    color: const Color(0xFF2563EB),
                    onTap: () => showAppSnackBar(
                      context,
                      'Membuka Email Support...',
                      icon: Icons.email_rounded,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _QuickContactCard(
                    icon: Icons.phone_outlined,
                    label: 'Telepon',
                    subtitle: '08:00 - 21:00',
                    color: const Color(0xFF7C3AED),
                    onTap: () => showAppSnackBar(
                      context,
                      'Menghubungi CS: 021-1234-5678',
                      icon: Icons.phone_rounded,
                      backgroundColor: const Color(0xFF7C3AED),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Search bar
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() {
                _searchQuery = v;
                _expandedIndex = null;
              }),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF111827),
              ),
              decoration: InputDecoration(
                hintText: 'Cari pertanyaan...',
                hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: Color(0xFF64748B), size: 22),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: Color(0xFF94A3B8), size: 20),
                        onPressed: () => setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                          _expandedIndex = null;
                        }),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
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
                  borderSide:
                      const BorderSide(color: Color(0xFF2563EB), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            // FAQ title
            Row(
              children: [
                const Text(
                  'Pertanyaan Umum',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${filtered.length}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // FAQ list
            if (filtered.isEmpty)
              _EmptySearchResult(query: _searchQuery)
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: filtered.asMap().entries.map((entry) {
                    final index = entry.key;
                    final faq = entry.value;
                    final isExpanded = _expandedIndex == index;
                    final isLast = index == filtered.length - 1;

                    return Column(
                      children: [
                        _FaqTile(
                          faq: faq,
                          isExpanded: isExpanded,
                          isFirst: index == 0,
                          isLast: isLast,
                          onTap: () => setState(() {
                            _expandedIndex =
                                isExpanded ? null : index;
                          }),
                        ),
                        if (!isLast)
                          const Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: Divider(
                                height: 1,
                                thickness: 1,
                                color: Color(0xFFF1F5F9)),
                          ),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Models & Helpers ─────────────────────────────────────────────────────────

class _FaqItem {
  const _FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
  final String question;
  final String answer;
  final String category;
}

// ─── Reusable widgets ────────────────────────────────────────────────────────

class _QuickContactCard extends StatelessWidget {
  const _QuickContactCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TapScale(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
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
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.faq,
    required this.isExpanded,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final _FaqItem faq;
  final bool isExpanded;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
        topRight: isFirst ? const Radius.circular(20) : Radius.zero,
        bottomLeft: isLast ? const Radius.circular(20) : Radius.zero,
        bottomRight: isLast ? const Radius.circular(20) : Radius.zero,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        color: isExpanded ? const Color(0xFFF8FAFF) : Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                faq.question,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isExpanded
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF111827),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: _CategoryChip(label: faq.category),
              ),
              trailing: AnimatedRotation(
                turns: isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: isExpanded
                      ? const Color(0xFF2563EB)
                      : const Color(0xFF94A3B8),
                ),
              ),
              onTap: onTap,
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  faq.answer,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF475569),
                    height: 1.6,
                  ),
                ),
              ),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

class _EmptySearchResult extends StatelessWidget {
  const _EmptySearchResult({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              size: 56, color: Color(0xFFCBD5E1)),
          const SizedBox(height: 12),
          const Text(
            'Tidak ada hasil',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Tidak ada pertanyaan yang cocok dengan\n"$query"',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
