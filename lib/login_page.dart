import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_ui.dart';
import 'dashboard_page.dart';
import 'package:logger/logger.dart';
import 'repository/http.dart';
import 'sessions.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _userController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;
  final Logger _logger = Logger();

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    try {
      final http = Http();
      _logger.i('Attempting login for: ${_userController.text.trim()}');
      final res = await http.login(
        email: _userController.text.trim(),
        password: _passwordController.text,
        deviceName: 'flutter',
      );
      _logger.i('Login response: $res');

      if (res['success'] == true) {
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true);

          if (http.token != null && http.token!.isNotEmpty) {
            await Sessions.setLoginSession(
              token: http.token!,
              userId: http.userId ?? '',
              name: http.name ?? '',
              email: http.email ?? '',
              phone: http.phone ?? '',
              roleId: http.roleId ?? '',
              role: http.role ?? '',
            );
            http.setToken(http.token!);
            final savedSession = await Sessions.getLoginSession();
            _logger.i(
              'Login sukses, session tersimpan: '
              'tokenLength=${savedSession['token']?.length ?? 0}, '
              'userId=${savedSession['userId']}, '
              'name=${savedSession['name']}, '
              'email=${savedSession['email']}, '
              'phone=${savedSession['phone']}, '
              'roleId=${savedSession['roleId']}, '
              'role=${savedSession['role']}',
            );
          } else {
            _logger.w('No access token found in response');
          }

          // save user if provided
          if (res['data'] is Map && res['data']['user'] != null) {
            final userJson = res['data']['user'];
            try {
              await Sessions.setUser(
                userJson is String ? userJson : userJson.toString(),
              );
            } catch (_) {}
          }

          // fetch roles
          try {
            _logger.i(
                'Calling getRoles with Authorization: ${http.dio.options.headers['Authorization']}');
            final roles = await http.getRoles();
            _logger.i('Roles: $roles');
            if (roles['success'] != true) {
              _logger.w(
                  'getRoles returned non-success: ${roles['message'] ?? roles}');
            }
          } catch (e) {
            _logger.w('Failed to fetch roles: $e');
          }
        } catch (e, st) {
          _logger.e('Failed to save login session: $e\n$st');
        }

        if (!mounted) return;
        showFakeNotification(
          context,
          'Login berhasil, selamat berbelanja',
          backgroundColor: const Color(0xFF2563EB),
          icon: Icons.verified_rounded,
        );
        Navigator.of(context).pushReplacement(
          buildPageRoute(const DashboardPage()),
        );
      } else {
        final message = res['message'] ?? 'Login gagal';
        _logger.w('Login failed: $message');
        showFakeNotification(
          context,
          message.toString(),
          backgroundColor: Colors.red,
          icon: Icons.error,
        );
      }
    } catch (e) {
      _logger.e('Login error: $e');
      showFakeNotification(
        context,
        'Terjadi kesalahan saat login',
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E293B), Color(0xFF334155)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 12,
                  color: Colors.white.withOpacity(0.95),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            height: 72,
                            width: 72,
                            decoration: BoxDecoration(
                              color:
                                  theme.colorScheme.primary.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.lock_outline,
                              size: 36,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Selamat Datang',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Masuk untuk melanjutkan ke aplikasi',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          TextFormField(
                            controller: _userController,
                            keyboardType: TextInputType.text,
                            decoration: const InputDecoration(
                              labelText: 'User / Email',
                              hintText:
                                  'Masukkan username, email, atau teks apa pun',
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'User tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              hintText: 'Masukkan password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _handleLogin,
                              style: ElevatedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Login',
                                      style: TextStyle(fontSize: 16),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
