import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:isar/isar.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/premium_text_field.dart';
import '../auth/auth_provider.dart';
import '../../services/firestore_service.dart';
import '../../database/isar_database.dart';
import '../../database/schemas/meeting_models.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _bioController;
  late TextEditingController _companyController;
  late TextEditingController _designationController;

  bool _isEditing = false;
  bool _isLoading = false;
  String? _photoUrl;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authStateProvider).user;

    _nameController = TextEditingController(text: user?.displayName ?? '');
    _phoneController = TextEditingController(text: user?.phoneNumber ?? '');
    _bioController = TextEditingController(text: user?.bio ?? '');
    _companyController = TextEditingController(text: user?.company ?? '');
    _designationController = TextEditingController(
      text: user?.designation ?? '',
    );
    _photoUrl = user?.photoUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _companyController.dispose();
    _designationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = ref.read(authStateProvider).user;
      if (user == null || user.uid == null) throw Exception('No user found');

      String? newPhotoUrl = _photoUrl;

      // 1. Upload photo to Firebase Storage if selected
      if (_selectedImage != null) {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profiles')
            .child('${user.uid}.jpg');

        final uploadTask = await storageRef.putFile(_selectedImage!);
        newPhotoUrl = await uploadTask.ref.getDownloadURL();
      }

      // 2. Sync to Firestore
      final profileData = {
        'displayName': _nameController.text.trim(),
        'photoUrl': newPhotoUrl ?? '',
        'phoneNumber': _phoneController.text.trim(),
        'bio': _bioController.text.trim(),
        'company': _companyController.text.trim(),
        'designation': _designationController.text.trim(),
        'lastSynced': DateTime.now().toIso8601String(),
      };

      await FirestoreService.instance.saveUserProfile(user.uid!, profileData);

      // 3. Sync to local Isar
      final isar = IsarDatabase.instance.isar;
      final localUser = await isar.userModels
          .filter()
          .uidEqualTo(user.uid)
          .findFirst();
      if (localUser != null) {
        await isar.writeTxn(() async {
          localUser.displayName = _nameController.text.trim();
          localUser.photoUrl = newPhotoUrl;
          localUser.phoneNumber = _phoneController.text.trim();
          localUser.bio = _bioController.text.trim();
          localUser.company = _companyController.text.trim();
          localUser.designation = _designationController.text.trim();
          localUser.lastSynced = DateTime.now();
          await isar.userModels.put(localUser);
        });

        // 4. Force state notifier reload to update UI globally
        ref.read(authStateProvider.notifier).updateUser(localUser);
      }

      setState(() {
        _photoUrl = newPhotoUrl;
        _selectedImage = null;
        _isEditing = false;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Profile Saved Successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Save Failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: AppColors.secondary),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
              onPressed: () {
                setState(() {
                  _selectedImage = null;
                  _isEditing = false;
                  // Restore initial controller values
                  _nameController.text = user?.displayName ?? '';
                  _phoneController.text = user?.phoneNumber ?? '';
                  _bioController.text = user?.bio ?? '';
                  _companyController.text = user?.company ?? '';
                  _designationController.text = user?.designation ?? '';
                });
              },
            ),
        ],
      ),
      body: FuturisticBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Avatar Display
                        Center(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: _pickImage,
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isEditing
                                          ? AppColors.secondary
                                          : Colors.white10,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 60,
                                    backgroundColor: AppColors.surface,
                                    backgroundImage: _selectedImage != null
                                        ? FileImage(_selectedImage!)
                                              as ImageProvider
                                        : (_photoUrl != null &&
                                                  _photoUrl!.isNotEmpty
                                              ? NetworkImage(_photoUrl!)
                                              : null),
                                    child:
                                        (_selectedImage == null &&
                                            (_photoUrl == null ||
                                                _photoUrl!.isEmpty))
                                        ? Text(
                                            (user?.displayName ?? 'U')[0]
                                                .toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 48,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              if (_isEditing)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Profile Form Fields Card
                        GlassCard(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Name field
                              PremiumTextField(
                                controller: _nameController,
                                hintText: 'Full Name',
                                readOnly: !_isEditing,
                                prefixIcon: Icons.person_outline_rounded,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Name is required';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Email field (read-only in firebase)
                              PremiumTextField(
                                controller: TextEditingController(
                                  text: user?.email ?? '',
                                ),
                                hintText: 'Email address',
                                readOnly: true,
                                prefixIcon: Icons.email_outlined,
                              ),
                              const SizedBox(height: 16),

                              // Phone field
                              PremiumTextField(
                                controller: _phoneController,
                                hintText: 'Phone Number',
                                readOnly: !_isEditing,
                                keyboardType: TextInputType.phone,
                                prefixIcon: Icons.phone_outlined,
                              ),
                              const SizedBox(height: 16),

                              // Bio field
                              PremiumTextField(
                                controller: _bioController,
                                hintText: 'Bio',
                                maxLines: 3,
                                readOnly: !_isEditing,
                                prefixIcon: Icons.info_outline_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Work Information Card
                        GlassCard(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Work details',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Company
                              PremiumTextField(
                                controller: _companyController,
                                hintText: 'Company',
                                readOnly: !_isEditing,
                                prefixIcon: Icons.business_outlined,
                              ),
                              const SizedBox(height: 16),

                              // Designation
                              PremiumTextField(
                                controller: _designationController,
                                hintText: 'Designation',
                                readOnly: !_isEditing,
                                prefixIcon: Icons.work_outline_rounded,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Action Buttons
                        if (_isEditing) ...[
                          GradientButton(
                            onPressed: _saveProfile,
                            child: const Text('Save Profile'),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Colors.white10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              setState(() {
                                _selectedImage = null;
                                _isEditing = false;
                                _nameController.text = user?.displayName ?? '';
                                _phoneController.text = user?.phoneNumber ?? '';
                                _bioController.text = user?.bio ?? '';
                                _companyController.text = user?.company ?? '';
                                _designationController.text =
                                    user?.designation ?? '';
                              });
                            },
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
