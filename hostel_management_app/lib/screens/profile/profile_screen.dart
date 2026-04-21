import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../auth/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  static const routeName = '/profile';

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _hostelNameController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  String _uid = '';
  String _role = 'student';
  Stream<UserModel?> _profileStream = const Stream.empty();
  String _lastSyncedFingerprint = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final user = auth.currentUser;
    if (user == null) return;

    _uid = user.uid;
    _profileStream = firestore.streamUserProfile(_uid);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    _hostelNameController.dispose();
    super.dispose();
  }

  void _syncControllers(UserModel profile) {
    _role = profile.role;
    final fingerprint = [
      profile.name,
      profile.email,
      profile.phone,
      profile.parentPhone,
      profile.hostelName,
      profile.role,
    ].join('|');

    if (fingerprint == _lastSyncedFingerprint) return;
    _lastSyncedFingerprint = fingerprint;

    final activeFocus = FocusManager.instance.primaryFocus;
    final isEditing = activeFocus != null &&
        (activeFocus.context?.widget is EditableText);
    if (isEditing && _saving) return;

    _nameController.text = profile.name;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _parentPhoneController.text = profile.parentPhone;
    _hostelNameController.text = profile.hostelName;
  }

  String? _validateName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return 'Name is required';
    if (input.length < 2) return 'Enter valid name';
    return null;
  }

  String? _validatePhone(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) return null;
    final digits = RegExp(r'^\d{10,15}$');
    if (!digits.hasMatch(input)) return 'Enter valid phone number';
    return null;
  }

  Future<void> _updateProfile() async {
    if (_uid.isEmpty) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final firestore = context.read<FirestoreService>();
      await firestore.updateStudentSelfProfile(
        uid: _uid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final auth = context.read<AuthService>();
    await auth.logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      LoginScreen.routeName,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: _profileStream,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        if (snapshot.connectionState == ConnectionState.waiting && profile == null) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_uid.isEmpty) {
          return const Center(child: Text('Please login again'));
        }
        if (profile == null) {
          return const Center(child: Text('Profile not found'));
        }

        _syncControllers(profile);

        final isStudent = _role == 'student';

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: _validateName,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  enabled: false,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _parentPhoneController,
                  readOnly: true,
                  enabled: !isStudent,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: "Parent's Phone Number"),
                  validator: _validatePhone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hostelNameController,
                  readOnly: true,
                  enabled: !isStudent,
                  decoration: const InputDecoration(labelText: 'Hostel Name'),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _updateProfile,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Logout', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
