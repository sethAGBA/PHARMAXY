class LotEntry {
  final int id;
  final String medicamentId;
  final String lot;
  final String peremptionIso;
  final int quantite;

  const LotEntry({
    required this.id,
    required this.medicamentId,
    required this.lot,
    required this.peremptionIso,
    required this.quantite,
  });

  factory LotEntry.fromMap(Map<String, Object?> map) {
    return LotEntry(
      id: (map['id'] as num?)?.toInt() ?? 0,
      medicamentId: map['medicament_id'] as String? ?? '',
      lot: map['lot'] as String? ?? '',
      peremptionIso: map['peremption'] as String? ?? '',
      quantite: (map['quantite'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'medicament_id': medicamentId,
      'lot': lot,
      'peremption': peremptionIso,
      'quantite': quantite,
    };
  }
}
