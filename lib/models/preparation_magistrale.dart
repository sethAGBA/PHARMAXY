import 'dart:convert';

class ComposantPreparation {
  const ComposantPreparation({
    required this.nom,
    required this.quantite,
    required this.unite,
  });

  final String nom;
  final double quantite;
  final String unite;

  factory ComposantPreparation.fromJson(Map<String, dynamic> json) {
    return ComposantPreparation(
      nom: json['nom'] as String? ?? '',
      quantite: (json['quantite'] as num?)?.toDouble() ?? 0,
      unite: json['unite'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'nom': nom, 'quantite': quantite, 'unite': unite};
  }
}

class PreparationMagistrale {
  PreparationMagistrale({
    required this.id,
    required this.nom,
    required this.categorie,
    required this.quantiteTotale,
    required this.unite,
    required this.composants,
    required this.instructions,
    required this.conservation,
    required this.posologie,
    required this.statut,
    required this.cout,
    required this.prix,
    required this.createdAt,
  });

  final String id;
  final String nom;
  final String categorie;
  final int quantiteTotale;
  final String unite;
  final List<ComposantPreparation> composants;
  final String instructions;
  final String conservation;
  final String posologie;
  final String statut;
  final double cout;
  final double prix;
  final DateTime createdAt;

  double get margePourcentage {
    if (prix <= 0) return 0;
    return ((prix - cout) / prix) * 100;
  }

  factory PreparationMagistrale.fromMap(Map<String, Object?> map) {
    final composantsJson = map['composants_json'] as String? ?? '[]';
    final decoded = jsonDecode(composantsJson);
    final composants = decoded is List
        ? decoded
              .whereType<Map>()
              .map(
                (e) => ComposantPreparation.fromJson(
                  e.map((k, v) => MapEntry(k.toString(), v)),
                ),
              )
              .toList()
        : <ComposantPreparation>[];
    return PreparationMagistrale(
      id: map['id'] as String? ?? '',
      nom: map['nom'] as String? ?? '',
      categorie: map['categorie'] as String? ?? '',
      quantiteTotale: (map['quantite_totale'] as num?)?.toInt() ?? 0,
      unite: map['unite'] as String? ?? '',
      composants: composants,
      instructions: map['instructions'] as String? ?? '',
      conservation: map['conservation'] as String? ?? '',
      posologie: map['posologie'] as String? ?? '',
      statut: map['statut'] as String? ?? '',
      cout: (map['cout'] as num?)?.toDouble() ?? 0,
      prix: (map['prix'] as num?)?.toDouble() ?? 0,
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nom': nom,
      'description': '',
      'categorie': categorie,
      'quantite_totale': quantiteTotale,
      'unite': unite,
      'composants_json': jsonEncode(composants.map((c) => c.toJson()).toList()),
      'instructions': instructions,
      'conservation': conservation,
      'posologie': posologie,
      'statut': statut,
      'cout': cout,
      'prix': prix,
      'created_at': createdAt.toIso8601String(),
    };
  }

  PreparationMagistrale copyWith({
    String? id,
    String? nom,
    String? categorie,
    int? quantiteTotale,
    String? unite,
    List<ComposantPreparation>? composants,
    String? instructions,
    String? conservation,
    String? posologie,
    String? statut,
    double? cout,
    double? prix,
    DateTime? createdAt,
  }) {
    return PreparationMagistrale(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      categorie: categorie ?? this.categorie,
      quantiteTotale: quantiteTotale ?? this.quantiteTotale,
      unite: unite ?? this.unite,
      composants: composants ?? this.composants,
      instructions: instructions ?? this.instructions,
      conservation: conservation ?? this.conservation,
      posologie: posologie ?? this.posologie,
      statut: statut ?? this.statut,
      cout: cout ?? this.cout,
      prix: prix ?? this.prix,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
