class InventoryProductSnapshot {
  final String medicamentId;
  final String code;
  final String name;
  final int theoreticalQty;
  final int purchasePrice;
  final int salePrice;
  final String lot;
  final DateTime? expiry;
  final String category;
  final String location;

  const InventoryProductSnapshot({
    required this.medicamentId,
    required this.code,
    required this.name,
    required this.theoreticalQty,
    required this.purchasePrice,
    required this.salePrice,
    required this.lot,
    required this.expiry,
    required this.category,
    required this.location,
  });

  InventoryLine toLine({required int realQty}) {
    return InventoryLine(
      medicamentId: medicamentId,
      code: code,
      name: name,
      qtyTheorique: theoreticalQty,
      qtyReelle: realQty,
      prixAchat: purchasePrice,
      prixVente: salePrice,
      lot: lot,
      peremption: expiry ?? DateTime.now(),
      categorie: category,
      emplacement: location,
      dateAjout: DateTime.now(),
    );
  }
}

class InventoryLine {
  final String medicamentId;
  final String code;
  final String name;
  final int qtyTheorique;
  int qtyReelle;
  final int prixAchat;
  final int prixVente;
  final String lot;
  final DateTime peremption;
  final String categorie;
  final String emplacement;
  final DateTime dateAjout;

  InventoryLine({
    required this.medicamentId,
    required this.code,
    required this.name,
    required this.qtyTheorique,
    required this.qtyReelle,
    required this.prixAchat,
    required this.prixVente,
    required this.lot,
    required this.peremption,
    required this.categorie,
    required this.emplacement,
    required this.dateAjout,
  });

  int get ecart => qtyReelle - qtyTheorique;
  int get valeurEcart => ecart * prixAchat;

  Map<String, Object?> toMap(String inventaireId) {
    return {
      'inventaire_id': inventaireId,
      'medicament_id': medicamentId,
      'code': code,
      'nom': name,
      'qty_theorique': qtyTheorique,
      'qty_reelle': qtyReelle,
      'prix_achat': prixAchat,
      'prix_vente': prixVente,
      'lot': lot,
      'peremption': peremption.toIso8601String(),
      'categorie': categorie,
      'emplacement': emplacement,
      'date_ajout': dateAjout.toIso8601String(),
    };
  }

  factory InventoryLine.fromMap(Map<String, Object?> map) {
    return InventoryLine(
      medicamentId: map['medicament_id'] as String? ?? '',
      code: map['code'] as String? ?? '',
      name: map['nom'] as String? ?? '',
      qtyTheorique: (map['qty_theorique'] as num?)?.toInt() ?? 0,
      qtyReelle: (map['qty_reelle'] as num?)?.toInt() ?? 0,
      prixAchat: (map['prix_achat'] as num?)?.toInt() ?? 0,
      prixVente: (map['prix_vente'] as num?)?.toInt() ?? 0,
      lot: map['lot'] as String? ?? '',
      peremption:
          DateTime.tryParse(map['peremption'] as String? ?? '') ??
          DateTime.now(),
      categorie: map['categorie'] as String? ?? '',
      emplacement: map['emplacement'] as String? ?? '',
      dateAjout:
          DateTime.tryParse(map['date_ajout'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class InventorySummary {
  final String id;
  final DateTime date;
  final String type;
  final String responsable;
  final String statut;
  final int nbProduits;
  final int ecartQte;
  final int ecartValeur;

  InventorySummary({
    required this.id,
    required this.date,
    required this.type,
    required this.responsable,
    required this.statut,
    required this.nbProduits,
    required this.ecartQte,
    required this.ecartValeur,
  });

  factory InventorySummary.fromMap(Map<String, Object?> map) {
    return InventorySummary(
      id: map['id'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
      type: map['type'] as String? ?? 'Complet',
      responsable: map['responsable'] as String? ?? 'Équipe',
      statut: map['statut'] as String? ?? 'Validé',
      nbProduits: (map['nb_produits'] as num?)?.toInt() ?? 0,
      ecartQte: (map['ecart_qte'] as num?)?.toInt() ?? 0,
      ecartValeur: (map['ecart_valeur'] as num?)?.toInt() ?? 0,
    );
  }
}
