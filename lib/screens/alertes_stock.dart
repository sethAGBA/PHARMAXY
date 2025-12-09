// screens/alertes_stock.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../services/product_service.dart';
import '../services/local_database_service.dart';

class AlertesStockScreen extends StatefulWidget {
  const AlertesStockScreen({super.key});

  @override
  State<AlertesStockScreen> createState() => _AlertesStockScreenState();
}

class _AlertesStockScreenState extends State<AlertesStockScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'Toutes';
  String _selectedLab = 'Tous';

  // Data loaded from DB
  List<AlertItem> _alerts = [];
  bool _loading = true;
  String? _error;

  // Dynamic filter lists derived from DB results
  List<String> _typesList = const ['Toutes'];
  List<String> _labsList = const ['Tous'];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _loadAlerts();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<AlertItem> get _filteredAlerts {
    return _alerts.where((item) {
      final matchesSearch = item.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          item.code.contains(_searchController.text);
      final matchesType = _selectedType == 'Toutes' || item.type == _selectedType;
      final matchesLab = _selectedLab == 'Tous' || item.lab == _selectedLab;
      return matchesSearch && matchesType && matchesLab;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    final accent = Colors.teal;

    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(palette),
            const SizedBox(height: 24),
            _buildFilters(palette),
            const SizedBox(height: 24),
            Expanded(
              child: _card(
                palette,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_filteredAlerts.length} alertes actives',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text),
                          ),
                          Text(
                            'Valeur impactée : ${_filteredAlerts.fold<int>(0, (sum, i) => sum + i.valeur).toString()} FCFA',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: _loading
                          ? Center(child: CircularProgressIndicator(color: accent))
                          : _error != null
                              ? Center(child: Text('Erreur: $_error'))
                              : _filteredAlerts.isEmpty
                                  ? Center(child: Text('Aucune alerte trouvée', style: TextStyle(color: palette.subText)))
                                  : ListView.builder(
                                      padding: const EdgeInsets.all(16),
                                      itemCount: _filteredAlerts.length,
                                      itemBuilder: (context, index) => _alertCard(_filteredAlerts[index], palette, accent),
                                    ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final entries = await ProductService.instance.fetchStockEntries();
      final now = DateTime.now();
      final List<AlertItem> list = entries.map((e) {
        final total = e.qtyOfficine + e.qtyReserve;
        String type;
        final peremp = e.peremption;
        bool isPerime = false;
        if (peremp.isNotEmpty) {
          try {
            final dt = DateFormat('MM/yyyy').parse(peremp);
            // parse returns first day of month - treat as end of month
            final endOfMonth = DateTime(dt.year, dt.month + 1, 0);
            if (endOfMonth.isBefore(now)) isPerime = true;
          } catch (_) {}
        }
        if (total <= 0) {
          type = 'Rupture';
        } else if (isPerime) {
          type = 'Périmé';
        } else if (total < e.seuil) {
          type = 'Sous seuil';
        } else {
          type = 'OK';
        }

        final valeur = total * e.prixVente;
        final actions = type == 'Rupture'
            ? ['commande', 'retrait']
            : type == 'Sous seuil'
                ? ['commande']
                : type == 'Périmé'
                    ? ['retrait', 'declassement']
                    : <String>[];

        return AlertItem(
          name: e.name,
          code: e.cip,
          type: type,
          lab: e.lab,
          seuil: e.seuil,
          stock: total,
          peremption: e.peremption,
          valeur: valeur,
          actions: actions,
        );
      }).where((a) => a.type != 'OK').toList();

      // build filter lists
      final types = <String>{'Toutes'};
      final labs = <String>{'Tous'};
      for (final a in list) {
        types.add(a.type);
        labs.add(a.lab);
      }

      setState(() {
        _alerts = list;
        _typesList = types.toList();
        _labsList = labs.toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Widget _buildHeader(ThemeColors palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Alertes stock', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: palette.text, letterSpacing: 1.2)),
        Text('Ruptures • Sous seuil • Péremption • Actions rapides', style: TextStyle(fontSize: 16, color: palette.subText)),
      ],
    );
  }

  Widget _buildFilters(ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final searchWidth = constraints.maxWidth > 900 ? 420.0 : constraints.maxWidth - 40;
            return Wrap(
              spacing: 12,
              runSpacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 280, maxWidth: searchWidth),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit, code CIP...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: palette.isDark ? Colors.grey[850] : Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                  ),
                ),
                _filterDropdown(
                  palette,
                  'Type',
                  _selectedType,
                  _typesList,
                  (v) => setState(() => _selectedType = v!),
                  width: 180,
                ),
                _filterDropdown(
                  palette,
                  'Labo',
                  _selectedLab,
                  _labsList,
                  (v) => setState(() => _selectedLab = v!),
                  width: 170,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _filterDropdown(
    ThemeColors palette,
    String label,
    String value,
    List<String> items,
    ValueChanged<String?> onChanged, {
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        dropdownColor: palette.isDark ? Colors.grey[900] : Colors.white,
        icon: Icon(Icons.keyboard_arrow_down_rounded, color: palette.subText),
      ),
    );
  }

  Widget _alertCard(AlertItem item, ThemeColors palette, Color accent) {
    final isRupture = item.type == 'Rupture';
    final isSousSeuil = item.type == 'Sous seuil';
    final isPerime = item.type == 'Périmé';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isRupture
              ? Colors.red.withOpacity(0.35)
              : isSousSeuil
                  ? Colors.orange.withOpacity(0.3)
                  : isPerime
                      ? Colors.red.withOpacity(0.3)
                      : palette.divider,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isRupture
                ? Colors.red.withOpacity(0.15)
                : isSousSeuil
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isRupture ? Icons.error : isSousSeuil ? Icons.warning_amber_rounded : Icons.calendar_today,
                color: isRupture ? Colors.red : isSousSeuil ? Colors.orange : Colors.red,
                size: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text)),
                    const SizedBox(height: 4),
                    Text(item.code, style: TextStyle(fontSize: 13, color: palette.subText, fontFamily: 'Roboto Mono')),
                  ],
                ),
              ),
              _typeBadge(item.type, palette),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _infoChip('Labo', item.lab, palette),
              _infoChip('Stock actuel', '${item.stock} un.', palette),
              _infoChip('Seuil mini', '${item.seuil} un.', palette),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _stockRow('Stock total', item.stock, true, palette),
                    if (isPerime) _stockRow('Péremption', item.peremption, true, palette),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Valeur impactée : ${item.valeur.toStringAsFixed(0)} FCFA', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: accent)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 12,
              children: item.actions.map((action) => _actionButton(action, item, palette)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String type, ThemeColors palette) {
    final color = switch (type) {
      'Rupture' => Colors.red,
      'Sous seuil' => Colors.orange,
      'Périmé' => Colors.red,
      _ => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withOpacity(0.5))),
      child: Text(type, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _actionButton(String action, AlertItem alert, ThemeColors palette) {
    final icon = switch (action) {
      'commande' => Icons.shopping_cart_outlined,
      'retrait' => Icons.remove_shopping_cart_outlined,
      'declassement' => Icons.delete_outline,
      _ => Icons.more_horiz,
    };
    final color = switch (action) {
      'commande' => Colors.green,
      'retrait' => Colors.orange,
      'declassement' => Colors.red,
      _ => Colors.grey,
    };

    return SizedBox(
      width: 140,
      child: TextButton.icon(
        onPressed: () => _handleAction(action, alert),
        icon: Icon(icon, size: 18, color: color),
        label: Text(_actionLabel(action), style: TextStyle(color: color, fontWeight: FontWeight.w600)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  String _actionLabel(String action) {
    return switch (action) {
      'commande' => 'Commander',
      'retrait' => 'Retirer',
      'declassement' => 'Déclasser',
      _ => action,
    };
  }

  Widget _stockRow(String label, dynamic value, bool alert, ThemeColors palette, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: TextStyle(color: palette.subText, fontSize: 14))),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: bold ? 20 : 17,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: alert ? Colors.orange : palette.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value, ThemeColors palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.white.withOpacity(0.08) : Colors.grey[200],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(fontSize: 12.5, color: palette.text.withOpacity(0.9), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _card(ThemeColors palette, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(palette.isDark ? 0.4 : 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }

  void _handleAction(String action, AlertItem alert) {
    if (action == 'commande') {
      _createOrderFromAlert(alert);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action "$action" pour ${alert.name}')),
      );
    }
  }

  Future<void> _createOrderFromAlert(AlertItem alert) async {
    try {
      final db = LocalDatabaseService.instance.db;

      // Generate a unique order ID based on timestamp
      final orderId = 'CMD-${DateTime.now().millisecondsSinceEpoch}';

      // Determine quantity to order: use the difference between seuil and current stock
      final quantityToOrder = (alert.seuil - alert.stock).clamp(1, alert.seuil).toInt();

      // Insert new order to commandes table
      // fournisseur_id set to null for now (user can assign later)
      await db.insert('commandes', {
        'id': orderId,
        'fournisseur_id': null,
        'date': DateTime.now().toIso8601String(),
        'statut': 'En cours',
        'total': 0, // total will be calculated later
      });

      if (!mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Commande créée: ${alert.name} (qty: $quantityToOrder)'),
          duration: const Duration(seconds: 3),
        ),
      );

      // Optionally refresh alerts to reflect any changes
      await _loadAlerts();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la création de la commande: $e')),
      );
    }
  }
}

class AlertItem {
  final String name, code, type, lab, peremption;
  final int seuil, stock, valeur;
  final List<String> actions;

  const AlertItem({
    required this.name, required this.code, required this.type, required this.lab, required this.peremption,
    required this.seuil, required this.stock, required this.valeur, required this.actions,
  });
}