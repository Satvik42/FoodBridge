import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/app_state.dart';
import '../services/firebase_service.dart';

/// Login / Register screen.
/// Uses existing app styling — no new UI patterns.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _auth    = AuthService();
  final _formKey = GlobalKey<FormState>();
  late TabController _tabCtrl;

  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl     = TextEditingController();

  UserRole _selectedRole = UserRole.user;
  bool _loading   = false;
  bool _obscure   = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    // Rebuild when tab changes so Name field and button label update
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() => _error = null);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Brand header ──────────────────────────────────────────
              Row(children: [
                Text('Food', style: GoogleFonts.syne(
                    fontSize: 28, fontWeight: FontWeight.w700,
                    color: AppColors.primary)),
                Text('Bridge', style: GoogleFonts.syne(
                    fontSize: 28, fontWeight: FontWeight.w700,
                    color: AppColors.primary2)),
              ]),
              const SizedBox(height: 6),
              Text('Connect surplus food to people in need',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height: 32),

              // ── Login / Register tabs ─────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.bg2,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(3),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: GoogleFonts.syne(
                      fontSize: 13, fontWeight: FontWeight.w600),
                  unselectedLabelStyle:
                      GoogleFonts.syne(fontSize: 13),
                  onTap: (_) => setState(() => _error = null),
                  tabs: const [Tab(text: 'Sign In'), Tab(text: 'Register')],
                ),
              ),
              const SizedBox(height: 24),

              // ── Error banner ──────────────────────────────────────────
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.coralL,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.coral.withOpacity(0.3), width: 0.5),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline,
                        size: 16, color: AppColors.coral),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: GoogleFonts.dmSans(
                              fontSize: 13, color: AppColors.coral)),
                    ),
                  ]),
                ),
                const SizedBox(height: 16),
              ],

              // ── Form ─────────────────────────────────────────────────
              Form(
                key: _formKey,
                child: Column(children: [
                  // Name (Register only)
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: _tabCtrl.index == 1
                        ? Column(children: [
                            _label('Full Name'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _nameCtrl,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Name is required'
                                      : null,
                              decoration: const InputDecoration(
                                hintText: 'e.g. Rohan Kumar',
                                prefixIcon: Icon(Icons.person_outline,
                                    size: 18,
                                    color: AppColors.textMuted),
                              ),
                              style: GoogleFonts.dmSans(
                                  fontSize: 14,
                                  color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 14),
                          ])
                        : const SizedBox.shrink(),
                  ),

                  _label('Email'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) =>
                        (v == null || !v.contains('@'))
                            ? 'Enter a valid email'
                            : null,
                    decoration: const InputDecoration(
                      hintText: 'you@example.com',
                      prefixIcon: Icon(Icons.email_outlined,
                          size: 18, color: AppColors.textMuted),
                    ),
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 14),

                  _label('Password'),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscure,
                    validator: (v) =>
                        (v == null || v.length < 6)
                            ? 'Min 6 characters'
                            : null,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline,
                          size: 18, color: AppColors.textMuted),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        onPressed: () =>
                            setState(() => _obscure = !_obscure),
                      ),
                    ),
                    style: GoogleFonts.dmSans(
                        fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 20),

                  // ── Role selection ──────────────────────────────────
                  _label('I am a...'),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: _RoleChip(
                        icon: Icons.person_outline,
                        label: 'User',
                        subtitle: 'Find & request food',
                        selected: _selectedRole == UserRole.user,
                        onTap: () =>
                            setState(() => _selectedRole = UserRole.user),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleChip(
                        icon: Icons.directions_bike_outlined,
                        label: 'Volunteer',
                        subtitle: 'Deliver food',
                        selected: _selectedRole == UserRole.volunteer,
                        onTap: () => setState(
                            () => _selectedRole = UserRole.volunteer),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 24),

                  // ── Submit button ───────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _loading ? null : _handleSubmit,
                      icon: _loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
                          : const Icon(Icons.arrow_forward_rounded,
                              size: 18),
                      label: Text(
                        _loading
                            ? 'Please wait...'
                            : _tabCtrl.index == 0
                                ? 'Sign In'
                                : 'Create Account',
                        style: GoogleFonts.syne(
                            fontSize: 14,
                            fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        disabledBackgroundColor:
                            AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 32),
              _buildDemoAccountsBox(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDemoAccountsBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Prototype Access',
                  style: GoogleFonts.syne(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Text('Tap to autofill demo credentials:',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _demoAccountTile('Admin', 'admin1@foodbridge.com', 'password123'),
          const SizedBox(height: 8),
          _demoAccountTile('User 1 (Donor)', 'user1@foodbridge.com', 'password123'),
          const SizedBox(height: 8),
          _demoAccountTile('User 2 (Donor)', 'user2@foodbridge.com', 'password123'),
          const SizedBox(height: 8),
          _demoAccountTile('User 3 (Donor)', 'user3@foodbridge.com', 'password123'),
          const SizedBox(height: 8),
          _demoAccountTile('Volunteer 1', 'volunteer1@foodbridge.com', 'password123'),
          const SizedBox(height: 8),
          _demoAccountTile('Volunteer 2', 'volunteer2@foodbridge.com', 'password123'),
          const SizedBox(height: 8),
          _demoAccountTile('Volunteer 3', 'volunteer3@foodbridge.com', 'password123'),
        ],
      ),
    );
  }

  Widget _demoAccountTile(String role, String email, String password) {
    return InkWell(
      onTap: () {
        _tabCtrl.animateTo(0); // Switch to Sign In tab
        _emailCtrl.text = email;
        _passwordCtrl.text = password;
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role,
                      style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(email,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.textMuted)),
                ],
              ),
            ),
            Icon(Icons.login, size: 16, color: AppColors.primary.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text.toUpperCase(),
        style: GoogleFonts.syne(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
            letterSpacing: 0.4),
      );

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      AppUser user;
      if (_tabCtrl.index == 0) {
        // Sign In — role comes from Firestore, ignore _selectedRole
        user = await _auth.signIn(
          email:    _emailCtrl.text,
          password: _passwordCtrl.text,
        );
      } else {
        // Register — use _selectedRole
        user = await _auth.register(
          email:    _emailCtrl.text,
          password: _passwordCtrl.text,
          name:     _nameCtrl.text,
          role:     _selectedRole,
        );
      }

      if (!mounted) return;
      // Push user into AppState and initialise FirebaseService
      final appState = context.read<AppState>();
      appState.setUser(user);
      FirebaseService().init(user.uid, user.name);
      // Navigation handled by StreamBuilder in main.dart (authStateChanges)
    } on Exception catch (e) {
      setState(() { _loading = false; _error = e.toString().replaceAll('Exception: ', ''); });
    } catch (e) {
      setState(() { _loading = false; _error = 'Authentication failed. Please try again.'; });
    }
  }
}

// ─── Role chip ────────────────────────────────────────────────────────────
class _RoleChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryXL : AppColors.bg2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary2 : AppColors.border,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 22,
                color: selected ? AppColors.primary : AppColors.textMuted),
            const SizedBox(height: 8),
            Text(label,
                style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.primary
                        : AppColors.textPrimary)),
            Text(subtitle,
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: selected
                        ? AppColors.primary2
                        : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
