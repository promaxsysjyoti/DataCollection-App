import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/shared_widgets.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../../../auth/presentation/screens/login_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  // Controllers
  final _nameCtrl      = TextEditingController();
  final _ageCtrl       = TextEditingController();
  final _dobCtrl       = TextEditingController();
  final _phoneCtrl     = TextEditingController();
  final _addressCtrl   = TextEditingController();
  final _cityCtrl      = TextEditingController();
  final _stateCtrl     = TextEditingController();
  final _pincodeCtrl   = TextEditingController();
  final _aadharCtrl    = TextEditingController();
  final _panCtrl       = TextEditingController();
  final _bankNameCtrl  = TextEditingController();
  final _bankAccCtrl   = TextEditingController();
  final _bankIfscCtrl  = TextEditingController();
  final _bankBranchCtrl= TextEditingController();
  final _upiCtrl       = TextEditingController();
  String? _gender;
  bool _populated = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    Future.microtask(() => ref.read(profileProvider.notifier).load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose(); _ageCtrl.dispose(); _dobCtrl.dispose();
    _phoneCtrl.dispose(); _addressCtrl.dispose(); _cityCtrl.dispose();
    _stateCtrl.dispose(); _pincodeCtrl.dispose(); _aadharCtrl.dispose();
    _panCtrl.dispose(); _bankNameCtrl.dispose(); _bankAccCtrl.dispose();
    _bankIfscCtrl.dispose(); _bankBranchCtrl.dispose(); _upiCtrl.dispose();
    super.dispose();
  }

  void _populateFields(profile) {
    if (_populated) return;
    _populated = true;
    _nameCtrl.text      = profile.fullName;
    _ageCtrl.text       = profile.age?.toString() ?? '';
    _dobCtrl.text       = profile.dateOfBirth ?? '';
    _phoneCtrl.text     = profile.phone ?? '';
    _addressCtrl.text   = profile.address ?? '';
    _cityCtrl.text      = profile.city ?? '';
    _stateCtrl.text     = profile.state ?? '';
    _pincodeCtrl.text   = profile.pincode ?? '';
    _aadharCtrl.text    = profile.aadharNumber ?? '';
    _panCtrl.text       = profile.panNumber ?? '';
    _bankNameCtrl.text  = profile.bankName ?? '';
    _bankAccCtrl.text   = profile.bankAccountNumber ?? '';
    _bankIfscCtrl.text  = profile.bankIfsc ?? '';
    _bankBranchCtrl.text= profile.bankBranch ?? '';
    _upiCtrl.text       = profile.upiId ?? '';
    _gender             = profile.gender;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final auth    = ref.watch(authProvider);
    final profSt  = ref.watch(profileProvider);
    final profile = profSt.profile;

    if (profile != null) _populateFields(profile);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildProfileHeader(profile ?? auth.user),
            ),
            bottom: TabBar(
              controller: _tabCtrl,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textMuted,
              tabs: const [
                Tab(text: 'Personal'),
                Tab(text: 'KYC'),
                Tab(text: 'Bank'),
              ],
            ),
          ),
        ],
        body: profSt.isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabCtrl,
                children: [
                  _personalTab(),
                  _kycTab(),
                  _bankTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileHeader(user) {
    final name = user?.fullName ?? 'User';
    final role = user?.role ?? '';
    final balance = user?.walletBalance ?? 0.0;
    final initials = name.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();
    final gradColors = role == 'admin' ? AppColors.adminGradient : AppColors.level1Gradient;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
              ),
              child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800))),
            ),
            const SizedBox(height: 8),
            Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                  child: Text(role.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, letterSpacing: 1, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                  child: Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _personalTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        _sectionCard('Basic Information', [
          AppTextField(controller: _nameCtrl, label: 'Full Name', prefixIcon: Icons.person_outline_rounded),
          const SizedBox(height: 12),
          AppTextField(controller: _ageCtrl, label: 'Age', prefixIcon: Icons.cake_outlined, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          AppTextField(controller: _dobCtrl, label: 'Date of Birth (DD/MM/YYYY)', prefixIcon: Icons.calendar_today_rounded),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _gender,
            dropdownColor: AppColors.surfaceVariant,
            decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.wc_rounded, size: 20)),
            items: ['Male', 'Female', 'Other', 'Prefer not to say'].map((g) =>
              DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(color: AppColors.textPrimary)))).toList(),
            onChanged: (v) => setState(() => _gender = v),
          ),
          const SizedBox(height: 12),
          AppTextField(controller: _phoneCtrl, label: 'Phone Number', prefixIcon: Icons.phone_rounded, keyboardType: TextInputType.phone),
        ]),
        const SizedBox(height: 16),
        _sectionCard('Address', [
          AppTextField(controller: _addressCtrl, label: 'Address', prefixIcon: Icons.home_outlined, maxLines: 2),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: AppTextField(controller: _cityCtrl, label: 'City', prefixIcon: Icons.location_city_rounded)),
            const SizedBox(width: 10),
            Expanded(child: AppTextField(controller: _stateCtrl, label: 'State', prefixIcon: Icons.map_outlined)),
          ]),
          const SizedBox(height: 12),
          AppTextField(controller: _pincodeCtrl, label: 'Pincode', prefixIcon: Icons.pin_drop_rounded, keyboardType: TextInputType.number),
        ]),
        const SizedBox(height: 20),
        _saveButton(() => _saveAll()),
        const SizedBox(height: 12),
        _logoutBtn(),
      ],
    ),
  );

  Widget _kycTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.warning.withOpacity(0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.lock_outline_rounded, color: AppColors.warning, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('KYC details are kept private and used only for verification and payments.',
                  style: TextStyle(color: AppColors.warning, fontSize: 12))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _sectionCard('Identity Documents', [
          AppTextField(controller: _aadharCtrl, label: 'Aadhar Card Number', prefixIcon: Icons.credit_card_rounded, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          AppTextField(controller: _panCtrl, label: 'PAN Card Number', prefixIcon: Icons.article_rounded),
        ]),
        const SizedBox(height: 20),
        _saveButton(() => _saveAll()),
      ],
    ),
  );

  Widget _bankTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    child: Column(
      children: [
        _sectionCard('Bank Account Details', [
          AppTextField(controller: _bankNameCtrl, label: 'Bank Name', prefixIcon: Icons.account_balance_rounded),
          const SizedBox(height: 12),
          AppTextField(controller: _bankAccCtrl, label: 'Account Number', prefixIcon: Icons.pin_outlined, keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          AppTextField(controller: _bankIfscCtrl, label: 'IFSC Code', prefixIcon: Icons.code_rounded),
          const SizedBox(height: 12),
          AppTextField(controller: _bankBranchCtrl, label: 'Branch Name', prefixIcon: Icons.location_on_outlined),
        ]),
        const SizedBox(height: 16),
        _sectionCard('UPI', [
          AppTextField(controller: _upiCtrl, label: 'UPI ID', prefixIcon: Icons.phone_android_rounded),
        ]),
        const SizedBox(height: 20),
        _saveButton(() => _saveAll()),
      ],
    ),
  );

  Widget _sectionCard(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.cardBg,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        const SizedBox(height: 14),
        ...children,
      ],
    ),
  );

  Widget _saveButton(VoidCallback onSave) {
    final profSt = ref.watch(profileProvider);
    return SizedBox(
      width: double.infinity,
      child: GradientButton(label: 'Save Changes', icon: Icons.save_rounded, isLoading: profSt.isSaving, onPressed: onSave),
    );
  }

  Widget _logoutBtn() => SizedBox(
    width: double.infinity,
    child: GestureDetector(
      onTap: () async {
        await ref.read(authProvider.notifier).logout();
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
          );
        }
      },
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.error.withOpacity(0.3)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error, size: 20),
            SizedBox(width: 8),
            Text('Logout', style: TextStyle(color: AppColors.error, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    ),
  );

  Future<void> _saveAll() async {
    final data = <String, dynamic>{
      'full_name': _nameCtrl.text.trim(),
      if (_ageCtrl.text.isNotEmpty) 'age': int.tryParse(_ageCtrl.text),
      if (_dobCtrl.text.isNotEmpty) 'date_of_birth': _dobCtrl.text.trim(),
      if (_gender != null) 'gender': _gender,
      if (_phoneCtrl.text.isNotEmpty) 'phone': _phoneCtrl.text.trim(),
      if (_addressCtrl.text.isNotEmpty) 'address': _addressCtrl.text.trim(),
      if (_cityCtrl.text.isNotEmpty) 'city': _cityCtrl.text.trim(),
      if (_stateCtrl.text.isNotEmpty) 'state': _stateCtrl.text.trim(),
      if (_pincodeCtrl.text.isNotEmpty) 'pincode': _pincodeCtrl.text.trim(),
      if (_aadharCtrl.text.isNotEmpty) 'aadhar_number': _aadharCtrl.text.trim(),
      if (_panCtrl.text.isNotEmpty) 'pan_number': _panCtrl.text.trim(),
      if (_bankNameCtrl.text.isNotEmpty) 'bank_name': _bankNameCtrl.text.trim(),
      if (_bankAccCtrl.text.isNotEmpty) 'bank_account_number': _bankAccCtrl.text.trim(),
      if (_bankIfscCtrl.text.isNotEmpty) 'bank_ifsc': _bankIfscCtrl.text.trim(),
      if (_bankBranchCtrl.text.isNotEmpty) 'bank_branch': _bankBranchCtrl.text.trim(),
      if (_upiCtrl.text.isNotEmpty) 'upi_id': _upiCtrl.text.trim(),
    };
    final ok = await ref.read(profileProvider.notifier).update(data);
    if (ok && mounted) showSuccessSnack(context, 'Profile saved!');
    else if (mounted) showErrorSnack(context, 'Failed to save profile');
  }
}
