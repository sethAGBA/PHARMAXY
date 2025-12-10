import 'dart:math';

import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../models/sale_models.dart';
import '../services/local_database_service.dart';

class ProductService {
  ProductService._();
  static final ProductService instance = ProductService._();
  static final _rng = Random();

  final _db = LocalDatabaseService.instance;

  String _generateMovementId() {
    final ts = DateTime.now().microsecondsSinceEpoch;
    final rand = _rng.nextInt(1 << 32);
    return 'MS-$ts-$rand';
  }

  Future<List<Product>> fetchProductsForSale({String? search}) async {
    final db = _db.db;
    final query = '''
      SELECT
        m.id,
        m.nom,
        m.cip,
        m.famille,
        m.prix_vente,
        COALESCE(s.officine, 0) as officine
      FROM medicaments m
      LEFT JOIN stocks s ON s.medicament_id = m.id
      GROUP BY m.id
    ''';
    final rows = await db.rawQuery(query);
    final list = rows.map((row) {
      final barcode = (row['cip'] as String?)?.isNotEmpty == true
          ? row['cip'] as String
          : row['id'] as String;
      return Product(
        id: row['id'] as String? ?? '',
        name: row['nom'] as String? ?? '',
        barcode: barcode,
        price: (row['prix_vente'] as num?)?.toDouble() ?? 0,
        category: row['famille'] as String? ?? '',
        availableStock: (row['officine'] as int?) ?? 0,
      );
    }).toList();

    if (search == null || search.isEmpty) return list;
    final lower = search.toLowerCase();
    return list
        .where(
          (p) =>
              p.name.toLowerCase().contains(lower) || p.barcode.contains(lower),
        )
        .toList();
  }

