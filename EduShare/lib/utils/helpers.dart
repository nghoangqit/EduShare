import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

class Formatter {
  static String price(double price) {
    if (price == 0) return '0đ';
    if (price >= 1000000) {
      return '${(price / 1000000).toStringAsFixed(1)}Mđ';
    }
    final formatted = price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '${formatted}đ';
  }

  static String joinDate(DateTime date) {
    return 'Tháng ${date.month}/${date.year}';
  }
}

String repairVietnamese(String value) {
  try {
    return utf8.decode(latin1.encode(value));
  } catch (_) {
    return value;
  }
}

Color categoryColor(String type) {
  switch (type) {
    case 'sach':
      return const Color(0xFF0D9488);
    case 'may_tinh':
      return const Color(0xFF3B82F6);
    case 've':
      return const Color(0xFFF59E0B);
    case 'dung_cu':
      return const Color(0xFF8B5CF6);
    default:
      return const Color(0xFF0D9488);
  }
}

String typeLabel(String type) {
  switch (type) {
    case 'sach':
      return 'Sách';
    case 'may_tinh':
      return 'Thiết bị';
    case 've':
      return 'Vẽ';
    case 'dung_cu':
      return 'Dụng cụ';
    default:
      return 'Khác';
  }
}

String imageForProductType(String type) {
  switch (type) {
    case 'may_tinh':
      return 'assets/images/calculator.png';
    case 've':
    case 'dung_cu':
      return 'assets/images/tool.png';
    case 'sach':
    default:
      return 'assets/images/book.png';
  }
}

bool isInlineImageData(String? value) {
  if (value == null) return false;
  return value.trim().startsWith('data:image');
}

Uint8List? decodeInlineImageData(String? value) {
  if (!isInlineImageData(value)) return null;
  try {
    final raw = value!.trim();
    final commaIndex = raw.indexOf(',');
    if (commaIndex == -1) return null;
    return base64Decode(raw.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

Widget buildProductImage({
  required String type,
  required String? imageUrl,
  BoxFit fit = BoxFit.cover,
}) {
  final inlineBytes = decodeInlineImageData(imageUrl);
  if (inlineBytes != null) {
    return Image.memory(inlineBytes, fit: fit);
  }

  final hasRemoteImage = imageUrl != null && imageUrl.trim().isNotEmpty;
  if (hasRemoteImage) {
    return Image.network(
      imageUrl,
      fit: fit,
      errorBuilder: (_, __, ___) =>
          Image.asset(imageForProductType(type), fit: fit),
    );
  }

  return Image.asset(imageForProductType(type), fit: fit);
}
