import 'package:flutter/material.dart';

import '../models/expense_record.dart';
import '../services/firebase_data_service.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class ExpenseManagerScreen extends StatefulWidget {
  const ExpenseManagerScreen({super.key});

  @override
  State<ExpenseManagerScreen> createState() => _ExpenseManagerScreenState();
}

class _ExpenseManagerScreenState extends State<ExpenseManagerScreen> {
  final FirebaseDataService _dataService = FirebaseDataService.instance;
  final List<ExpenseRecord> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    final records = await _dataService.getCurrentUserExpenseRecords();
    if (!mounted) return;
    setState(() {
      _records
        ..clear()
        ..addAll(records);
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final monthRecords = _records
        .where(
          (record) =>
              record.occurredAt.month == now.month &&
              record.occurredAt.year == now.year,
        )
        .toList();
    final monthlyExpense = _sumByType(monthRecords, 'expense');
    final monthlyIncome = _sumByType(monthRecords, 'income');

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Quan ly chi tieu'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRecordSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Them giao dich'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRecords,
        color: AppColors.primary,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _summaryCard(monthlyIncome, monthlyExpense),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          label: 'Thu thang nay',
                          value: Formatter.price(monthlyIncome),
                          icon: Icons.trending_up_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _metricCard(
                          label: 'Chi thang nay',
                          value: Formatter.price(monthlyExpense),
                          icon: Icons.trending_down_rounded,
                          color: AppColors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _lineChartCard(monthRecords),
                  const SizedBox(height: 18),
                  const Text(
                    'Giao dich gan day',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_records.isEmpty)
                    _emptyState()
                  else
                    ..._records.map(_recordTile),
                ],
              ),
      ),
    );
  }

  Widget _lineChartCard(List<ExpenseRecord> monthRecords) {
    final values = _dailyExpenseValues(monthRecords);
    final hasData = values.any((value) => value > 0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.show_chart_rounded,
                  color: AppColors.blue,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bieu do chi tieu',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDark,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Theo ngay trong thang hien tai',
                      style: TextStyle(fontSize: 12, color: AppColors.textGray),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 190,
            width: double.infinity,
            child: hasData
                ? CustomPaint(painter: _ExpenseLineChartPainter(values))
                : const Center(
                    child: Text(
                      'Chua co du lieu chi tieu trong thang nay',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textGray,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(double income, double expense) {
    final balance = income - expense;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF111827), Color(0xFF115E59), Color(0xFF0D9488)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.insights_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Tong quan thang nay',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            Formatter.price(balance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            balance >= 0 ? 'Ban dang duong ngan sach.' : 'Chi tieu vuot thu.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGray),
          ),
        ],
      ),
    );
  }

  Widget _recordTile(ExpenseRecord record) {
    final color = record.isIncome ? AppColors.primary : AppColors.red;
    return Dismissible(
      key: ValueKey(record.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _confirmDelete(record),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_categoryIcon(record.category), color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${record.category} - ${_formatDate(record.occurredAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textGray,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${record.isIncome ? '+' : '-'}${Formatter.price(record.amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: AppColors.textGray,
            size: 42,
          ),
          SizedBox(height: 10),
          Text(
            'Chua co giao dich nao',
            style: TextStyle(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Bam Them giao dich de bat dau theo doi thu chi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textGray, fontSize: 12.5),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddRecordSheet() async {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var type = 'expense';
    var category = 'Sach/tai lieu';
    var occurredAt = DateTime.now();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Them giao dich',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'expense',
                            icon: Icon(Icons.remove_circle_outline_rounded),
                            label: Text('Chi tien'),
                          ),
                          ButtonSegment(
                            value: 'income',
                            icon: Icon(Icons.add_circle_outline_rounded),
                            label: Text('Thu tien'),
                          ),
                        ],
                        selected: {type},
                        onSelectionChanged: (value) {
                          setSheetState(() => type = value.first);
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: titleCtrl,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          'Ten giao dich',
                          Icons.edit_note_rounded,
                        ),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Nhap ten giao dich'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          'So tien',
                          Icons.payments_outlined,
                        ),
                        validator: (value) =>
                            _parseCurrencyInput(value ?? '') <= 0
                            ? 'Nhap so tien hop le'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: _inputDecoration(
                          'Danh muc',
                          Icons.category_outlined,
                        ),
                        items: _categories
                            .map(
                              (item) => DropdownMenuItem(
                                value: item,
                                child: Text(item),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setSheetState(() => category = value);
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: occurredAt,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setSheetState(() => occurredAt = picked);
                          }
                        },
                        icon: const Icon(Icons.calendar_today_outlined),
                        label: Text(_formatDate(occurredAt)),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: noteCtrl,
                        minLines: 2,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          'Ghi chu',
                          Icons.notes_rounded,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) return;
                            final navigator = Navigator.of(sheetContext);
                            final messenger = ScaffoldMessenger.of(
                              this.context,
                            );
                            final record = await _dataService.addExpenseRecord(
                              title: titleCtrl.text,
                              category: category,
                              type: type,
                              amount: _parseCurrencyInput(amountCtrl.text),
                              note: noteCtrl.text,
                              occurredAt: occurredAt,
                            );
                            if (!mounted) return;
                            navigator.pop();
                            if (record == null) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Khong the them giao dich luc nay.',
                                  ),
                                  backgroundColor: AppColors.red,
                                ),
                              );
                              return;
                            }
                            setState(() {
                              _records.insert(0, record);
                              _records.sort(
                                (a, b) => b.occurredAt.compareTo(a.occurredAt),
                              );
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          child: const Text('Luu giao dich'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    titleCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();
  }

  Future<bool> _confirmDelete(ExpenseRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoa giao dich?'),
        content: Text('Xoa "${record.title}" khoi quan ly chi tieu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('Xoa'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;

    final deleted = await _dataService.deleteExpenseRecord(record.id);
    if (!mounted) return false;
    if (deleted) {
      setState(() => _records.removeWhere((item) => item.id == record.id));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Khong the xoa giao dich luc nay.'),
          backgroundColor: AppColors.red,
        ),
      );
    }
    return deleted;
  }

  double _sumByType(List<ExpenseRecord> records, String type) {
    return records
        .where((record) => record.type == type)
        .fold<double>(0, (total, record) => total + record.amount);
  }

  List<double> _dailyExpenseValues(List<ExpenseRecord> records) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final values = List<double>.filled(daysInMonth, 0);

    for (final record in records) {
      if (!record.isExpense) continue;
      final index = record.occurredAt.day - 1;
      if (index >= 0 && index < values.length) {
        values[index] += record.amount;
      }
    }

    return values;
  }

  double _parseCurrencyInput(String value) {
    final normalized = value.replaceAll(RegExp(r'[^0-9]'), '');
    return double.tryParse(normalized) ?? 0;
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Sach/tai lieu':
        return Icons.menu_book_outlined;
      case 'Dung cu hoc tap':
        return Icons.inventory_2_outlined;
      case 'An uong':
        return Icons.restaurant_outlined;
      case 'Di chuyen':
        return Icons.directions_bus_outlined;
      case 'Thu nhap':
        return Icons.savings_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  static const List<String> _categories = [
    'Sach/tai lieu',
    'Dung cu hoc tap',
    'An uong',
    'Di chuyen',
    'Thu nhap',
    'Khac',
  ];
}

