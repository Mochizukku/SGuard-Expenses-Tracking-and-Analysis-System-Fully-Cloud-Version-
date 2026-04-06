import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../data/services/app_settings_controller.dart';
import '../../../data/services/record_book_store.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    IconData icon,
    String subtitle,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          color: const Color(0xFF004AAD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 96,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF2C69C8)),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Settings',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    children: [
                      _buildRow(
                        context,
                        'Profile',
                        Icons.person_outline,
                        'Edit your name, status, and profile image.',
                        () => _open(context, const SettingsProfilePage()),
                      ),
                      _buildRow(
                        context,
                        'Account',
                        Icons.lock_outline,
                        'Change your password or send a reset email.',
                        () => _open(context, const SettingsAccountPage()),
                      ),
                      _buildRow(
                        context,
                        'Tracking System',
                        Icons.track_changes_outlined,
                        'Manage local history, reset behavior, and date badges.',
                        () => _open(context, const SettingsTrackingPage()),
                      ),
                      _buildRow(
                        context,
                        'Record Template',
                        Icons.library_books_outlined,
                        'Set the category template that will apply on the next new day.',
                        () => _open(context, const SettingsRecordTemplatePage()),
                      ),
                      _buildRow(
                        context,
                        'Personalization',
                        Icons.palette_outlined,
                        'Theme, text size, accent color, and other preferences.',
                        () => _open(context, const SettingsPersonalizationPage()),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsScaffold extends StatelessWidget {
  const _SettingsScaffold({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: const Color(0xFF004AAD),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [child],
      ),
    );
  }
}

class SettingsProfilePage extends StatefulWidget {
  const SettingsProfilePage({super.key});

  @override
  State<SettingsProfilePage> createState() => _SettingsProfilePageState();
}