  Future<Map<String, int>> fetchOfficineStockByProductIds(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) return {};
    final db = _db.db;
    final placeholders = List.filled(productIds.length, '?').join(', ');
    final rows = await db.rawQuery(
      'SELECT medicament_id, officine FROM stocks WHERE medicament_id IN ($placeholders)',
      productIds,
    );
    return {
      for (final row in rows)
        row['medicament_id'] as String: (row['officine'] as int?) ?? 0,
    };
  }

  Future<List<StockEntry>> fetchStockEntries() async {
    final db = _db.db;
    final query = '''
      SELECT m.id, m.nom, m.dci, m.dosage, m.cip, m.famille, m.laboratoire, m.forme, m.prix_achat, m.prix_vente, m.tva, m.remboursement,
             m.sku, m.type, m.statut, m.description, m.fournisseur, m.localisation, m.ordonnance, m.controle, m.conditionnement, m.notice, m.image,
             COALESCE(s.officine,0) as officine, COALESCE(s.reserve,0) as reserve,
             COALESCE(s.seuil,0) as seuil, COALESCE(s.seuil_max,0) as seuil_max,
             COALESCE(s.peremption,'') as peremption, COALESCE(s.lot,'') as lot
      FROM medicaments m
      LEFT JOIN stocks s ON s.medicament_id = m.id
      GROUP BY m.id
    ''';
    final rows = await db.rawQuery(query);
    return rows.map((row) {
      final qtyOfficine = row['officine'] as int? ?? 0;
      final qtyReserve = row['reserve'] as int? ?? 0;
      final prixVente = (row['prix_vente'] as num?)?.toInt() ?? 0;
      return StockEntry(
        id: row['id'] as String,
        name: row['nom'] as String? ?? '',
        dci: row['dci'] as String? ?? '',
        dosage: row['dosage'] as String? ?? '',
        cip: row['cip'] as String? ?? '',
        family: row['famille'] as String? ?? '',
        lab: row['laboratoire'] as String? ?? '',
        form: row['forme'] as String? ?? '',
        prixAchat: (row['prix_achat'] as num?)?.toInt() ?? 0,
        prixVente: prixVente,
        tva: (row['tva'] as num?)?.toInt() ?? 0,
        remboursement: (row['remboursement'] as num?)?.toInt() ?? 0,
        qtyOfficine: qtyOfficine,
        qtyReserve: qtyReserve,
        seuil: row['seuil'] as int? ?? 0,
        seuilMax: row['seuil_max'] as int? ?? 0,
        peremption: _formatDate(row['peremption'] as String?),
        lot: row['lot'] as String? ?? '',
        statut: row['statut'] as String? ?? 'Actif',
        type: row['type'] as String? ?? '',
        sku: row['sku'] as String? ?? '',
        localisation: row['localisation'] as String? ?? '',
        fournisseur: row['fournisseur'] as String? ?? '',
        ordonnance: (row['ordonnance'] as int? ?? 0) == 1,
        controle: (row['controle'] as int? ?? 0) == 1,
        description: row['description'] as String? ?? '',
        conditionnement: row['conditionnement'] as String? ?? '',
        notice: row['notice'] as String? ?? '',
        image: row['image'] as String? ?? '',
      );
    }).toList();
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      return DateFormat('MM/yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return '';
    }
  }

  Future<void> upsertProduct({
    String? id,
    required String nom,
    required String dci,
    required String dosage,
    required String cip,
    required String famille,
    required String laboratoire,
    required String forme,
    required int prixAchat,
    required int prixVente,
    required int tva,
    required int remboursement,
    String? sku,
    String? type,
    String? statut,
    int? seuilMax,
    String? localisation,
    String? fournisseur,
    bool ordonnance = false,
    bool controle = false,
    String? description,
    String? conditionnement,
    String? notice,
    String? image,
    required int seuil,
    required int reserve,
    required int officine,
    required String peremptionIso,
    required String lot,
  }) async {
    final db = _db.db;
    final productId = id ?? 'MED-${DateTime.now().millisecondsSinceEpoch}';

    await db.insert('medicaments', {
      'id': productId,
      'nom': nom,
      'dci': dci,
      'cip': cip,
      'dosage': dosage,
      'famille': famille,
      'laboratoire': laboratoire,
      'forme': forme,
      'prix_achat': prixAchat,
      'prix_vente': prixVente,
      'tva': tva,
      'remboursement': remboursement,
      'sku': sku,
      'type': type,
      'statut': statut,
      'localisation': localisation,
      'fournisseur': fournisseur,
      'ordonnance': ordonnance ? 1 : 0,
      'controle': controle ? 1 : 0,
      'description': description,
      'conditionnement': conditionnement,
      'notice': notice,
      'image': image,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    final existingStock = await db.query(
      'stocks',
      where: 'medicament_id = ?',
      whereArgs: [productId],
      limit: 1,
    );
    if (existingStock.isEmpty) {
      await db.insert('stocks', {
        'medicament_id': productId,
        'reserve': reserve,
        'officine': officine,
        'seuil': seuil,
        'seuil_max': seuilMax,
        'peremption': peremptionIso,
        'lot': lot,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    } else {
      await db.update(
        'stocks',
        {
          'reserve': reserve,
          'officine': officine,
          'seuil': seuil,
          'seuil_max': seuilMax,
          'peremption': peremptionIso,
          'lot': lot,
        },
        where: 'medicament_id = ?',
        whereArgs: [productId],
      );
    }
  }
}

class StockEntry {
  final String id;
  final String name;
  final String dci;
  final String dosage;
  final String cip;
  final String family;
  final String lab;
  final String form;
  final int prixAchat;
  final int prixVente;
  final int tva;
  final int remboursement;
  final int qtyOfficine;
  final int qtyReserve;
  final int seuil;
  final int seuilMax;
  final String peremption;
  final String lot;
  final String statut;
  final String type;
  final String sku;
  final String localisation;
  final String fournisseur;
  final bool ordonnance;
  final bool controle;
  final String description;
  final String conditionnement;
  final String notice;
  final String image;

  const StockEntry({
    required this.id,
    required this.name,
    required this.dci,
    required this.dosage,
    required this.cip,
    required this.family,
    required this.lab,
    required this.form,
    required this.prixAchat,
    required this.prixVente,
    required this.tva,
    required this.remboursement,
    required this.qtyOfficine,
    required this.qtyReserve,
    required this.seuil,
    required this.seuilMax,
    required this.peremption,
    required this.lot,
    required this.statut,
    required this.type,
    required this.sku,
    required this.localisation,
    required this.fournisseur,
    required this.ordonnance,
    required this.controle,
    required this.description,
    required this.conditionnement,
    required this.notice,
    required this.image,
  });
}

// Methods for stock movements
extension StockMovementsMethods on ProductService {
  Future<void> recordStockMovement({
    DatabaseExecutor? executor,
    required String medicamentId,
    required String type, // 'entree', 'sortie', 'ajustement', 'transfert'
    required int quantity,
    required int quantityBefore,
    required int quantityAfter,
    required String
    reason, // 'achat', 'vente', 'inventaire', 'perte', 'correction', etc.
    String? reference,
    String? notes,
    required String utilisateur,
  }) async {
    final dbExecutor = executor ?? _db.db;
    final id = _generateMovementId();
    await dbExecutor.insert('mouvements_stocks', {
      'id': id,
      'medicament_id': medicamentId,
      'type': type,
      'quantite': quantity,
      'quantite_avant': quantityBefore,
      'quantite_apres': quantityAfter,
      'raison': reason,
      'reference': reference,
      'notes': notes,
      'utilisateur': utilisateur,
      'date': DateTime.now().toIso8601String(),
    });
  }

  Future<List<StockMovement>> fetchMovementsForProduct(
    String medicamentId,
  ) async {
    final db = _db.db;
    final rows = await db.query(
      'mouvements_stocks',
      where: 'medicament_id = ?',
      whereArgs: [medicamentId],
      orderBy: 'date DESC',
    );
    return rows.map((row) {
      return StockMovement(
        id: row['id'] as String,
        productName: '', // Will be filled by caller
        type: row['type'] as String,
        quantity: row['quantite'] as int,
        quantityBefore: row['quantite_avant'] as int,
        quantityAfter: row['quantite_apres'] as int,
        reason: row['raison'] as String,
        date: DateTime.parse(row['date'] as String),
        reference: row['reference'] as String?,
        notes: row['notes'] as String?,
        user: row['utilisateur'] as String,
      );
    }).toList();
  }

  Future<List<StockMovement>> fetchAllMovements({
    String? typeFilter,
    String? reasonFilter,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    final db = _db.db;
    String query = '''
      SELECT m.*, med.nom
      FROM mouvements_stocks m
      JOIN medicaments med ON m.medicament_id = med.id
      WHERE 1=1
    ''';
    final args = <dynamic>[];

    if (typeFilter != null && typeFilter.isNotEmpty) {
      query += ' AND m.type = ?';
      args.add(typeFilter);
    }
    if (reasonFilter != null && reasonFilter.isNotEmpty) {
      query += ' AND m.raison = ?';
      args.add(reasonFilter);
    }
    if (dateFrom != null) {
      query += ' AND m.date >= ?';
      args.add(dateFrom.toIso8601String());
    }
    if (dateTo != null) {
      query += ' AND m.date <= ?';
      args.add(dateTo.add(const Duration(days: 1)).toIso8601String());
    }

    query += ' ORDER BY m.date DESC';

    final rows = await db.rawQuery(query, args);
    return rows.map((row) {
      return StockMovement(
        id: row['id'] as String,
        productName: row['nom'] as String,
        type: row['type'] as String,
        quantity: row['quantite'] as int,
        quantityBefore: row['quantite_avant'] as int,
        quantityAfter: row['quantite_apres'] as int,
        reason: row['raison'] as String,
        date: DateTime.parse(row['date'] as String),
        reference: row['reference'] as String?,
        notes: row['notes'] as String?,
        user: row['utilisateur'] as String,
      );
    }).toList();
  }
}
