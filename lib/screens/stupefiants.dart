import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/stupefiant_mouvement.dart';
import '../services/local_database_service.dart';

class StupefiantsScreen extends StatefulWidget {
  const StupefiantsScreen({super.key});

  @override
  State<StupefiantsScreen> createState() => _StupefiantsScreenState();
}

class _StupefiantsScreenState extends State<StupefiantsScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double> _fade = const AlwaysStoppedAnimation<double>(1);
  final TextEditingController _searchController = TextEditingController();
  String _type = 'Tous';
  String _periode = 'Ce mois';

  List<StupefiantMouvement> _mouvements = [];
  bool _loading = true;
  String? _error;
  List<String> _produitSuggestions = [];
  final Map<String, List<String>> _lotsParProduit = {};

  final List<_Controle> _controles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeOutCubic),
    );
    _controller!.forward();
    _loadMouvements();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMouvements() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await LocalDatabaseService.instance.init();
      final movs = await LocalDatabaseService.instance
          .getStupefiantMouvements();
      final db = LocalDatabaseService.instance.db;
      final produitsRows = await db.query(
        'medicaments',
        columns: ['nom'],
        where: 'stupefiant = 1',
        orderBy: 'nom ASC',
      );
      final produitSuggestions = produitsRows
          .map((r) => (r['nom'] as String?) ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      final lotsRows = await db.rawQuery('''
        SELECT m.nom as produit, l.lot as lot
        FROM lots l
        JOIN medicaments m ON m.id = l.medicament_id
        WHERE m.stupefiant = 1
      ''');
      final lotsParProduit = <String, Set<String>>{};
      for (final r in lotsRows) {
        final produit = (r['produit'] as String?) ?? '';
        final lot = (r['lot'] as String?) ?? '';
        if (produit.isEmpty || lot.isEmpty) continue;
        lotsParProduit.putIfAbsent(produit, () => <String>{}).add(lot);
      }
      if (!mounted) return;
      setState(() {
        _mouvements = movs;
        _produitSuggestions = produitSuggestions;
        _lotsParProduit
          ..clear()
          ..addAll(
            lotsParProduit.map((k, v) => MapEntry(k, v.toList()..sort())),
          );
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _inSelectedPeriod(DateTime date) {
    final now = DateTime.now();
    if (_periode == 'Ce mois') {
      return date.year == now.year && date.month == now.month;
    }
    if (_periode == '30 jours') {
      return date.isAfter(now.subtract(const Duration(days: 30)));
    }
    if (_periode == '90 jours') {
      return date.isAfter(now.subtract(const Duration(days: 90)));
    }
    return true;
  }

  List<StupefiantMouvement> get _filtered {
    final q = _searchController.text.toLowerCase();
    return _mouvements.where((m) {
      final matchesText =
          m.produit.toLowerCase().contains(q) ||
          m.ref.toLowerCase().contains(q) ||
          m.lot.toLowerCase().contains(q);
      final matchesType = _type == 'Tous' || m.type == _type;
      final matchesPeriode = _inSelectedPeriod(m.date);
      return matchesText && matchesType && matchesPeriode;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    const accent = Colors.deepPurple;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Text('Erreur: $_error', style: TextStyle(color: palette.text)),
      );
    }

    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(palette, accent),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    _buildKpis(palette, accent),
                    const SizedBox(height: 16),
                    _buildFilters(palette, accent),
                    const SizedBox(height: 16),
                    _buildRegister(palette, accent),
                    const SizedBox(height: 16),
                    _buildAuditAndDeclarations(palette, accent),
                  ],
                ),
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.verified_user, color: accent, size: 26),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gestion des stupéfiants',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            Text(
              'Registre spécifique • Traçabilité renforcée • Déclarations',
              style: TextStyle(color: palette.subText),
            ),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Exporter registre'),
          style: OutlinedButton.styleFrom(
            foregroundColor: accent,
            side: BorderSide(color: accent.withOpacity(0.35)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpis(ThemeColors palette, Color accent) {
    final totalEntrees = _mouvements
        .where((m) => m.type == 'Entrée')
        .fold<int>(0, (sum, m) => sum + m.quantite);
    final totalSorties = _mouvements
        .where((m) => m.type == 'Sortie')
        .fold<int>(0, (sum, m) => sum + m.quantite);
    final stockTheorique = totalEntrees - totalSorties;

    final entreesPeriode = _mouvements
        .where((m) => m.type == 'Entrée' && _inSelectedPeriod(m.date))
        .fold<int>(0, (sum, m) => sum + m.quantite);
    final sortiesPeriode = _mouvements
        .where((m) => m.type == 'Sortie' && _inSelectedPeriod(m.date))
        .fold<int>(0, (sum, m) => sum + m.quantite);

    final stockParLot = <String, int>{};
    for (final m in _mouvements) {
      final key = '${m.produit}::${m.lot}';
      final delta = m.type == 'Entrée' ? m.quantite : -m.quantite;
      stockParLot[key] = (stockParLot[key] ?? 0) + delta;
    }
    final alertes = stockParLot.values.where((v) => v < 0).length;

    return Row(
      children: [
        Expanded(
          child: _kpi(
            'Stock théorique',
            '$stockTheorique unités',
            Icons.inventory_2,
            accent,
            palette,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpi(
            'Entrées (mois)',
            '$entreesPeriode',
            Icons.download,
            Colors.green,
            palette,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpi(
            'Sorties (mois)',
            '$sortiesPeriode',
            Icons.upload,
            Colors.orange,
            palette,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpi(
            'Alertes / écarts',
            '$alertes',
            Icons.warning_amber,
            Colors.redAccent,
            palette,
          ),
        ),
      ],
    );
  }

  Widget _kpi(
    String title,
    String value,
    IconData icon,
    Color color,
    ThemeColors palette,
  ) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: palette.subText, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final searchWidth = math.min(320.0, constraints.maxWidth);
            final fieldWidth = math.min(180.0, constraints.maxWidth - 32.0);
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: searchWidth,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher référence, lot, produit...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: palette.isDark
                          ? Colors.grey[850]
                          : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: DropdownButtonFormField<String>(
                    value: _type,
                    items: const ['Tous', 'Entrée', 'Sortie']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _type = v ?? 'Tous'),
                    decoration: InputDecoration(
                      labelText: 'Type de mouvement',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    dropdownColor: palette.card,
                  ),
                ),
                SizedBox(
                  width: fieldWidth,
                  child: DropdownButtonFormField<String>(
                    value: _periode,
                    items: const ['Ce mois', '30 jours', '90 jours']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => setState(() => _periode = v ?? 'Ce mois'),
                    decoration: InputDecoration(
                      labelText: 'Période',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    dropdownColor: palette.card,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fact_check, color: accent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${_filtered.length} mouvements',
                        style: TextStyle(
                          color: palette.text,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildRegister(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.library_books, color: accent),
                const SizedBox(width: 8),
                Text(
                  'Registre des mouvements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => _ouvrirDialogMouvement(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle écriture'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 18,
                columns: [
                  _col('Référence', palette),
                  _col('Date', palette),
                  _col('Produit', palette),
                  _col('Lot', palette),
                  _col('Type', palette),
                  _col('Quantité', palette),
                  _col('Agent', palette),
                  _col('Motif', palette),
                  _col('Actions', palette),
                ],
                rows: _filtered.map((m) => _row(m, palette)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataColumn _col(String label, ThemeColors palette) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, color: palette.text),
      ),
    );
  }

  DataRow _row(StupefiantMouvement m, ThemeColors palette) {
    final color = m.type == 'Entrée' ? Colors.green : Colors.orange;
    return DataRow(
      cells: [
        DataCell(Text(m.ref, style: TextStyle(color: palette.text))),
        DataCell(
          Text(
            '${m.date.day.toString().padLeft(2, '0')}/${m.date.month.toString().padLeft(2, '0')}/${m.date.year}',
            style: TextStyle(color: palette.text),
          ),
        ),
        DataCell(Text(m.produit, style: TextStyle(color: palette.text))),
        DataCell(Text(m.lot, style: TextStyle(color: palette.text))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              m.type,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        DataCell(
          Text(
            '${m.quantite}',
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(Text(m.agent, style: TextStyle(color: palette.text))),
        DataCell(Text(m.motif, style: TextStyle(color: palette.subText))),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _ouvrirDialogMouvement(existing: m),
                icon: const Icon(Icons.edit, size: 18),
              ),
              IconButton(
                onPressed: () => _confirmerSuppression(m),
                icon: const Icon(Icons.delete, size: 18),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _ouvrirDialogMouvement({StupefiantMouvement? existing}) async {
    final formKey = GlobalKey<FormState>();
    final produitCtrl = TextEditingController(text: existing?.produit ?? '');
    final lotCtrl = TextEditingController(text: existing?.lot ?? '');
    final quantiteCtrl = TextEditingController(
      text: existing != null ? existing.quantite.toString() : '',
    );
    final agentCtrl = TextEditingController(text: existing?.agent ?? '');
    final motifCtrl = TextEditingController(text: existing?.motif ?? '');
    DateTime date = existing?.date ?? DateTime.now();
    String type = existing?.type ?? 'Entrée';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(
                existing == null
                    ? 'Nouvelle écriture stupéfiants'
                    : 'Modifier écriture',
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: produitCtrl.text),
                        optionsBuilder: (textEditingValue) {
                          final q = textEditingValue.text.toLowerCase();
                          if (q.isEmpty) return _produitSuggestions;
                          return _produitSuggestions
                              .where((p) => p.toLowerCase().contains(q))
                              .toList();
                        },
                        onSelected: (selection) {
                          setLocal(() {
                            produitCtrl.text = selection;
                            lotCtrl.text = '';
                          });
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onSubmit) {
                              controller.text = produitCtrl.text;
                              controller.selection = TextSelection.collapsed(
                                offset: controller.text.length,
                              );
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Produit',
                                ),
                                onChanged: (v) => setLocal(() {
                                  produitCtrl.text = v;
                                  lotCtrl.text = '';
                                }),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Requis'
                                    : null,
                              );
                            },
                      ),
                      const SizedBox(height: 12),
                      Autocomplete<String>(
                        initialValue: TextEditingValue(text: lotCtrl.text),
                        optionsBuilder: (textEditingValue) {
                          final produit = produitCtrl.text.trim();
                          final lots = _lotsParProduit[produit] ?? const [];
                          final q = textEditingValue.text.toLowerCase();
                          if (q.isEmpty) return lots;
                          return lots
                              .where((l) => l.toLowerCase().contains(q))
                              .toList();
                        },
                        onSelected: (selection) {
                          setLocal(() {
                            lotCtrl.text = selection;
                          });
                        },
                        fieldViewBuilder:
                            (context, controller, focusNode, onSubmit) {
                              controller.text = lotCtrl.text;
                              controller.selection = TextSelection.collapsed(
                                offset: controller.text.length,
                              );
                              return TextFormField(
                                controller: controller,
                                focusNode: focusNode,
                                decoration: const InputDecoration(
                                  labelText: 'Lot',
                                ),
                                onChanged: (v) => setLocal(() {
                                  lotCtrl.text = v;
                                }),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Requis'
                                    : null,
                              );
                            },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: const ['Entrée', 'Sortie']
                            .map(
                              (t) => DropdownMenuItem(value: t, child: Text(t)),
                            )
                            .toList(),
                        onChanged: (v) => setLocal(() {
                          type = v ?? type;
                        }),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantiteCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Quantité',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) =>
                            int.tryParse(v ?? '') == null ? 'Nombre' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: agentCtrl,
                        decoration: const InputDecoration(labelText: 'Agent'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: motifCtrl,
                        decoration: const InputDecoration(labelText: 'Motif'),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text('Date'),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: date,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setLocal(() => date = picked);
                              }
                            },
                            child: Text(
                              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() != true) return;
                    Navigator.pop(context, true);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );
    if (confirm != true) return;

    final mouvement =
        (existing ??
                StupefiantMouvement(
                  id: 0,
                  produit: '',
                  lot: '',
                  type: 'Entrée',
                  quantite: 0,
                  date: date,
                  agent: '',
                  motif: '',
                ))
            .copyWith(
              produit: produitCtrl.text.trim(),
              lot: lotCtrl.text.trim(),
              type: type,
              quantite: int.tryParse(quantiteCtrl.text.trim()) ?? 0,
              agent: agentCtrl.text.trim(),
              motif: motifCtrl.text.trim(),
              date: date,
            );

    if (existing == null) {
      await LocalDatabaseService.instance.insertStupefiantMouvement(mouvement);
    } else {
      await LocalDatabaseService.instance.updateStupefiantMouvement(mouvement);
    }
    await _loadMouvements();
  }

  Future<void> _confirmerSuppression(StupefiantMouvement m) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer écriture'),
        content: Text('Supprimer ${m.ref} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await LocalDatabaseService.instance.deleteStupefiantMouvement(m.id);
    await _loadMouvements();
  }

  Widget _buildAuditAndDeclarations(ThemeColors palette, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildControleCard(palette, accent)),
        const SizedBox(width: 12),
        Expanded(child: _buildDeclarationCard(palette, accent)),
      ],
    );
  }

  Widget _buildControleCard(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.verified, color: accent),
                const SizedBox(width: 8),
                Text(
                  'Contrôles & écarts',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_controles.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'Aucun contrôle enregistré',
                  style: TextStyle(color: palette.subText),
                ),
              )
            else
              ..._controles.map((c) => _controleTile(c, palette)),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.playlist_add_check),
                label: const Text('Programmer un contrôle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controleTile(_Controle c, ThemeColors palette) {
    final color = c.statut.contains('Conforme') ? Colors.green : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: palette.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month, size: 18, color: palette.subText),
          const SizedBox(width: 6),
          Text(
            c.date,
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              c.statut,
              style: TextStyle(color: color, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Text('Ecart: ${c.ecart}', style: TextStyle(color: palette.subText)),
          const Spacer(),
          Text('Par ${c.agent}', style: TextStyle(color: palette.subText)),
        ],
      ),
    );
  }

  Widget _buildDeclarationCard(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.assignment, color: accent),
                const SizedBox(width: 8),
                Text(
                  'Déclarations & traçabilité',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Aucune déclaration programmée',
                style: TextStyle(color: palette.subText),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Déposer déclaration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(ThemeColors palette, {required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.divider),
        boxShadow: [
          BoxShadow(
            color: palette.isDark
                ? Colors.black.withOpacity(0.25)
                : Colors.grey.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Controle {
  final String date;
  final String ecart;
  final String statut;
  final String agent;

  const _Controle({
    required this.date,
    required this.ecart,
    required this.statut,
    required this.agent,
  });
}
