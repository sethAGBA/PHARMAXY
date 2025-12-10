// screens/reporting_stats.dart
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../app_theme.dart';
import '../services/local_database_service.dart';

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

    final previousRange =
        filter.range != null ? _previousRange(filter.range!) : null;
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
    final total = rows.fold<num>(0, (sum, r) => sum + ((r['ca'] as num?) ?? 0));
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
                        return SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Row(
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
                              ),
                            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.bar_chart, color: accent, size: 40),
            const SizedBox(width: 16),
            Text(
              'Reporting & Statistiques',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: palette.text,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        Text(
          'Analyse complète de l\'activité • CA • Marges • Tendances',
          style: TextStyle(fontSize: 16, color: palette.subText),
        ),
      ],
    );
  }

  Widget _buildPeriodeSelector(
      BuildContext context, ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.date_range, color: accent, size: 28),
            const SizedBox(width: 16),
            Text(
              'Période :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            const SizedBox(width: 20),
            DropdownButton<String>(
              value: _periode,
              items: [
                'Aujourd\'hui',
                '7 jours',
                'Ce mois',
                '3 mois',
                'Cette année',
                'Personnalisé',
              ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
              onChanged: (v) {
                setState(() => _periode = v!);
                _loadData();
              },
              style: TextStyle(
                color: palette.text,
                fontWeight: FontWeight.w600,
              ),
              dropdownColor: palette.isDark ? Colors.grey[900] : Colors.white,
              underline: Container(),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _exportAsPdf(context),
              icon: const Icon(Icons.file_download),
              label: const Text('Exporter PDF'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _exportAsCsv(context),
              icon: const Icon(Icons.table_view),
              label: const Text('Exporter Excel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpis(ThemeColors palette, Color accent) {
    return Row(
      children: [
        Expanded(
        child: _kpiCard(
          'CA Total',
          _formatCurrency(_caTotal),
          _growthText(),
          Icons.trending_up,
          Colors.green,
          palette,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard(
            'Panier moyen',
            _formatCurrency(_panierMoyen),
            '',
            Icons.shopping_basket,
            accent,
            palette,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard(
            'Taux de marge',
            '${_tauxMarge.toStringAsFixed(1)}%',
            '',
            Icons.pie_chart,
            Colors.purple,
            palette,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard(
            'Nombre de ventes',
            '$_nbVentes',
            '',
            Icons.receipt_long,
            Colors.blue,
            palette,
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(
    String label,
    String value,
    String evolution,
    IconData icon,
    Color color,
    ThemeColors palette,
  ) {
    final hasEvolution = evolution.isNotEmpty;
    final showArrow = evolution.startsWith('+') || evolution.startsWith('-');
    final isPositive = evolution.startsWith('+');
    final evolutionColor = showArrow
        ? (isPositive ? Colors.green : Colors.red)
        : palette.subText;
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 28),
                ),
                const Spacer(),
                if (hasEvolution)
                  Row(
                    children: [
                      Text(
                        evolution,
                        style: TextStyle(
                          color: evolutionColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (showArrow)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(
                            isPositive
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: evolutionColor,
                          ),
                        ),
                    ],
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 16),
            Text(label, style: TextStyle(color: palette.subText, fontSize: 14)),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
          ],
        ),
      ),
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
          const SizedBox(height: 24),
          SizedBox(
            height: 280,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _caData.entries.map((e) {
                final max = _caData.values.reduce((a, b) => a > b ? a : b);
                final height = max == 0 ? 0.0 : (e.value / max) * 240;
                return Column(
                  children: [
                    Container(
                      width: 40,
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
                    const SizedBox(height: 8),
                    Text(
                      e.key,
                      style: TextStyle(color: palette.subText, fontSize: 12),
                    ),
                    Text(
                      NumberFormat.compact().format(e.value),
                      style: TextStyle(color: palette.text, fontSize: 11),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export PDF annulé')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('L\'export PDF a échoué : $e')),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export Excel annulé')),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('L\'export Excel a échoué : $e')),
      );
    }
  }

  Future<Uint8List> _buildReportPdfBytes() async {
    final doc = pw.Document();
    final headerStyle = pw.TextStyle(
      fontSize: 22,
      fontWeight: pw.FontWeight.bold,
    );
    final subStyle = pw.TextStyle(fontSize: 12, color: PdfColors.grey800);
    final tableHeader =
        pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return [
            pw.Text('Reporting • $_periode', style: headerStyle),
            pw.SizedBox(height: 6),
            pw.Text(
              'Généré le ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
              style: subStyle,
            ),
            pw.SizedBox(height: 16),
            pw.Text('KPIs', style: tableHeader),
            pw.Bullet(text: 'CA total : ${_formatCurrency(_caTotal)}'),
            pw.Bullet(text: 'Panier moyen : ${_formatCurrency(_panierMoyen)}'),
            pw.Bullet(text: 'Nombre de ventes : $_nbVentes'),
            pw.Bullet(text: 'Marge : ${_formatCurrency(_marge)}'),
            if (_growthLabel.isNotEmpty)
              pw.Bullet(text: 'Croissance : $_growthLabel'),
            if (_topProduits.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text('Top produits', style: tableHeader),
              pw.Table.fromTextArray(
                headers: ['Produit', 'Quantité', 'CA'],
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
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
              ),
            ],
            if (_topVendeurs.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              pw.Text('Top vendeurs', style: tableHeader),
              pw.Table.fromTextArray(
                headers: ['Vendeur', 'Ventes', 'CA'],
                data: _topVendeurs
                    .map(
                      (vendeur) => [
                        vendeur.nom,
                        vendeur.ventes.toString(),
                        NumberFormat('#,###', 'fr_FR').format(vendeur.ca),
                      ],
                    )
                    .toList(),
                headerStyle: tableHeader,
                cellAlignment: pw.Alignment.centerLeft,
                headerDecoration: pw.BoxDecoration(
                  color: PdfColors.grey300,
                ),
              ),
            ],
          ];
        },
      ),
    );
    return doc.save();
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
