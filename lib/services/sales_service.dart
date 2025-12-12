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
      final lotsAllocations = <String, Map<String, int>>{};

      for (final item in items) {
        final productId = item.productId;
        if (productId == null || productId.isEmpty) continue;
        adjustedQuantities[productId] =
            (adjustedQuantities[productId] ?? 0) + item.quantity;
        productNames[productId] ??= item.name;
      }

      final stockBefore = <String, int>{};
      for (final entry in adjustedQuantities.entries) {
        final productId = entry.key;
        final qtyNeeded = entry.value;
        final lotRows = await txn.query(
          'lots',
          where: 'medicament_id = ?',
          whereArgs: [productId],
          orderBy:
              "CASE WHEN peremption IS NULL OR peremption = '' THEN 1 ELSE 0 END, peremption ASC, id ASC",
        );
        if (lotRows.isNotEmpty) {
          final lots = lotRows
              .map(
                (r) => {
                  'id': (r['id'] as num?)?.toInt() ?? 0,
                  'lot': r['lot'] as String? ?? '',
                  'peremption': r['peremption'] as String? ?? '',
                  'quantite': (r['quantite'] as num?)?.toInt() ?? 0,
                },
              )
              .toList();
          final available = lots.fold<int>(
            0,
            (sum, l) => sum + (l['quantite'] as int),
          );
          if (available < qtyNeeded) {
            final label = productNames[productId] ?? productId;
            throw StockException(
              'Stock insuffisant pour $label (reste: $available)',
            );
          }
          stockBefore[productId] = available;
          var remainingToTake = qtyNeeded;
          final allocations = <String, int>{};
          for (final lot in lots) {
            if (remainingToTake <= 0) break;
            final lotQty = lot['quantite'] as int;
            if (lotQty <= 0) continue;
            final take = lotQty >= remainingToTake ? remainingToTake : lotQty;
            remainingToTake -= take;
            final lotNumber = (lot['lot'] as String).trim();
            if (lotNumber.isNotEmpty) {
              allocations[lotNumber] = (allocations[lotNumber] ?? 0) + take;
            }
            final newQty = lotQty - take;
            await txn.update(
              'lots',
              {'quantite': newQty},
              where: 'id = ?',
              whereArgs: [lot['id']],
            );
          }
          lotsAllocations[productId] = allocations;
          final remainingTotal = available - qtyNeeded;
          final earliestRemaining = await txn.query(
            'lots',
            where: 'medicament_id = ? AND quantite > 0',
            whereArgs: [productId],
            orderBy:
                "CASE WHEN peremption IS NULL OR peremption = '' THEN 1 ELSE 0 END, peremption ASC, id ASC",
            limit: 1,
          );
          await txn.update(
            'stocks',
            {
              'officine': remainingTotal,
              'lot': earliestRemaining.isNotEmpty
                  ? (earliestRemaining.first['lot'] as String? ?? '')
                  : '',
              'peremption': earliestRemaining.isNotEmpty
                  ? (earliestRemaining.first['peremption'] as String? ?? '')
                  : '',
            },
            where: 'medicament_id = ?',
            whereArgs: [productId],
          );
        } else {
          final rows = await txn.query(
            'stocks',
            where: 'medicament_id = ?',
            whereArgs: [productId],
            limit: 1,
          );
          final available = rows.isNotEmpty
              ? (rows.first['officine'] as int?) ?? 0
              : 0;
          if (available < qtyNeeded) {
            final label = productNames[productId] ?? productId;
            throw StockException(
              'Stock insuffisant pour $label (reste: $available)',
            );
          }
          stockBefore[productId] = available;
        }
      }

      // Inject lot allocations into items for storage/receipt
      for (var i = 0; i < items.length; i++) {
        final pid = items[i].productId;
        if (pid == null) continue;
        final alloc = lotsAllocations[pid];
        if (alloc != null && alloc.isNotEmpty) {
          items[i] = items[i].copyWith(lots: alloc);
        }
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
        // stocks already updated when lots exist; otherwise update here
        if (!lotsAllocations.containsKey(entry.key)) {
          await txn.update(
            'stocks',
            {'officine': remaining},
            where: 'medicament_id = ?',
            whereArgs: [entry.key],
          );
        }
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
