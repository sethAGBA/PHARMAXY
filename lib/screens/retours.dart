import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

import '../services/auth_service.dart';
import '../services/local_database_service.dart';

class RetoursScreen extends StatefulWidget {
  const RetoursScreen({super.key});

  @override
  State<RetoursScreen> createState() => _RetoursScreenState();
}

class _RetoursScreenState extends State<RetoursScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _controller;
  late Animation<double> _fade;
  String _selectedFilter = 'Tous';
  bool _loading = true;
  String? _error;

  List<_RetourRecord> _retourRecords = [];
  List<_NamedEntity> _clients = [];
  List<_NamedEntity> _fournisseurs = [];
  List<_NamedEntity> _produits = [];
  String _returnType = 'client';
  _NamedEntity? _selectedEntity;
  _NamedEntity? _selectedProduct;
  final TextEditingController _entityController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _lotController = TextEditingController();
  final TextEditingController _commandeDateController = TextEditingController();
  final TextEditingController _quantiteController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  String? _selectedMotif;
  final List<String> _retourMotifs = [
    'Périmé',
    'Défectueux',
    'Non conforme',
    'Erreur dispensation',
    'Effet indésirable',
    'Rappel de lot',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _tabController.dispose();
    _controller.dispose();
    _entityController.dispose();
    _productController.dispose();
    _lotController.dispose();
    _commandeDateController.dispose();
    _quantiteController.dispose();
    _montantController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await LocalDatabaseService.instance.init();
      final db = LocalDatabaseService.instance.db;

      // retours clients from ventes negative? (type retour) - fallback demo
      _clients = await _fetchEntities(db, 'patients', 'name');
      _fournisseurs = await _fetchEntities(db, 'fournisseurs', 'nom');
      _produits = await _fetchEntities(db, 'medicaments', 'nom');

      try {
        final rows = await db.query('retours', orderBy: 'date DESC');
        _retourRecords = rows.map((row) => _RetourRecord.fromMap(row)).toList();
      } catch (_) {
        _retourRecords = [];
      }

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

  Future<List<_NamedEntity>> _fetchEntities(
    Database db,
    String table,
    String labelColumn,
  ) async {
    try {
      final rows = await db.query(table, columns: ['id', labelColumn]);
      final items = rows.map((row) {
        final id = row['id'] as String? ?? '';
        final label = (row[labelColumn] as String?)?.trim() ?? '';
        return _NamedEntity(
          id: id,
          label: label.isNotEmpty ? label : 'Entrée sans nom',
        );
      }).toList();
      items.sort((a, b) => a.label.compareTo(b.label));
      return items;
    } catch (_) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _ThemeColors(isDark);
    const accent = Colors.teal;

    if (_loading) return const Center(child: CircularProgressIndicator());
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
            const SizedBox(height: 24),
            _buildKpis(palette),
            const SizedBox(height: 24),
            _buildFilters(palette, accent),
            const SizedBox(height: 24),
            Expanded(child: _buildTabView(palette, accent)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(_ThemeColors palette, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_return, color: accent, size: 40),
            const SizedBox(width: 16),
            Text(
              'Gestion des Retours',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: palette.text,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showNewReturnDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Retours clients/fournisseurs • Avoirs • Suivi processus',
          style: TextStyle(fontSize: 16, color: palette.subText),
        ),
      ],
    );
  }

  Widget _buildKpis(_ThemeColors palette) {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            'En attente',
            '8',
            Icons.pending_actions,
            Colors.orange,
            palette,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard(
            'Traités',
            '24',
            Icons.check_circle,
            Colors.green,
            palette,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard(
            'Avoirs ce mois',
            '1 245 000 FCFA',
            Icons.euro,
            Colors.blue,
            palette,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _kpiCard('En litige', '2', Icons.warning, Colors.red, palette),
        ),
      ],
    );
  }

  Widget _kpiCard(
    String label,
    String value,
    IconData icon,
    Color color,
    _ThemeColors palette,
  ) {
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

  Widget _buildFilters(_ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: accent, size: 28),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Rechercher un retour...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: palette.divider),
                      ),
                      filled: true,
                      fillColor: palette.card,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedFilter,
                  items: ['Tous', 'En attente', 'Traité', 'Litige', 'Remboursé']
                      .map(
                        (filter) => DropdownMenuItem(
                          value: filter,
                          child: Text(filter),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedFilter = value!),
                  style: TextStyle(
                    color: palette.text,
                    fontWeight: FontWeight.w600,
                  ),
                  dropdownColor: palette.card,
                  underline: Container(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TabBar(
              controller: _tabController,
              labelColor: accent,
              unselectedLabelColor: palette.subText,
              indicatorColor: accent,
              indicatorWeight: 3,
              tabs: const [
                Tab(text: 'Retours clients'),
                Tab(text: 'Retours fournisseurs'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabView(_ThemeColors palette, Color accent) {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildRetoursClientsList(palette, accent),
        _buildRetoursFournisseursList(palette, accent),
      ],
    );
  }

  Widget _buildRetoursClientsList(_ThemeColors palette, Color accent) {
    final retours = _retourRecords
        .where((retour) => retour.type == 'client')
        .toList();

    return _card(
      palette,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(palette.card),
            columns: [
              DataColumn(
                label: Text(
                  'N° Retour',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Client',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Produit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Qté',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Motif',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Montant',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Statut',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
            ],
            rows: retours
                .map((r) => _buildRetourClientRow(r, palette, accent))
                .toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRetoursFournisseursList(_ThemeColors palette, Color accent) {
    final retours = _retourRecords
        .where((retour) => retour.type == 'fournisseur')
        .toList();

    return _card(
      palette,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(palette.card),
            columns: [
              DataColumn(
                label: Text(
                  'N° Retour',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Date',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Fournisseur',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Produit',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Lot',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Qté',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Motif',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Montant',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Statut',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'Actions',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
            ],
            rows: retours
                .map((r) => _buildRetourFournisseurRow(r, palette, accent))
                .toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRetourClientRow(
    _RetourRecord r,
    _ThemeColors palette,
    Color accent,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            r.numero,
            style: TextStyle(fontWeight: FontWeight.w600, color: accent),
          ),
        ),
        DataCell(Text(r.formattedDate, style: TextStyle(color: palette.text))),
        DataCell(Text(r.entityName, style: TextStyle(color: palette.text))),
        DataCell(Text(r.productName, style: TextStyle(color: palette.text))),
        DataCell(Text('${r.quantite}', style: TextStyle(color: palette.text))),
        DataCell(Text(r.motif, style: TextStyle(color: palette.text))),
        DataCell(
          Text(
            _formatCurrency(r.montant),
            style: TextStyle(fontWeight: FontWeight.bold, color: palette.text),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: r.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              r.statut,
              style: TextStyle(
                color: r.statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                color: Colors.blue,
                onPressed: () => _showRetourDetails(r, palette, accent),
                tooltip: 'Voir détails',
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.orange,
                onPressed: () {},
                tooltip: 'Modifier',
              ),
              IconButton(
                icon: const Icon(Icons.print, size: 20),
                color: Colors.grey,
                onPressed: () {},
                tooltip: 'Imprimer',
              ),
            ],
          ),
        ),
      ],
    );
  }

  DataRow _buildRetourFournisseurRow(
    _RetourRecord r,
    _ThemeColors palette,
    Color accent,
  ) {
    return DataRow(
      cells: [
        DataCell(
          Text(
            r.numero,
            style: TextStyle(fontWeight: FontWeight.w600, color: accent),
          ),
        ),
        DataCell(Text(r.formattedDate, style: TextStyle(color: palette.text))),
        DataCell(Text(r.entityName, style: TextStyle(color: palette.text))),
        DataCell(Text(r.productName, style: TextStyle(color: palette.text))),
        DataCell(Text(r.lot, style: TextStyle(color: palette.text))),
        DataCell(Text('${r.quantite}', style: TextStyle(color: palette.text))),
        DataCell(Text(r.motif, style: TextStyle(color: palette.text))),
        DataCell(
          Text(
            _formatCurrency(r.montant),
            style: TextStyle(fontWeight: FontWeight.bold, color: palette.text),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: r.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              r.statut,
              style: TextStyle(
                color: r.statusColor,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                color: Colors.blue,
                onPressed: () => _showRetourDetails(r, palette, accent),
                tooltip: 'Voir détails',
              ),
              IconButton(
                icon: const Icon(Icons.description, size: 20),
                color: Colors.green,
                onPressed: () {},
                tooltip: 'Générer avoir',
              ),
              IconButton(
                icon: const Icon(Icons.print, size: 20),
                color: Colors.grey,
                onPressed: () {},
                tooltip: 'Imprimer',
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showNewReturnDialog() {
    final palette = _ThemeColors(
      Theme.of(context).brightness == Brightness.dark,
    );
    _resetReturnForm();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, dialogSetState) => Dialog(
            backgroundColor: palette.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Nouveau retour',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: palette.text,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _resetReturnForm();
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      value: _returnType,
                      decoration: InputDecoration(
                        labelText: 'Type de retour',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: palette.card,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'client',
                          child: Text('Retour client'),
                        ),
                        DropdownMenuItem(
                          value: 'fournisseur',
                          child: Text('Retour fournisseur'),
                        ),
                      ],
                      onChanged: (value) {
                        dialogSetState(() {
                          _returnType = value ?? 'client';
                        });
                        setState(() {
                          _selectedEntity = null;
                          _entityController.clear();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildEntityField(palette, dialogSetState),
                    const SizedBox(height: 16),
                    _buildProductField(palette, dialogSetState),
                    if (_returnType == 'fournisseur') ...[
                      const SizedBox(height: 16),
                      _buildLotField(palette),
                      const SizedBox(height: 16),
                      _buildCommandeField(palette),
                    ],
                    const SizedBox(height: 16),
                    _buildQuantityAmountRow(palette),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedMotif,
                      decoration: InputDecoration(
                        labelText: 'Motif du retour',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: palette.card,
                      ),
                      items: _retourMotifs
                          .map(
                            (motif) => DropdownMenuItem(
                              value: motif,
                              child: Text(motif),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        dialogSetState(() => _selectedMotif = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _commentController,
                      decoration: InputDecoration(
                        labelText: 'Commentaire / notes',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: palette.card,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            _resetReturnForm();
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Annuler'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () async {
                            final saved = await _saveReturn(context);
                            if (saved) {
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Enregistrer'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEntityField(
    _ThemeColors palette,
    void Function(void Function()) dialogSetState,
  ) {
    final isClient = _returnType == 'client';
    final label = isClient ? 'Client concerné' : 'Fournisseur concerné';
    final suggestions = isClient ? _clients : _fournisseurs;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.w600, color: palette.subText),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _entityController,
                decoration: InputDecoration(
                  hintText:
                      'Sélectionnez un ${isClient ? 'client' : 'fournisseur'}',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: Icon(
                    isClient ? Icons.person : Icons.store,
                    size: 20,
                  ),
                  suffixIcon: suggestions.isEmpty
                      ? null
                      : PopupMenuButton<_NamedEntity>(
                          icon: const Icon(Icons.arrow_drop_down),
                          tooltip:
                              'Choisir un ${isClient ? 'client' : 'fournisseur'} enregistré',
                          itemBuilder: (context) => suggestions
                              .map(
                                (entity) => PopupMenuItem(
                                  value: entity,
                                  child: Text(entity.label),
                                ),
                              )
                              .toList(),
                          onSelected: (entity) {
                            dialogSetState(() {
                              _selectedEntity = entity;
                              _entityController.text = entity.label;
                            });
                          },
                        ),
                  filled: true,
                  fillColor: palette.card,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProductField(
    _ThemeColors palette,
    void Function(void Function()) dialogSetState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Produit concerné',
          style: TextStyle(fontWeight: FontWeight.w600, color: palette.subText),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _productController,
                decoration: InputDecoration(
                  hintText: 'Choisir un produit',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(
                    Icons.medical_services_outlined,
                    size: 20,
                  ),
                  suffixIcon: _produits.isEmpty
                      ? null
                      : PopupMenuButton<_NamedEntity>(
                          icon: const Icon(Icons.arrow_drop_down),
                          tooltip: 'Choisir un produit enregistré',
                          itemBuilder: (context) => _produits
                              .map(
                                (entity) => PopupMenuItem(
                                  value: entity,
                                  child: Text(entity.label),
                                ),
                              )
                              .toList(),
                          onSelected: (entity) {
                            dialogSetState(() {
                              _selectedProduct = entity;
                              _productController.text = entity.label;
                            });
                          },
                        ),
                  filled: true,
                  fillColor: palette.card,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLotField(_ThemeColors palette) {
    return TextField(
      controller: _lotController,
      decoration: InputDecoration(
        labelText: 'Lot / série',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.numbers),
        filled: true,
        fillColor: palette.card,
      ),
    );
  }

  Widget _buildCommandeField(_ThemeColors palette) {
    return TextField(
      controller: _commandeDateController,
      readOnly: true,
      decoration: InputDecoration(
        labelText: 'Date de la commande',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: _pickCommandeDate,
        ),
        filled: true,
        fillColor: palette.card,
      ),
    );
  }

  Widget _buildQuantityAmountRow(_ThemeColors palette) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _quantiteController,
            decoration: InputDecoration(
              labelText: 'Quantité',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: palette.card,
            ),
            keyboardType: TextInputType.number,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: _montantController,
            decoration: InputDecoration(
              labelText: 'Montant',
              suffixText: 'FCFA',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: palette.card,
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }

  Future<void> _pickCommandeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _commandeDateController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<bool> _saveReturn(BuildContext context) async {
    final entityName = _entityController.text.trim();
    final productName = _productController.text.trim();
    final quantiteRaw = _quantiteController.text.trim();
    final montantRaw = _montantController.text.trim();
    final quantite = int.tryParse(quantiteRaw) ?? 0;
    final montant =
        double.tryParse(montantRaw.replaceAll(' ', '').replaceAll(',', '.')) ??
        0.0;
    if (entityName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez indiquer le client ou fournisseur.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    if (productName.isEmpty || quantite <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit et quantité sont obligatoires.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    final db = LocalDatabaseService.instance.db;
    final id = 'RET-${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('retours', {
      'id': id,
      'numero': id,
      'type': _returnType,
      'date': DateTime.now().toIso8601String(),
      'entity_id': _selectedEntity?.id ?? '',
      'entity_name': entityName,
      'product_id': _selectedProduct?.id ?? '',
      'product_name': productName,
      'lot': _lotController.text.trim(),
      'commande_date': _commandeDateController.text.trim(),
      'quantite': quantite,
      'montant': montant,
      'motif': _selectedMotif ?? '',
      'commentaire': _commentController.text.trim(),
      'declared_by': AuthService.instance.currentUser?.name ?? 'Utilisateur',
      'statut': 'En attente',
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    await _loadData();
    _resetReturnForm();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Retour enregistré avec succès'),
        backgroundColor: Colors.green,
      ),
    );
    return true;
  }

  void _resetReturnForm() {
    _entityController.clear();
    _productController.clear();
    _lotController.clear();
    _commandeDateController.clear();
    _quantiteController.clear();
    _montantController.clear();
    _commentController.clear();
    _selectedEntity = null;
    _selectedProduct = null;
    _selectedMotif = null;
    _returnType = 'client';
  }

  void _showRetourDetails(
    _RetourRecord record,
    _ThemeColors palette,
    Color accent,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 700,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Détails du retour ${record.numero}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Divider(height: 40, color: palette.divider),
              _buildDetailRow(
                'Type',
                record.type == 'client'
                    ? 'Retour client'
                    : 'Retour fournisseur',
                palette,
              ),
              _buildDetailRow('Date', record.formattedDate, palette),
              _buildDetailRow(
                record.type == 'client' ? 'Client' : 'Fournisseur',
                record.entityName,
                palette,
              ),
              _buildDetailRow('Produit', record.productName, palette),
              if (record.lot.isNotEmpty)
                _buildDetailRow('Lot', record.lot, palette),
              if (record.commandeDate.isNotEmpty)
                _buildDetailRow('Commande', record.commandeDate, palette),
              _buildDetailRow('Quantité', '${record.quantite}', palette),
              _buildDetailRow(
                'Montant',
                _formatCurrency(record.montant),
                palette,
              ),
              _buildDetailRow('Motif', record.motif, palette),
              if (record.commentaire.isNotEmpty)
                _buildDetailRow('Commentaire', record.commentaire, palette),
              _buildDetailRow('Déclaré par', record.declaredBy, palette),
              Divider(height: 40, color: palette.divider),
              Text(
                'Historique du traitement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 16),
              _buildHistoryItem(
                record.formattedDate,
                'Retour créé',
                record.declaredBy,
                palette,
                accent,
              ),
              _buildHistoryItem(
                DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                'Vérification en attente',
                'Pharmacien',
                palette,
                accent,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print),
                    label: const Text('Imprimer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(
                      record.type == 'fournisseur'
                          ? Icons.description
                          : Icons.check,
                    ),
                    label: Text(
                      record.type == 'fournisseur'
                          ? 'Générer avoir'
                          : 'Valider remboursement',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, _ThemeColors palette) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: palette.subText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 15, color: palette.text),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    String date,
    String action,
    String user,
    _ThemeColors palette,
    Color accent,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: palette.text,
                  ),
                ),
                Text(
                  '$date - $user',
                  style: TextStyle(fontSize: 12, color: palette.subText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(value)} FCFA';
  }

  Widget _card(_ThemeColors palette, {required Widget child}) {
    return Container(
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
class _RetourRecord {
  final String numero;
  final String type;
  final DateTime date;
  final String entityName;
  final String productName;
  final String lot;
  final String commandeDate;
  final int quantite;
  final double montant;
  final String motif;
  final String commentaire;
  final String declaredBy;
  final String statut;

  const _RetourRecord({
    required this.numero,
    required this.type,
    required this.date,
    required this.entityName,
    required this.productName,
    required this.lot,
    required this.commandeDate,
    required this.quantite,
    required this.montant,
    required this.motif,
    required this.commentaire,
    required this.declaredBy,
    required this.statut,
  });

  factory _RetourRecord.fromMap(Map<String, Object?> map) {
    final rawDate = map['date'] as String? ?? '';
    final parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    return _RetourRecord(
      numero: (map['numero'] as String?) ?? (map['id'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'client',
      date: parsedDate,
      entityName: (map['entity_name'] as String?) ?? '',
      productName: (map['product_name'] as String?) ?? '',
      lot: (map['lot'] as String?) ?? '',
      commandeDate: (map['commande_date'] as String?) ?? '',
      quantite: (map['quantite'] as num?)?.toInt() ?? 0,
      montant: (map['montant'] as num?)?.toDouble() ?? 0.0,
      motif: (map['motif'] as String?) ?? '',
      commentaire: (map['commentaire'] as String?) ?? '',
      declaredBy: (map['declared_by'] as String?) ?? 'Utilisateur',
      statut: (map['statut'] as String?) ?? 'En attente',
    );
  }

  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm').format(date);

  Color get statusColor {
    final label = statut.toLowerCase();
    if (label.contains('trait')) return Colors.green;
    if (label.contains('litige') || label.contains('annul')) return Colors.red;
    return Colors.orange;
  }
}

class _NamedEntity {
  final String id;
  final String label;
  const _NamedEntity({required this.id, required this.label});
}

class _ThemeColors {
  final bool isDark;
  _ThemeColors(this.isDark);

  Color get text => isDark ? Colors.white : Colors.black87;
  Color get subText => isDark ? Colors.grey[400]! : Colors.grey[600]!;
  Color get card => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get divider => isDark ? Colors.grey[800]! : Colors.grey[300]!;
}
