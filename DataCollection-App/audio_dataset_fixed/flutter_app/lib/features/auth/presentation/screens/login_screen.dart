import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../../../admin/presentation/screens/admin_shell.dart';
import '../../../level1/presentation/screens/level1_shell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure = true;
  bool _isSignup = false;
  final _nameCtrl = TextEditingController();
  String _selectedRole = 'level1'; // 'admin' or 'level1'

  late AnimationController _bgCtrl;
  late AnimationController _cardCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))
      ..repeat(reverse: true);
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim  = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose(); _cardCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose(); _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) return;
    bool ok;
    if (_isSignup) {
      if (_nameCtrl.text.isEmpty) return;
      ok = await ref.read(authProvider.notifier).signup(
        _emailCtrl.text.trim(), _passCtrl.text.trim(),
        _nameCtrl.text.trim(), _selectedRole,
      );
    } else {
      ok = await ref.read(authProvider.notifier).login(
        _emailCtrl.text.trim(), _passCtrl.text.trim(),
      );
    }
    if (ok && mounted) {
      final user = ref.read(authProvider).user!;
      Widget dest = user.isAdmin ? const AdminShell() : const Level1Shell();
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (_, a, __) => dest,
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (_) => false,
      );
    }
  }

  void _fillDemo(String role) {
    if (role == 'admin') {
      _emailCtrl.text = 'admin@example.com';
      _passCtrl.text  = 'admin123';
    } else {
      _emailCtrl.text = 'level1@example.com';
      _passCtrl.text  = 'level1123';
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: Stack(
        children: [
          // Animated BG
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: const [Color(0xFF0F0F1A), Color(0xFF1A0A2E), Color(0xFF0D1B3E)],
                  begin: Alignment(-1 + _bgCtrl.value * 0.4, -1 + _bgCtrl.value * 0.3),
                  end: Alignment(1 - _bgCtrl.value * 0.2, 1 - _bgCtrl.value * 0.1),
                ),
              ),
            ),
          ),
          // Glow circles
          Positioned(top: -100, right: -80, child: _glowCircle(300, AppColors.primary, 0.18)),
          Positioned(bottom: -60, left: -60, child: _glowCircle(240, AppColors.secondary, 0.12)),
          Positioned(top: 200, left: -40, child: _glowCircle(180, AppColors.accent, 0.08)),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      children: [
                        _buildLogo(),
                        const SizedBox(height: 32),
                        _buildRoleSelector(),
                        const SizedBox(height: 20),
                        _buildCard(auth),
                        const SizedBox(height: 20),
                        _buildDemoSection(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle(double size, Color color, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color.withOpacity(opacity), Colors.transparent]),
    ),
  );

  Widget _buildLogo() => Column(
    children: [
      Container(
        width: 90, height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 35, spreadRadius: 2)],
        ),
        child: const Icon(Icons.mic_rounded, color: Colors.white, size: 44),
      ),
      const SizedBox(height: 16),
      const Text('Audio Dataset',
        style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      const SizedBox(height: 4),
      Text('Dataset Collection Platform',
        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
    ],
  );

  Widget _buildRoleSelector() => Container(
    padding: const EdgeInsets.all(5),
    decoration: BoxDecoration(
      color: AppColors.surfaceVariant,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        _roleTab('admin', 'Admin', Icons.admin_panel_settings_rounded, AppColors.adminGradient),
        _roleTab('level1', 'Level 1', Icons.person_rounded, AppColors.level1Gradient),
      ],
    ),
  );

  Widget _roleTab(String role, String label, IconData icon, List<Color> gradient) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedRole = role);
          if (!_isSignup) _fillDemo(role);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected ? [BoxShadow(color: gradient.first.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontWeight: FontWeight.w600, fontSize: 13,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(AuthState auth) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AppColors.border),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 50, offset: const Offset(0, 24))],
    ),
    padding: const EdgeInsets.all(28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_isSignup ? 'Create Account' : 'Welcome back',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(_isSignup ? 'Register as ${_selectedRole == 'admin' ? 'Admin' : 'Level 1 User'}' : 'Sign in to continue',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),

        if (auth.error != null) ...[
          _errorBox(auth.error!),
          const SizedBox(height: 16),
        ],

        if (_isSignup) ...[
          _buildInput(_nameCtrl, 'Full Name', Icons.person_outline_rounded),
          const SizedBox(height: 14),
        ],

        _buildInput(_emailCtrl, 'Email address', Icons.email_outlined, type: TextInputType.emailAddress),
        const SizedBox(height: 14),
        _buildPasswordField(),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: _buildSubmitButton(auth.isLoading),
        ),
        const SizedBox(height: 16),
        Center(
          child: GestureDetector(
            onTap: () {
              setState(() => _isSignup = !_isSignup);
              ref.read(authProvider.notifier).clearError();
            },
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  TextSpan(
                    text: _isSignup ? 'Already have an account? ' : "Don't have an account? ",
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                  TextSpan(
                    text: _isSignup ? 'Sign In' : 'Sign Up',
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _errorBox(String msg) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.error.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.error.withOpacity(0.3)),
    ),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: AppColors.error, fontSize: 13))),
      ],
    ),
  );

  Widget _buildInput(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? type}) =>
    TextField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: AppColors.textPrimary),
      onSubmitted: (_) => _submit(),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );

  Widget _buildPasswordField() => TextField(
    controller: _passCtrl,
    obscureText: _obscure,
    style: const TextStyle(color: AppColors.textPrimary),
    onSubmitted: (_) => _submit(),
    decoration: InputDecoration(
      labelText: 'Password',
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
      suffixIcon: IconButton(
        icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    ),
  );

  Widget _buildSubmitButton(bool isLoading) {
    final colors = _selectedRole == 'admin' ? AppColors.adminGradient : AppColors.level1Gradient;
    return GestureDetector(
      onTap: isLoading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 52,
        decoration: BoxDecoration(
          gradient: isLoading ? null : LinearGradient(colors: colors),
          color: isLoading ? AppColors.surfaceVariant : null,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isLoading ? null : [
            BoxShadow(color: colors.first.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: isLoading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(_isSignup ? 'Create Account' : 'Sign In',
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }

  Widget _buildDemoSection() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Colors.white.withOpacity(0.08)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.info_outline_rounded, size: 14, color: Colors.white.withOpacity(0.5)),
            const SizedBox(width: 6),
            Text('Demo Credentials',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontWeight: FontWeight.w600, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 10),
        _credTile('Admin', 'admin@example.com', 'admin123', AppColors.primary,
            () => _fillDemo('admin')),
        const SizedBox(height: 6),
        _credTile('Level 1', 'level1@example.com', 'level1123', AppColors.secondary,
            () => _fillDemo('level1')),
      ],
    ),
  );

  Widget _credTile(String role, String email, String pass, Color color, VoidCallback onTap) =>
    GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
              child: Text(role, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text('$email / $pass',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
            ),
            Icon(Icons.touch_app_rounded, size: 14, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
}
