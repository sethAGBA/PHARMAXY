import 'package:flutter/material.dart';
import 'dart:convert';

class Product {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final String category;
  final int availableStock;
  final bool ordonnance;
  final bool controle;
  final bool stupefiant;

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.category,
    this.availableStock = 0,
    this.ordonnance = false,
    this.controle = false,
    this.stupefiant = false,
  });
}

class CartItem {
  final String? productId;
  final String name;
  final String barcode;
  final double price;
  final String category;
  final bool ordonnance;
  final bool controle;
  final bool stupefiant;
  final Map<String, int>? lots;
  int quantity;

  CartItem({
    this.productId,
    required this.name,
    required this.barcode,
    required this.price,
    required this.category,
    required this.quantity,
    this.ordonnance = false,
    this.controle = false,
    this.stupefiant = false,
    this.lots,
  });

  Map<String, Object?> toMap() {
    return {
      'product_id': productId,
      'name': name,
      'barcode': barcode,
      'price': price,
      'category': category,
      'quantity': quantity,
      'ordonnance': ordonnance ? 1 : 0,
      'controle': controle ? 1 : 0,
      'stupefiant': stupefiant ? 1 : 0,
      if (lots != null) 'lots': jsonEncode(lots),
    };
  }

  factory CartItem.fromMap(Map<String, Object?> map) {
    Map<String, int>? parsedLots;
    final lotsRaw = map['lots'];
    if (lotsRaw is String && lotsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(lotsRaw);
        if (decoded is Map) {
          parsedLots = decoded.map(
            (k, v) => MapEntry(k.toString(), (v as num).toInt()),
          );
        }
      } catch (_) {}
    } else if (lotsRaw is Map) {
      parsedLots = lotsRaw.map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      );
    }
    return CartItem(
      productId: map['product_id'] as String?,
      name: map['name'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      category: map['category'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      ordonnance: (map['ordonnance'] as num?)?.toInt() == 1,
      controle: (map['controle'] as num?)?.toInt() == 1,
      stupefiant: (map['stupefiant'] as num?)?.toInt() == 1,
      lots: parsedLots,
    );
  }

  CartItem copyWith({int? quantity, Map<String, int>? lots}) {
    return CartItem(
      productId: productId,
      name: name,
      barcode: barcode,
      price: price,
      category: category,
      quantity: quantity ?? this.quantity,
      ordonnance: ordonnance,
      controle: controle,
      stupefiant: stupefiant,
      lots: lots ?? this.lots,
    );
  }
}

class SaleRecord {
  final String id;
  final String timeLabel;
  final double total;
  final String paymentMethod;
  final String? customer;
  final String? vendor;
  final String status;
  final String? cancellationReason;
  final List<CartItem> items;

  const SaleRecord({
    required this.id,
    required this.timeLabel,
    required this.total,
    required this.paymentMethod,
    this.customer,
    this.vendor,
    this.status = 'Réglée',
    this.cancellationReason,
    this.items = const [],
  });
}

class StockMovement {
  final String id;
  final String productName;
  final String type; // 'entree', 'sortie', 'ajustement', 'transfert'
  final int quantity;
  final int quantityBefore;
  final int quantityAfter;
  final String reason; // 'achat', 'vente', 'inventaire', 'perte', etc.
  final DateTime date;
  final String? reference; // numéro bon de livraison, facture, etc.
  final String? notes;
  final String user; // utilisateur qui a enregistré

  const StockMovement({
    required this.id,
    required this.productName,
    required this.type,
    required this.quantity,
    required this.quantityBefore,
    required this.quantityAfter,
    required this.reason,
    required this.date,
    this.reference,
    this.notes,
    required this.user,
  });

  String get formattedDate =>
      '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

  String get displayType {
    return switch (type) {
      'entree' => '📥 Entrée',
      'sortie' => '📤 Sortie',
      'ajustement' => '⚙️ Ajustement',
      'transfert' => '↔️ Transfert',
      _ => type,
    };
  }

  String get displayReason {
    return switch (reason) {
      'achat' => 'Achat fournisseur',
      'vente' => 'Vente caisse',
      'inventaire' => 'Inventaire',
      'perte' => 'Perte/Casse',
      'correction' => 'Correction',
      'retour' => 'Retour client',
      'expiration' => 'Péremption',
      _ => reason,
    };
  }

  Color get typeColor {
    return switch (type) {
      'entree' => const Color(0xFF10B981),
      'sortie' => const Color(0xFFEF4444),
      'ajustement' => const Color(0xFFF59E0B),
      'transfert' => const Color(0xFF3B82F6),
      _ => const Color(0xFF6B7280),
    };
  }
}
