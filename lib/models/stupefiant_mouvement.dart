class StupefiantMouvement {
  StupefiantMouvement({
    required this.id,
    required this.produit,
    required this.lot,
    required this.type,
    required this.quantite,
    required this.date,
    required this.agent,
    required this.motif,
  });

  final int id;
  final String produit;
  final String lot;
  final String type; // Entrée / Sortie
  final int quantite;
  final DateTime date;
  final String agent;
  final String motif;

  String get ref => 'STU-$id';

  factory StupefiantMouvement.fromMap(Map<String, Object?> map) {
    return StupefiantMouvement(
      id: (map['id'] as num?)?.toInt() ?? 0,
      produit: map['produit'] as String? ?? '',
      lot: map['lot'] as String? ?? '',
      type: map['type'] as String? ?? '',
      quantite: (map['quantite'] as num?)?.toInt() ?? 0,
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      agent: map['agent'] as String? ?? '',
      motif: map['motif'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id == 0 ? null : id,
      'produit': produit,
      'lot': lot,
      'type': type,
      'quantite': quantite,
      'date': date.toIso8601String(),
      'agent': agent,
      'motif': motif,
    };
  }

  StupefiantMouvement copyWith({
    int? id,
    String? produit,
    String? lot,
    String? type,
    int? quantite,
    DateTime? date,
    String? agent,
    String? motif,
  }) {
    return StupefiantMouvement(
      id: id ?? this.id,
      produit: produit ?? this.produit,
      lot: lot ?? this.lot,
      type: type ?? this.type,
      quantite: quantite ?? this.quantite,
      date: date ?? this.date,
      agent: agent ?? this.agent,
      motif: motif ?? this.motif,
    );
  }
}
