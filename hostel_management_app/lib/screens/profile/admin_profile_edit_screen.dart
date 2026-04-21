import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../services/firestore_service.dart';

class AdminProfileEditScreen extends StatefulWidget {
  static const routeName = '/admin-profile-edit';

  final String studentUid;

  const AdminProfileEditScreen({
    super.key,
    required this.studentUid,
  });

  @override
  State<AdminProfileEditScreen> createState() => _AdminProfileEditScreenState();
}

class _AdminProfileEditScreenState extends State<AdminProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _hostelNameController = TextEditingController();

  bool _initialized = false;
  bool _saving = false;
  Stream<UserModel?> _profileStream = const Stream.empty();
  String _lastSyncedFingerprint = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;

    Future<void>.microtask(() {
      final firestore = context.read<FirestoreService>();
      _profileStream = firestore.streamUserProfile(widget.studentUid);
      if (mounted) setState(() {});
    });
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
    final fingerprint = [
      profile.name,
      profile.email,
      profile.phone,
      profile.parentPhone,
      profile.hostelName,
    ].join('|');

    if (_lastSyncedFingerprint == fingerprint) return;
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

  Future<void> _update() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final firestore = context.read<FirestoreService>();
      await firestore.updateAdminEditableStudentProfile(
        studentUid: widget.studentUid,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        hostelName: _hostelNameController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Student profile updated')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Student Profile')),
      body: StreamBuilder<UserModel?>(
        stream: _profileStream,
        builder: (context, snapshot) {
          final profile = snapshot.data;
          if (snapshot.connectionState == ConnectionState.waiting && profile == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (profile == null) {
            return const Center(child: Text('Student profile not found'));
          }

          _syncControllers(profile);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: "Parent's Phone Number"),
                    validator: _validatePhone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _hostelNameController,
                    decoration: const InputDecoration(labelText: 'Hostel Name'),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _update,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Update'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
