import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:printing/printing.dart';

import '../app_theme.dart';
import '../models/caisse_settings.dart';
import '../models/lot_entry.dart';
import '../models/patient_model.dart';
import '../models/sale_models.dart';
import '../services/local_database_service.dart';
import '../services/product_service.dart';
import '../services/sales_service.dart';
import '../services/ticket_service.dart';
import '../widgets/patient_autocomplete_field.dart';

class VenteCaisseScreen extends StatefulWidget {
  const VenteCaisseScreen({super.key});

  @override
  State<VenteCaisseScreen> createState() => _VenteCaisseScreenState();
}

class _VenteCaisseScreenState extends State<VenteCaisseScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _barcodeController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _historySearchController =
      TextEditingController();
  final List<CartItem> _cartItems = [];
  List<Product> _availableProducts = [];
  List<PatientModel> _patients = [];
  String? _selectedClientId;
  String _clientSearchTerm = '';
  double _remisePercentage = 0;
  double _remiseAmount = 0;
  _RemiseMode _remiseMode = _RemiseMode.pourcentage;
  final TextEditingController _remiseController = TextEditingController();
  String _selectedPaymentMethod = 'Espèces';
  late AnimationController _animationController;
  List<SaleRecord> _salesHistory = [];
  bool _loading = true;
  final TextEditingController _clientInfoController = TextEditingController();
  final FocusNode _clientInfoFocus = FocusNode();
  bool _printCustomerReceipt = true;
  String _clientFieldLabel = 'Client';
  String _currency = 'FCFA';
  String? _logoPath;
  String _pharmacyName = 'Pharmacie PHARMAXY';
  String _pharmacyAddress = '';
  String _pharmacyPhone = '';
  String _pharmacyEmail = '';
  String _pharmacyOrderNumber = '';
  String _pharmacyWebsite = '';
  String _pharmacyHours = '';
  String _emergencyContact = '';
  String _fiscalId = '';
  String _taxDetails = '';
  String _returnPolicy = '';
  String _healthAdvice = '';
  String _loyaltyMessage = '';
  String _ticketLink = '';
  String _ticketFooter = 'Merci de votre confiance. Prompt rétablissement !';

  String _formatLotExpiry(String isoOrLegacy) {
    final raw = isoOrLegacy.trim();
    if (raw.isEmpty) return '-';
    try {
      return DateFormat('MM/yyyy').format(DateTime.parse(raw));
    } catch (_) {
      // Legacy formats like "08/2026" or already formatted strings
      return raw;
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _loadData();
    _loadSettings();
  }

  Future<void> _loadData() async {
    await LocalDatabaseService.instance.init();
    final products = await ProductService.instance.fetchProductsForSale();
    final history = await SalesService.instance.fetchSalesHistory(limit: 30);
    final CaisseSettings caisse = await LocalDatabaseService.instance
        .getCaisseSettings();
    final patients = await LocalDatabaseService.instance.getPatientsLite();
    setState(() {
      _availableProducts = products;
      _salesHistory = history;
      _patients = patients;
      _loading = false;
      _printCustomerReceipt = caisse.printCustomerReceipt;
      _clientFieldLabel = caisse.customerField;
    });
  }

  Future<void> _loadSettings() async {
    final settings = await LocalDatabaseService.instance.getSettings();
    if (!mounted) return;
    setState(() {
      _currency = settings.currency;
      _logoPath = settings.logoPath;
      _pharmacyName = settings.pharmacyName;
      _pharmacyAddress = settings.pharmacyAddress;
      _pharmacyPhone = settings.pharmacyPhone;
      _pharmacyEmail = settings.pharmacyEmail;
      _pharmacyOrderNumber = settings.pharmacyOrderNumber;
      _pharmacyWebsite = settings.pharmacyWebsite;
      _pharmacyHours = settings.pharmacyHours;
      _emergencyContact = settings.emergencyContact;
      _fiscalId = settings.fiscalId;
      _taxDetails = settings.taxDetails;
      _returnPolicy = settings.returnPolicy;
      _healthAdvice = settings.healthAdvice;
      _loyaltyMessage = settings.loyaltyMessage;
      _ticketLink = settings.ticketLink;
      _ticketFooter = settings.ticketFooter;
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _searchController.dispose();
    _historySearchController.dispose();
    _animationController.dispose();
    _clientInfoController.dispose();
    _clientInfoFocus.dispose();
    _remiseController.dispose();
    super.dispose();
  }

  double get _sousTotal =>
      _cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get _montantRemise {
    if (_remiseMode == _RemiseMode.pourcentage) {
      final pct = _remisePercentage.clamp(0, 100);
      return _sousTotal * (pct / 100);
    }
    final amt = _remiseAmount.clamp(0, _sousTotal);
    return amt.toDouble();
  }

  double get _total => _sousTotal - _montantRemise;

  List<Product> get _filteredProducts {
    final search = _searchController.text.toLowerCase();
    final filtered = _availableProducts.where((p) {
      return p.name.toLowerCase().contains(search) ||
          p.barcode.contains(search);
    }).toList();
    filtered.sort((a, b) => a.name.compareTo(b.name));
    return filtered;
  }

  List<SaleRecord> get _filteredSalesHistory {
    final search = _historySearchController.text.toLowerCase();
    return _salesHistory.where((sale) {
      return sale.id.toLowerCase().contains(search) ||
          sale.paymentMethod.toLowerCase().contains(search) ||
          (sale.customer?.toLowerCase().contains(search) ?? false) ||
          (sale.vendor?.toLowerCase().contains(search) ?? false);
    }).toList();
  }

  int _reservedQtyForLot(String productId, String lot, {int? excludeIndex}) {
    var reserved = 0;
    for (var i = 0; i < _cartItems.length; i++) {
      if (excludeIndex != null && i == excludeIndex) continue;
      final item = _cartItems[i];
      if (item.productId != productId) continue;
      final lots = item.lots;
      if (lots == null) continue;
      reserved += lots[lot] ?? 0;
    }
    return reserved;
  }

  Future<Map<String, int>?> _pickLotForProduct(
    Product product, {
    int initialQty = 1,
  }) async {
    final palette = ThemeColors.from(context);
    List<LotEntry> lots = [];
    try {
      lots = await ProductService.instance.fetchLotsForProduct(product.id);
    } catch (_) {}
    if (lots.isEmpty) return null;

    LotEntry? selected = lots.first;
    final qtyCtrl = TextEditingController(text: initialQty.toString());

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final availableForSelected = selected == null
                ? 0
                : selected!.quantite -
                      _reservedQtyForLot(product.id, selected!.lot);
            return AlertDialog(
              backgroundColor: palette.card,
              title: Text(
                'Choisir le lot',
                style: TextStyle(color: palette.text),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<LotEntry>(
                      value: selected,
                      isExpanded: true,
                      items: lots
                          .map(
                            (l) => DropdownMenuItem(
                              value: l,
                              child: Text(
                                '${l.lot} • ${l.quantite} • ${_formatLotExpiry(l.peremptionIso)}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setModalState(() => selected = v ?? selected),
                      decoration: const InputDecoration(
                        labelText: 'Lot disponible',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: qtyCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Quantité',
                        helperText: 'Disponible: $availableForSelected',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Ajouter'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true || selected == null) return null;
    final qty = int.tryParse(qtyCtrl.text.trim()) ?? 0;
    final availableForSelected =
        selected!.quantite - _reservedQtyForLot(product.id, selected!.lot);
    if (qty <= 0 || qty > availableForSelected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Quantité invalide pour le lot ${selected!.lot} (disponible: $availableForSelected)',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
      return null;
    }
    return {selected!.lot: qty};
  }

  Future<void> _editLotsForCartItem(int index) async {
    final item = _cartItems[index];
    final product = _findProduct(item.productId);
    if (product == null) return;
    List<LotEntry> lots = [];
    try {
      lots = await ProductService.instance.fetchLotsForProduct(product.id);
    } catch (_) {}
    if (lots.isEmpty) return;

    final palette = ThemeColors.from(context);
    final allocations = <String, int>{...?item.lots};
    // Ensure every lot has an entry (0 by default)
    for (final l in lots) {
      allocations.putIfAbsent(l.lot, () => 0);
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int totalAllocated = allocations.values.fold(0, (s, v) => s + v);
            final remaining = item.quantity - totalAllocated;

            int availableForLot(LotEntry l) {
              final reservedOther = _reservedQtyForLot(
                product.id,
                l.lot,
                excludeIndex: index,
              );
              final currentAlloc = allocations[l.lot] ?? 0;
              return (l.quantite - reservedOther) + currentAlloc;
            }

            return AlertDialog(
              backgroundColor: palette.card,
              title: Text(
                'Modifier les lots',
                style: TextStyle(color: palette.text),
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${item.name} • Quantité totale: ${item.quantity}',
                      style: TextStyle(color: palette.subText),
                    ),
                    const SizedBox(height: 8),
                    if (remaining != 0)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          remaining > 0
                              ? 'Reste à affecter: $remaining'
                              : 'Sur-affecté: ${-remaining}',
                          style: TextStyle(
                            color: remaining == 0
                                ? palette.subText
                                : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: lots.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: palette.divider),
                        itemBuilder: (context, i) {
                          final l = lots[i];
                          final alloc = allocations[l.lot] ?? 0;
                          final available = availableForLot(l);
                          final peremp = _formatLotExpiry(l.peremptionIso);
                          return Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l.lot,
                                      style: TextStyle(
                                        color: palette.text,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      'Péremption: $peremp • Dispo: $available',
                                      style: TextStyle(
                                        color: palette.subText,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: alloc > 0
                                    ? () => setModalState(() {
                                        allocations[l.lot] = alloc - 1;
                                      })
                                    : null,
                                icon: const Icon(
                                  Icons.remove_circle_outline,
                                  size: 20,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                              SizedBox(
                                width: 46,
                                child: Text(
                                  '$alloc',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: palette.text,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed:
                                    alloc < available &&
                                        totalAllocated < item.quantity
                                    ? () => setModalState(() {
                                        allocations[l.lot] = alloc + 1;
                                      })
                                    : null,
                                icon: const Icon(
                                  Icons.add_circle_outline,
                                  size: 20,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton.icon(
                  onPressed: remaining == 0
                      ? () => Navigator.pop(context, true)
                      : null,
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    allocations.removeWhere((k, v) => v <= 0);
    setState(() {
      _cartItems[index] = item.copyWith(
        lots: allocations.isEmpty ? null : allocations,
      );
    });
  }

  void _removeOneFromCart(int index) {
    final item = _cartItems[index];
    if (item.quantity <= 0) return;
    if (item.lots != null && item.lots!.isNotEmpty) {
      final lots = Map<String, int>.from(item.lots!);
      // Remove from any lot with qty > 0 (prefer the largest)
      final ordered = lots.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      for (final e in ordered) {
        if (e.value <= 0) continue;
        lots[e.key] = e.value - 1;
        if (lots[e.key] == 0) lots.remove(e.key);
        break;
      }
      setState(() {
        _cartItems[index] = item.copyWith(
          quantity: item.quantity - 1,
          lots: lots.isEmpty ? null : lots,
        );
        if (_cartItems[index].quantity <= 0) {
          _cartItems.removeAt(index);
        }
      });
      return;
    }
    _updateQuantity(index, item.quantity - 1);
  }

  Future<bool> _addToCart(Product product) async {
    if (product.availableStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock épuisé pour ${product.name}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return false;
    }

    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id,
    );
    final currentQty = existingIndex != -1
        ? _cartItems[existingIndex].quantity
        : 0;

    // If already in cart and has lots allocations, auto-add 1 to same/preferred lot
    if (existingIndex != -1) {
      final existing = _cartItems[existingIndex];
      if (existing.lots != null && existing.lots!.isNotEmpty) {
        List<LotEntry> lots = [];
        try {
          lots = await ProductService.instance.fetchLotsForProduct(product.id);
        } catch (_) {}
        if (lots.isNotEmpty) {
          final allocations = Map<String, int>.from(existing.lots!);
          // Prefer lot with highest allocated qty, else earliest available.
          String? preferredLot = allocations.entries.isNotEmpty
              ? (allocations.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .first
                    .key
              : null;
          // Find a lot with availability.
          LotEntry? target;
          if (preferredLot != null) {
            target = lots.firstWhere(
              (l) => l.lot == preferredLot,
              orElse: () => lots.first,
            );
            final available =
                target.quantite -
                _reservedQtyForLot(
                  product.id,
                  target.lot,
                  excludeIndex: existingIndex,
                );
            if (available <= 0) {
              target = null;
            }
          }
          if (target == null) {
            for (final l in lots) {
              final available =
                  l.quantite -
                  _reservedQtyForLot(
                    product.id,
                    l.lot,
                    excludeIndex: existingIndex,
                  );
              if (available > 0) {
                target = l;
                break;
              }
            }
          }
          if (target == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Stock limité pour ${product.name}'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
            return false;
          }
          if (currentQty + 1 > product.availableStock) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Stock limité à ${product.availableStock} pour ce produit',
                ),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
            return false;
          }
          allocations[target.lot] = (allocations[target.lot] ?? 0) + 1;
          setState(() {
            _cartItems[existingIndex] = existing.copyWith(
              quantity: existing.quantity + 1,
              lots: allocations,
            );
          });
          _animationController.forward(from: 0);
          return true;
        }
      }

      // No lots allocations yet, or no lots in DB: just increment quantity.
      if (currentQty + 1 > product.availableStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Stock limité à ${product.availableStock} pour ce produit',
            ),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
        return false;
      }
      setState(() {
        _cartItems[existingIndex].quantity++;
      });
      _animationController.forward(from: 0);
      return true;
    }

    // Not yet in cart: if product has lots, ask once.
    Map<String, int>? pickedLots;
    try {
      final lots = await ProductService.instance.fetchLotsForProduct(
        product.id,
      );
      if (lots.isNotEmpty) {
        pickedLots = await _pickLotForProduct(product);
        if (pickedLots == null) return false;
      }
    } catch (_) {}

    final addingQty = pickedLots?.values.fold<int>(0, (s, v) => s + v) ?? 1;
    if (currentQty + addingQty > product.availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Stock limité à ${product.availableStock} pour ce produit',
          ),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return false;
    }
    setState(() {
      _cartItems.add(
        CartItem(
          productId: product.id,
          name: product.name,
          barcode: product.barcode,
          price: product.price,
          quantity: addingQty,
          category: product.category,
          ordonnance: product.ordonnance,
          controle: product.controle,
          stupefiant: product.stupefiant,
          lots: pickedLots,
        ),
      );
    });
    _animationController.forward(from: 0);
    return true;
  }

  void _removeFromCart(int index) {
    setState(() => _cartItems.removeAt(index));
  }

  void _updateQuantity(int index, int newQuantity) {
    final item = _cartItems[index];
    final availableStock = _availableStockForItem(item, newQuantity);
    if (availableStock > 0 && newQuantity > availableStock) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock limité à $availableStock pour ${item.name}'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    }
    setState(() {
      if (newQuantity > 0) {
        _cartItems[index].quantity = newQuantity;
      } else {
        _cartItems.removeAt(index);
      }
    });
  }

  Future<void> _scanBarcode() async {
    final barcode = _barcodeController.text.trim();
    if (barcode.isEmpty) return;
    final product = _availableProducts.firstWhere(
      (p) => p.barcode == barcode,
      orElse: () => const Product(
        id: '',
        name: 'Produit introuvable',
        barcode: '',
        price: 0,
        category: '',
        availableStock: 0,
      ),
    );
    if (product.price > 0) {
      final added = await _addToCart(product);
      _barcodeController.clear();
      if (added) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} ajouté au panier'),
            backgroundColor: const Color(0xFF10B981),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Code-barres invalide'),
          backgroundColor: Color(0xFFEF4444),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
      _remisePercentage = 0;
      _remiseAmount = 0;
      _remiseController.clear();
    });
  }

  Future<void> _completeTransaction() async {
    final saleId = 'CMD-${DateTime.now().millisecondsSinceEpoch}';
    final clientInfo = _clientInfoController.text.trim();
    final receiptTotal = _total;
    final cartSnapshot = List<CartItem>.from(_cartItems);
    String? clientId = _selectedClientId;
    if (clientInfo.isNotEmpty && clientId == null) {
      clientId = await _ensureClientExists(clientInfo);
    }
    try {
      await SalesService.instance.recordSale(
        id: saleId,
        total: _total,
        paymentMethod: _selectedPaymentMethod,
        type: 'Vente comptoir',
        clientId: clientInfo.isEmpty ? null : clientId,
        items: cartSnapshot,
      );
    } on StockException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
      return;
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de finaliser la vente'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    await _loadData();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paiement effectué avec succès'),
        backgroundColor: Color(0xFF10B981),
        duration: Duration(seconds: 2),
      ),
    );
    final receiptItems = cartSnapshot;
    _clearCart();
    setState(() {
      _clientInfoController.clear();
      _selectedClientId = null;
      _clientSearchTerm = '';
    });
    _clientInfoFocus.unfocus();
    if (_printCustomerReceipt) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ticket client généré ${clientInfo.isNotEmpty ? 'pour $clientInfo' : ''}',
          ),
          backgroundColor: const Color(0xFF3B82F6),
          duration: const Duration(seconds: 2),
        ),
      );
      _showReceiptDialog(
        id: saleId,
        clientInfo: clientInfo,
        total: receiptTotal,
        paymentMethod: _selectedPaymentMethod,
        items: receiptItems,
      );
    }
  }

  Future<String?> _ensureClientExists(String input) async {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;

    // Try match existing by name or phone
    final lower = trimmed.toLowerCase();
    final existing = _patients.firstWhere(
      (p) =>
          p.name.toLowerCase() == lower ||
          (p.phone.isNotEmpty && lower.contains(p.phone.replaceAll(' ', ''))),
      orElse: () => const PatientModel(
        id: '',
        name: '',
        phone: '',
        nir: '',
        mutuelle: '',
        email: '',
        dateOfBirthIso: '',
      ),
    );
    if (existing.id.isNotEmpty) {
      setState(() {
        _selectedClientId = existing.id;
        _clientInfoController.text = existing.displayLabel;
      });
      return existing.id;
    }

    // Parse "Nom - téléphone" if provided
    String name = trimmed;
    String phone = '';
    if (trimmed.contains('-')) {
      final parts = trimmed.split('-');
      name = parts.first.trim();
      phone = parts.skip(1).join('-').trim();
    }
    final phoneDigits = phone.replaceAll(RegExp(r'\\s+'), '');
    if (!RegExp(r'^\\+?\\d{6,}$').hasMatch(phoneDigits)) {
      phone = '';
    }

    final newId = await LocalDatabaseService.instance.insertQuickPatient(
      name: name,
      phone: phone,
    );
    final newPatient = PatientModel(
      id: newId,
      name: name,
      phone: phone,
      nir: '',
      mutuelle: '',
      email: '',
      dateOfBirthIso: '',
    );
    setState(() {
      _patients.add(newPatient);
      _patients.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      _selectedClientId = newId;
    });
    return newId;
  }

  void _tryAutoSelectClient(String input) {
    final raw = input.trim();
    if (raw.isEmpty) return;
    final lower = raw.toLowerCase();
    final normalizedDigits = lower.replaceAll(RegExp(r'\\s+'), '');
    final match = _patients.where((p) {
      final nameLower = p.name.toLowerCase();
      final phoneDigits = p.phone.replaceAll(RegExp(r'\\s+'), '');
      final nirLower = p.nir.toLowerCase();
      return nameLower == lower ||
          (phoneDigits.isNotEmpty && normalizedDigits.contains(phoneDigits)) ||
          (nirLower.isNotEmpty && nirLower == lower);
    }).toList();
    if (match.length == 1) {
      final p = match.first;
      setState(() {
        _selectedClientId = p.id;
        _clientInfoController.text = p.displayLabel;
        _clientSearchTerm = p.displayLabel;
      });
    }
  }

  void _processPayment() {
    if (_cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le panier est vide'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    showDialog(context: context, builder: (_) => _buildPaymentDialog());
  }

  void _showReceiptDialog({
    required String id,
    required String clientInfo,
    required double total,
    required String paymentMethod,
    required List<CartItem> items,
  }) {
    final palette = ThemeColors.from(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ticket client'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pharmacie PHARMAXY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              Text('Ticket #$id', style: TextStyle(color: palette.subText)),
              const SizedBox(height: 12),
              if (items.isNotEmpty)
                ...items.map(
                  (item) => Text(
                    '${item.name} x${item.quantity} • ${(item.price * item.quantity).toStringAsFixed(0)} FCFA',
                  ),
                ),
              if (items.isEmpty)
                Text(
                  'Aucun détail reçu',
                  style: TextStyle(color: palette.subText),
                ),
              const SizedBox(height: 12),
              Text(
                'Client: ${clientInfo.isNotEmpty ? clientInfo : 'Générique'}',
              ),
              Text('Méthode: $paymentMethod'),
              Text('Total: ${total.toStringAsFixed(0)} FCFA'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _promptCancelSale(SaleRecord sale) async {
    final reasonCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Annuler la vente'),
          content: TextField(
            controller: reasonCtrl,
            decoration: const InputDecoration(
              labelText: 'Motif de l\'annulation',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (reasonCtrl.text.trim().isEmpty) return;
                Navigator.of(context).pop(true);
              },
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      await SalesService.instance.cancelSale(sale.id, reasonCtrl.text.trim());
      await _loadData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vente annulée'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Hauteur un peu plus grande pour laisser respirer le panier.
          final rowHeight = constraints.maxHeight - 24;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(palette),
                  const SizedBox(height: 24),

                  // === SECTION PRINCIPALE : Scan + Produits + Panier + Totaux ===
                  SizedBox(
                    height: rowHeight > 620 ? rowHeight : 620,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildLeftColumn(palette)),
                        const SizedBox(width: 20),
                        SizedBox(width: 420, child: _buildRightColumn(palette)),
                      ],
                    ),
                  ),

                  // === ESPACE POUR DESCENDRE L'HISTORIQUE ===
                  const SizedBox(height: 40),

                  // === HISTORIQUE DES VENTES TOUT EN BAS ===
                  _buildSalesHistoryTable(palette, height: 360),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(ThemeColors palette) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Point de Vente',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: palette.text,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              'Scan, vente et encaissement',
              style: TextStyle(fontSize: 16, color: palette.subText),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF10B981), Color(0xFF34D399)],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: const [
              Icon(Icons.point_of_sale, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Caisse Active',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeftColumn(ThemeColors palette) {
    return Column(
      children: [
        _buildScanSearch(palette),
        const SizedBox(height: 20),
        Expanded(child: _buildProductsGrid(palette)),
      ],
    );
  }

  Widget _buildScanSearch(ThemeColors palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(palette),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _barcodeController,
                  style: TextStyle(color: palette.text, fontSize: 18),
                  decoration: InputDecoration(
                    hintText: 'Scannez ou saisissez le code-barres',
                    hintStyle: TextStyle(color: palette.subText),
                    prefixIcon: const Icon(
                      Icons.qr_code_scanner,
                      color: Color(0xFF10B981),
                    ),
                    filled: true,
                    fillColor: palette.isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _scanBarcode(),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _scanBarcode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.all(18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Icon(Icons.add_shopping_cart, size: 26),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            style: TextStyle(color: palette.text),
            decoration: InputDecoration(
              hintText: 'Rechercher un produit...',
              hintStyle: TextStyle(color: palette.subText),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF3B82F6)),
              filled: true,
              fillColor: palette.isDark ? Colors.grey[800] : Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsGrid(ThemeColors palette) {
    final products = _filteredProducts;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Produits Disponibles', palette),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) =>
                  _buildProductCard(products[index], palette),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product, ThemeColors palette) {
    return GestureDetector(
      onTap: () async => _addToCart(product),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF3B82F6).withOpacity(0.2),
              const Color(0xFF3B82F6).withOpacity(0.4),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.medication, color: Color(0xFF3B82F6), size: 32),
              const SizedBox(height: 8),
              Text(
                product.name,
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (product.stupefiant || product.ordonnance || product.controle)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    alignment: WrapAlignment.center,
                    children: [
                      if (product.stupefiant)
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 14,
                          color: Colors.redAccent,
                        ),
                      if (product.ordonnance)
                        const Icon(
                          Icons.description,
                          size: 14,
                          color: Colors.deepPurple,
                        ),
                      if (product.controle)
                        const Icon(
                          Icons.verified_user,
                          size: 14,
                          color: Colors.orange,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                '${product.price.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Disponible: ${product.availableStock}',
                style: TextStyle(color: palette.subText, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRightColumn(ThemeColors palette) {
    return Column(
      children: [
        Expanded(child: _buildCart(palette)),
        const SizedBox(height: 20),
        _buildTotals(palette, maxHeight: 380),
      ],
    );
  }

  Widget _buildCart(ThemeColors palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(palette),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Panier (${_cartItems.length})',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              if (_cartItems.isNotEmpty)
                IconButton(
                  onPressed: _clearCart,
                  icon: const Icon(
                    Icons.delete_sweep,
                    color: Color(0xFFEF4444),
                  ),
                  tooltip: 'Vider le panier',
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cartItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 64,
                          color: palette.subText.withOpacity(0.4),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Panier vide',
                          style: TextStyle(
                            color: palette.subText,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _cartItems.length,
                    itemBuilder: (context, index) =>
                        _buildCartItem(_cartItems[index], index, palette),
                  ),
          ),
        ],
      ),
    );
  }

  // HISTORIQUE TOUT EN BAS
  Widget _buildSalesHistoryTable(ThemeColors palette, {double height = 360}) {
    final history = _filteredSalesHistory;
    return SizedBox(
      height: height,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(palette),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _sectionTitle('Historique du jour', palette),
                SizedBox(
                  width: 260,
                  child: TextField(
                    controller: _historySearchController,
                    style: TextStyle(color: palette.text),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un ticket...',
                      hintStyle: TextStyle(color: palette.subText),
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: palette.isDark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(color: palette.divider),
            const SizedBox(height: 12),
            if (history.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Aucune vente enregistrée',
                    style: TextStyle(color: palette.subText),
                  ),
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    _historyHeaderRow(palette),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (context, index) =>
                            _historyDataRow(history[index], palette),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _historyHeaderRow(ThemeColors palette) {
    return Row(
      children: [
        _historyCell('Ticket', palette, flex: 2, isHeader: true),
        _historyCell('Heure', palette, isHeader: true),
        _historyCell('Montant', palette, isHeader: true),
        _historyCell('Paiement', palette, isHeader: true),
        _historyCell('Client', palette, isHeader: true),
        _historyCell('Vendeur', palette, isHeader: true),
        _historyCell('Action', palette, isHeader: true, alignEnd: true),
      ],
    );
  }

  Widget _historyDataRow(SaleRecord sale, ThemeColors palette) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          _historyCell(sale.id, palette, flex: 2),
          _historyCell(sale.timeLabel, palette),
          _historyCell('${sale.total.toStringAsFixed(0)} FCFA', palette),
          _historyCell(sale.paymentMethod, palette),
          _historyCell(sale.customer ?? 'Client', palette),
          _historyCell(sale.vendor ?? 'Vendeur', palette),
          _historyCell(
            '',
            palette,
            alignEnd: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sale.status == 'Annulée')
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Annulée',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (sale.cancellationReason?.isNotEmpty ?? false)
                          Text(
                            sale.cancellationReason!,
                            style: TextStyle(
                              color: palette.subText,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) => _onHistoryAction(sale, value),
                  icon: const Icon(Icons.more_vert, size: 18),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'print',
                      child: Text('Imprimer'),
                    ),
                    const PopupMenuItem(
                      value: 'save',
                      child: Text('Enregistrer'),
                    ),
                    if (sale.status != 'Annulée')
                      const PopupMenuItem(
                        value: 'cancel',
                        child: Text('Annuler'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _historyCell(
    String text,
    ThemeColors palette, {
    int flex = 1,
    bool isHeader = false,
    bool alignEnd = false,
    Widget? child,
  }) {
    final content =
        child ??
        Text(
          text,
          style: TextStyle(
            color: palette.text,
            fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
          ),
        );
    return Expanded(
      flex: flex,
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: content,
      ),
    );
  }

  Widget _buildCartItem(CartItem item, int index, ThemeColors palette) {
    final lotsText = item.lots != null && item.lots!.isNotEmpty
        ? 'Lots: ${item.lots!.entries.map((e) => '${e.key} x${e.value}').join(', ')}'
        : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.grey[800] : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: palette.isDark ? Colors.white12 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF10B981).withOpacity(0.2),
                  const Color(0xFF10B981).withOpacity(0.4),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.medication,
              color: Color(0xFF10B981),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                if (item.stupefiant || item.ordonnance || item.controle)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 2,
                      children: [
                        if (item.stupefiant)
                          const Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                        if (item.ordonnance)
                          const Icon(
                            Icons.description,
                            size: 14,
                            color: Colors.deepPurple,
                          ),
                        if (item.controle)
                          const Icon(
                            Icons.verified_user,
                            size: 14,
                            color: Colors.orange,
                          ),
                      ],
                    ),
                  ),
                Text(
                  '${item.price.toStringAsFixed(0)} FCFA',
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 13,
                  ),
                ),
                if (lotsText.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      lotsText,
                      style: TextStyle(
                        fontSize: 12,
                        color: palette.subText,
                        fontFamily: 'Roboto Mono',
                      ),
                    ),
                  ),
                if (item.productId != null && item.productId!.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _editLotsForCartItem(index),
                      icon: const Icon(Icons.layers, size: 16),
                      label: const Text('Modifier lots'),
                      style: TextButton.styleFrom(
                        foregroundColor: palette.subText,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () => _removeOneFromCart(index),
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Color(0xFFEF4444),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: palette.isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.quantity}',
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              IconButton(
                onPressed: () async {
                  final product = _findProduct(item.productId);
                  if (product == null) {
                    _updateQuantity(index, item.quantity + 1);
                    return;
                  }
                  await _addToCart(product);
                },
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Text(
            '${(item.price * item.quantity).toStringAsFixed(0)} F',
            style: TextStyle(
              color: palette.text,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () => _removeFromCart(index),
            icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
          ),
        ],
      ),
    );
  }

  Widget _buildTotals(ThemeColors palette, {double? maxHeight}) {
    final content = Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Remise',
              style: TextStyle(color: palette.subText, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: SegmentedButton<_RemiseMode>(
                      segments: const [
                        ButtonSegment(
                          value: _RemiseMode.pourcentage,
                          label: Text('%'),
                          icon: Icon(Icons.percent, size: 16),
                        ),
                        ButtonSegment(
                          value: _RemiseMode.montant,
                          label: Text('FCFA'),
                          icon: Icon(Icons.money, size: 16),
                        ),
                      ],
                      selected: {_remiseMode},
                      onSelectionChanged: (v) {
                        setState(() {
                          _remiseMode = v.first;
                          _remiseController.text =
                              _remiseMode == _RemiseMode.pourcentage
                              ? (_remisePercentage == 0
                                    ? ''
                                    : _remisePercentage.toStringAsFixed(0))
                              : (_remiseAmount == 0
                                    ? ''
                                    : _remiseAmount.toStringAsFixed(0));
                        });
                      },
                      style: const ButtonStyle(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 140,
                  height: 44,
                  child: TextField(
                    controller: _remiseController,
                    style: TextStyle(color: palette.text),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: palette.subText),
                      suffixText: _remiseMode == _RemiseMode.pourcentage
                          ? '%'
                          : _currency,
                      suffixStyle: TextStyle(color: palette.subText),
                      filled: true,
                      fillColor: palette.isDark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        final parsed =
                            double.tryParse(
                              value.replaceAll(' ', '').replaceAll(',', '.'),
                            ) ??
                            0;
                        if (_remiseMode == _RemiseMode.pourcentage) {
                          _remisePercentage = parsed;
                        } else {
                          _remiseAmount = parsed;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Divider(color: palette.divider),
        const SizedBox(height: 16),
        _buildTotalRow('Sous-total', _sousTotal, false, palette),
        const SizedBox(height: 12),
        _buildTotalRow(
          'Remise',
          _montantRemise,
          false,
          palette,
          color: const Color(0xFFEF4444),
        ),
        const SizedBox(height: 16),
        Divider(color: palette.divider, thickness: 2),
        const SizedBox(height: 16),
        _buildTotalRow('TOTAL', _total, true, palette),
        const SizedBox(height: 24),
        PatientAutocompleteField(
          palette: palette,
          patients: _patients,
          controller: _clientInfoController,
          focusNode: _clientInfoFocus,
          labelText: _clientFieldLabel,
          hintText: 'Ex: Jean Dupont - 99XXXXXX (nouveau si non trouvé)',
          onChanged: (v) => setState(() {
            _selectedClientId = null;
            _clientSearchTerm = v;
          }),
          onSubmitted: _tryAutoSelectClient,
          onSelected: (p) {
            setState(() {
              _selectedClientId = p.id;
              _clientInfoController.text = p.displayLabel;
              _clientSearchTerm = p.displayLabel;
            });
          },
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: const Text('Imprimer ticket client'),
          value: _printCustomerReceipt,
          onChanged: (value) => setState(() => _printCustomerReceipt = value),
        ),
        Row(
          children: [
            Expanded(
              child: _buildPaymentMethodButton('Espèces', Icons.money, palette),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPaymentMethodButton(
                'Carte',
                Icons.credit_card,
                palette,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPaymentMethodButton(
                'Mobile',
                Icons.phone_android,
                palette,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 8,
              shadowColor: const Color(0xFF10B981).withOpacity(0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.payment, size: 28),
                SizedBox(width: 12),
                Text(
                  'PAYER',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final container = Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(palette),
      child: maxHeight == null
          ? content
          : SingleChildScrollView(child: content),
    );

    if (maxHeight == null) return container;
    return SizedBox(height: maxHeight, child: container);
  }

  Widget _buildTotalRow(
    String label,
    double amount,
    bool isTotal,
    ThemeColors palette, {
    Color? color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color ?? (isTotal ? palette.text : palette.subText),
            fontSize: isTotal ? 22 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} FCFA',
          style: TextStyle(
            color: color ?? (isTotal ? const Color(0xFF10B981) : palette.text),
            fontSize: isTotal ? 24 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodButton(
    String method,
    IconData icon,
    ThemeColors palette,
  ) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF3B82F6)],
                )
              : null,
          color: isSelected
              ? null
              : (palette.isDark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B82F6) : palette.divider,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : palette.subText,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              method,
              style: TextStyle(
                color: isSelected ? Colors.white : palette.subText,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDialog() {
    final palette = ThemeColors.from(context);
    final montantDonneController = TextEditingController();
    double montantDonne = 0;

    return StatefulBuilder(
      builder: (context, setDialogState) {
        final monnaie = montantDonne - _total;
        return AlertDialog(
          backgroundColor: palette.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.payment, color: Color(0xFF10B981), size: 32),
              const SizedBox(width: 12),
              Text(
                'Finaliser le Paiement',
                style: TextStyle(color: palette.text, fontSize: 22),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.2),
                        const Color(0xFF10B981).withOpacity(0.4),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Montant à payer',
                        style: TextStyle(color: palette.subText, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_total.toStringAsFixed(0)} FCFA',
                        style: TextStyle(
                          color: palette.text,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Méthode: $_selectedPaymentMethod',
                  style: TextStyle(color: palette.subText, fontSize: 16),
                ),
                const SizedBox(height: 16),
                if (_selectedPaymentMethod == 'Espèces') ...[
                  TextField(
                    controller: montantDonneController,
                    style: TextStyle(color: palette.text, fontSize: 20),
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Montant donné',
                      labelStyle: TextStyle(color: palette.subText),
                      suffixText: 'FCFA',
                      suffixStyle: TextStyle(color: palette.subText),
                      filled: true,
                      fillColor: palette.isDark
                          ? Colors.grey[800]
                          : Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setDialogState(
                      () => montantDonne = double.tryParse(value) ?? 0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (monnaie >= 0 && montantDonne > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: palette.isDark
                            ? Colors.grey[800]
                            : Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Monnaie à rendre:',
                            style: TextStyle(
                              color: palette.subText,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '${monnaie.toStringAsFixed(0)} FCFA',
                            style: const TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: TextStyle(color: palette.subText, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_selectedPaymentMethod == 'Espèces' &&
                    montantDonne < _total) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Montant insuffisant'),
                      backgroundColor: Color(0xFFEF4444),
                    ),
                  );
                  return;
                }
                Navigator.pop(context);
                await _completeTransaction();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
              ),
              child: const Text(
                'Confirmer le Paiement',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  int _availableStockForItem(CartItem item, int fallback) {
    final product = _findProduct(item.productId);
    if (product == null) return fallback;
    return product.availableStock;
  }

  Product? _findProduct(String? id) {
    if (id == null || id.isEmpty) return null;
    final matches = _availableProducts.where((p) => p.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  // Helpers
  BoxDecoration _cardDecoration(ThemeColors palette) {
    return BoxDecoration(
      color: palette.card,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _sectionTitle(String text, ThemeColors palette) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: palette.text,
      ),
    );
  }

  Future<void> _printSaleReceipt(SaleRecord sale) async {
    try {
      final bytes = await TicketService.instance.generateReceipt(
        saleId: sale.id,
        client: sale.customer ?? 'Client',
        total: sale.total,
        paymentMethod: sale.paymentMethod,
        items: sale.items,
        vendor: sale.vendor,
        logoPath: _logoPath,
        currency: _currency,
        pharmacyName: _pharmacyName,
        pharmacyAddress: _pharmacyAddress,
        pharmacyPhone: _pharmacyPhone,
        pharmacyEmail: _pharmacyEmail,
        pharmacyOrderNumber: _pharmacyOrderNumber,
        pharmacyWebsite: _pharmacyWebsite,
        pharmacyHours: _pharmacyHours,
        emergencyContact: _emergencyContact,
        fiscalId: _fiscalId,
        taxDetails: _taxDetails,
        returnPolicy: _returnPolicy,
        healthAdvice: _healthAdvice,
        loyaltyMessage: _loyaltyMessage,
        ticketLink: _ticketLink,
        footerMessage: _ticketFooter,
      );
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } catch (e) {
      debugPrint('Erreur d\'impression: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur d\'impression: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _savePdfAndOpen(SaleRecord sale) async {
    final dir = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choisissez un dossier de sauvegarde',
    );
    if (dir == null) return;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final receiptPath = '$dir/ticket_${sale.id}_$timestamp.pdf';
    try {
      final bytes = await TicketService.instance.generateReceipt(
        saleId: sale.id,
        client: sale.customer ?? 'Client',
        total: sale.total,
        paymentMethod: sale.paymentMethod,
        items: sale.items,
        vendor: sale.vendor,
        logoPath: _logoPath,
        currency: _currency,
        pharmacyName: _pharmacyName,
        pharmacyAddress: _pharmacyAddress,
        pharmacyPhone: _pharmacyPhone,
        pharmacyEmail: _pharmacyEmail,
        pharmacyOrderNumber: _pharmacyOrderNumber,
        pharmacyWebsite: _pharmacyWebsite,
        pharmacyHours: _pharmacyHours,
        emergencyContact: _emergencyContact,
        fiscalId: _fiscalId,
        taxDetails: _taxDetails,
        returnPolicy: _returnPolicy,
        healthAdvice: _healthAdvice,
        loyaltyMessage: _loyaltyMessage,
        ticketLink: _ticketLink,
        footerMessage: _ticketFooter,
      );
      final file = File(receiptPath);
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('Ticket PDF écrit dans $receiptPath');

      try {
        if (Platform.isMacOS) {
          final openResult = await Process.run('open', [file.path]);
          if (openResult.exitCode != 0) {
            throw Exception(
              openResult.stderr ?? 'open exited with ${openResult.exitCode}',
            );
          }
        } else {
          await OpenFilex.open(file.path);
        }
      } catch (openError, stack) {
        debugPrint('Impossible d\'ouvrir le ticket: $openError\n$stack');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Ticket enregistré mais non ouvert automatiquement: $openError',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ticket sauvegardé: ${file.path}'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e, stack) {
      debugPrint('Erreur lors de l\'enregistrement du ticket : $e\n$stack');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impossible d\'enregistrer le ticket: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onHistoryAction(SaleRecord sale, String action) async {
    if (action == 'print') {
      await _printSaleReceipt(sale);
    } else if (action == 'save') {
      await _savePdfAndOpen(sale);
    } else if (action == 'cancel') {
      await _promptCancelSale(sale);
    }
  }
}

enum _RemiseMode { pourcentage, montant }
