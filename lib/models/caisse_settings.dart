import 'dart:convert';

class CaisseSettings {
  CaisseSettings({
    required this.acceptCash,
    required this.acceptCard,
    required this.acceptMobileMoney,
    required this.acceptCheque,
    required this.acceptTransfer,
    required this.invoicePrefix,
    required this.nextNumber,
    required this.numberingFormat,
    required this.autoPrint,
    required this.openDrawer,
    required this.requireSignature,
    required this.printCustomerReceipt,
    required this.customerField,
  });

  final bool acceptCash;
  final bool acceptCard;
  final bool acceptMobileMoney;
  final bool acceptCheque;
  final bool acceptTransfer;
  final String invoicePrefix;
  final String nextNumber;
  final String numberingFormat;
  final bool autoPrint;
  final bool openDrawer;
  final bool requireSignature;
  final bool printCustomerReceipt;
  final String customerField;

  factory CaisseSettings.defaults() {
    return CaisseSettings(
      acceptCash: true,
      acceptCard: true,
      acceptMobileMoney: true,
      acceptCheque: false,
      acceptTransfer: false,
      invoicePrefix: 'FAC-',
      nextNumber: '25001',
      numberingFormat: 'FAC-YYMM-NNNN',
      autoPrint: true,
      openDrawer: true,
      requireSignature: false,
      printCustomerReceipt: true,
      customerField: 'Nom / Tel',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'acceptCash': acceptCash,
      'acceptCard': acceptCard,
      'acceptMobileMoney': acceptMobileMoney,
      'acceptCheque': acceptCheque,
      'acceptTransfer': acceptTransfer,
      'invoicePrefix': invoicePrefix,
      'nextNumber': nextNumber,
      'numberingFormat': numberingFormat,
      'autoPrint': autoPrint,
      'openDrawer': openDrawer,
      'requireSignature': requireSignature,
      'printCustomerReceipt': printCustomerReceipt,
      'customerField': customerField,
    };
  }

  factory CaisseSettings.fromJsonString(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    return CaisseSettings(
      acceptCash: map['acceptCash'] as bool? ?? true,
      acceptCard: map['acceptCard'] as bool? ?? true,
      acceptMobileMoney: map['acceptMobileMoney'] as bool? ?? true,
      acceptCheque: map['acceptCheque'] as bool? ?? false,
      acceptTransfer: map['acceptTransfer'] as bool? ?? false,
      invoicePrefix: map['invoicePrefix'] as String? ?? 'FAC-',
      nextNumber: map['nextNumber'] as String? ?? '25001',
      numberingFormat: map['numberingFormat'] as String? ?? 'FAC-YYMM-NNNN',
      autoPrint: map['autoPrint'] as bool? ?? true,
      openDrawer: map['openDrawer'] as bool? ?? true,
      requireSignature: map['requireSignature'] as bool? ?? false,
      printCustomerReceipt: map['printCustomerReceipt'] as bool? ?? true,
      customerField: map['customerField'] as String? ?? 'Nom / Tel',
    );
  }

  String toJsonString() => jsonEncode(toJson());

  CaisseSettings copyWith({
    bool? acceptCash,
    bool? acceptCard,
    bool? acceptMobileMoney,
    bool? acceptCheque,
    bool? acceptTransfer,
    String? invoicePrefix,
    String? nextNumber,
    String? numberingFormat,
    bool? autoPrint,
    bool? openDrawer,
    bool? requireSignature,
    bool? printCustomerReceipt,
    String? customerField,
  }) {
    return CaisseSettings(
      acceptCash: acceptCash ?? this.acceptCash,
      acceptCard: acceptCard ?? this.acceptCard,
      acceptMobileMoney: acceptMobileMoney ?? this.acceptMobileMoney,
      acceptCheque: acceptCheque ?? this.acceptCheque,
      acceptTransfer: acceptTransfer ?? this.acceptTransfer,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      nextNumber: nextNumber ?? this.nextNumber,
      numberingFormat: numberingFormat ?? this.numberingFormat,
      autoPrint: autoPrint ?? this.autoPrint,
      openDrawer: openDrawer ?? this.openDrawer,
      requireSignature: requireSignature ?? this.requireSignature,
      printCustomerReceipt: printCustomerReceipt ?? this.printCustomerReceipt,
      customerField: customerField ?? this.customerField,
    );
  }
}
