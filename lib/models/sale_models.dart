import 'package:flutter/material.dart';

class Product {
  final String name;
  final String barcode;
  final double price;
  final String category;

  const Product(this.name, this.barcode, this.price, this.category);
}

class CartItem {
  final String name;
  final String barcode;
  final double price;
  final String category;
  int quantity;

  CartItem({
    required this.name,
    required this.barcode,
    required this.price,
    required this.category,
    required this.quantity,
  });
}

class SaleRecord {
  final String id;
  final String timeLabel;
  final double total;
  final String paymentMethod;
  final String? customer;

  const SaleRecord({
    required this.id,
    required this.timeLabel,
    required this.total,
    required this.paymentMethod,
    this.customer,
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

  String get formattedDate => '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  
  String get displayType {
    return switch(type) {
      'entree' => '📥 Entrée',
      'sortie' => '📤 Sortie',
      'ajustement' => '⚙️ Ajustement',
      'transfert' => '↔️ Transfert',
      _ => type,
    };
  }

  String get displayReason {
    return switch(reason) {
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
    return switch(type) {
      'entree' => const Color(0xFF10B981),
      'sortie' => const Color(0xFFEF4444),
      'ajustement' => const Color(0xFFF59E0B),
      'transfert' => const Color(0xFF3B82F6),
      _ => const Color(0xFF6B7280),
    };
  }
}
