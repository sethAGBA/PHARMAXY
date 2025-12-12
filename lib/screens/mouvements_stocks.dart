// screens/mouvements_stocks.dart
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/sale_models.dart';
import '../services/product_service.dart';

class MouvementsStocksScreen extends StatefulWidget {
  const MouvementsStocksScreen({super.key});

  @override
  State<MouvementsStocksScreen> createState() => _MouvementsStocksScreenState();
}

class _MouvementsStocksScreenState extends State<MouvementsStocksScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController _searchController = TextEditingController();
  String _selectedType = 'Tous';
  String _selectedReason = 'Tous';
  DateTime? _dateFrom;
  DateTime? _dateTo;

  List<StockMovement> _allMovements = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _loadMovements();
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMovements() async {
    try {
      final movements = await ProductService.instance.fetchAllMovements();
      setState(() {
        _allMovements = movements;
        _loading = false;
      });
    } catch (e, st) {
      // If the DB table doesn't exist or another error occurs, avoid leaving the spinner forever.
      // Log and show a user-friendly message.
      // ignore: avoid_print
      print('Failed to load stock movements: $e\n$st');
      if (!mounted) return;
      setState(() {
        _allMovements = [];
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Erreur lors du chargement des mouvements (table manquante ?)',
          ),
        ),
      );
    }
  }

  List<StockMovement> _getFilteredMovements() {
    var filtered = _allMovements;

    // Filtre par texte
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered
          .where(
            (m) =>
                m.productName.toLowerCase().contains(query) ||
                m.reference?.toLowerCase().contains(query) == true,
          )
          .toList();
    }

    // Filtre par type
    if (_selectedType != 'Tous') {
      filtered = filtered
          .where((m) => m.type == _selectedType.toLowerCase())
          .toList();
    }

    // Filtre par raison
    if (_selectedReason != 'Tous') {
      filtered = filtered
          .where((m) => m.reason == _selectedReason.toLowerCase())
          .toList();
    }

    // Filtre par date
    if (_dateFrom != null) {
      filtered = filtered.where((m) => m.date.isAfter(_dateFrom!)).toList();
    }
    if (_dateTo != null) {
      filtered = filtered
          .where((m) => m.date.isBefore(_dateTo!.add(const Duration(days: 1))))
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    final filteredMovements = _getFilteredMovements();

    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: Theme.of(context).primaryColor),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(palette),
                const SizedBox(height: 24),
                _buildFiltersCard(palette),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildStatsRow(palette, filteredMovements),
                        const SizedBox(height: 18),
                        if (filteredMovements.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    size: 64,
                                    color: palette.subText.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Aucun mouvement trouvé',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: palette.subText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            children: filteredMovements
                                .map(
                                  (movement) =>
                                      _buildMovementCard(movement, palette),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors palette) {
    final accent = Theme.of(context).primaryColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mouvements de stocks',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'Entrées • Sorties • Ajustements • Traçabilité',
                  style: TextStyle(fontSize: 16, color: palette.subText),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export en préparation...')),
              ),
              icon: const Icon(Icons.download),
              label: const Text('Exporter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFiltersCard(ThemeColors palette) {
    final accent = Theme.of(context).primaryColor;
    return Card(
      color: palette.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recherche et filtres',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher produit ou référence...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                fillColor: palette.isDark
                    ? Colors.white.withOpacity(0.04)
                    : Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _filterChip(
                  'Type',
                  _selectedType,
                  ['Tous', 'Entree', 'Sortie', 'Ajustement'],
                  (value) {
                    setState(() => _selectedType = value);
                  },
                  palette,
                  accent,
                ),
                _filterChip(
                  'Raison',
                  _selectedReason,
                  [
                    'Tous',
                    'Achat',
                    'Vente',
                    'Inventaire',
                    'Perte',
                    'Correction',
                  ],
                  (value) {
                    setState(() => _selectedReason = value);
                  },
                  palette,
                  accent,
                ),
                _filterChip(
                  'Date début',
                  _dateFrom == null
                      ? 'Toutes'
                      : '${_dateFrom!.day}/${_dateFrom!.month}',
                  ['Toutes'],
                  (value) => _selectDateFrom(),
                  palette,
                  accent,
                  isDate: true,
                ),
                _filterChip(
                  'Date fin',
                  _dateTo == null
                      ? 'Toutes'
                      : '${_dateTo!.day}/${_dateTo!.month}',
                  ['Toutes'],
                  (value) => _selectDateTo(),
                  palette,
                  accent,
                  isDate: true,
                ),
                if (_dateFrom != null ||
                    _dateTo != null ||
                    _searchController.text.isNotEmpty ||
                    _selectedType != 'Tous' ||
                    _selectedReason != 'Tous')
                  ActionChip(
                    onPressed: _resetFilters,
                    label: const Text('Réinitialiser'),
                    avatar: const Icon(Icons.clear, size: 18),
                    backgroundColor: palette.isDark
                        ? Colors.white.withOpacity(0.1)
                        : Colors.grey[200],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(
    String label,
    String value,
    List<String> options,
    Function(String) onSelected,
    ThemeColors palette,
    Color accent, {
    bool isDate = false,
  }) {
    if (isDate) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: value == 'Toutes'
                ? palette.isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey[300]!
                : accent,
          ),
          borderRadius: BorderRadius.circular(20),
          color: value == 'Toutes'
              ? Colors.transparent
              : accent.withOpacity(0.1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event,
              size: 16,
              color: value == 'Toutes' ? palette.subText : Colors.teal,
            ),
            const SizedBox(width: 6),
            Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 13,
                color: value == 'Toutes' ? palette.subText : accent,
                fontWeight: value == 'Toutes'
                    ? FontWeight.normal
                    : FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButton<String>(
      value: value,
      items: options
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => onSelected(v ?? value),
      underline: const SizedBox.shrink(),
      isDense: true,
      style: TextStyle(color: palette.text, fontSize: 13),
      dropdownColor: palette.card,
    );
  }

  Future<void> _selectDateFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFrom ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      useRootNavigator: true,
    );
    if (picked != null) {
      setState(() => _dateFrom = picked);
    }
  }

  Future<void> _selectDateTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateTo ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      useRootNavigator: true,
    );
    if (picked != null) {
      setState(() => _dateTo = picked);
    }
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedType = 'Tous';
      _selectedReason = 'Tous';
      _dateFrom = null;
      _dateTo = null;
    });
  }

  Widget _buildStatsRow(ThemeColors palette, List<StockMovement> movements) {
    final entrees = movements
        .where((m) => m.type == 'entree')
        .fold<int>(0, (sum, m) => sum + m.quantity);
    final sorties = movements
        .where((m) => m.type == 'sortie')
        .fold<int>(0, (sum, m) => sum + m.quantity);
    final bilan = entrees - sorties;

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: [
        _statCard(
          'Entrées',
          entrees.toString(),
          const Color(0xFF10B981),
          palette,
        ),
        _statCard(
          'Sorties',
          sorties.toString(),
          const Color(0xFFEF4444),
          palette,
        ),
        _statCard(
          'Bilan',
          bilan.toString(),
          bilan >= 0 ? const Color(0xFF3B82F6) : const Color(0xFFEF4444),
          palette,
        ),
        _statCard(
          'Mouvements',
          movements.length.toString(),
          const Color(0xFF8B5CF6),
          palette,
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    Color color,
    ThemeColors palette,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: palette.subText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMovementCard(StockMovement movement, ThemeColors palette) {
    final isPositive =
        movement.type == 'entree' ||
        (movement.type == 'ajustement' && movement.quantity > 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.isDark
            ? Colors.white.withOpacity(0.05)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: palette.isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.grey[300]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movement.productName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: palette.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: movement.typeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            movement.displayType,
                            style: TextStyle(
                              fontSize: 11,
                              color: movement.typeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: palette.isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            movement.displayReason,
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.subText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isPositive ? '+' : '-'}${movement.quantity}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isPositive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${movement.quantityBefore} → ${movement.quantityAfter}',
                    style: TextStyle(fontSize: 11, color: palette.subText),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, size: 13, color: palette.subText),
              const SizedBox(width: 4),
              Text(
                movement.formattedDate,
                style: TextStyle(fontSize: 11, color: palette.subText),
              ),
              const SizedBox(width: 12),
              Icon(Icons.person, size: 13, color: palette.subText),
              const SizedBox(width: 4),
              Text(
                movement.user,
                style: TextStyle(fontSize: 11, color: palette.subText),
              ),
              if (movement.reference != null) ...[
                const SizedBox(width: 12),
                Icon(Icons.tag, size: 13, color: palette.subText),
                const SizedBox(width: 4),
                Text(
                  movement.reference!,
                  style: TextStyle(
                    fontSize: 11,
                    color: palette.subText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          if (movement.notes != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: palette.isDark
                    ? Colors.white.withOpacity(0.03)
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '📝 ${movement.notes!}',
                style: TextStyle(
                  fontSize: 11,
                  color: palette.subText,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
