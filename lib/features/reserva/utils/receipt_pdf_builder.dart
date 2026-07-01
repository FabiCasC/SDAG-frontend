import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Recibo formal de pago SDAG (RF-077).
Future<pw.Document> buildPaymentReceiptPdf({
  required String reservationId,
  required String passengerName,
  required String passengerDni,
  required String pickupPoint,
  required List<int> seats,
  required double amountSoles,
  required String receiptNumber,
  required String driverName,
  required String driverPlate,
  required DateTime paidAt,
}) async {
  final doc = pw.Document();
  final seatLabel = seats.map((s) => '#$s').join(', ');

  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      build: (context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'SDAG',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue800,
                      ),
                    ),
                    pw.Text(
                      'Sistema de Distribución de Asientos Guiados',
                      style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                    ),
                  ],
                ),
                pw.Text(
                  'RECIBO DE PAGO',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),
            pw.Divider(),
            pw.SizedBox(height: 16),
            _row('ID Reserva', reservationId),
            _row('Comprobante Culqi', receiptNumber),
            _row('Fecha', _formatDate(paidAt)),
            pw.SizedBox(height: 12),
            _row('Pasajero', passengerName),
            _row('DNI', passengerDni.isEmpty ? '—' : passengerDni),
            _row('Conductor', driverName),
            _row('Placa', driverPlate),
            _row('Paradero', pickupPoint.isEmpty ? '—' : pickupPoint),
            _row('Asientos', seatLabel),
            pw.SizedBox(height: 16),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL PAGADO',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
                  ),
                  pw.Text(
                    'S/ ${amountSoles.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 18,
                      color: PdfColors.blue800,
                    ),
                  ),
                ],
              ),
            ),
            pw.Spacer(),
            pw.Text(
              'Tarifa fija S/ 15.00 por asiento · Comprobante generado por SDAG',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        );
      },
    ),
  );

  return doc;
}

pw.Widget _row(String label, String value) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 120,
          child: pw.Text(label, style: const pw.TextStyle(color: PdfColors.grey700)),
        ),
        pw.Expanded(child: pw.Text(value)),
      ],
    ),
  );
}

String _formatDate(DateTime dt) {
  final d = dt.toLocal();
  return '${d.day.toString().padLeft(2, '0')}/'
      '${d.month.toString().padLeft(2, '0')}/'
      '${d.year} '
      '${d.hour.toString().padLeft(2, '0')}:'
      '${d.minute.toString().padLeft(2, '0')}';
}
