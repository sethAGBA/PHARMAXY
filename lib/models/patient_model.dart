import 'package:intl/intl.dart';

class PatientModel {
  final String id;
  final String name;
  final String phone;
  final String nir;
  final String mutuelle;
  final String email;
  final String dateOfBirthIso;

  const PatientModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.nir,
    required this.mutuelle,
    required this.email,
    required this.dateOfBirthIso,
  });

  factory PatientModel.fromMap(Map<String, Object?> map) {
    return PatientModel(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      nir: map['nir'] as String? ?? '',
      mutuelle: map['mutuelle'] as String? ?? '',
      email: map['email'] as String? ?? '',
      dateOfBirthIso: map['date_of_birth'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'nir': nir,
      'mutuelle': mutuelle,
      'email': email,
      'date_of_birth': dateOfBirthIso,
    };
  }

  String get displayLabel {
    final parts = <String>[name];
    if (phone.isNotEmpty) parts.add(phone);
    if (nir.isNotEmpty) parts.add(nir);
    return parts.join(' • ');
  }

  String get prettyDob {
    if (dateOfBirthIso.isEmpty) return '';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateOfBirthIso));
    } catch (_) {
      return dateOfBirthIso;
    }
  }
}
