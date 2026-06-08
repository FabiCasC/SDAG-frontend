enum PaymentBrand {
  visa,
  mastercard,
}

extension PaymentBrandLabel on PaymentBrand {
  String get label {
    switch (this) {
      case PaymentBrand.visa:
        return 'Visa';
      case PaymentBrand.mastercard:
        return 'Mastercard';
    }
  }
}

class PaymentMethod {
  const PaymentMethod({
    required this.brand,
    required this.last4,
    required this.token,
    required this.saveForFuture,
  });

  final PaymentBrand brand;
  final String last4;
  final String token;
  final bool saveForFuture;

  PaymentMethod copyWith({
    PaymentBrand? brand,
    String? last4,
    String? token,
    bool? saveForFuture,
  }) {
    return PaymentMethod(
      brand: brand ?? this.brand,
      last4: last4 ?? this.last4,
      token: token ?? this.token,
      saveForFuture: saveForFuture ?? this.saveForFuture,
    );
  }

  String get maskedLabel => '${brand.label} **** $last4';
}

