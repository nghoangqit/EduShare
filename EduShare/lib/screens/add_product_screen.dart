import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String _selectedType = 'sach';
  String _selectedCategory = 'Toan - Tin';
  String _selectedCondition = 'Nhu moi';
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
              _sectionTitle('Anh minh hoa'),
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
                        activeColor: AppColors.primary,
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
                        activeColor: AppColors.amber,
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
                  onPressed: _saving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 20),
                            SizedBox(width: 8),
                            Text('Dang san pham', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: double.infinity,
              height: 180,
              child: Image.asset(
                imageForProductType(_selectedType),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Anh minh hoa duoc gan tu dong theo loai san pham.',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Ban khong can bat Firebase Storage hoac nang cap goi tra phi.',
            style: TextStyle(color: AppColors.textGray, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewCard() {
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final originalPrice = double.tryParse(_originalPriceCtrl.text);
    final hasDiscount = originalPrice != null && originalPrice > price && !_isFree;
    final discountPct = hasDiscount ? (((originalPrice - price) / originalPrice) * 100).round() : 0;

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
              child: Image.asset(imageForProductType(_selectedType), fit: BoxFit.cover),
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
                          color: AppColors.primary.withOpacity(0.3),
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
            color: AppColors.red.withOpacity(0.1),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
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
      value: value,
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
        imageUrl: null,
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
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 90,
              height: 90,
              child: Image.asset(imageForProductType(_selectedType)),
            ),
            const SizedBox(height: 12),
            const Text('Dang thanh cong!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(
              '"${_titleCtrl.text}" da duoc dang len EduShare.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGray, fontSize: 13),
            ),
            const SizedBox(height: 20),
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
      _isFree = false;
      _isFeatured = false;
    });
  }
}
