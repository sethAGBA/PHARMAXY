class AppSettings {
  AppSettings({
    required this.currency,
    required this.logoPath,
    required this.pharmacyName,
    required this.pharmacyAddress,
    required this.pharmacyPhone,
    required this.pharmacyEmail,
    required this.pharmacyOrderNumber,
    required this.pharmacyWebsite,
    required this.pharmacyHours,
    required this.emergencyContact,
    required this.fiscalId,
    required this.taxDetails,
    required this.returnPolicy,
    required this.healthAdvice,
    required this.loyaltyMessage,
    required this.ticketLink,
    required this.ticketFooter,
  });

  final String currency;
  final String logoPath;
  final String pharmacyName;
  final String pharmacyAddress;
  final String pharmacyPhone;
  final String pharmacyEmail;
  final String pharmacyOrderNumber;
  final String pharmacyWebsite;
  final String pharmacyHours;
  final String emergencyContact;
  final String fiscalId;
  final String taxDetails;
  final String returnPolicy;
  final String healthAdvice;
  final String loyaltyMessage;
  final String ticketLink;
  final String ticketFooter;

  factory AppSettings.defaults() {
    return AppSettings(
      currency: 'XOF',
      logoPath: '',
      pharmacyName: 'Pharmacie PHARMAXY',
      pharmacyAddress: '',
      pharmacyPhone: '',
      pharmacyEmail: '',
      pharmacyOrderNumber: '',
      pharmacyWebsite: '',
      pharmacyHours: '',
      emergencyContact: '',
      fiscalId: '',
      taxDetails: '',
      returnPolicy: '',
      healthAdvice: '',
      loyaltyMessage: '',
      ticketLink: '',
      ticketFooter: 'Merci de votre confiance. Prompt rétablissement !',
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
      'pharmacy_website': pharmacyWebsite,
      'pharmacy_hours': pharmacyHours,
      'emergency_contact': emergencyContact,
      'fiscal_id': fiscalId,
      'tax_details': taxDetails,
      'return_policy': returnPolicy,
      'health_advice': healthAdvice,
      'loyalty_message': loyaltyMessage,
      'ticket_link': ticketLink,
      'ticket_footer': ticketFooter,
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
      pharmacyWebsite: map['pharmacy_website'] as String? ?? '',
      pharmacyHours: map['pharmacy_hours'] as String? ?? '',
      emergencyContact: map['emergency_contact'] as String? ?? '',
      fiscalId: map['fiscal_id'] as String? ?? '',
      taxDetails: map['tax_details'] as String? ?? '',
      returnPolicy: map['return_policy'] as String? ?? '',
      healthAdvice: map['health_advice'] as String? ?? '',
      loyaltyMessage: map['loyalty_message'] as String? ?? '',
      ticketLink: map['ticket_link'] as String? ?? '',
      ticketFooter:
          map['ticket_footer'] as String? ??
          'Merci de votre confiance. Prompt rétablissement !',
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
    String? pharmacyWebsite,
    String? pharmacyHours,
    String? emergencyContact,
    String? fiscalId,
    String? taxDetails,
    String? returnPolicy,
    String? healthAdvice,
    String? loyaltyMessage,
    String? ticketLink,
    String? ticketFooter,
  }) {
    return AppSettings(
      currency: currency ?? this.currency,
      logoPath: logoPath ?? this.logoPath,
      pharmacyName: pharmacyName ?? this.pharmacyName,
      pharmacyAddress: pharmacyAddress ?? this.pharmacyAddress,
      pharmacyPhone: pharmacyPhone ?? this.pharmacyPhone,
      pharmacyEmail: pharmacyEmail ?? this.pharmacyEmail,
      pharmacyOrderNumber: pharmacyOrderNumber ?? this.pharmacyOrderNumber,
      pharmacyWebsite: pharmacyWebsite ?? this.pharmacyWebsite,
      pharmacyHours: pharmacyHours ?? this.pharmacyHours,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      fiscalId: fiscalId ?? this.fiscalId,
      taxDetails: taxDetails ?? this.taxDetails,
      returnPolicy: returnPolicy ?? this.returnPolicy,
      healthAdvice: healthAdvice ?? this.healthAdvice,
      loyaltyMessage: loyaltyMessage ?? this.loyaltyMessage,
      ticketLink: ticketLink ?? this.ticketLink,
      ticketFooter: ticketFooter ?? this.ticketFooter,
    );
  }
}
