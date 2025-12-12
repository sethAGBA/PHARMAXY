// screens/facturation_compta.dart
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;
import 'package:printing/printing.dart';
import 'package:pharmaxy/services/local_database_service.dart';

import '../app_theme.dart';
import '../models/app_settings.dart';
import '../models/sale_models.dart';
import '../services/ticket_service.dart';
import '../widgets/stats_card.dart';

class FacturationComptaScreen extends StatefulWidget {
  const FacturationComptaScreen({super.key});

  @override
  State<FacturationComptaScreen> createState() =>
      _FacturationComptaScreenState();
}

class _FacturationComptaScreenState extends State<FacturationComptaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  DateTime _selectedDate = DateTime.now();
  String _selectedPeriode = 'Aujourd\'hui';
  String _ongletActif =
      'journal'; // journal, factures, reglements, rapprochement
  bool _loading = true;
  String? _error;

  AppSettings _settings = AppSettings.defaults();

  // Loaded from DB
  final List<VenteJournal> _journal = [];
  final List<Facture> _factures = [];
  final List<Reglement> _reglements = [];

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
    _loadData();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // CALCULS
  int get _totalVentes =>
      _journal.where((v) => v.montant > 0).fold(0, (sum, v) => sum + v.montant);
  int get _totalAvoirs => _journal
      .where((v) => v.montant < 0)
      .fold(0, (sum, v) => sum + v.montant.abs());
  int get _caNet => _totalVentes - _totalAvoirs;
  int get _nbTransactions => _journal.length;

  Map<String, int> get _ventilationModes {
    final Map<String, int> ventilation = {};
    for (var v in _journal.where((v) => v.montant > 0)) {
      ventilation[v.mode] = (ventilation[v.mode] ?? 0) + v.montant;
    }
    return ventilation;
  }

  int get _facturesEnAttente => _factures
      .where((f) => f.statut == 'En attente')
      .fold(0, (sum, f) => sum + f.montant);
  int get _facturesPayees => _factures
      .where((f) => f.statut == 'Payée')
      .fold(0, (sum, f) => sum + f.montant);

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _loadJournal();
      await _loadFactures();
      await _loadReglements();
      final settings = await LocalDatabaseService.instance.getSettings();
      if (mounted) {
        setState(() {
          _loading = false;
          _settings = settings;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _loadJournal() async {
    _journal.clear();
    final db = LocalDatabaseService.instance.db;
    final filters = _periodeBounds();
    final rows = await db.query(
      'ventes',
      where: filters.where,
      whereArgs: filters.args,
      orderBy: 'date DESC',
    );
    for (final row in rows) {
      final date =
          DateTime.tryParse(row['date'] as String? ?? '') ?? DateTime.now();
      _journal.add(
        VenteJournal(
          id: row['id'] as String? ?? '',
          dateHeure: date,
          montant: (row['montant'] as num?)?.toInt() ?? 0,
          mode: row['mode'] as String? ?? '',
          type: row['type'] as String? ?? '',
          statut: row['statut'] as String? ?? '',
          vendeur: row['vendeur'] as String? ?? 'Utilisateur',
          client: row['client_id'] as String? ?? '',
          items: _deserializeItems(row['details'] as String?),
        ),
      );
    }
  }

  Future<void> _loadFactures() async {
    _factures.clear();
    final db = LocalDatabaseService.instance.db;
    try {
      final rows = await db.query('factures', orderBy: 'date DESC');
      for (final r in rows) {
        final date =
            DateTime.tryParse(r['date'] as String? ?? '') ?? DateTime.now();
        final echeance =
            DateTime.tryParse(r['echeance'] as String? ?? '') ?? date;
        _factures.add(
          Facture(
            id: r['id'] as String? ?? '',
            date: date,
            client: r['client_id'] as String? ?? '',
            montant: (r['montant'] as num?)?.toInt() ?? 0,
            statut: r['statut'] as String? ?? '',
            echeance: echeance,
            type: r['type'] as String? ?? '',
          ),
        );
      }
    } catch (_) {
      // table peut être absente
    }
  }

  Future<void> _loadReglements() async {
    _reglements.clear();
    for (final vente in _journal.where(
      (v) => v.statut.toLowerCase().contains('régl'),
    )) {
      _reglements.add(
        Reglement(
          id: vente.id,
          date: vente.dateHeure,
          facture: vente.id,
          client: vente.vendeur,
          montant: vente.montant,
          mode: vente.mode,
          statut: vente.statut,
        ),
      );
    }
  }

  _PeriodeFilter _periodeBounds() {
    DateTime? from;
    if (_selectedPeriode == 'Aujourd\'hui') {
      final now = DateTime.now();
      from = DateTime(now.year, now.month, now.day);
    } else if (_selectedPeriode == 'Cette semaine') {
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      from = DateTime(monday.year, monday.month, monday.day);
    } else if (_selectedPeriode == 'Ce mois') {
      final now = DateTime.now();
      from = DateTime(now.year, now.month, 1);
    }
    if (from == null) return const _PeriodeFilter(where: null, args: []);
    return _PeriodeFilter(where: 'date >= ?', args: [from.toIso8601String()]);
  }

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
          : Column(
              children: [
                // HEADER AVEC FILTRES
                _buildHeader(palette, accent),

                // INDICATEURS CLÉS
                _buildIndicateursGlobaux(palette, accent),

                // ONGLETS ET CONTENU
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 250),
                          child: _buildOnglets(palette, accent),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: _buildContenuPrincipal(palette, accent),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader(ThemeColors palette, Color accent) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.25 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: accent,
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Facturation & Comptabilité',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: palette.text,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestion complète des ventes, factures et règlements',
                      style: TextStyle(fontSize: 14, color: palette.subText),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _buildFiltrePeriode(palette, accent),
              const SizedBox(width: 12),
              _buildBoutonsActions(palette, accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltrePeriode(ThemeColors palette, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today, size: 18, color: accent),
          const SizedBox(width: 8),
          DropdownButton<String>(
            value: _selectedPeriode,
            underline: const SizedBox(),
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w600),
            items: [
              'Aujourd\'hui',
              'Cette semaine',
              'Ce mois',
              'Personnalisé',
            ].map((p) => DropdownMenuItem(value: p, child: Text(p))).toList(),
            onChanged: (value) {
              setState(() => _selectedPeriode = value!);
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBoutonsActions(ThemeColors palette, Color accent) {
    return Row(
      children: [
        _actionButton(
          'Nouvelle facture',
          Icons.add_circle_outline,
          accent,
          palette,
          () => _afficherDialogueFacture(),
        ),
        const SizedBox(width: 12),
        _actionButton(
          'Exporter',
          Icons.file_download,
          Colors.purple,
          palette,
          () => _afficherMenuExport(),
        ),
      ],
    );
  }

  Widget _actionButton(
    String label,
    IconData icon,
    Color color,
    ThemeColors palette,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 2,
      ),
    );
  }

  Widget _buildIndicateursGlobaux(ThemeColors palette, Color accent) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: _indicateurCard(
              'CA Brut',
              _totalVentes,
              Icons.trending_up,
              Colors.teal,
              palette,
              details: '$_nbTransactions transactions',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _indicateurCard(
              'Avoirs',
              _totalAvoirs,
              Icons.trending_down,
              Colors.red,
              palette,
              details: '${_journal.where((v) => v.montant < 0).length} retours',
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _indicateurCard(
              'CA Net',
              _caNet,
              Icons.payments,
              accent,
              palette,
              isMain: true,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _indicateurCard(
              'En attente',
              _facturesEnAttente,
              Icons.schedule,
              Colors.orange,
              palette,
              details:
                  '${_factures.where((f) => f.statut == 'En attente').length} factures',
            ),
          ),
        ],
      ),
    );
  }

  Widget _indicateurCard(
    String label,
    int montant,
    IconData icon,
    Color color,
    ThemeColors palette, {
    bool isMain = false,
    String? details,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isMain ? color.withOpacity(0.1) : palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMain ? color.withOpacity(0.3) : palette.divider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              if (isMain)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'PRINCIPAL',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: palette.subText,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${NumberFormat('#,###', 'fr_FR').format(montant)} FCFA',
            style: TextStyle(
              fontSize: isMain ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: isMain ? color : palette.text,
            ),
          ),
          if (details != null) ...[
            const SizedBox(height: 4),
            Text(
              details,
              style: TextStyle(color: palette.subText, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOnglets(ThemeColors palette, Color accent) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              'SECTIONS',
              style: TextStyle(
                color: palette.subText,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
          _ongletItem(
            'Journal des ventes',
            Icons.receipt_long,
            'journal',
            palette,
            accent,
            badge: _journal.length,
          ),
          _ongletItem(
            'Factures & Avoirs',
            Icons.description,
            'factures',
            palette,
            accent,
            badge: _factures.length,
          ),
          _ongletItem(
            'État des règlements',
            Icons.payment,
            'reglements',
            palette,
            accent,
            badge: _reglements.length,
          ),
          _ongletItem(
            'Rapprochement bancaire',
            Icons.account_balance,
            'rapprochement',
            palette,
            accent,
          ),
          const Divider(height: 32),
          _ongletItem(
            'Statistiques',
            Icons.bar_chart,
            'stats',
            palette,
            Colors.purple,
          ),
          _ongletItem(
            'Export comptable',
            Icons.download,
            'export',
            palette,
            Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _ongletItem(
    String label,
    IconData icon,
    String onglet,
    ThemeColors palette,
    Color color, {
    int? badge,
  }) {
    final isActif = _ongletActif == onglet;
    return InkWell(
      onTap: () => setState(() => _ongletActif = onglet),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isActif ? color.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActif ? color.withOpacity(0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isActif ? color : palette.subText, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isActif ? color : palette.text,
                  fontWeight: isActif ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActif ? color : palette.subText.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$badge',
                  style: TextStyle(
                    color: isActif ? Colors.white : palette.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContenuPrincipal(ThemeColors palette, Color accent) {
    return switch (_ongletActif) {
      'journal' => _buildJournalVentes(palette, accent),
      'factures' => _buildFacturesAvoirs(palette, accent),
      'reglements' => _buildEtatReglements(palette, accent),
      'rapprochement' => _buildRapprochementBancaire(palette, accent),
      'stats' => _buildStatistiques(palette, accent),
      'export' => _buildExportComptable(palette, accent),
      _ => _buildJournalVentes(palette, accent),
    };
  }

  Widget _buildJournalVentes(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.receipt_long, color: accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Journal des ventes',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                      ),
                      Text(
                        '${DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate)}',
                        style: TextStyle(color: palette.subText),
                      ),
                    ],
                  ),
                ),
                _buildVentilationModes(palette),
              ],
            ),
          ),
          const Divider(height: 1),
          Container(
            color: palette.background.withOpacity(0.5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _headerCell('N° VENTE', 140, palette),
                  _headerCell('HEURE', 80, palette),
                  _headerCell('VENDEUR', 150, palette),
                  _headerCell('CLIENT', 160, palette),
                  _headerCell('MONTANT', 120, palette, align: TextAlign.right),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 320,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 820,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _journal.length,
                  itemBuilder: (context, index) =>
                      _venteRow(_journal[index], palette, accent),
                ),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: palette.background.withOpacity(0.3),
              border: Border(top: BorderSide(color: palette.divider)),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Text(
                    'Total ventes: ',
                    style: TextStyle(color: palette.subText, fontSize: 16),
                  ),
                  Text(
                    '${NumberFormat('#,###', 'fr_FR').format(_totalVentes)} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 40),
                  Text(
                    'Avoirs: ',
                    style: TextStyle(color: palette.subText, fontSize: 16),
                  ),
                  Text(
                    '${NumberFormat('#,###', 'fr_FR').format(_totalAvoirs)} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 40),
                  Text(
                    'Net: ',
                    style: TextStyle(color: palette.subText, fontSize: 16),
                  ),
                  Text(
                    '${NumberFormat('#,###', 'fr_FR').format(_caNet)} FCFA',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: accent,
                      fontSize: 20,
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

  Widget _headerCell(
    String label,
    double width,
    ThemeColors palette, {
    TextAlign align = TextAlign.left,
  }) {
    return SizedBox(
      width: width,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: palette.subText,
        ),
        textAlign: align,
      ),
    );
  }

  Widget _venteRow(VenteJournal vente, ThemeColors palette, Color accent) {
    final isAvoir = vente.montant < 0;
    final color = isAvoir
        ? Colors.red
        : vente.statut == 'Réglée'
        ? Colors.green
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvoir ? Colors.red.withOpacity(0.3) : palette.divider,
        ),
      ),
      child: Row(
        children: [
          // N° VENTE
          SizedBox(
            width: 140,
            child: Row(
              children: [
                Icon(
                  isAvoir ? Icons.keyboard_return : Icons.receipt,
                  color: color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    vente.id,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // HEURE
          SizedBox(
            width: 80,
            child: Text(
              DateFormat('HH:mm').format(vente.dateHeure),
              style: TextStyle(color: palette.subText),
            ),
          ),
          const SizedBox(width: 16),

          // VENDEUR
          SizedBox(
            width: 150,
            child: Text(
              vente.vendeur,
              style: TextStyle(color: palette.subText, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 16),

          // CLIENT
          SizedBox(
            width: 160,
            child: Text(
              vente.client.isEmpty ? 'Générique' : vente.client,
              style: TextStyle(color: palette.subText, fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // MONTANT
          SizedBox(
            width: 120,
            child: Text(
              '${isAvoir ? '-' : ''}${NumberFormat('#,###', 'fr_FR').format(vente.montant.abs())} F',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isAvoir ? Colors.red : accent,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // ACTIONS
          SizedBox(
            width: 50,
            child: PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: palette.subText, size: 18),
              onSelected: (value) => _onVenteAction(vente, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Text('Voir détails'),
                ),
                const PopupMenuItem(
                  value: 'enregistrer',
                  child: Text('Enregistrer reçu'),
                ),
                const PopupMenuItem(value: 'imprimer', child: Text('Imprimer')),
                if (isAvoir)
                  const PopupMenuItem(
                    value: 'annuler',
                    child: Text('Annuler avoir'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onVenteAction(VenteJournal vente, String action) {
    switch (action) {
      case 'details':
        _showSaleDetails(vente);
        break;
      case 'enregistrer':
        _saveSaleReceipt(vente);
        break;
      case 'imprimer':
        _printSaleReceipt(vente);
        break;
      case 'annuler':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Annulation non implémentée')),
        );
        break;
    }
  }

  void _onReglementAction(Reglement reglement, String action) {
    final vente = _findSaleById(reglement.id);
    if (vente == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ticket introuvable')));
      return;
    }
    switch (action) {
      case 'details':
        _showSaleDetails(vente);
        break;
      case 'enregistrer':
        _saveSaleReceipt(vente);
        break;
      case 'imprimer':
        _printSaleReceipt(vente);
        break;
      case 'encaisser':
        // TODO: Add encaissé workflow
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Encaissement non implémenté')),
        );
        break;
    }
  }

  void _showSaleDetails(VenteJournal vente) {
    final palette = ThemeColors.from(context);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: palette.card,
          title: Text('Détails de la vente ${vente.id}'),
          content: SizedBox(
            width: 360,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Client: ${vente.client.isEmpty ? 'Générique' : vente.client}',
                  ),
                  const SizedBox(height: 6),
                  Text('Vendeur: ${vente.vendeur}'),
                  const SizedBox(height: 6),
                  Text(
                    'Date: ${DateFormat('dd/MM/yyyy HH:mm').format(vente.dateHeure)}',
                    style: TextStyle(color: palette.subText),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Statut: ${vente.statut}',
                    style: TextStyle(color: palette.subText),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mode: ${vente.mode}',
                    style: TextStyle(color: palette.subText),
                  ),
                  const SizedBox(height: 12),
                  if (vente.items.isEmpty)
                    Text(
                      'Aucun détail de vente disponible',
                      style: TextStyle(color: palette.subText),
                    )
                  else
                    ...vente.items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name} x${item.quantity}',
                                style: TextStyle(color: palette.text),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${NumberFormat('#,###', 'fr_FR').format((item.price * item.quantity).toInt())} F',
                              style: TextStyle(color: palette.subText),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Total: ${NumberFormat('#,###', 'fr_FR').format(vente.montant.abs())} FCFA',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveSaleReceipt(vente);
              },
              child: const Text('Enregistrer'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _printSaleReceipt(vente);
              },
              child: const Text('Imprimer'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _printSaleReceipt(VenteJournal vente) async {
    try {
      final bytes = await TicketService.instance.generateReceipt(
        saleId: vente.id,
        client: vente.client.isNotEmpty ? vente.client : 'Client',
        total: vente.montant.abs().toDouble(),
        paymentMethod: vente.mode,
        items: vente.items,
        vendor: vente.vendeur,
        logoPath: _settings.logoPath,
        currency: _settings.currency,
        pharmacyName: _settings.pharmacyName,
        pharmacyAddress: _settings.pharmacyAddress,
        pharmacyPhone: _settings.pharmacyPhone,
        pharmacyEmail: _settings.pharmacyEmail,
        pharmacyOrderNumber: _settings.pharmacyOrderNumber,
        pharmacyWebsite: _settings.pharmacyWebsite,
        pharmacyHours: _settings.pharmacyHours,
        emergencyContact: _settings.emergencyContact,
        fiscalId: _settings.fiscalId,
        taxDetails: _settings.taxDetails,
        returnPolicy: _settings.returnPolicy,
        healthAdvice: _settings.healthAdvice,
        loyaltyMessage: _settings.loyaltyMessage,
        ticketLink: _settings.ticketLink,
        footerMessage: _settings.ticketFooter,
      );
      await Printing.layoutPdf(onLayout: (_) => bytes);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur d\'impression: $e')));
    }
  }

  Future<void> _saveSaleReceipt(VenteJournal vente) async {
    final directory = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Choisissez un dossier pour enregistrer le reçu',
    );
    if (directory == null) return;
    try {
      final bytes = await TicketService.instance.generateReceipt(
        saleId: vente.id,
        client: vente.client.isNotEmpty ? vente.client : 'Client',
        total: vente.montant.abs().toDouble(),
        paymentMethod: vente.mode,
        items: vente.items,
        vendor: vente.vendeur,
        logoPath: _settings.logoPath,
        currency: _settings.currency,
        pharmacyName: _settings.pharmacyName,
        pharmacyAddress: _settings.pharmacyAddress,
        pharmacyPhone: _settings.pharmacyPhone,
        pharmacyEmail: _settings.pharmacyEmail,
        pharmacyOrderNumber: _settings.pharmacyOrderNumber,
        pharmacyWebsite: _settings.pharmacyWebsite,
        pharmacyHours: _settings.pharmacyHours,
        emergencyContact: _settings.emergencyContact,
        fiscalId: _settings.fiscalId,
        taxDetails: _settings.taxDetails,
        returnPolicy: _settings.returnPolicy,
        healthAdvice: _settings.healthAdvice,
        loyaltyMessage: _settings.loyaltyMessage,
        ticketLink: _settings.ticketLink,
        footerMessage: _settings.ticketFooter,
      );
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = p.join(directory, 'ticket_${vente.id}_$timestamp.pdf');
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reçu sauvegardé : ${file.path}')));
      try {
        await OpenFilex.open(file.path);
      } catch (openError) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Impossible d\'ouvrir le reçu automatiquement: $openError',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement: $e')),
      );
    }
  }

  VenteJournal? _findSaleById(String id) {
    try {
      return _journal.firstWhere((vente) => vente.id == id);
    } catch (_) {
      return null;
    }
  }

  Widget _modeBadge(String mode, ThemeColors palette) {
    final (color, icon) = switch (mode) {
      'Espèces' => (Colors.green, Icons.money),
      'Carte' => (Colors.blue, Icons.credit_card),
      'Mobile Money' => (Colors.purple, Icons.phone_android),
      'Tiers payant' => (Colors.orange, Icons.health_and_safety),
      'Avoir' => (Colors.red, Icons.keyboard_return),
      _ => (Colors.grey, Icons.payment),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            mode,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVentilationModes(ThemeColors palette) {
    final ventilation = _ventilationModes;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.background.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ventilation par mode',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: palette.text,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ...ventilation.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  _modeBadge(e.key, palette),
                  const SizedBox(width: 12),
                  Text(
                    '${NumberFormat('#,###', 'fr_FR').format(e.value)} F',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                      fontSize: 13,
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

  Widget _buildFacturesAvoirs(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.description, color: accent, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Factures & Avoirs',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: palette.text,
                          ),
                        ),
                        Text(
                          'Gestion des factures clients',
                          style: TextStyle(color: palette.subText),
                        ),
                      ],
                    ),
                  ),
                  _buildFiltresFactures(palette),
                ],
              ),
            ),
            const Divider(height: 1),
            LayoutBuilder(
              builder: (context, constraints) {
                final width = math.max(960.0, constraints.maxWidth);
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: width,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          color: palette.background.withOpacity(0.5),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 120,
                                child: Text(
                                  'N° FACTURE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: palette.subText,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 100,
                                child: Text(
                                  'DATE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: palette.subText,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 200,
                                child: Text(
                                  'CLIENT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: palette.subText,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 120,
                                child: Text(
                                  'ÉCHÉANCE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: palette.subText,
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 140,
                                child: Text(
                                  'MONTANT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: palette.subText,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              SizedBox(
                                width: 140,
                                child: Text(
                                  'STATUT',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: palette.subText,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 50),
                            ],
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          itemCount: _factures.length,
                          itemBuilder: (context, index) =>
                              _factureRow(_factures[index], palette, accent),
                        ),
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: palette.background.withOpacity(0.3),
                            border: Border(
                              top: BorderSide(color: palette.divider),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                'Total factures payées: ',
                                style: TextStyle(
                                  color: palette.subText,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,###', 'fr_FR').format(_facturesPayees)} FCFA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(width: 40),
                              Text(
                                'En attente: ',
                                style: TextStyle(
                                  color: palette.subText,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                '${NumberFormat('#,###', 'fr_FR').format(_facturesEnAttente)} FCFA',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _factureRow(Facture facture, ThemeColors palette, Color accent) {
    final isAvoir = facture.type == 'Avoir';
    final statusColor = switch (facture.statut) {
      'Payée' => Colors.green,
      'En attente' => Colors.orange,
      'Partiellement payée' => Colors.blue,
      'Remboursée' => Colors.red,
      _ => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isAvoir ? Colors.red.withOpacity(0.3) : palette.divider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // N° FACTURE
          SizedBox(
            width: 120,
            child: Row(
              children: [
                Icon(
                  isAvoir ? Icons.assignment_return : Icons.description,
                  color: isAvoir ? Colors.red : accent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  facture.id,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // DATE
          SizedBox(
            width: 100,
            child: Text(
              DateFormat('dd/MM/yyyy').format(facture.date),
              style: TextStyle(color: palette.subText),
            ),
          ),

          // CLIENT
          SizedBox(
            width: 200,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  facture.client,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                Text(
                  facture.type,
                  style: TextStyle(color: palette.subText, fontSize: 12),
                ),
              ],
            ),
          ),

          // ÉCHÉANCE
          SizedBox(
            width: 120,
            child: Text(
              DateFormat('dd/MM/yyyy').format(facture.echeance),
              style: TextStyle(
                color:
                    facture.echeance.isBefore(DateTime.now()) &&
                        facture.statut == 'En attente'
                    ? Colors.red
                    : palette.subText,
                fontWeight:
                    facture.echeance.isBefore(DateTime.now()) &&
                        facture.statut == 'En attente'
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),

          // MONTANT
          SizedBox(
            width: 140,
            child: Text(
              '${isAvoir ? '-' : ''}${NumberFormat('#,###', 'fr_FR').format(facture.montant.abs())} F',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isAvoir ? Colors.red : accent,
              ),
              textAlign: TextAlign.right,
            ),
          ),

          // STATUT
          SizedBox(
            width: 140,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  facture.statut,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),

          // ACTIONS
          SizedBox(
            width: 50,
            child: PopupMenuButton(
              icon: Icon(Icons.more_vert, color: palette.subText, size: 18),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Text('Voir détails'),
                ),
                const PopupMenuItem(value: 'imprimer', child: Text('Imprimer')),
                const PopupMenuItem(
                  value: 'email',
                  child: Text('Envoyer par email'),
                ),
                if (facture.statut == 'En attente')
                  const PopupMenuItem(
                    value: 'paiement',
                    child: Text('Enregistrer paiement'),
                  ),
                const PopupMenuItem(value: 'annuler', child: Text('Annuler')),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltresFactures(ThemeColors palette) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: palette.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list, size: 18, color: palette.subText),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: 'Toutes',
                underline: const SizedBox(),
                style: TextStyle(
                  color: palette.text,
                  fontWeight: FontWeight.w600,
                ),
                items: ['Toutes', 'En attente', 'Payées', 'Échues']
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (value) {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEtatReglements(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.max(960.0, constraints.maxWidth);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(Icons.payment, color: accent, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'État des règlements',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: palette.text,
                            ),
                          ),
                          Text(
                            'Suivi des paiements clients',
                            style: TextStyle(color: palette.subText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        color: palette.background.withOpacity(0.5),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: Text(
                                'N° RÈGLEMENT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: palette.subText,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 100,
                              child: Text(
                                'DATE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: palette.subText,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'FACTURE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: palette.subText,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                'CLIENT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: palette.subText,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'MODE',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: palette.subText,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 140,
                              child: Text(
                                'MONTANT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: palette.subText,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                            SizedBox(
                              width: 120,
                              child: Text(
                                'STATUT',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: palette.subText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(width: 50),
                          ],
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _reglements.length,
                        itemBuilder: (context, index) =>
                            _reglementRow(_reglements[index], palette, accent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _reglementRow(Reglement reglement, ThemeColors palette, Color accent) {
    final statusColor = reglement.statut == 'Encaissé'
        ? Colors.green
        : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              reglement.id,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              DateFormat('dd/MM/yyyy').format(reglement.date),
              style: TextStyle(color: palette.subText),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              reglement.facture,
              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              reglement.client,
              style: TextStyle(color: palette.text),
            ),
          ),
          SizedBox(width: 120, child: _modeBadge(reglement.mode, palette)),
          SizedBox(
            width: 140,
            child: Text(
              '${NumberFormat('#,###', 'fr_FR').format(reglement.montant)} F',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: accent,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 120,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  reglement.statut,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: PopupMenuButton(
              icon: Icon(Icons.more_vert, color: palette.subText, size: 18),
              onSelected: (value) => _onReglementAction(reglement, value),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'details',
                  child: Text('Voir détails'),
                ),
                const PopupMenuItem(
                  value: 'enregistrer',
                  child: Text('Enregistrer reçu'),
                ),
                const PopupMenuItem(
                  value: 'imprimer',
                  child: Text('Imprimer reçu'),
                ),
                if (reglement.statut == 'En attente')
                  const PopupMenuItem(
                    value: 'encaisser',
                    child: Text('Marquer encaissé'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRapprochementBancaire(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance,
              size: 80,
              color: palette.subText.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Rapprochement bancaire',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fonctionnalité à venir',
              style: TextStyle(fontSize: 16, color: palette.subText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistiques(ThemeColors palette, Color accent) {
    final currency = _settings.currency.isNotEmpty
        ? _settings.currency
        : 'FCFA';
    final formatter = NumberFormat('#,###', 'fr_FR');
    final totalVentes = _totalVentes.toDouble();
    final totalAvoirs = _totalAvoirs.toDouble();
    final caNet = _caNet.toDouble();
    final panierMoyen = _nbTransactions == 0 ? 0 : caNet / _nbTransactions;

    final kpis = [
      (
        title: 'CA ventes',
        value: '${formatter.format(totalVentes)} $currency',
        subtitle: _selectedPeriode,
        icon: Icons.trending_up,
        color: Colors.green,
      ),
      (
        title: 'Avoirs / retours',
        value: '${formatter.format(totalAvoirs)} $currency',
        subtitle: '${_journal.where((v) => v.montant < 0).length} retours',
        icon: Icons.undo,
        color: Colors.redAccent,
      ),
      (
        title: 'CA net',
        value: '${formatter.format(caNet)} $currency',
        subtitle: 'Après avoirs',
        icon: Icons.account_balance_wallet,
        color: Colors.teal,
      ),
      (
        title: 'Transactions',
        value: '$_nbTransactions',
        subtitle: 'Ventes/avoirs',
        icon: Icons.receipt_long,
        color: Colors.orange,
      ),
      (
        title: 'Panier moyen',
        value: '${formatter.format(panierMoyen)} $currency',
        subtitle: 'Par vente',
        icon: Icons.shopping_basket,
        color: Colors.indigo,
      ),
      (
        title: 'Factures payées',
        value: '${formatter.format(_facturesPayees)} $currency',
        subtitle:
            '${_factures.where((f) => f.statut == 'Payée').length} factures',
        icon: Icons.verified,
        color: Colors.blue,
      ),
      (
        title: 'Factures en attente',
        value: '${formatter.format(_facturesEnAttente)} $currency',
        subtitle:
            '${_factures.where((f) => f.statut == 'En attente').length} factures',
        icon: Icons.pending_actions,
        color: Colors.purple,
      ),
    ];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Statistiques',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: palette.text,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final cardWidth = width > 1200
                  ? (width - 36) / 3
                  : width > 800
                  ? (width - 24) / 2
                  : width;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: kpis.map((kpi) {
                  return SizedBox(
                    width: cardWidth,
                    child: StatsCard(
                      title: kpi.title,
                      value: kpi.value,
                      icon: kpi.icon,
                      color: kpi.color,
                      subtitle: kpi.subtitle,
                      textColor: palette.text,
                      subTextColor: palette.subText,
                      cardColor: palette.card,
                    ),
                  );
                }).toList(),
              );
            },
          ),
          const SizedBox(height: 20),
          _card(
            palette,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.pie_chart, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        'Ventilation des paiements',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_ventilationModes.isEmpty)
                    Text(
                      'Aucune vente sur la période',
                      style: TextStyle(color: palette.subText),
                    )
                  else
                    ..._ventilationModes.entries.map((e) {
                      final mode = e.key;
                      final montant = e.value;
                      final part = totalVentes == 0
                          ? 0.0
                          : montant / totalVentes;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                mode,
                                style: TextStyle(color: palette.text),
                              ),
                            ),
                            Expanded(
                              flex: 5,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: part.clamp(0.0, 1.0),
                                  minHeight: 10,
                                  backgroundColor: palette.divider,
                                  valueColor: AlwaysStoppedAnimation(accent),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 110,
                              child: Text(
                                '${formatter.format(montant)} $currency',
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: palette.text,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _card(
            palette,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person, color: accent),
                      const SizedBox(width: 8),
                      Text(
                        'Ventes par vendeur',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final ventesVendeur = <String, List<VenteJournal>>{};
                      for (final v in _journal.where((j) {
                        if (j.montant <= 0) return false;
                        return !j.statut.toLowerCase().contains('annul');
                      })) {
                        ventesVendeur.putIfAbsent(v.vendeur, () => []).add(v);
                      }
                      if (ventesVendeur.isEmpty) {
                        return Text(
                          'Aucune vente sur la période',
                          style: TextStyle(color: palette.subText),
                        );
                      }
                      final entries =
                          ventesVendeur.entries.map((e) {
                            final ca = e.value.fold<int>(
                              0,
                              (sum, v) => sum + v.montant,
                            );
                            return MapEntry(
                              e.key.isEmpty ? 'Vendeur inconnu' : e.key,
                              {'ca': ca, 'ventes': e.value.length},
                            );
                          }).toList()..sort(
                            (a, b) => (b.value['ca'] as int).compareTo(
                              a.value['ca'] as int,
                            ),
                          );

                      return Column(
                        children: entries.map((e) {
                          final vendeur = e.key;
                          final ca = e.value['ca'] as int;
                          final nb = e.value['ventes'] as int;
                          final part = totalVentes == 0
                              ? 0.0
                              : ca / totalVentes;
                          final panier = nb == 0 ? 0 : ca / nb;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        vendeur,
                                        style: TextStyle(
                                          color: palette.text,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        '$nb ventes • ${formatter.format(panier)} $currency/vente',
                                        style: TextStyle(
                                          color: palette.subText,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 5,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: part.clamp(0.0, 1.0),
                                      minHeight: 10,
                                      backgroundColor: palette.divider,
                                      valueColor: AlwaysStoppedAnimation(
                                        accent,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    '${formatter.format(ca)} $currency',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: palette.text,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportComptable(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.download,
              size: 80,
              color: palette.subText.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Export comptable',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fonctionnalité à venir',
              style: TextStyle(fontSize: 16, color: palette.subText),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(ThemeColors palette, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  void _afficherDialogueFacture() {
    // TODO: Implémenter le dialogue de création de facture
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dialogue de création de facture à implémenter'),
      ),
    );
  }

  void _afficherMenuExport() {
    // TODO: Implémenter le menu d'export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Menu d\'export à implémenter')),
    );
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
}

// MODÈLES DE DONNÉES
class VenteJournal {
  final String id;
  final DateTime dateHeure;
  final int montant;
  final String mode;
  final String type;
  final String statut;
  final String vendeur;
  final String client;
  final List<CartItem> items;

  VenteJournal({
    required this.id,
    required this.dateHeure,
    required this.montant,
    required this.mode,
    required this.type,
    required this.statut,
    required this.vendeur,
    required this.client,
    required this.items,
  });
}

class Facture {
  final String id;
  final DateTime date;
  final String client;
  final int montant;
  final String statut;
  final DateTime echeance;
  final String type;

  Facture({
    required this.id,
    required this.date,
    required this.client,
    required this.montant,
    required this.statut,
    required this.echeance,
    required this.type,
  });
}

class Reglement {
  final String id;
  final DateTime date;
  final String facture;
  final String client;
  final int montant;
  final String mode;
  final String statut;

  Reglement({
    required this.id,
    required this.date,
    required this.facture,
    required this.client,
    required this.montant,
    required this.mode,
    required this.statut,
  });
}

class _PeriodeFilter {
  final String? where;
  final List<Object?> args;
  const _PeriodeFilter({required this.where, required this.args});
}
