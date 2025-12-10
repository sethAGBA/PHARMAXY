import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String barcode;
  final double price;
  final String category;
  final int availableStock;

  const Product({
    required this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.category,
    this.availableStock = 0,
  });
}

class CartItem {
  final String? productId;
  final String name;
  final String barcode;
  final double price;
  final String category;
  int quantity;

  CartItem({
    this.productId,
    required this.name,
    required this.barcode,
    required this.price,
    required this.category,
    required this.quantity,
  });

  Map<String, Object?> toMap() {
    return {
      'product_id': productId,
      'name': name,
      'barcode': barcode,
      'price': price,
      'category': category,
      'quantity': quantity,
    };
  }

  factory CartItem.fromMap(Map<String, Object?> map) {
    return CartItem(
      productId: map['product_id'] as String?,
      name: map['name'] as String? ?? '',
      barcode: map['barcode'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      category: map['category'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
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
