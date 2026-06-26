/// Validaciones de pago extraídas de [PagoScreen] y flujo Culqi.
const int kSeatFareCents = 1500;

(int month, int year) parseCardExpiry(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 4) return (0, 0);
  final mm = int.tryParse(digits.substring(0, 2)) ?? 0;
  final yy = int.tryParse(digits.substring(2, 4)) ?? 0;
  return (mm, yy);
}

String? validateCardPaymentFields({
  required String cardNumber,
  required String cvv,
  required String expiry,
  required String holder,
}) {
  final cardNumberDigits = cardNumber.replaceAll(RegExp(r'\D'), '');
  final cvvDigits = cvv.replaceAll(RegExp(r'\D'), '');
  if (cardNumberDigits.length != 16) return 'Número de tarjeta inválido';
  if (cvvDigits.length != 3) return 'CVV inválido';
  final (mm, yy) = parseCardExpiry(expiry);
  if (mm < 1 || mm > 12) return 'Fecha de vencimiento inválida';
  if (yy < 0 || yy > 99) return 'Fecha de vencimiento inválida';
  if (holder.trim().length < 3) return 'Nombre del titular inválido';
  return null;
}

bool isYapePhoneComplete(String rawPhone) {
  return rawPhone.replaceAll(RegExp(r'\D'), '').length == 9;
}

bool isNewCardFormComplete({
  required String cardNumber,
  required String cvv,
  required String expiry,
  required String holder,
}) {
  return cardNumber.replaceAll(' ', '').length == 16 &&
      cvv.length == 3 &&
      expiry.length == 5 &&
      holder.trim().length >= 3;
}

int paymentAmountCents(int seatCount) => seatCount * kSeatFareCents;

int culqiChargeResultStatus(int statusCode, String? message) {
  return statusCode != 201 ? -1 : 0;
}

String culqiChargeResultMessage(int statusCode, String? message) {
  return statusCode != 201 ? (message ?? 'Tarjeta rechazada') : 'ok';
}

double seatFareTotalSoles(int seatCount) => paymentAmountCents(seatCount) / 100.0;

int culqiExpirationYear(int yy) => yy < 100 ? 2000 + yy : yy;
