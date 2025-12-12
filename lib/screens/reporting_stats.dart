// screens/reporting_stats.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../app_theme.dart';
import '../services/local_database_service.dart';
import '../widgets/stats_card.dart';
import '../models/sale_models.dart';

class ReportingStatsScreen extends StatefulWidget {
  const ReportingStatsScreen({super.key});

  @override
  State<ReportingStatsScreen> createState() => _ReportingStatsScreenState();
}

class _ReportingStatsScreenState extends State<ReportingStatsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  String _periode = 'Ce mois';
  DateTimeRange? _customRange;
  bool _loading = true;
  String? _error;

  // No hard-coded reporting/demo data — charts and rankings load from DB/services
  final Map<String, double> _caData = {};

  final List<TopProduit> _topProduits = [];
  final List<TopVendeur> _topVendeurs = [];

  final List<FamilleStats> _familles = [];
  double _caTotal = 0;
  int _nbVentes = 0;
  double _panierMoyen = 0;
  double _marge = 0;
  double _tauxMarge = 0;
  String _growthLabel = '';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await LocalDatabaseService.instance.init();
      _caData.clear();
      _topProduits.clear();
      _topVendeurs.clear();
      _familles.clear();
      _caTotal = 0;
      _nbVentes = 0;
      _panierMoyen = 0;
      _marge = 0;
      _tauxMarge = 0;
      _growthLabel = '';

      await _loadVentes();
      await _loadTopProduits();
      await _loadFamilles();
      await _loadTopVendeurs();

      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  _PeriodeFilter _periodeFilter() {
    DateTime? from;
    DateTime? to;
    final now = DateTime.now();
    switch (_periode) {
      case 'Aujourd\'hui':
        from = DateTime(now.year, now.month, now.day);
        to = DateTime(now.year, now.month, now.day, 23, 59, 59);
        break;
      case '7 jours':
        from = now.subtract(const Duration(days: 6));
        to = now;
        break;
      case 'Ce mois':
        from = DateTime(now.year, now.month, 1);
        to = now;
        break;
      case '3 mois':
        from = DateTime(now.year, now.month - 2, 1);
        to = now;
        break;
      case 'Cette année':
        from = DateTime(now.year, 1, 1);
        to = now;
        break;
      case 'Personnalisé':
        if (_customRange != null) {
          from = _customRange!.start;
          to = _customRange!.end;
        }
        break;
      default:
        break;
    }
    if (from == null && to == null) {
      return const _PeriodeFilter(where: null, args: [], range: null);
    }
    to ??= now;
    from ??= DateTime(1970);
    final range = DateTimeRange(start: from, end: to);
    return _PeriodeFilter(
      where: 'date >= ? AND date <= ?',
      args: [from.toIso8601String(), to.toIso8601String()],
      range: range,
    );
  }

  Future<void> _loadVentes() async {
    final db = LocalDatabaseService.instance.db;
    final filter = _periodeFilter();
    final rows = await db.query(
      'ventes',
      where: filter.where,
      whereArgs: filter.args,
    );

    final Map<String, double> caByDay = {};
    double caTotal = 0;
    int nbVentes = 0;
    for (final r in rows) {
      final iso = r['date'] as String? ?? '';
      final dt = DateTime.tryParse(iso) ?? DateTime.now();
      final ca = (r['montant'] as num?)?.toDouble() ?? 0;
      caTotal += ca;
      nbVentes += 1;
      final label = DateFormat('dd/MM').format(dt);
      caByDay[label] = (caByDay[label] ?? 0) + ca;
    }

    double marge = 0;
    try {
      final marginWhereClause = filter.where != null
          ? _buildPrefixedWhereClause(filter.where!, 'v')
          : '';
      final marginArgs = filter.where != null ? filter.args : null;
      final marginRows = await db.rawQuery('''
        SELECT lv.quantite, lv.prix, lv.remise, m.prix_achat
        FROM lignes_vente lv
        JOIN ventes v ON v.id = lv.vente_id
        LEFT JOIN medicaments m ON m.id = lv.medicament_id
        $marginWhereClause
      ''', marginArgs);
      for (final r in marginRows) {
        final qte = (r['quantite'] as num?)?.toDouble() ?? 0;
        final prix = (r['prix'] as num?)?.toDouble() ?? 0;
        final remise = (r['remise'] as num?)?.toDouble() ?? 0;
        final achat = (r['prix_achat'] as num?)?.toDouble() ?? 0;
        marge += ((prix - achat) * qte) - remise;
      }
    } catch (_) {
      marge = 0;
    }

    final previousRange = filter.range != null
        ? _previousRange(filter.range!)
        : null;
    double previousCa = 0;
    if (previousRange != null) {
      previousCa = await _sumSalesBetween(previousRange);
    }
    final growthLabel = _buildGrowthLabel(caTotal, previousCa);

    setState(() {
      _caData.clear();
      _caData.addAll(caByDay);
      _caTotal = caTotal;
      _nbVentes = nbVentes;
      _panierMoyen = nbVentes == 0 ? 0 : caTotal / nbVentes;
      _marge = marge;
      _tauxMarge = caTotal == 0 ? 0 : (marge / caTotal) * 100;
      _growthLabel = growthLabel;
    });
  }

  Future<void> _loadTopProduits() async {
    final db = LocalDatabaseService.instance.db;
    final filter = _periodeFilter();
    final whereClause = filter.where != null
        ? _buildPrefixedWhereClause(filter.where!, 'v')
        : '';
    final args = filter.where != null ? filter.args : null;
    final rows = await db.rawQuery('''
      SELECT lv.medicament_id, SUM(lv.quantite) as qte, SUM((lv.prix * lv.quantite) - COALESCE(lv.remise,0)) as ca, m.nom
      FROM lignes_vente lv
      JOIN ventes v ON v.id = lv.vente_id
      LEFT JOIN medicaments m ON m.id = lv.medicament_id
      $whereClause
      GROUP BY lv.medicament_id
      ORDER BY qte DESC
      LIMIT 5
    ''', args);

    if (rows.isNotEmpty) {
      setState(() {
        _topProduits
          ..clear()
          ..addAll(
            rows.map(
              (r) => TopProduit(
                nom: (r['nom'] as String?)?.isNotEmpty == true
                    ? r['nom'] as String
                    : (r['medicament_id'] as String? ?? ''),
                ventes: (r['qte'] as num?)?.toInt() ?? 0,
                ca: (r['ca'] as num?)?.toInt() ?? 0,
              ),
            ),
          );
      });
      return;
    }

    // Fallback: compute from ventes.details JSON if lignes_vente empty
    final ventesRows = await db.query(
      'ventes',
      columns: ['details', 'statut'],
      where: filter.where,
      whereArgs: filter.args,
    );
    final Map<String, int> qteById = {};
    final Map<String, double> caById = {};
    final Map<String, String> nameById = {};
    for (final v in ventesRows) {
      final statut = (v['statut'] as String? ?? '').toLowerCase();
      if (statut.contains('annul')) continue;
      final details = v['details'] as String?;
      if (details == null || details.isEmpty) continue;
      try {
        final parsed = jsonDecode(details) as List<dynamic>;
        for (final e in parsed) {
          final item = CartItem.fromMap(Map<String, Object?>.from(e as Map));
          final id = item.productId ?? item.barcode;
          qteById[id] = (qteById[id] ?? 0) + item.quantity;
          caById[id] = (caById[id] ?? 0) + (item.price * item.quantity);
          nameById[id] = item.name;
        }
      } catch (_) {}
    }
    final ranked = qteById.keys.toList()
      ..sort((a, b) => (qteById[b] ?? 0).compareTo(qteById[a] ?? 0));
    setState(() {
      _topProduits
        ..clear()
        ..addAll(
          ranked
              .take(5)
              .map(
                (id) => TopProduit(
                  nom: nameById[id] ?? id,
                  ventes: qteById[id] ?? 0,
                  ca: (caById[id] ?? 0).toInt(),
                ),
              ),
        );
    });
  }

  Future<void> _loadFamilles() async {
    final db = LocalDatabaseService.instance.db;
    final filter = _periodeFilter();
    final whereClause = filter.where != null
        ? _buildPrefixedWhereClause(filter.where!, 'v')
        : '';
    final args = filter.where != null ? filter.args : null;
    final rows = await db.rawQuery('''
      SELECT m.famille, SUM((lv.prix * lv.quantite) - COALESCE(lv.remise,0)) as ca
      FROM lignes_vente lv
      JOIN ventes v ON v.id = lv.vente_id
      LEFT JOIN medicaments m ON m.id = lv.medicament_id
      $whereClause
      GROUP BY m.famille
      ORDER BY ca DESC
    ''', args);
    if (rows.isNotEmpty) {
      final total = rows.fold<num>(
        0,
        (sum, r) => sum + ((r['ca'] as num?) ?? 0),
      );
      setState(() {
        _familles
          ..clear()
          ..addAll(
            rows.map((r) {
              final ca = (r['ca'] as num?)?.toInt() ?? 0;
              final famille = (r['famille'] as String?)?.isNotEmpty == true
                  ? r['famille'] as String
                  : 'Non définie';
              final pourc = total == 0 ? 0.0 : (ca / total) * 100;
              return FamilleStats(
                famille: famille,
                ca: ca,
                pourcentage: pourc.toDouble(),
              );
            }),
          );
      });
      return;
    }

    // Fallback from ventes.details JSON
    final ventesRows = await db.query(
      'ventes',
      columns: ['details', 'statut'],
      where: filter.where,
      whereArgs: filter.args,
    );
    final Map<String, double> caByFamille = {};
    final ids = <String>{};
    final itemsById = <String, double>{};
    for (final v in ventesRows) {
      final statut = (v['statut'] as String? ?? '').toLowerCase();
      if (statut.contains('annul')) continue;
      final details = v['details'] as String?;
      if (details == null || details.isEmpty) continue;
      try {
        final parsed = jsonDecode(details) as List<dynamic>;
        for (final e in parsed) {
          final item = CartItem.fromMap(Map<String, Object?>.from(e as Map));
          final id = item.productId ?? item.barcode;
          ids.add(id);
          itemsById[id] = (itemsById[id] ?? 0) + (item.price * item.quantity);
        }
      } catch (_) {}
    }
    if (ids.isEmpty) {
      setState(() => _familles.clear());
      return;
    }
    final placeholders = List.filled(ids.length, '?').join(', ');
    final meds = await db.rawQuery(
      'SELECT id, famille FROM medicaments WHERE id IN ($placeholders)',
      ids.toList(),
    );
    final famById = {
      for (final m in meds)
        (m['id'] as String): (m['famille'] as String?) ?? 'Non définie',
    };
    for (final id in ids) {
      final famille = famById[id] ?? 'Non définie';
      caByFamille[famille] = (caByFamille[famille] ?? 0) + (itemsById[id] ?? 0);
    }
    final total = caByFamille.values.fold<double>(0, (a, b) => a + b);
    final ordered = caByFamille.keys.toList()
      ..sort((a, b) => (caByFamille[b] ?? 0).compareTo(caByFamille[a] ?? 0));
    setState(() {
      _familles
        ..clear()
        ..addAll(
          ordered.map((famille) {
            final ca = caByFamille[famille] ?? 0;
            final pourc = total == 0 ? 0.0 : (ca / total) * 100;
            return FamilleStats(
              famille: famille,
              ca: ca.toInt(),
              pourcentage: pourc,
            );
          }),
        );
    });
  }

  Future<void> _loadTopVendeurs() async {
    final db = LocalDatabaseService.instance.db;
    final filter = _periodeFilter();
    final whereClause = filter.where != null ? 'WHERE ${filter.where}' : '';
    final rows = await db.rawQuery('''
      SELECT vendeur, SUM(montant) as ca, COUNT(*) as ventes
      FROM ventes
      $whereClause
      GROUP BY vendeur
      ORDER BY ca DESC
      LIMIT 4
    ''', filter.where != null ? filter.args : null);

    setState(() {
      _topVendeurs
        ..clear()
        ..addAll(
          rows.map((r) {
            final vendor = (r['vendeur'] as String?)?.isNotEmpty == true
                ? r['vendeur'] as String
                : 'Vendeur inconnu';
            return TopVendeur(
              id: vendor,
              nom: vendor,
              ventes: (r['ventes'] as num?)?.toInt() ?? 0,
              ca: (r['ca'] as num?)?.toInt() ?? 0,
            );
          }),
        );
    });
  }

  String _formatCurrency(double value) {
    if (value == 0) return '0 FCFA';
    return '${NumberFormat('#,###', 'fr_FR').format(value)} FCFA';
  }

  String _growthText() => _growthLabel;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    final accent = Colors.teal;

    return FadeTransition(
      opacity: _fade,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(
                'Erreur: $_error',
                style: TextStyle(color: palette.text),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(palette, accent),
                  const SizedBox(height: 24),
                  _buildPeriodeSelector(context, palette, accent),
                  const SizedBox(height: 24),
                  _buildKpis(palette, accent),
                  const SizedBox(height: 24),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 1100;
                        return SingleChildScrollView(
                          child: isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: _buildGraphiques(palette, accent),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(
                                      flex: 2,
                                      child: _buildClassements(palette, accent),
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildGraphiques(palette, accent),
                                    const SizedBox(height: 24),
                                    _buildClassements(palette, accent),
                                  ],
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader(ThemeColors palette, Color accent) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(Icons.bar_chart, color: accent, size: 34),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reporting & Statistiques',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: palette.text,
                letterSpacing: 1.2,
              ),
            ),
            Text(
              'Analyse complète de l\'activité • CA • Marges • Tendances',
              style: TextStyle(fontSize: 15, color: palette.subText),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodeSelector(
    BuildContext context,
    ThemeColors palette,
    Color accent,
  ) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.date_range, color: accent, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Période',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ],
            ),
            DropdownButton<String>(
              value: _periode,
              items: const [
                'Aujourd\'hui',
                '7 jours',
                'Ce mois',
                '3 mois',
                'Cette année',
                'Personnalisé',
              ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) async {
                if (v == null) return;
                setState(() => _periode = v);
                if (v == 'Personnalisé') {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _customRange,
                  );
                  if (picked != null) {
                    setState(() => _customRange = picked);
                  }
                }
                _loadData();
              },
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
              dropdownColor: palette.isDark ? Colors.grey[900] : Colors.white,
              underline: const SizedBox.shrink(),
            ),
            if (_periode == 'Personnalisé')
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _customRange,
                  );
                  if (picked != null) {
                    setState(() => _customRange = picked);
                    _loadData();
                  }
                },
                icon: const Icon(Icons.edit_calendar),
                label: Text(
                  _customRange == null
                      ? 'Choisir dates'
                      : '${DateFormat('dd/MM').format(_customRange!.start)} - ${DateFormat('dd/MM').format(_customRange!.end)}',
                ),
              ),
            OutlinedButton.icon(
              onPressed: () => _exportAsPdf(context),
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: BorderSide(color: Colors.red.withOpacity(0.4)),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _exportAsCsv(context),
              icon: const Icon(Icons.table_view),
              label: const Text('Excel'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: BorderSide(color: Colors.green.withOpacity(0.4)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpis(ThemeColors palette, Color accent) {
    final cards = [
      (
        title: 'CA Total',
        value: _formatCurrency(_caTotal),
        subtitle: _growthText(),
        icon: Icons.trending_up,
        color: Colors.green,
      ),
      (
        title: 'Panier moyen',
        value: _formatCurrency(_panierMoyen),
        subtitle: 'Par vente',
        icon: Icons.shopping_basket,
        color: Colors.blue,
      ),
      (
        title: 'Marge brute',
        value: _formatCurrency(_marge),
        subtitle: '${_tauxMarge.toStringAsFixed(1)}% du CA',
        icon: Icons.insights,
        color: Colors.purple,
      ),
      (
        title: 'Ventes',
        value: '$_nbVentes',
        subtitle: 'Transactions',
        icon: Icons.receipt_long,
        color: Colors.orange,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final cardWidth = width > 1200
            ? (width - 48) / 4
            : width > 800
            ? (width - 36) / 3
            : width > 520
            ? (width - 24) / 2
            : width;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((c) {
            return SizedBox(
              width: cardWidth,
              child: StatsCard(
                title: c.title,
                value: c.value,
                icon: c.icon,
                color: c.color,
                subtitle: c.subtitle,
                textColor: palette.text,
                subTextColor: palette.subText,
                cardColor: palette.card,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildGraphiques(ThemeColors palette, Color accent) {
    return Column(
      children: [
        _card(palette, child: _graphiqueCA(palette, accent)),
        const SizedBox(height: 20),
        _card(palette, child: _graphiqueFamilles(palette)),
      ],
    );
  }

  Widget _graphiqueCA(ThemeColors palette, Color accent) {
    if (_caData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aucune donnée de CA pour la période',
          style: TextStyle(color: palette.subText),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxValue = _caData.values.reduce((a, b) => a > b ? a : b);
        final chartHeight = constraints.maxWidth < 700 ? 300.0 : 360.0;
        final barMaxHeight = chartHeight - 60;
        final barWidth = constraints.maxWidth < 700 ? 28.0 : 36.0;
        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.show_chart, color: accent, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    'Évolution du CA (2025)',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: chartHeight,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _caData.entries.map((e) {
                      final height = maxValue == 0
                          ? 0.0
                          : (e.value / maxValue) * barMaxHeight;
                      return Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              width: barWidth,
                              height: height,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [accent, accent.withOpacity(0.6)],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              e.key,
                              style: TextStyle(
                                color: palette.subText,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              NumberFormat.compact().format(e.value),
                              style: TextStyle(
                                color: palette.text,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _graphiqueFamilles(ThemeColors palette) {
    if (_familles.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aucune donnée famille pour la période',
          style: TextStyle(color: palette.subText),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart, color: Colors.orange, size: 32),
              const SizedBox(width: 12),
              Text(
                'Répartition par famille',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ..._familles.map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      f.famille,
                      style: TextStyle(
                        color: palette.text,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: f.pourcentage / 100,
                      backgroundColor: palette.divider,
                      valueColor: AlwaysStoppedAnimation(
                        _couleurFamille(f.famille),
                      ),
                      minHeight: 12,
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 80,
                    child: Text(
                      '${f.pourcentage.toStringAsFixed(1)}%',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportAsPdf(BuildContext context) async {
    try {
      final bytes = await _buildReportPdfBytes();
      final now = DateTime.now();
      final fileName =
          'reporting_${DateFormat('yyyyMMdd_HHmmss').format(now)}.pdf';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le rapport PDF',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (path == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export PDF annulé')));
        return;
      }
      final file = File(path);
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      await OpenFilex.open(file.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rapport PDF enregistré dans ${file.path}')),
      );
    } catch (e) {
      debugPrint('Erreur export PDF reporting : $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('L\'export PDF a échoué : $e')));
    }
  }

  Future<void> _exportAsCsv(BuildContext context) async {
    try {
      final buffer = StringBuffer();
      buffer.writeln('Section;Détail;Valeur');
      buffer.writeln('KPIs;CA total;${_formatCurrency(_caTotal)}');
      buffer.writeln('KPIs;Panier moyen;${_formatCurrency(_panierMoyen)}');
      buffer.writeln('KPIs;Marge;${_formatCurrency(_marge)}');
      buffer.writeln('KPIs;Nombre de ventes;$_nbVentes');
      if (_growthLabel.isNotEmpty) {
        buffer.writeln('KPIs;Croissance;$_growthLabel');
      }
      if (_topProduits.isNotEmpty) {
        for (final produit in _topProduits) {
          buffer.writeln(
            'Top produits;${produit.nom};'
            '${produit.ventes} ventes • '
            '${NumberFormat('#,###', 'fr_FR').format(produit.ca)} FCFA',
          );
        }
      }
      if (_topVendeurs.isNotEmpty) {
        for (final vendeur in _topVendeurs) {
          buffer.writeln(
            'Top vendeurs;${vendeur.nom};'
            '${_formatCurrency(vendeur.ca.toDouble())} '
            '(${vendeur.ventes} ventes)',
          );
        }
      }
      final now = DateTime.now();
      final fileName =
          'reporting_${DateFormat('yyyyMMdd_HHmmss').format(now)}.csv';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Enregistrer le rapport CSV',
        fileName: fileName,
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );
      if (path == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Export Excel annulé')));
        return;
      }
      final file = File(path);
      await file.create(recursive: true);
      await file.writeAsString(buffer.toString());
      await OpenFilex.open(file.path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Rapport CSV enregistré dans ${file.path}')),
      );
    } catch (e) {
      debugPrint('Erreur export CSV reporting : $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('L\'export Excel a échoué : $e')));
    }
  }

  Future<Uint8List> _buildReportPdfBytes() async {
    final settings = await LocalDatabaseService.instance.getSettings();
    final doc = pw.Document();
    final accent = PdfColors.teal600;
    final headerStyle = pw.TextStyle(
      fontSize: 20,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.white,
    );
    final headerSubStyle = pw.TextStyle(fontSize: 10, color: PdfColors.white);
    final subStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);
    final sectionTitle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey900,
    );
    final kpiValueStyle = pw.TextStyle(
      fontSize: 14,
      fontWeight: pw.FontWeight.bold,
      color: PdfColors.grey900,
    );
    final kpiLabelStyle = pw.TextStyle(fontSize: 9, color: PdfColors.grey700);
    final tableHeader = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );
    final logo = await _loadPdfLogo(settings.logoPath);

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            // Header inspired by ticket
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (logo != null)
                    pw.Container(
                      width: 48,
                      height: 48,
                      margin: const pw.EdgeInsets.only(right: 10),
                      child: pw.Image(logo, fit: pw.BoxFit.contain),
                    ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          settings.pharmacyName.isNotEmpty
                              ? settings.pharmacyName
                              : 'Pharmacie',
                          style: headerStyle,
                        ),
                        if (settings.pharmacyAddress.isNotEmpty)
                          pw.Text(
                            settings.pharmacyAddress,
                            style: headerSubStyle,
                          ),
                        pw.Row(
                          children: [
                            if (settings.pharmacyPhone.isNotEmpty)
                              pw.Text(
                                'Tel: ${settings.pharmacyPhone}  ',
                                style: headerSubStyle,
                              ),
                            if (settings.pharmacyEmail.isNotEmpty)
                              pw.Text(
                                'Email: ${settings.pharmacyEmail}',
                                style: headerSubStyle,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'Reporting',
                        style: headerStyle.copyWith(fontSize: 18),
                      ),
                      pw.Text('Periode: $_periode', style: headerSubStyle),
                      pw.Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                        style: headerSubStyle,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 14),

            // KPI blocks
            pw.Text('Indicateurs clefs', style: sectionTitle),
            pw.SizedBox(height: 8),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _kpiPdfCard(
                  label: 'CA total',
                  value: _formatCurrency(_caTotal),
                  subtitle: _growthLabel,
                  valueStyle: kpiValueStyle,
                  labelStyle: kpiLabelStyle,
                  accent: accent,
                ),
                _kpiPdfCard(
                  label: 'Panier moyen',
                  value: _formatCurrency(_panierMoyen),
                  subtitle: 'Par vente',
                  valueStyle: kpiValueStyle,
                  labelStyle: kpiLabelStyle,
                  accent: accent,
                ),
                _kpiPdfCard(
                  label: 'Marge brute',
                  value: _formatCurrency(_marge),
                  subtitle: '${_tauxMarge.toStringAsFixed(1)}% du CA',
                  valueStyle: kpiValueStyle,
                  labelStyle: kpiLabelStyle,
                  accent: accent,
                ),
                _kpiPdfCard(
                  label: 'Nombre de ventes',
                  value: '$_nbVentes',
                  subtitle: 'Transactions',
                  valueStyle: kpiValueStyle,
                  labelStyle: kpiLabelStyle,
                  accent: accent,
                ),
              ],
            ),

            pw.SizedBox(height: 14),

            if (_caData.isNotEmpty) ...[
              pw.Text('Ventes par periode', style: sectionTitle),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: ['Date', 'CA (FCFA)'],
                data: _caData.entries
                    .map(
                      (e) => [
                        e.key,
                        NumberFormat('#,###', 'fr_FR').format(e.value),
                      ],
                    )
                    .toList(),
                headerStyle: tableHeader,
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
                cellStyle: const pw.TextStyle(fontSize: 9),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
              ),
              pw.SizedBox(height: 10),
            ],

            if (_topProduits.isNotEmpty) ...[
              pw.Text('Top produits', style: sectionTitle),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: ['Produit', 'Quantite', 'CA (FCFA)'],
                data: _topProduits
                    .map(
                      (produit) => [
                        produit.nom,
                        produit.ventes.toString(),
                        NumberFormat('#,###', 'fr_FR').format(produit.ca),
                      ],
                    )
                    .toList(),
                headerStyle: tableHeader,
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
              ),
              pw.SizedBox(height: 10),
            ],

            if (_topVendeurs.isNotEmpty) ...[
              pw.Text('Top vendeurs', style: sectionTitle),
              pw.SizedBox(height: 6),
              pw.Table.fromTextArray(
                headers: ['Vendeur', 'Ventes', 'CA (FCFA)'],
                data: _topVendeurs
                    .map(
                      (vendeur) => [
                        vendeur.nom.isNotEmpty
                            ? vendeur.nom
                            : 'Vendeur ${vendeur.id}',
                        vendeur.ventes.toString(),
                        NumberFormat('#,###', 'fr_FR').format(vendeur.ca),
                      ],
                    )
                    .toList(),
                headerStyle: tableHeader,
                headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellAlignment: pw.Alignment.centerLeft,
                border: pw.TableBorder.all(color: PdfColors.grey300, width: .5),
              ),
              pw.SizedBox(height: 10),
            ],

            if (_familles.isNotEmpty) ...[
              pw.Text('Repartition par famille', style: sectionTitle),
              pw.SizedBox(height: 6),
              pw.Column(
                children: _familles.map((f) {
                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          flex: 3,
                          child: pw.Text(
                            f.famille,
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Expanded(
                          flex: 5,
                          child: pw.Container(
                            height: 8,
                            decoration: pw.BoxDecoration(
                              color: PdfColors.grey200,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Stack(
                              children: [
                                pw.Positioned(
                                  left: 0,
                                  top: 0,
                                  bottom: 0,
                                  child: pw.Container(
                                    width: 200 * (f.pourcentage / 100),
                                    decoration: pw.BoxDecoration(
                                      color: accent,
                                      borderRadius: pw.BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Expanded(
                          flex: 2,
                          child: pw.Text(
                            '${f.pourcentage.toStringAsFixed(1)}%',
                            style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ];
        },
      ),
    );
    return doc.save();
  }

  pw.ImageProvider? _loadPdfLogo(String path) {
    if (path.isEmpty) return null;
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final bytes = file.readAsBytesSync();
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  pw.Widget _kpiPdfCard({
    required String label,
    required String value,
    required String subtitle,
    required pw.TextStyle valueStyle,
    required pw.TextStyle labelStyle,
    required PdfColor accent,
  }) {
    return pw.Container(
      width: 125,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300, width: .6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: labelStyle),
          pw.SizedBox(height: 4),
          pw.Text(value, style: valueStyle),
          if (subtitle.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(subtitle, style: labelStyle.copyWith(color: accent)),
          ],
        ],
      ),
    );
  }

  Future<double> _sumSalesBetween(DateTimeRange range) async {
    final db = LocalDatabaseService.instance.db;
    final rows = await db.rawQuery(
      'SELECT SUM(montant) as total FROM ventes WHERE date >= ? AND date <= ?',
      [range.start.toIso8601String(), range.end.toIso8601String()],
    );
    if (rows.isEmpty) return 0;
    return (rows.first['total'] as num?)?.toDouble() ?? 0;
  }

  DateTimeRange _previousRange(DateTimeRange range) {
    final duration = range.duration;
    final prevEnd = range.start.subtract(const Duration(seconds: 1));
    final prevStart = prevEnd.subtract(duration);
    return DateTimeRange(start: prevStart, end: prevEnd);
  }

  String _buildGrowthLabel(double current, double previous) {
    if (previous == 0) {
      return current == 0 ? '' : 'Nouveaux chiffres';
    }
    final diff = current - previous;
    final percent = diff / previous * 100;
    final sign = percent >= 0 ? '+' : '';
    return '$sign${percent.toStringAsFixed(1)}% vs précédent';
  }

  String _buildPrefixedWhereClause(String where, String prefix) {
    final replaced = where.replaceAllMapped(
      RegExp(r'\bdate\b'),
      (match) => '$prefix.date',
    );
    return 'WHERE $replaced';
  }

  Color _couleurFamille(String famille) {
    return switch (famille) {
      'Antalgiques' => Colors.teal,
      'Antibiotiques' => Colors.blue,
      'Gastro' => Colors.orange,
      'Cardio' => Colors.red,
      'Dermatologie' => Colors.purple,
      _ => Colors.grey,
    };
  }

  Widget _buildClassements(ThemeColors palette, Color accent) {
    return Column(
      children: [
        _card(palette, child: _topVentes(palette, accent)),
        const SizedBox(height: 20),
        _card(palette, child: _meilleursVendeurs(palette, accent)),
      ],
    );
  }

  Widget _topVentes(ThemeColors palette, Color accent) {
    if (_topProduits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aucun produit vendu sur la période',
          style: TextStyle(color: palette.subText),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.green, size: 32),
              const SizedBox(width: 12),
              Text(
                'Top 5 produits',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._topProduits.take(5).toList().asMap().entries.map((e) {
            final index = e.key + 1;
            final produit = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: index == 1 ? Colors.amber : palette.divider,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: index == 1
                          ? Colors.amber
                          : accent.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(
                        '$index',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: index == 1 ? Colors.black : accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      produit.nom,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: palette.text,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${produit.ventes} ventes',
                        style: TextStyle(color: palette.subText, fontSize: 13),
                      ),
                      Text(
                        NumberFormat('#,###', 'fr_FR').format(produit.ca),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _meilleursVendeurs(ThemeColors palette, Color accent) {
    if (_topVendeurs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aucun vendeur / client avec données pour la période',
          style: TextStyle(color: palette.subText),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              const SizedBox(width: 12),
              Text(
                'Meilleurs vendeurs',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ..._topVendeurs.asMap().entries.map((e) {
            final i = e.key + 1;
            final vendeur = e.value;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: i == 1 ? Colors.amber : accent,
                child: Text(
                  '$i',
                  style: TextStyle(
                    color: i == 1 ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                vendeur.nom.isEmpty ? 'Client ${vendeur.id}' : vendeur.nom,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: palette.text,
                ),
              ),
              subtitle: Text(
                '${vendeur.ventes} ventes',
                style: TextStyle(color: palette.subText),
              ),
              trailing: Text(
                _formatCurrency(vendeur.ca.toDouble()),
                style: TextStyle(fontWeight: FontWeight.bold, color: accent),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _card(ThemeColors palette, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.4 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

// === MODÈLES ===
class TopProduit {
  final String nom;
  final int ventes, ca;
  const TopProduit({required this.nom, required this.ventes, required this.ca});
}

class FamilleStats {
  final String famille;
  final int ca;
  final double pourcentage;
  const FamilleStats({
    required this.famille,
    required this.ca,
    required this.pourcentage,
  });
}

class TopVendeur {
  final String id;
  final String nom;
  final int ventes;
  final int ca;
  const TopVendeur({
    required this.id,
    required this.nom,
    required this.ventes,
    required this.ca,
  });
}

class _PeriodeFilter {
  final String? where;
  final List<Object?> args;
  final DateTimeRange? range;
  const _PeriodeFilter({
    required this.where,
    required this.args,
    required this.range,
  });
}
