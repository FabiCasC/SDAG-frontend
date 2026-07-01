import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

/// Devolución Culqi POST /v2/refunds (RF-012, RF-054).
Future<CulqiRefundResult> requestCulqiRefund({
  required String chargeId,
  required int amountCents,
  String reason = 'solicitud_comprador',
}) async {
  if (chargeId.trim().isEmpty) {
    return const CulqiRefundResult(success: false, message: 'Cargo Culqi no encontrado');
  }

  final secretKey = dotenv.env['CULQI_SECRET_KEY']?.trim() ?? '';

  if (secretKey.isEmpty) {
    debugPrint('[Culqi][refund] Simulación exitosa (sin CULQI_SECRET_KEY)');
    return CulqiRefundResult(
      success: true,
      message: 'Reembolso simulado',
      refundId: 'ref_sim_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  try {
    final response = await http.post(
      Uri.parse('https://api.culqi.com/v2/refunds'),
      headers: {
        'Authorization': 'Bearer $secretKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'amount': amountCents,
        'charge_id': chargeId,
        'reason': reason,
      }),
    );

    final json = _tryDecode(response.body);
    if (response.statusCode == 201) {
      return CulqiRefundResult(
        success: true,
        message: 'Reembolso procesado',
        refundId: json?['id']?.toString(),
      );
    }

    final msg = json?['user_message']?.toString() ??
        json?['merchant_message']?.toString() ??
        'No se pudo procesar el reembolso';
    return CulqiRefundResult(success: false, message: msg);
  } catch (e) {
    return CulqiRefundResult(success: false, message: e.toString());
  }
}

Map<String, dynamic>? _tryDecode(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return decoded.cast<String, dynamic>();
  } catch (_) {}
  return null;
}

class CulqiRefundResult {
  const CulqiRefundResult({
    required this.success,
    required this.message,
    this.refundId,
  });

  final bool success;
  final String message;
  final String? refundId;
}
