import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../admin_theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/app_state.dart';
import '../services/firebase_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _auth       = AuthService();
  final _formKey    = GlobalKey<FormState>();
  final _emailCtrl  = TextEditingController();
  final _passCtrl   = TextEditingController();
  bool _loading     = false;
  bool _obscure     = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              // Brand
              Row(children: [
                Text('Food', style: GoogleFonts.syne(
                    fontSize: 32, fontWeight: FontWeight.w700,
                    color: AdminColors.navy)),
                Text('Bridge', style: GoogleFonts.syne(
                    fontSize: 32, fontWeight: FontWeight.w700,
                    color: AdminColors.accent)),
              ]),
              const SizedBox(height: 4),
              Text('Admin Control Panel', style: GoogleFonts.dmSans(
                  fontSize: 15, color: AdminColors.textMuted)),
              const SizedBox(height: 36),

              // Lock icon
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: AdminColors.navy.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.admin_panel_settings_outlined,
                    size: 28, color: AdminColors.navy),
              ),
              const SizedBox(height: 28),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AdminColors.coralL,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AdminColors.coral.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline, size: 16, color: AdminColors.coral),
                    const SizedBox(width: 8),
                    Expanded(child: Text(_error!, style: GoogleFonts.dmSans(
                        fontSize: 13, color: AdminColors.coral))),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              Form(
                key: _formKey,
                child: Column(children: [
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Enter a valid email' : null,
                    decoration: const InputDecoration(
                      hintText: 'Admin email',
                      prefixIcon: Icon(Icons.email_outlined,
                          size: 18, color: AdminColors.textMuted),
                    ),
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AdminColors.textPrimary),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Min 6 characters' : null,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline,
                          size: 18, color: AdminColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off_outlined
                                   : Icons.visibility_outlined,
                          size: 18, color: AdminColors.textMuted,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AdminColors.textPrimary),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _login,
                      icon: _loading
                          ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.lock_open_outlined, size: 18),
                      label: Text(_loading ? 'Signing in…' : 'Sign In as Admin',
                          style: GoogleFonts.syne(
                              fontSize: 14, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AdminColors.navy,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor:
                            AdminColors.navy.withOpacity(0.5),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Only accounts with role = admin can access this panel.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.dmSans(
                      fontSize: 12, color: AdminColors.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      final user = await _auth.signIn(
        email: _emailCtrl.text,
        password: _passCtrl.text,
      );

      // Admin-only check
      if (user.role != UserRole.admin) {
        await _auth.signOut();
        throw Exception('Access denied. This account does not have admin privileges.');
      }

      if (!mounted) return;
      final appState = context.read<AppState>();
      appState.setUser(user);
      FirebaseService().init(user.uid, user.name);
    } on Exception catch (e) {
      setState(() {
        _loading = false;
        _error   = e.toString().replaceAll('Exception: ', '');
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error   = 'Login failed. Please check your credentials.';
      });
    }
  }
}
