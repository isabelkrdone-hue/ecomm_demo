import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_ui.dart';
import 'edit_profile_page.dart';
import 'help_page.dart';
import 'login_page.dart';
import 'my_address_page.dart';
import 'my_businesses_page.dart';
import 'my_products_page.dart';
import 'order_history_page.dart';
import 'payment_method_page.dart';
import 'profile_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _profileModel = ProfileModel.instance;
  bool _isDarkMode = false;
  bool _isNotificationEnabled = true;

  @override
  void initState() {
    super.initState();
    _profileModel.addListener(_onProfileChanged);
  }

  @override
  void dispose() {
    _profileModel.removeListener(_onProfileChanged);
    super.dispose();
  }

  void _onProfileChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _handleLogout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      buildPageRoute(const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFFF8FAFC);
    const primaryTextColor = Color(0xFF111827);
    const secondaryTextColor = Color(0xFF64748B);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        foregroundColor: primaryTextColor,
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth > 600 ? 32.0 : 16.0;
            final avatarSize = constraints.maxWidth > 600 ? 76.0 : 64.0;

            return ListView(
              padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 24),
              children: [
                _ProfileHeaderCard(
                  avatarSize: avatarSize,
                ),
                const SizedBox(height: 20),
                const _SectionTitle(title: 'Menu Akun'),
                const SizedBox(height: 12),
                _ModernCard(
                  child: Column(
                    children: [
                      _MenuItemTile(
                        icon: Icons.person,
                        title: 'Edit Profile',
                        onTap: () async {
                          final result = await Navigator.of(context).push(
                            buildPageRoute(const EditProfilePage()),
                          );
                          if (result == true && mounted) {
                            setState(() {});
                          }
                        },
                      ),
                      const _MenuDivider(),
                      _MenuItemTile(
                        icon: Icons.location_on,
                        title: 'Alamat Saya',
                        onTap: () {
                          Navigator.of(context).push(
                            buildPageRoute(const MyAddressPage()),
                          );
                        },
                      ),
                      const _MenuDivider(),
                      _MenuItemTile(
                        icon: Icons.payment,
                        title: 'Metode Pembayaran',
                        onTap: () {
                          Navigator.of(context).push(
                            buildPageRoute(const PaymentMethodPage()),
                          );
                        },
                      ),
                      const _MenuDivider(),
                      _MenuItemTile(
                        icon: Icons.receipt_long,
                        title: 'Riwayat Pesanan',
                        onTap: () {
                          Navigator.of(context).push(
                            buildPageRoute(const OrderHistoryPage()),
                          );
                        },
                      ),
                      const _MenuDivider(),
                      _MenuItemTile(
                        icon: Icons.business,
                        title: 'Bisnis Saya',
                        onTap: () {
                          Navigator.of(context).push(
                            buildPageRoute(const MyBusinessesPage()),
                          );
                        },
                      ),
                      const _MenuDivider(),
                      _MenuItemTile(
                        icon: Icons.store,
                        title: 'Produk Saya',
                        onTap: () {
                          Navigator.of(context).push(
                            buildPageRoute(const MyProductsPage()),
                          );
                        },
                      ),
                      const _MenuDivider(),
                      _MenuItemTile(
                        icon: Icons.help_outline,
                        title: 'Bantuan',
                        onTap: () {
                          Navigator.of(context).push(
                            buildPageRoute(const HelpPage()),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _SectionTitle(title: 'Settings'),
                const SizedBox(height: 12),
                _ModernCard(
                  child: Column(
                    children: [
                      _SettingsTile(
                        icon: Icons.dark_mode_outlined,
                        title: 'Dark Mode',
                        subtitle: 'Tampilan gelap aplikasi',
                        value: _isDarkMode,
                        onChanged: (value) {
                          setState(() {
                            _isDarkMode = value;
                          });
                        },
                      ),
                      const _MenuDivider(),
                      _SettingsTile(
                        icon: Icons.notifications_none,
                        title: 'Notifikasi',
                        subtitle: 'Aktifkan notifikasi promo dan pesanan',
                        value: _isNotificationEnabled,
                        onChanged: (value) {
                          setState(() {
                            _isNotificationEnabled = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text(
                      'Logout',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE2E2),
                      foregroundColor: const Color(0xFFB91C1C),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFFECACA)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_profileModel.name} • ${_profileModel.email}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.avatarSize,
  });

  final double avatarSize;

  @override
  Widget build(BuildContext context) {
    const primaryTextColor = Color(0xFF111827);
    const secondaryTextColor = Color(0xFF64748B);
    final profileModel = ProfileModel.instance;

    return _ModernCard(
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: profileModel.hasProfileImage()
                  ? null
                  : const LinearGradient(
                      colors: [Color(0xFFDBEAFE), Color(0xFFE0E7FF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
              image: profileModel.hasProfileImage()
                  ? DecorationImage(
                      image: FileImage(File(profileModel.profileImagePath!)),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: profileModel.hasProfileImage()
                ? null
                : const Icon(
                    Icons.person_rounded,
                    size: 34,
                    color: Color(0xFF2563EB),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profileModel.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: primaryTextColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  profileModel.email,
                  style: const TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                const _ProfileChip(label: 'Premium Member'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernCard extends StatelessWidget {
  const _ModernCard({required this.child});

  final Widget child;

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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: Color(0xFF111827),
      ),
    );
  }
}

class _MenuItemTile extends StatelessWidget {
  const _MenuItemTile({
    required this.icon,
    required this.title,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF334155),
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Color(0xFF111827),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right_rounded,
        color: Color(0xFF94A3B8),
      ),
      onTap: onTap,
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF2563EB),
      title: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF334155),
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 3),
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
        ],
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 54),
      child: Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF4338CA),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
