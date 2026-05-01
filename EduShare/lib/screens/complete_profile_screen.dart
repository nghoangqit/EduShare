import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_profile.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';

class CompleteProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final VoidCallback onCompleted;

  const CompleteProfileScreen({
    super.key,
    required this.profile,
    required this.onCompleted,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dataService = FirebaseDataService.instance;
  final _imagePicker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _universityCtrl;
  bool _saving = false;
  bool _pickingAvatar = false;
  String? _avatarBase64;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: widget.profile.name.trim().toLowerCase() == 'nguoi dung edushare'
          ? ''
          : widget.profile.name,
    );
    _phoneCtrl = TextEditingController(text: widget.profile.phone);
    _universityCtrl = TextEditingController(text: widget.profile.university);
    _avatarBase64 = widget.profile.avatarBase64;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _universityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: _buildAvatarPicker()),
                  const SizedBox(height: 20),
                  const Text(
                    'Hoan thien thong tin ca nhan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Can nhap du thong tin truoc khi su dung EduShare.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textGray, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField(
                            controller: _nameCtrl,
                            label: 'Ho va ten',
                            hint: 'Nhap ho va ten',
                            icon: Icons.person_outline,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui long nhap ho va ten';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _phoneCtrl,
                            label: 'So dien thoai',
                            hint: 'Nhap so dien thoai',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui long nhap so dien thoai';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _universityCtrl,
                            label: 'Truong hoc',
                            hint: 'Nhap truong hoc',
                            icon: Icons.school_outlined,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Vui long nhap truong hoc';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Text(
                                      'Luu thong tin',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildAvatarPicker() {
    return GestureDetector(
      onTap: _pickAvatar,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: _avatarBase64 != null && _avatarBase64!.isNotEmpty
                ? Image.memory(base64Decode(_avatarBase64!), fit: BoxFit.cover)
                : Image.asset('assets/images/avatar.png', fit: BoxFit.cover),
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    widget.profile.name = _nameCtrl.text.trim();
    widget.profile.phone = _phoneCtrl.text.trim();
    widget.profile.university = _universityCtrl.text.trim();
    widget.profile.avatarBase64 = _avatarBase64;

    await _dataService.updateUserProfile(widget.profile);

    if (!mounted) return;
    setState(() => _saving = false);
    widget.onCompleted();
  }

  Future<void> _pickAvatar() async {
    if (_pickingAvatar) return;

    _pickingAvatar = true;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 35,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      final encoded = base64Encode(bytes);

      if (encoded.length > 800000) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anh qua lon, vui long chon anh nho hon.'),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }

      setState(() {
        _avatarBase64 = encoded;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      if (error.code == 'already_active') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trinh chon anh dang mo, vui long cho mot chut.'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      _pickingAvatar = false;
    }
  }
}
