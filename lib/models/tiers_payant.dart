class TiersPayant {
  TiersPayant({
    required this.id,
    required this.nom,
    required this.type,
    required this.tauxPriseEnCharge,
    required this.delaiPaiement,
    required this.actif,
    required this.nbPatients,
    required this.montantEnAttente,
    required this.createdAt,
  });

  final String id;
  final String nom;
  final String type;
  final int tauxPriseEnCharge;
  final int delaiPaiement;
  final bool actif;
  final int nbPatients;
  final int montantEnAttente;
  final DateTime createdAt;

  factory TiersPayant.fromMap(Map<String, Object?> map) {
    return TiersPayant(
      id: map['id'] as String? ?? '',
      nom: map['nom'] as String? ?? '',
      type: map['type'] as String? ?? '',
      tauxPriseEnCharge: (map['taux_prise_en_charge'] as num?)?.toInt() ?? 0,
      delaiPaiement: (map['delai_paiement'] as num?)?.toInt() ?? 0,
      actif: (map['actif'] as num?)?.toInt() == 1,
      nbPatients: (map['nb_patients'] as num?)?.toInt() ?? 0,
      montantEnAttente: (map['montant_en_attente'] as num?)?.toInt() ?? 0,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nom': nom,
      'type': type,
      'taux_prise_en_charge': tauxPriseEnCharge,
      'delai_paiement': delaiPaiement,
      'actif': actif ? 1 : 0,
      'nb_patients': nbPatients,
      'montant_en_attente': montantEnAttente,
      'created_at': createdAt.toIso8601String(),
    };
  }

  TiersPayant copyWith({
    String? id,
    String? nom,
    String? type,
    int? tauxPriseEnCharge,
    int? delaiPaiement,
    bool? actif,
    int? nbPatients,
    int? montantEnAttente,
    DateTime? createdAt,
  }) {
    return TiersPayant(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      type: type ?? this.type,
      tauxPriseEnCharge: tauxPriseEnCharge ?? this.tauxPriseEnCharge,
      delaiPaiement: delaiPaiement ?? this.delaiPaiement,
      actif: actif ?? this.actif,
      nbPatients: nbPatients ?? this.nbPatients,
      montantEnAttente: montantEnAttente ?? this.montantEnAttente,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
