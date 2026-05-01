import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseDataService _dataService = FirebaseDataService.instance;
  final ImagePicker _imagePicker = ImagePicker();
  UserProfile? _profile;
  bool _loading = true;
  bool _pickingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _dataService.getCurrentUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    if (_profile == null) {
      return const Scaffold(
        body: Center(child: Text('Không tìm thấy hồ sơ')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildStatsRow(),
            _buildMenuSection(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final profile = _profile!;
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Hồ sơ của tôi',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
                    onPressed: _showEditProfile,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: GestureDetector(
                  onTap: _pickAvatar,
                  child: Transform.scale(
                    scale: 1.18,
                    child: _buildAvatarImage(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                profile.name,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(profile.email, style: const TextStyle(color: AppColors.primaryLight, fontSize: 13)),
              if (profile.university.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school_outlined, color: AppColors.primaryLight, size: 14),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        profile.university,
                        style: const TextStyle(color: AppColors.primaryLight, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ...List.generate(5, (i) {
                    return Icon(
                      i < profile.rating.floor()
                          ? Icons.star
                          : (i < profile.rating ? Icons.star_half : Icons.star_border),
                      color: AppColors.amber,
                      size: 18,
                    );
                  }),
                  const SizedBox(width: 6),
                  Text('${profile.rating}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    final profile = _profile!;
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Row(
          children: [
            _statItem('${profile.totalPurchases}', 'Đã mua', Icons.shopping_bag_outlined, AppColors.primary),
            _divider(),
            _statItem('${profile.totalSales}', 'Đã bán', Icons.sell_outlined, AppColors.blue),
            _divider(),
            _statItem(Formatter.joinDate(profile.joinDate), 'Ngày tham gia', Icons.calendar_today_outlined, AppColors.amber),
          ],
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textGray), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 48, color: Colors.grey[200]);
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _menuGroup('Tài khoản', [
            _MenuItem(icon: Icons.person_outline, label: 'Thông tin cá nhân', onTap: _showEditProfile),
            _MenuItem(icon: Icons.phone_outlined, label: _profile!.phone, subtitle: 'Số điện thoại', onTap: () {}),
            _MenuItem(icon: Icons.lock_outline, label: 'Đổi mật khẩu', onTap: () {}),
          ]),
          const SizedBox(height: 12),
          _menuGroup('Hoạt động', [
            _MenuItem(icon: Icons.history_outlined, label: 'Lịch sử mua hàng', badge: '${_profile!.totalPurchases}', onTap: () {}),
            _MenuItem(icon: Icons.store_outlined, label: 'Sản phẩm đang bán', badge: '${_profile!.totalSales}', onTap: () {}),
            _MenuItem(icon: Icons.favorite_outline, label: 'Yêu thích', onTap: () {}),
          ]),
          const SizedBox(height: 12),
          _menuGroup('Hỗ trợ', [
            _MenuItem(icon: Icons.help_outline, label: 'Trung tâm hỗ trợ', onTap: () {}),
            _MenuItem(icon: Icons.info_outline, label: 'Về EduShare', onTap: () {}),
            _MenuItem(icon: Icons.logout, label: 'Đăng xuất', color: AppColors.red, onTap: _confirmLogout),
          ]),
        ],
      ),
    );
  }

  Widget _menuGroup(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textGray)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
            ],
          ),
          child: Column(
            children: List.generate(items.length, (i) {
              final item = items[i];
              return Column(
                children: [
                  ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (item.color ?? AppColors.primary).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.color ?? AppColors.primary, size: 18),
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: item.color ?? AppColors.textDark),
                    ),
                    subtitle: item.subtitle != null
                        ? Text(item.subtitle!, style: const TextStyle(fontSize: 11, color: AppColors.textGray))
                        : null,
                    trailing: item.badge != null
                        ? Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              item.badge!,
                              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          )
                        : const Icon(Icons.chevron_right, color: AppColors.textGray, size: 18),
                    onTap: item.onTap,
                    dense: true,
                  ),
                  if (i < items.length - 1) const Divider(height: 1, indent: 60, color: Color(0xFFF1F5F9)),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: _profile!.name);
    final phoneCtrl = TextEditingController(text: _profile!.phone);
    final uniCtrl = TextEditingController(text: _profile!.university);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Chỉnh sửa hồ sơ', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              _editField('Họ và tên', nameCtrl, Icons.person_outline),
              const SizedBox(height: 12),
              _editField('Số điện thoại', phoneCtrl, Icons.phone_outlined, type: TextInputType.phone),
              const SizedBox(height: 12),
              _editField('Trường đại học', uniCtrl, Icons.school_outlined),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    _profile!.name = nameCtrl.text;
                    _profile!.phone = phoneCtrl.text;
                    _profile!.university = uniCtrl.text;
                    await _dataService.updateUserProfile(_profile!);
                    if (mounted) {
                      setState(() {});
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Lưu thay đổi', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _editField(String label, TextEditingController ctrl, IconData icon, {TextInputType? type}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
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

  Widget _buildAvatarImage() {
    if (_profile?.hasCustomAvatar == true) {
      return Image.memory(
        base64Decode(_profile!.avatarBase64!),
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }

    return Image.asset(
      'assets/images/avatar.png',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
    );
  }

  Future<void> _pickAvatar() async {
    if (_profile == null || _pickingAvatar) return;

    _pickingAvatar = true;
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 35,
        maxWidth: 512,
        maxHeight: 512,
      );
      if (picked == null) return;

      final encoded = base64Encode(await picked.readAsBytes());
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

      _profile!.avatarBase64 = encoded;
      await _dataService.updateUserProfile(_profile!);
      if (!mounted) return;
      setState(() {});
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

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất không?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthProvider>().logout();
            },
            child: const Text('Đăng xuất', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? badge;
  final Color? color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.badge,
    this.color,
    required this.onTap,
  });
}
