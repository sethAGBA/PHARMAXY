import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../models/sale_models.dart';
import '../services/local_database_service.dart';

class SalesService {
  SalesService._();
  static final SalesService instance = SalesService._();

  final _db = LocalDatabaseService.instance;

  Future<List<SaleRecord>> fetchSalesHistory({int limit = 30}) async {
    final db = _db.db;
    final rows = await db.query(
      'ventes',
      orderBy: 'date DESC',
      limit: limit,
    );
    return rows.map((row) {
      final date = DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now();
      return SaleRecord(
        id: row['id'] as String? ?? '',
        timeLabel: DateFormat('HH:mm').format(date),
        total: (row['montant'] as num?)?.toDouble() ?? 0,
        paymentMethod: row['mode'] as String? ?? '',
        customer: row['client_id'] as String?,
      );
    }).toList();
  }

  Future<void> recordSale({
    required String id,
    required double total,
    required String paymentMethod,
    required String type,
    String? clientId,
  }) async {
    final db = _db.db;
    await db.insert(
      'ventes',
      {
        'id': id,
        'date': DateTime.now().toIso8601String(),
        'montant': total,
        'mode': paymentMethod,
        'client_id': clientId ?? '',
        'type': type,
        'statut': 'Réglée',
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
