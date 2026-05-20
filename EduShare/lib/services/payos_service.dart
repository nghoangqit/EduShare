import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../utils/constants.dart';

class PayosPaymentLink {
  final int orderCode;
  final int amount;
  final String paymentLinkId;
  final String status;
  final String checkoutUrl;
  final String qrCode;

  const PayosPaymentLink({
    required this.orderCode,
    required this.amount,
    required this.paymentLinkId,
    required this.status,
    required this.checkoutUrl,
    required this.qrCode,
  });

  factory PayosPaymentLink.fromMap(Map<String, dynamic> map) {
    return PayosPaymentLink(
      orderCode: (map['orderCode'] as num?)?.toInt() ?? 0,
      amount: (map['amount'] as num?)?.toInt() ?? 0,
      paymentLinkId:
          (map['paymentLinkId'] as String?) ?? (map['id'] as String?) ?? '',
      status: map['status'] as String? ?? '',
      checkoutUrl: map['checkoutUrl'] as String? ?? '',
      qrCode: map['qrCode'] as String? ?? '',
    );
  }

  bool get isPaid => status.toUpperCase() == 'PAID';
}

class PayosService {
  PayosService._();

  static final PayosService instance = PayosService._();

  static const String _baseUrl = 'https://api-merchant.payos.vn';

  bool get isConfigured =>
      AdminConfig.payosClientId.trim().isNotEmpty &&
      AdminConfig.payosApiKey.trim().isNotEmpty &&
      AdminConfig.payosChecksumKey.trim().isNotEmpty;

  Future<PayosPaymentLink?> createWalletTopupLink({
    required String requestId,
    required int orderCode,
    required int amount,
    required String description,
    required String buyerName,
    required String buyerEmail,
  }) async {
    if (!isConfigured) return null;

    try {
      final normalizedDescription = _normalizeDescription(description);
      final cancelUrl = AdminConfig.payosCancelUrl;
      final returnUrl = AdminConfig.payosReturnUrl;
      final signature = _signature({
        'amount': amount,
        'cancelUrl': cancelUrl,
        'description': normalizedDescription,
        'orderCode': orderCode,
        'returnUrl': returnUrl,
      });

      final response = await http
          .post(
            Uri.parse('$_baseUrl/v2/payment-requests'),
            headers: _headers,
            body: jsonEncode({
              'orderCode': orderCode,
              'amount': amount,
              'description': normalizedDescription,
              'buyerName': buyerName,
              'buyerEmail': buyerEmail,
              'items': [
                {
                  'name': 'Nap vi EduShare $requestId',
                  'quantity': 1,
                  'price': amount,
                },
              ],
              'cancelUrl': cancelUrl,
              'returnUrl': returnUrl,
              'signature': signature,
            }),
          )
          .timeout(const Duration(seconds: 12));

      final body = _decodeResponse(response);
      if (response.statusCode != 200 || body['code'] != '00') {
        debugPrint(
          'PayOS create payment failed: status=${response.statusCode}, body=$body',
        );
        return null;
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;
      return PayosPaymentLink.fromMap(data);
    } on TimeoutException catch (error) {
      debugPrint('PayOS create payment timeout: $error');
      return null;
    } on FormatException catch (error) {
      debugPrint('PayOS create payment invalid response: $error');
      return null;
    } on http.ClientException catch (error) {
      debugPrint('PayOS create payment network error: $error');
      return null;
    }
  }

  Future<PayosPaymentLink?> getPaymentLink(String idOrOrderCode) async {
    if (!isConfigured || idOrOrderCode.trim().isEmpty) return null;

    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/v2/payment-requests/$idOrOrderCode'),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 12));

      final body = _decodeResponse(response);
      if (response.statusCode != 200 || body['code'] != '00') {
        debugPrint(
          'PayOS get payment failed: status=${response.statusCode}, body=$body',
        );
        return null;
      }
      final data = body['data'];
      if (data is! Map<String, dynamic>) return null;
      return PayosPaymentLink.fromMap(data);
    } on TimeoutException catch (error) {
      debugPrint('PayOS get payment timeout: $error');
      return null;
    } on FormatException catch (error) {
      debugPrint('PayOS get payment invalid response: $error');
      return null;
    } on http.ClientException catch (error) {
      debugPrint('PayOS get payment network error: $error');
      return null;
    }
  }

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'x-client-id': AdminConfig.payosClientId,
      'x-api-key': AdminConfig.payosApiKey,
    };
    if (AdminConfig.payosPartnerCode.trim().isNotEmpty) {
      headers['x-partner-code'] = AdminConfig.payosPartnerCode;
    }
    return headers;
  }

  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded is Map<String, dynamic> ? decoded : const {};
  }

  String _signature(Map<String, Object> values) {
    final sortedKeys = values.keys.toList()..sort();
    final data = sortedKeys.map((key) => '$key=${values[key]}').join('&');
    final hmac = Hmac(sha256, utf8.encode(AdminConfig.payosChecksumKey));
    return hmac.convert(utf8.encode(data)).toString();
  }

  String _normalizeDescription(String description) {
    final normalized = description
        .replaceAll(RegExp(r'[^A-Za-z0-9]'), '')
        .toUpperCase();
    if (normalized.length <= 9) return normalized;
    return normalized.substring(0, 9);
  }
}
