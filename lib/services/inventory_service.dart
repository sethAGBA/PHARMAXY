import 'package:sqflite/sqflite.dart';

import '../models/inventory_models.dart';
import '../services/auth_service.dart';
import '../services/local_database_service.dart';
import '../services/product_service.dart';

class InventoryService {
  InventoryService._();
  static final InventoryService instance = InventoryService._();

  final _dbService = LocalDatabaseService.instance;

  Future<List<InventoryProductSnapshot>> fetchStockSnapshots() async {
    final db = _dbService.db;
    final rows = await db.rawQuery('''
      SELECT
        med.id as medicament_id,
        med.nom,
        med.cip,
        COALESCE(s.officine, 0) as officine,
        med.prix_achat,
        med.prix_vente,
        COALESCE(s.lot, '') as lot,
        COALESCE(s.peremption, '') as peremption,
        COALESCE(med.famille, '') as categorie,
        COALESCE(med.localisation, '') as emplacement
      FROM medicaments med
      LEFT JOIN stocks s ON s.medicament_id = med.id
      ORDER BY med.nom ASC
    ''');
    return rows.map((row) {
      final expiryIso = row['peremption'] as String? ?? '';
      final expiry = expiryIso.isNotEmpty ? DateTime.tryParse(expiryIso) : null;
      final code = (row['cip'] as String?)?.isNotEmpty == true
          ? row['cip'] as String
          : row['medicament_id'] as String? ?? '';
      return InventoryProductSnapshot(
        medicamentId: row['medicament_id'] as String? ?? '',
        code: code,
        name: row['nom'] as String? ?? '',
        theoreticalQty: (row['officine'] as int?) ?? 0,
        purchasePrice: (row['prix_achat'] as num?)?.toInt() ?? 0,
        salePrice: (row['prix_vente'] as num?)?.toInt() ?? 0,
        lot: row['lot'] as String? ?? '',
        expiry: expiry,
        category: row['categorie'] as String? ?? '',
        location: row['emplacement'] as String? ?? '',
      );
    }).toList();
  }

  Future<List<InventorySummary>> fetchHistory({int limit = 6}) async {
    final db = _dbService.db;
    final rows = await db.query(
      'inventaires',
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map(InventorySummary.fromMap).toList();
  }

  Future<void> saveInventory({
    required String type,
    required String responsable,
    required List<InventoryLine> lines,
    String status = 'Validé',
  }) async {
    if (lines.isEmpty) return;
    final db = _dbService.db;
    final inventoryId = 'INV-${DateTime.now().millisecondsSinceEpoch}';
    final ecartQte = lines.fold(0, (sum, l) => sum + l.ecart);
    final ecartValeur = lines.fold(0, (sum, l) => sum + l.valeurEcart);
    await db.transaction((txn) async {
      await txn.insert('inventaires', {
        'id': inventoryId,
        'date': DateTime.now().toIso8601String(),
        'type': type,
        'responsable': responsable,
        'statut': status,
        'nb_produits': lines.length,
        'ecart_qte': ecartQte,
        'ecart_valeur': ecartValeur,
      });
      for (final line in lines) {
        await txn.insert('inventaire_lignes', line.toMap(inventoryId));
        await txn.update(
          'stocks',
          {'officine': line.qtyReelle},
          where: 'medicament_id = ?',
          whereArgs: [line.medicamentId],
        );
        await ProductService.instance.recordStockMovement(
          executor: txn,
          medicamentId: line.medicamentId,
          type: 'ajustement',
          quantity: line.ecart.abs(),
          quantityBefore: line.qtyTheorique,
          quantityAfter: line.qtyReelle,
          reason: 'inventaire',
          utilisateur: AuthService.instance.currentUser?.name ?? 'Utilisateur',
        );
      }
    });
  }
}
