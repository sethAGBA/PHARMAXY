class AppSettings {
  AppSettings({
    required this.currency,
    required this.logoPath,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.pharmacyPhone,
    required this.pharmacyEmail,
    required this.pharmacyOrderNumber,
  });

  final String currency;
  final String logoPath;
  final String pharmacyName;
  final String pharmacyAddress;
  final String pharmacyPhone;
  final String pharmacyEmail;
  final String pharmacyOrderNumber;

  factory AppSettings.defaults() {
    return AppSettings(
      currency: 'XOF',
      logoPath: '',
      pharmacyName: 'Pharmacie PHARMAXY',
      pharmacyAddress: '',
      pharmacyPhone: '',
      pharmacyEmail: '',
      pharmacyOrderNumber: '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'currency': currency,
      'logoPath': logoPath,
      'pharmacy_name': pharmacyName,
      'pharmacy_address': pharmacyAddress,
      'pharmacy_phone': pharmacyPhone,
      'pharmacy_email': pharmacyEmail,
      'pharmacy_order_number': pharmacyOrderNumber,
    };
  }

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      currency: map['currency'] as String? ?? 'XOF',
      logoPath: map['logoPath'] as String? ?? '',
      pharmacyName: map['pharmacy_name'] as String? ?? 'Pharmacie PHARMAXY',
      pharmacyAddress: map['pharmacy_address'] as String? ?? '',
      pharmacyPhone: map['pharmacy_phone'] as String? ?? '',
      pharmacyEmail: map['pharmacy_email'] as String? ?? '',
      pharmacyOrderNumber: map['pharmacy_order_number'] as String? ?? '',
    );
  }

  AppSettings copyWith({
    String? currency,
    String? logoPath,
    String? pharmacyName,
    String? pharmacyAddress,
    String? pharmacyPhone,
    String? pharmacyEmail,
    String? pharmacyOrderNumber,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      logoPath: logoPath ?? this.logoPath,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyAddress: pharmacyAddress ?? this.pharmacyAddress,
      pharmacyPhone: pharmacyPhone ?? this.pharmacyPhone,
      pharmacyEmail: pharmacyEmail ?? this.pharmacyEmail,
      pharmacyOrderNumber:
          pharmacyOrderNumber ?? this.pharmacyOrderNumber,
    );
  }
}