class _ExpenseLineChartPainter extends CustomPainter {
  _ExpenseLineChartPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    const leftPadding = 4.0;
    const rightPadding = 8.0;
    const topPadding = 10.0;
    const bottomPadding = 30.0;
    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;
    final maxValue = values.fold<double>(0, (max, value) {
      return value > max ? value : max;
    });

    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = topPadding + chartHeight * i / 3;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? leftPadding
          : leftPadding + chartWidth * i / (values.length - 1);
      final ratio = maxValue == 0 ? 0.0 : values[i] / maxValue;
      final y = topPadding + chartHeight - (chartHeight * ratio);
      points.add(Offset(x, y));
    }

    final fillPath = Path()..moveTo(points.first.dx, topPadding + chartHeight);
    for (final point in points) {
      fillPath.lineTo(point.dx, point.dy);
    }
    fillPath
      ..lineTo(points.last.dx, topPadding + chartHeight)
      ..close();

    final fillPaint = Paint()
      ..shader =
          LinearGradient(
            colors: [
              AppColors.red.withValues(alpha: 0.18),
              AppColors.red.withValues(alpha: 0.02),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ).createShader(
            Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight),
          );
    canvas.drawPath(fillPath, fillPaint);

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final previous = points[i - 1];
      final current = points[i];
      final controlX = (previous.dx + current.dx) / 2;
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }

    final linePaint = Paint()
      ..color = AppColors.red
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = Colors.white;
    final dotBorderPaint = Paint()
      ..color = AppColors.red
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < points.length; i++) {
      if (values[i] <= 0) continue;
      canvas.drawCircle(points[i], 4.5, dotPaint);
      canvas.drawCircle(points[i], 4.5, dotBorderPaint);
    }

    _drawLabel(canvas, '1', Offset(leftPadding, size.height - 20));
    _drawLabel(
      canvas,
      '${values.length}',
      Offset(size.width - rightPadding - 16, size.height - 20),
    );
    _drawLabel(
      canvas,
      _compactPrice(maxValue),
      Offset(leftPadding, topPadding - 2),
    );
  }

  void _drawLabel(Canvas canvas, String text, Offset offset) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: AppColors.textGray,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, offset);
  }

  String _compactPrice(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}tr';
    }
    if (value >= 1000) {
      return '${(value / 1000).round()}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _ExpenseLineChartPainter oldDelegate) {
    return oldDelegate.values != values;
  }
}