class _SettingsProfilePageState extends State<SettingsProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _customStatusController;
  final _picker = ImagePicker();
  late String _avatarKey;
  late String _statusPreset;
  String _avatarImagePath = '';
  bool _isSaving = false;
  bool _isPickingImage = false;

  static const _statusOptions = [
    'Student',
    'Employee',
    'Businessman',
    'Teacher',
    'Custom',
  ];

  static const _avatarChoices = <String, ({IconData icon, Color color, String label})>{
    'classic_blue': (icon: Icons.person, color: Color(0xFF004AAD), label: 'Classic Blue'),
    'green_guard': (icon: Icons.shield_outlined, color: Color(0xFF147D64), label: 'Green Guard'),
    'sunrise_star': (icon: Icons.star_border, color: Color(0xFFC05621), label: 'Sunrise Star'),
    'violet_face': (icon: Icons.sentiment_satisfied_alt, color: Color(0xFF6B46C1), label: 'Violet Face'),
  };

  @override
  void initState() {
    super.initState();
    final settings = AppSettingsController.instance.settings.value.profile;
    final user = FirebaseAuth.instance.currentUser;
    _nameController =
        TextEditingController(text: settings.displayName.isNotEmpty ? settings.displayName : (user?.displayName ?? ''));
    _customStatusController = TextEditingController(text: settings.customStatus);
    _avatarKey = settings.avatarKey;
    _statusPreset = settings.statusPreset;
    _avatarImagePath = settings.avatarImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customStatusController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    setState(() => _isPickingImage = true);
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1200,
      );
      if (picked == null || !mounted) {
        return;
      }
      setState(() => _avatarImagePath = picked.path);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to pick image: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);
    final user = FirebaseAuth.instance.currentUser;

    try {
      if (user != null && _nameController.text.trim().isNotEmpty) {
        await user.updateDisplayName(_nameController.text.trim());
      }

      final current = AppSettingsController.instance.settings.value.profile;
      await AppSettingsController.instance.updateProfile(
        current.copyWith(
          displayName: _nameController.text.trim(),
          statusPreset: _statusPreset,
          customStatus: _customStatusController.text.trim(),
          avatarKey: _avatarKey,
          avatarImagePath: _avatarImagePath,
        ),
      );

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile settings updated.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save profile: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildAvatarChoice(String key, ({IconData icon, Color color, String label}) avatar) {
    final isSelected = _avatarKey == key && _avatarImagePath.trim().isEmpty;
    return InkWell(
      onTap: () => setState(() {
        _avatarKey = key;
        _avatarImagePath = '';
      }),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? avatar.color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: avatar.color.withValues(alpha: 0.15),
              child: Icon(avatar.icon, color: avatar.color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              avatar.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPreview() {
    final imagePath = _avatarImagePath.trim();
    if (imagePath.isNotEmpty && File(imagePath).existsSync()) {
      return CircleAvatar(
        radius: 36,
        backgroundImage: FileImage(File(imagePath)),
      );
    }

    final avatar = _avatarChoices[_avatarKey] ?? _avatarChoices['classic_blue']!;
    return CircleAvatar(
      radius: 36,
      backgroundColor: avatar.color.withValues(alpha: 0.15),
      child: Icon(avatar.icon, color: avatar.color, size: 36),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Profile',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Profile Image', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildAvatarPreview(),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _isPickingImage
                                  ? null
                                  : () => _pickProfileImage(ImageSource.gallery),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Choose from Gallery'),
                            ),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _isPickingImage
                                  ? null
                                  : () => _pickProfileImage(ImageSource.camera),
                              icon: const Icon(Icons.photo_camera_outlined),
                              label: const Text('Take Photo'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: _avatarChoices.entries
                      .map((entry) => _buildAvatarChoice(entry.key, entry.value))
                      .toList(),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _statusPreset,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.school_outlined),
                  ),
                  items: _statusOptions
                      .map((status) => DropdownMenuItem<String>(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _statusPreset = value);
                    }
                  },
                ),
                if (_statusPreset == 'Custom') ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customStatusController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Status',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit_note_outlined),
                    ),
                    validator: (value) {
                      if (_statusPreset == 'Custom' &&
                          (value == null || value.trim().isEmpty)) {
                        return 'Enter a custom status';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  _statusPreset == 'Custom'
                      ? 'Your typed custom status will appear on the profile page.'
                      : 'Selected status will appear on the profile page.',
                  style: const TextStyle(color: Color(0xFF4A6078), fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isSaving ? null : _saveProfile,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_isSaving ? 'Saving...' : 'Save Profile'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsAccountPage extends StatefulWidget {
  const SettingsAccountPage({super.key});

  @override
  State<SettingsAccountPage> createState() => _SettingsAccountPageState();
}

class _SettingsAccountPageState extends State<SettingsAccountPage> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isUpdating = false;
  bool _isSendingReset = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (user == null || email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in first to change your password.')),
      );
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match.')),
      );
      return;
    }
    if (_newPasswordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New password must be at least 6 characters.')),
      );
      return;
    }

    setState(() => _isUpdating = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: _currentPasswordController.text,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully.')),
      );
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to change password.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  Future<void> _sendResetEmail() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No account email is available.')),
      );
      return;
    }

    setState(() => _isSendingReset = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password reset email sent to $email')),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Unable to send reset email.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingReset = false);
      }
    }
  }

  Widget _buildAccountHero(User? user) {
    final email = user?.email ?? 'Not signed in';
    final firstLetter = email.isNotEmpty ? email[0].toUpperCase() : 'S';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004AAD), Color(0xFF2B74D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withValues(alpha: 0.18),
            child: Text(
              firstLetter,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Security',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: const TextStyle(color: Color(0xFFE8F0FF), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD8E4F3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF16304B)),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Color(0xFF4A6078), fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return _SettingsScaffold(
      title: 'Account',
      child: Column(
        children: [
          _buildAccountHero(user),
          _buildSectionCard(
            title: 'Password',
            subtitle: 'Update your password with your current credentials.',
            child: Column(
              children: [
                TextField(
                  controller: _currentPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_clock_outlined),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _confirmPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _isUpdating ? null : _changePassword,
                    icon: const Icon(Icons.password_outlined),
                    label: Text(_isUpdating ? 'Updating...' : 'Change Password'),
                  ),
                ),
              ],
            ),
          ),
          _buildSectionCard(
            title: 'Recovery',
            subtitle: 'Send a reset email in case you need to recover access later.',
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isSendingReset ? null : _sendResetEmail,
                icon: const Icon(Icons.email_outlined),
                label: Text(_isSendingReset ? 'Sending...' : 'Send Reset Email'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsRecordTemplatePage extends StatefulWidget {
  const SettingsRecordTemplatePage({super.key});

  @override
  State<SettingsRecordTemplatePage> createState() =>
      _SettingsRecordTemplatePageState();
}

class _SettingsRecordTemplatePageState extends State<SettingsRecordTemplatePage> {
  late List<String> _categoryNames;

  @override
  void initState() {
    super.initState();
    _categoryNames = List<String>.from(
      AppSettingsController.instance.settings.value.recordTemplate.categoryNames,
    );
  }

  Future<void> _persist() async {
    final cleaned = _categoryNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList();
    if (cleaned.isEmpty) {
      cleaned.addAll(['Billing', 'Food', 'Others']);
    }
    setState(() => _categoryNames = cleaned);
    await AppSettingsController.instance.updateRecordTemplate(
      RecordBookTemplateSettings(categoryNames: cleaned),
    );
  }

  Future<void> _showCategoryDialog({int? index}) async {
    final controller = TextEditingController(
      text: index != null ? _categoryNames[index] : '',
    );
    final isEditing = index != null;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(isEditing ? 'Edit Template Category' : 'Add Template Category'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Category name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final value = controller.text.trim();
                if (value.isEmpty) {
                  return;
                }
                setState(() {
                  if (isEditing) {
                    _categoryNames[index] = value;
                  } else {
                    _categoryNames.add(value);
                  }
                });
                await _persist();
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Record Template',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Template Categories',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(
                'Changes here do not affect the current day. They apply the next time a new day is created and stay in effect until you change them again.',
                style: TextStyle(color: Color(0xFF4A6078), fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ..._categoryNames.asMap().entries.map((entry) {
                final index = entry.key;
                final name = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD6E2F4)),
                  ),
                  child: ListTile(
                    title: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    trailing: Wrap(
                      spacing: 4,
                      children: [
                        IconButton(
                          onPressed: () => _showCategoryDialog(index: index),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                        IconButton(
                          onPressed: () async {
                            setState(() => _categoryNames.removeAt(index));
                            await _persist();
                          },
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _showCategoryDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Template Category'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsTrackingPage extends StatefulWidget {
  const SettingsTrackingPage({super.key});

  @override
  State<SettingsTrackingPage> createState() => _SettingsTrackingPageState();
}

class _SettingsTrackingPageState extends State<SettingsTrackingPage> {
  String? _lastSync;
  late TrackingSettings _tracking;

  @override
  void initState() {
    super.initState();
    _tracking = AppSettingsController.instance.settings.value.tracking;
    _loadSync();
  }

  Future<void> _loadSync() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() => _lastSync = prefs.getString('last_sync_time'));
  }

  Future<void> _updateTracking(TrackingSettings next) async {
    setState(() => _tracking = next);
    await AppSettingsController.instance.updateTracking(next);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Tracking System',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Current active date: ${RecordBookStore.dateKeyFromDate(DateTime.now())}'),
              const SizedBox(height: 8),
              Text('Last cloud save: ${_lastSync ?? 'No cloud save recorded yet'}'),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _tracking.autoSaveHistoryCache,
                onChanged: (value) => _updateTracking(_tracking.copyWith(autoSaveHistoryCache: value)),
                secondary: const Icon(Icons.save_as_outlined),
                title: const Text('Auto-save local history cache'),
                subtitle: const Text('Keep dated records ready for analysis and offline history views.'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _tracking.cloudSyncReminder,
                onChanged: (value) => _updateTracking(_tracking.copyWith(cloudSyncReminder: value)),
                secondary: const Icon(Icons.cloud_sync_outlined),
                title: const Text('Cloud sync reminder'),
                subtitle: const Text('Keep save-to-cloud nudges enabled on profile workflows.'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _tracking.openLastActiveDate,
                onChanged: (value) => _updateTracking(_tracking.copyWith(openLastActiveDate: value)),
                secondary: const Icon(Icons.history_toggle_off_outlined),
                title: const Text('Prefer last active date'),
                subtitle: const Text('Reserve the last working date locally when available.'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _tracking.confirmResetSensitiveActions,
                onChanged: (value) => _updateTracking(_tracking.copyWith(confirmResetSensitiveActions: value)),
                secondary: const Icon(Icons.warning_amber_outlined),
                title: const Text('Confirm reset-sensitive actions'),
                subtitle: const Text('Show stronger confirmation prompts around reset-adjacent flows.'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _tracking.showActiveDateBadge,
                onChanged: (value) => _updateTracking(_tracking.copyWith(showActiveDateBadge: value)),
                secondary: const Icon(Icons.date_range_outlined),
                title: const Text('Show active date badge'),
                subtitle: const Text('Keep the active record date visible on supported screens.'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsPersonalizationPage extends StatefulWidget {
  const SettingsPersonalizationPage({super.key});

  @override
  State<SettingsPersonalizationPage> createState() => _SettingsPersonalizationPageState();
}

class _SettingsPersonalizationPageState extends State<SettingsPersonalizationPage> {
  late PersonalizationSettings _settings;

  @override
  void initState() {
    super.initState();
    _settings = AppSettingsController.instance.settings.value.personalization;
  }

  Future<void> _update(PersonalizationSettings next) async {
    setState(() => _settings = next);
    await AppSettingsController.instance.updatePersonalization(next);
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScaffold(
      title: 'Personalization',
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<ThemeMode>(
                value: _settings.themeMode,
                decoration: const InputDecoration(
                  labelText: 'Theme Mode',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.dark_mode_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: ThemeMode.system, child: Text('Use system theme')),
                  DropdownMenuItem(value: ThemeMode.light, child: Text('Light mode')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark mode')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _update(_settings.copyWith(themeMode: value));
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _settings.accentColorKey,
                decoration: const InputDecoration(
                  labelText: 'Accent Color',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.color_lens_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 'blue', child: Text('Classic Blue')),
                  DropdownMenuItem(value: 'emerald', child: Text('Emerald')),
                  DropdownMenuItem(value: 'sunset', child: Text('Sunset')),
                  DropdownMenuItem(value: 'slate', child: Text('Slate')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _update(_settings.copyWith(accentColorKey: value));
                  }
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _settings.startPageIndex,
                decoration: const InputDecoration(
                  labelText: 'Start Page',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.home_outlined),
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Home')),
                  DropdownMenuItem(value: 1, child: Text('Record Book')),
                  DropdownMenuItem(value: 2, child: Text('Analysis')),
                  DropdownMenuItem(value: 3, child: Text('Profile')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _update(_settings.copyWith(startPageIndex: value));
                  }
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _settings.compactCards,
                onChanged: (value) => _update(_settings.copyWith(compactCards: value)),
                secondary: const Icon(Icons.dashboard_customize_outlined),
                title: const Text('Compact cards'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _settings.showQuickHints,
                onChanged: (value) => _update(_settings.copyWith(showQuickHints: value)),
                secondary: const Icon(Icons.lightbulb_outline),
                title: const Text('Show quick hints'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _settings.largeText,
                onChanged: (value) => _update(_settings.copyWith(largeText: value)),
                secondary: const Icon(Icons.format_size_outlined),
                title: const Text('Larger text mode'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _settings.reduceMotion,
                onChanged: (value) => _update(_settings.copyWith(reduceMotion: value)),
                secondary: const Icon(Icons.animation_outlined),
                title: const Text('Reduce motion'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _settings.showCurrencySymbol,
                onChanged: (value) => _update(_settings.copyWith(showCurrencySymbol: value)),
                secondary: const Icon(Icons.attach_money_outlined),
                title: const Text('Show currency symbol'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
