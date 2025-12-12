import 'dart:convert';

class MargeCategorie {
  MargeCategorie({
    required this.id,
    required this.nom,
    required this.margeMin,
    required this.margeMax,
  });

  final String id;
  final String nom;
  final int margeMin;
  final int margeMax;

  factory MargeCategorie.fromJson(Map<String, dynamic> json) {
    return MargeCategorie(
      id: json['id'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      margeMin: (json['margeMin'] as num?)?.toInt() ?? 0,
      margeMax: (json['margeMax'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'nom': nom, 'margeMin': margeMin, 'margeMax': margeMax};
  }

  MargeCategorie copyWith({
    String? id,
    String? nom,
    int? margeMin,
    int? margeMax,
  }) {
    return MargeCategorie(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      margeMin: margeMin ?? this.margeMin,
      margeMax: margeMax ?? this.margeMax,
    );
  }
}

class MargesSettings {
  MargesSettings({required this.categories});

  final List<MargeCategorie> categories;

  factory MargesSettings.defaults() {
    return MargesSettings(
      categories: [
        MargeCategorie(
          id: 'generiques',
          nom: 'Médicaments génériques',
          margeMin: 8,
          margeMax: 18,
        ),
        MargeCategorie(
          id: 'marque',
          nom: 'Médicaments de marque',
          margeMin: 12,
          margeMax: 25,
        ),
        MargeCategorie(
          id: 'parapharmacie',
          nom: 'Parapharmacie',
          margeMin: 20,
          margeMax: 35,
        ),
        MargeCategorie(
          id: 'cosmetiques',
          nom: 'Cosmétiques',
          margeMin: 25,
          margeMax: 40,
        ),
        MargeCategorie(
          id: 'materiel',
          nom: 'Matériel médical',
          margeMin: 15,
          margeMax: 30,
        ),
      ],
    );
  }

  Map<String, dynamic> toJson() {
    return {'categories': categories.map((c) => c.toJson()).toList()};
  }

  factory MargesSettings.fromJsonString(String jsonStr) {
    final map = jsonDecode(jsonStr) as Map<String, dynamic>;
    final raw = (map['categories'] as List?) ?? const [];
    return MargesSettings(
      categories: raw
          .whereType<Map<String, dynamic>>()
          .map(MargeCategorie.fromJson)
          .toList(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  MargesSettings copyWith({List<MargeCategorie>? categories}) {
    return MargesSettings(categories: categories ?? this.categories);
  }
}
