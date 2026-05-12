import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _originalPriceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  final _dataService = FirebaseDataService.instance;
  final _auth = FirebaseAuth.instance;
  final _imagePicker = ImagePicker();

  String _selectedType = 'sach';
  String _selectedCategory = 'Toan - Tin';
  String _selectedCondition = 'Nhu moi';
  String? _selectedImageDataUrl;
  bool _imageValidationError = false;
  bool _imagePicking = false;
  bool _isFree = false;
  bool _isFeatured = false;
  bool _saving = false;

  final List<Map<String, String>> _types = const [
    {'value': 'sach', 'label': 'Sach', 'emoji': '📚'},
    {'value': 'may_tinh', 'label': 'Thiet bi', 'emoji': '🧮'},
    {'value': 've', 'label': 'Ve - My thuat', 'emoji': '🎨'},
    {'value': 'dung_cu', 'label': 'Dung cu', 'emoji': '✂️'},
  ];

  final List<String> _categories = const [
    'Toan - Tin',
    'Van hoc',
    'Khoa hoc',
    'Kinh te',
    'Ngoai ngu',
    'Ve - My thuat',
    'May tinh',
    'Dung cu',
  ];

  final List<String> _conditions = const ['Nhu moi', 'Tot', 'Trung binh'];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _originalPriceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Dang san pham', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreviewCard(),
              const SizedBox(height: 20),
              Row(
                children: [
                  _sectionTitle('Anh minh hoa'),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Bat buoc',
                      style: TextStyle(
                        color: AppColors.red,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              _buildImagePreviewCard(),
              const SizedBox(height: 20),
              _sectionTitle('Loai san pham *'),
              _buildTypeSelector(),
              const SizedBox(height: 20),
              _sectionTitle('Thong tin san pham'),
              _buildCard(
                children: [
                  _buildTextField(
                    controller: _titleCtrl,
                    label: 'Ten san pham *',
                    hint: 'VD: Giao trinh Giai tich 1',
                    icon: Icons.title_rounded,
                    validator: (v) => v == null || v.trim().isEmpty ? 'Vui long nhap ten san pham' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    label: 'Danh muc *',
                    icon: Icons.category_outlined,
                    value: _selectedCategory,
                    items: _categories,
                    onChanged: (v) => setState(() => _selectedCategory = v!),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown(
                    label: 'Tinh trang *',
                    icon: Icons.star_outline_rounded,
                    value: _selectedCondition,
                    items: _conditions,
                    onChanged: (v) => setState(() => _selectedCondition = v!),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle('Gia ban'),
              _buildCard(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.card_giftcard_outlined, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Cho tang mien phi', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            Text('San pham se hien thi badge "Tang"', style: TextStyle(fontSize: 11, color: AppColors.textGray)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isFree,
                        activeThumbColor: AppColors.primary,
                        activeTrackColor: AppColors.primaryLight,
                        onChanged: (v) => setState(() {
                          _isFree = v;
                          if (v) {
                            _priceCtrl.clear();
                            _originalPriceCtrl.clear();
                          }
                        }),
                      ),
                    ],
                  ),
                  if (!_isFree) ...[
                    const Divider(height: 20),
                    _buildTextField(
                      controller: _priceCtrl,
                      label: 'Gia ban (d) *',
                      hint: 'VD: 50000',
                      icon: Icons.payments_outlined,
                      type: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (_isFree) return null;
                        if (v == null || v.trim().isEmpty) return 'Vui long nhap gia ban';
                        return null;
                      },
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _originalPriceCtrl,
                      label: 'Gia goc (d)',
                      hint: 'VD: 150000 (tuy chon)',
                      icon: Icons.price_change_outlined,
                      type: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                    ),
                    if (_priceCtrl.text.isNotEmpty && _originalPriceCtrl.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: _discountBadge(),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle('Mo ta san pham'),
              _buildCard(
                children: [
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Mo ta tinh trang, ly do ban, thong tin them...',
                      hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 13),
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
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle('Tuy chon'),
              _buildCard(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.star_rounded, color: AppColors.amber, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('San pham noi bat', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textDark)),
                            Text('Hien thi o muc noi bat trang chu', style: TextStyle(fontSize: 11, color: AppColors.textGray)),
                          ],
                        ),
                      ),
                      Switch(
                        value: _isFeatured,
                        activeThumbColor: AppColors.amber,
                        activeTrackColor: const Color(0xFFFEF3C7),
                        onChanged: (v) => setState(() => _isFeatured = v),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: (_saving || _imagePicking) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedImageDataUrl == null
                        ? const Color(0xFF7FC9C2)
                        : AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _saving || _imagePicking
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _selectedImageDataUrl == null
                                  ? Icons.image_not_supported_outlined
                                  : Icons.cloud_upload_outlined,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _selectedImageDataUrl == null
                                  ? 'Can chon anh minh hoa'
                                  : 'Dang san pham',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreviewCard() {
    final hasSelectedImage =
        _selectedImageDataUrl != null && _selectedImageDataUrl!.trim().isNotEmpty;
    return InkWell(
      onTap: _imagePicking ? null : _showImageSourceSheet,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _imageValidationError
                ? AppColors.red
                : hasSelectedImage
                    ? AppColors.primary.withValues(alpha: 0.24)
                    : const Color(0xFFD8E6E8),
            width: _imageValidationError ? 1.5 : 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.035),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 188,
                    child: hasSelectedImage
                        ? buildProductImage(
                            type: _selectedType,
                            imageUrl: _selectedImageDataUrl,
                          )
                        : _buildEmptyImagePlaceholder(
                            large: true,
                            showHint: false,
                          ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.photo_camera_back_outlined,
                          size: 15,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          hasSelectedImage ? 'Doi anh' : 'Them anh',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              hasSelectedImage
                  ? 'Anh san pham da san sang'
                  : 'Them anh minh hoa cho san pham',
              style: const TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hasSelectedImage
                  ? 'Ban co the cham vao day de doi anh, chup anh moi hoac xoa anh da chon.'
                  : 'Chua co anh mac dinh. Ban can tu them anh tu thu vien hoac chup bang camera.',
              style: const TextStyle(
                color: AppColors.textGray,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            if (_imageValidationError) ...[
              const SizedBox(height: 8),
              const Text(
                'Vui long chon anh minh hoa cho san pham.',
                style: TextStyle(
                  color: AppColors.red,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _imageActionChip(
                  icon: Icons.photo_library_outlined,
                  label: hasSelectedImage ? 'Doi tu thu vien' : 'Chon tu thu vien',
                  onTap: () => _pickProductImage(ImageSource.gallery),
                ),
                _imageActionChip(
                  icon: Icons.photo_camera_outlined,
                  label: 'Chup bang camera',
                  onTap: () => _pickProductImage(ImageSource.camera),
                ),
                if (hasSelectedImage)
                  _imageActionChip(
                    icon: Icons.delete_outline_rounded,
                    label: 'Bo anh',
                    isDanger: true,
                    onTap: () => setState(() {
                      _selectedImageDataUrl = null;
                      _imageValidationError = true;
                    }),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final color = isDanger ? AppColors.red : AppColors.primary;
    return InkWell(
      onTap: _imagePicking ? null : onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard() {
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final originalPrice = double.tryParse(_originalPriceCtrl.text);
    final hasDiscount = originalPrice != null && originalPrice > price && !_isFree;
    final discountPct = hasDiscount ? (((originalPrice - price) / originalPrice) * 100).round() : 0;
    final hasSelectedImage =
        _selectedImageDataUrl != null && _selectedImageDataUrl!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 72,
              height: 72,
              child: hasSelectedImage
                  ? buildProductImage(
                      type: _selectedType,
                      imageUrl: _selectedImageDataUrl,
                    )
                  : _buildEmptyImagePlaceholder(),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _titleCtrl.text.isEmpty ? 'Ten san pham...' : _titleCtrl.text,
                  style: TextStyle(
                    color: _titleCtrl.text.isEmpty ? Colors.white54 : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(_selectedCategory, style: const TextStyle(color: AppColors.primaryLight, fontSize: 12)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      _isFree ? 'Mien phi' : (price > 0 ? Formatter.price(price) : 'Chua nhap gia'),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    if (hasDiscount) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('-$discountPct%', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Row(
      children: _types.map((t) {
        final selected = _selectedType == t['value'];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedType = t['value']!),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? AppColors.primary : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Text(t['emoji']!, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    t['label']!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : AppColors.textGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _discountBadge() {
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final originalPrice = double.tryParse(_originalPriceCtrl.text) ?? 0;
    if (originalPrice <= price) {
      return const Text('Gia goc phai lon hon gia ban', style: TextStyle(color: AppColors.red, fontSize: 12));
    }
    final pct = (((originalPrice - price) / originalPrice) * 100).round();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('Giam $pct%', style: const TextStyle(color: AppColors.red, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(width: 8),
        Text('Tiet kiem ${Formatter.price(originalPrice - price)}', style: const TextStyle(color: AppColors.textGray, fontSize: 12)),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textDark)),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? type,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      inputFormatters: inputFormatters,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textGray, fontSize: 13),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required IconData icon,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      onChanged: onChanged,
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
      borderRadius: BorderRadius.circular(12),
      items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImageDataUrl == null || _selectedImageDataUrl!.trim().isEmpty) {
      setState(() => _imageValidationError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Can chon anh minh hoa truoc khi dang san pham.'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw StateError('Not logged in');
      }

      final price = _isFree ? 0.0 : (double.tryParse(_priceCtrl.text) ?? 0);
      final originalPrice = _originalPriceCtrl.text.isNotEmpty ? double.tryParse(_originalPriceCtrl.text) : null;
      final discount = (originalPrice != null && originalPrice > price && !_isFree)
          ? (((originalPrice - price) / originalPrice) * 100).round()
          : 0;

      final profile = await _dataService.getCurrentUserProfile();
      final productId = 'prod_${DateTime.now().millisecondsSinceEpoch}';

      final product = Product(
        id: productId,
        title: _titleCtrl.text.trim(),
        author: profile?.name ?? user.email ?? 'Nguoi ban',
        university: (profile?.university.trim().isNotEmpty == true) ? profile!.university : 'EduShare Campus',
        price: price,
        originalPrice: originalPrice,
        category: _selectedCategory,
        type: _selectedType,
        isNew: true,
        isFree: _isFree,
        discount: discount,
        imageEmoji: '',
        imageUrl: _selectedImageDataUrl,
        description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        condition: _selectedCondition,
        isFeatured: _isFeatured,
        createdAt: DateTime.now(),
        sellerUid: user.uid,
      );

      await _dataService.insertProduct(product);

      if (!mounted) return;
      setState(() => _saving = false);
      _showSuccess();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dang san pham that bai. Kiem tra Firebase va thu lai.'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SuccessCheckmark(),
            const SizedBox(height: 18),
            const Text('Dang thanh cong!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(
              '"${_titleCtrl.text}" da duoc dang len EduShare.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _resetForm();
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Dang tiep', style: TextStyle(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Xong'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _resetForm() {
    _titleCtrl.clear();
    _priceCtrl.clear();
    _originalPriceCtrl.clear();
    _descCtrl.clear();
    setState(() {
      _selectedType = 'sach';
      _selectedCategory = 'Toan - Tin';
      _selectedCondition = 'Nhu moi';
      _selectedImageDataUrl = null;
      _imageValidationError = false;
      _isFree = false;
      _isFeatured = false;
    });
  }

  Future<void> _showImageSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const Text(
                'Chon anh minh hoa',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ban co the tai anh san pham tu thu vien hoac chup nhanh bang camera.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textGray,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _pickerOption(
                icon: Icons.photo_library_outlined,
                title: 'Chon tu thu vien',
                subtitle: 'Lay anh co san trong may',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickProductImage(ImageSource.gallery);
                },
              ),
              const SizedBox(height: 12),
              _pickerOption(
                icon: Icons.photo_camera_outlined,
                title: 'Chup bang camera',
                subtitle: 'Tao anh moi ngay luc nay',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickProductImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _pickerOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FBFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.textGray,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyImagePlaceholder({
    bool large = false,
    bool showHint = true,
  }) {
    final borderRadius = BorderRadius.circular(large ? 14 : 12);
    final iconSize = large ? 38.0 : 22.0;
    final titleStyle = TextStyle(
      color: large ? AppColors.textDark : Colors.white,
      fontWeight: FontWeight.w700,
      fontSize: large ? 14 : 10.5,
    );
    final subtitleStyle = TextStyle(
      color: large
          ? AppColors.textGray
          : Colors.white.withValues(alpha: 0.72),
      fontSize: large ? 12 : 9.5,
      height: 1.35,
    );

    return Container(
      decoration: BoxDecoration(
        color: large ? const Color(0xFFF5FAFA) : Colors.white.withValues(alpha: 0.16),
        borderRadius: borderRadius,
        border: Border.all(
          color: large
              ? const Color(0xFFD8E6E8)
              : Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: large ? 18 : 8,
            vertical: large ? 18 : 6,
          ),
          child: large
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                        size: iconSize,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Chua co anh',
                      style: titleStyle,
                      textAlign: TextAlign.center,
                    ),
                    if (showHint) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Them anh de dang san pham',
                        style: subtitleStyle,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                )
              : Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _pickProductImage(ImageSource source) async {
    try {
      setState(() => _imagePicking = true);
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 55,
        maxWidth: 1400,
      );
      if (picked == null) {
        if (!mounted) return;
        setState(() => _imagePicking = false);
        return;
      }

      final bytes = await picked.readAsBytes();
      final encoded = base64Encode(bytes);
      final mimeType = _mimeTypeForPath(picked.path);
      final dataUrl = 'data:$mimeType;base64,$encoded';

      if (dataUrl.length > 900000) {
        if (!mounted) return;
        setState(() => _imagePicking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Anh qua lon. Vui long chon anh nho hon.'),
            backgroundColor: AppColors.red,
          ),
        );
        return;
      }

      setState(() {
        _selectedImageDataUrl = dataUrl;
        _imageValidationError = false;
        _imagePicking = false;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() => _imagePicking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khong the mo bo chon anh. Thu lai sau.'),
          backgroundColor: AppColors.red,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _imagePicking = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khong the tai anh len. Thu lai sau.'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  String _mimeTypeForPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}

class _SuccessCheckmark extends StatefulWidget {
  const _SuccessCheckmark();

  @override
  State<_SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<_SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 92,
          height: 92,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE9F9F1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF16A34A).withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF16A34A),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
