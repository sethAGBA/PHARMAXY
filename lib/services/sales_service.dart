import 'dart:convert';

import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../models/sale_models.dart';
import '../services/auth_service.dart';
import '../services/local_database_service.dart';
import '../services/product_service.dart';

class StockException implements Exception {
  final String message;

  StockException(this.message);

  @override
  String toString() => message;
}

class SalesService {
  SalesService._();
  static final SalesService instance = SalesService._();

  final _db = LocalDatabaseService.instance;

  Future<List<SaleRecord>> fetchSalesHistory({int limit = 30}) async {
    final db = _db.db;
    final rows = await db.query('ventes', orderBy: 'date DESC', limit: limit);
    final List<SaleRecord> result = [];
    for (final row in rows) {
      final date =
          DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now();
      // Try to deserialize stored details; if empty, fallback to lignes_vente table
      List<CartItem> items = _deserializeItems(row['details'] as String?);
      if (items.isEmpty) {
        try {
          final venteId = row['id'] as String? ?? '';
          final lines = await db.query(
            'lignes_vente',
            where: 'vente_id = ?',
            whereArgs: [venteId],
          );
          if (lines.isNotEmpty) {
            final temp = <CartItem>[];
            for (final l in lines) {
              final medId = l['medicament_id'] as String? ?? '';
              // Attempt to get product name from medicaments table
              String medName = medId;
              try {
                final medRows = await db.query(
                  'medicaments',
                  where: 'id = ?',
                  whereArgs: [medId],
                  limit: 1,
                );
                if (medRows.isNotEmpty) {
                  medName = medRows.first['nom'] as String? ?? medId;
                }
              } catch (_) {
                // ignore and fallback to medId
              }
              final qty = (l['quantite'] as num?)?.toInt() ?? 1;
              final prix = (l['prix'] as num?)?.toDouble() ?? 0.0;
              temp.add(
                CartItem(
                  name: medName,
                  barcode: medId,
                  productId: medId,
                  price: prix,
                  category: '',
                  quantity: qty,
                ),
              );
            }
            items = temp;
          }
        } catch (_) {
          // ignore and leave items empty
        }
      }

      result.add(
        SaleRecord(
          id: row['id'] as String? ?? '',
          timeLabel: DateFormat('HH:mm').format(date),
          total: (row['montant'] as num?)?.toDouble() ?? 0,
          paymentMethod: row['mode'] as String? ?? '',
          customer: row['client_id'] as String?,
          vendor: row['vendeur'] as String?,
          status: row['statut'] as String? ?? 'Réglée',
          cancellationReason: row['cancellation_reason'] as String?,
          items: items,
        ),
      );
    }
    return result;
  }

  Future<void> recordSale({
    required String id,
    required double total,
    required String paymentMethod,
    required String type,
    String? clientId,
    required List<CartItem> items,
  }) async {
    final db = _db.db;
    await db.transaction((txn) async {
      final adjustedQuantities = <String, int>{};
      final productNames = <String, String>{};

      for (final item in items) {
        final productId = item.productId;
        if (productId == null || productId.isEmpty) continue;
        adjustedQuantities[productId] =
            (adjustedQuantities[productId] ?? 0) + item.quantity;
        productNames[productId] ??= item.name;
      }

      final stockBefore = <String, int>{};
      for (final entry in adjustedQuantities.entries) {
        final rows = await txn.query(
          'stocks',
          where: 'medicament_id = ?',
          whereArgs: [entry.key],
          limit: 1,
        );
        final available = rows.isNotEmpty
            ? (rows.first['officine'] as int?) ?? 0
            : 0;
        if (available < entry.value) {
          final label = productNames[entry.key] ?? entry.key;
          throw StockException(
            'Stock insuffisant pour $label (reste: $available)',
          );
        }
        stockBefore[entry.key] = available;
      }

      await txn.insert('ventes', {
        'id': id,
        'date': DateTime.now().toIso8601String(),
        'montant': total,
        'mode': paymentMethod,
        'client_id': clientId ?? '',
        'vendeur': AuthService.instance.currentUser?.name ?? 'Utilisateur',
        'statut': 'Réglée',
        'cancellation_reason': '',
        'details': jsonEncode(items.map((item) => item.toMap()).toList()),
        'type': type,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      for (final entry in adjustedQuantities.entries) {
        final previous = stockBefore[entry.key] ?? 0;
        final remaining = previous - entry.value;
        await txn.update(
          'stocks',
          {'officine': remaining},
          where: 'medicament_id = ?',
          whereArgs: [entry.key],
        );
        await ProductService.instance.recordStockMovement(
          executor: txn,
          medicamentId: entry.key,
          type: 'sortie',
          quantity: entry.value,
          quantityBefore: previous,
          quantityAfter: remaining,
          reason: 'vente',
          utilisateur: AuthService.instance.currentUser?.name ?? 'Utilisateur',
        );
      }
    });
  }

  List<CartItem> _deserializeItems(String? details) {
    if (details == null || details.isEmpty) return [];
    try {
      final List<dynamic> parsed = jsonDecode(details) as List<dynamic>;
      return parsed
          .map((e) => CartItem.fromMap(Map<String, Object?>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> cancelSale(String id, String reason) async {
    final db = _db.db;
    await db.update(
      'ventes',
      {'statut': 'Annulée', 'cancellation_reason': reason},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
