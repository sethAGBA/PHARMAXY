// screens/commandes_fournisseurs.dart
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_theme.dart';
import '../services/local_database_service.dart';

class CommandesFournisseursScreen extends StatefulWidget {
  const CommandesFournisseursScreen({super.key});

  @override
  State<CommandesFournisseursScreen> createState() =>
      _CommandesFournisseursScreenState();
}

class _CommandesFournisseursScreenState
    extends State<CommandesFournisseursScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late TabController _tabController;

  String? _selectedFournisseur;
  // Start with an empty order list; do not pre-populate with demo items.
  final List<CommandeItem> _itemsToOrder = [];

  // Dynamic data from DB
  List<String> _fournisseurs = [];
  List<CommandeEnCours> _commandesEnCours = [];
  List<CommandeEnCours> _commandesAnnulees = [];
  List<Map<String, dynamic>> _produits = [];
  bool _loading = true;
  String? _error;
  bool _showInfosCommande = true;

  // Form controllers for manual order
  String? _selectedProduit;
  late TextEditingController _qtyController;
  late TextEditingController _prixController;
  late TextEditingController _notesController;
  late TextEditingController _orderNotesController;
  late TextEditingController _orderAuthorController;

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
    _tabController = TabController(length: 2, vsync: this);
    _qtyController = TextEditingController();
    _prixController = TextEditingController();
    _notesController = TextEditingController();
    _orderNotesController = TextEditingController();
    _orderAuthorController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final db = LocalDatabaseService.instance.db;

      // fournisseurs: extract unique fournisseur from medicaments table
      final rowsM = await db.query(
        'medicaments',
        columns: ['fournisseur'],
        distinct: true,
        where: 'fournisseur IS NOT NULL AND fournisseur != ""',
        orderBy: 'fournisseur ASC',
      );
      _fournisseurs = rowsM
          .map((r) => (r['fournisseur'] as String?) ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      // Also try to load from fournisseurs table (for cases where it's populated)
      final rowsF = await db.query('fournisseurs', orderBy: 'nom ASC');
      final fournisseursFromTable = rowsF
          .map((r) => (r['nom'] as String?) ?? '')
          .where((n) => n.isNotEmpty)
          .toList();

      // Merge both sources and remove duplicates
      _fournisseurs.addAll(fournisseursFromTable);
      _fournisseurs = _fournisseurs.toSet().toList();
      _fournisseurs.sort();

      if (_fournisseurs.isNotEmpty && _selectedFournisseur == null)
        _selectedFournisseur = _fournisseurs.first;

      // produits: load all medicaments
      _produits = await db.query('medicaments', orderBy: 'nom ASC');
      if (_produits.isNotEmpty && _selectedProduit == null) {
        _selectedProduit = _produits.first['id'] as String?;
      }

      // Ensure optional columns exist in commandes table before selecting
      final pragmaCols = await db.rawQuery("PRAGMA table_info('commandes')");
      final existingCols = pragmaCols
          .map((c) => (c['name'] as String?) ?? '')
          .where((s) => s.isNotEmpty)
          .toSet();
      if (!existingCols.contains('raison_annulation')) {
        await db.execute(
          'ALTER TABLE commandes ADD COLUMN raison_annulation TEXT;',
        );
        existingCols.add('raison_annulation');
      }
      if (!existingCols.contains('auteur')) {
        await db.execute('ALTER TABLE commandes ADD COLUMN auteur TEXT;');
        existingCols.add('auteur');
      }
      if (!existingCols.contains('notes')) {
        await db.execute('ALTER TABLE commandes ADD COLUMN notes TEXT;');
        existingCols.add('notes');
      }

      // commandes (now safe to select optional columns)
      final rows = await db.rawQuery(
        'SELECT id, date, fournisseur_id, statut, total, raison_annulation, auteur, notes FROM commandes ORDER BY date DESC',
      );
      _commandesEnCours = rows
          .map((r) {
            final rawDate = r['date'] as String? ?? '';
            String prettyDate;
            try {
              final dt = DateTime.parse(rawDate);
              prettyDate = DateFormat('dd/MM/yyyy').format(dt);
            } catch (_) {
              prettyDate = rawDate;
            }
            return CommandeEnCours(
              id: r['id'] as String? ?? '',
              date: prettyDate,
              fournisseur: (r['fournisseur_id'] as String?) ?? '',
              statut: (r['statut'] as String?) ?? 'En cours',
              montant: ((r['total'] as num?)?.toInt()) ?? 0,
              raisonAnnulation: (r['raison_annulation'] as String?) ?? '',
              auteur: (r['auteur'] as String?) ?? '',
              notes: (r['notes'] as String?) ?? '',
            );
          })
          .where((c) => c.statut != 'Annulée')
          .toList();

      // Commandes annulées
      _commandesAnnulees = rows
          .where((r) => (r['statut'] as String?) == 'Annulée')
          .map((r) {
            final rawDate = r['date'] as String? ?? '';
            String prettyDate;
            try {
              final dt = DateTime.parse(rawDate);
              prettyDate = DateFormat('dd/MM/yyyy').format(dt);
            } catch (_) {
              prettyDate = rawDate;
            }
            return CommandeEnCours(
              id: r['id'] as String? ?? '',
              date: prettyDate,
              fournisseur: (r['fournisseur_id'] as String?) ?? '',
              statut: (r['statut'] as String?) ?? 'Annulée',
              montant: ((r['total'] as num?)?.toInt()) ?? 0,
              raisonAnnulation: (r['raison_annulation'] as String?) ?? '',
              auteur: (r['auteur'] as String?) ?? '',
              notes: (r['notes'] as String?) ?? '',
            );
          })
          .toList();

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

  @override
  void dispose() {
    _controller.dispose();
    _tabController.dispose();
    _qtyController.dispose();
    _prixController.dispose();
    _notesController.dispose();
    _orderNotesController.dispose();
    _orderAuthorController.dispose();
    super.dispose();
  }

  int get _totalCommande => _itemsToOrder.fold(
    0,
    (sum, item) => sum + (item.qtyCommandee * item.prixUnitaire),
  );

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    final accent = Colors.teal;

    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(palette),
                const SizedBox(height: 24),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFournisseurSelector(palette),
                        const SizedBox(height: 24),
                        _buildFormulaireAjoutProduit(palette),
                        const SizedBox(height: 16),
                        _buildInfosCommande(palette),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: max(420, constraints.maxHeight - 24),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // === PANIER DE COMMANDE ===
                              Expanded(
                                flex: 3,
                                child: _buildPanierCommande(palette, accent),
                              ),
                              const SizedBox(width: 24),
                              // === HISTORIQUE COMMANDES ===
                              Expanded(
                                flex: 2,
                                child: _buildHistoriqueCommandesWithTabs(
                                  palette,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors palette) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commandes fournisseurs',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                'Sélection • Quantités suggérées • Validation • Suivi',
                style: TextStyle(fontSize: 16, color: palette.subText),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: _showInfosCommande
              ? 'Masquer infos commande'
              : 'Afficher infos commande',
          onPressed: () =>
              setState(() => _showInfosCommande = !_showInfosCommande),
          icon: Icon(
            _showInfosCommande ? Icons.visibility_off : Icons.visibility,
            color: palette.subText,
          ),
        ),
      ],
    );
  }

  Widget _buildFournisseurSelector(ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.local_shipping, color: Colors.teal, size: 28),
            const SizedBox(width: 16),
            Text(
              'Fournisseur sélectionné :',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            const SizedBox(width: 20),
            if (_loading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(),
              )
            else if (_fournisseurs.isEmpty)
              Text(
                'Aucun fournisseur',
                style: TextStyle(color: palette.subText),
              )
            else
              DropdownButton<String>(
                value: _selectedFournisseur,
                items: _fournisseurs
                    .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedFournisseur = v!),
                style: TextStyle(color: palette.text, fontSize: 18),
                dropdownColor: palette.isDark ? Colors.grey[900] : Colors.white,
                underline: Container(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaireAjoutProduit(ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ajouter un produit manuellement',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Produit
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Produit',
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.subText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_produits.isEmpty)
                        Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: palette.isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Aucun produit',
                              style: TextStyle(color: palette.subText),
                            ),
                          ),
                        )
                      else
                        DropdownButtonFormField<String>(
                          value: _selectedProduit,
                          items: _produits.map((p) {
                            final nom = p['nom'] as String? ?? '';
                            final id = p['id'] as String? ?? '';
                            return DropdownMenuItem(
                              value: id,
                              child: Text(nom, overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (v) =>
                              setState(() => _selectedProduit = v),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: palette.isDark
                                ? Colors.grey[800]
                                : Colors.grey[200],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Quantité
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantité',
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.subText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.isDark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Prix unitaire
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prix unitaire',
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.subText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _prixController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.isDark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          hintText: '0',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Notes
                Expanded(
                  flex: 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notes',
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.subText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _notesController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: palette.isDark
                              ? Colors.grey[800]
                              : Colors.grey[200],
                          hintText: 'Infos',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Bouton Ajouter
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: ElevatedButton.icon(
                    onPressed: _ajouterProduit,
                    icon: const Icon(Icons.add, size: 22),
                    label: const Text('Ajouter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _ajouterProduit() {
    if (_selectedProduit == null || _selectedProduit!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un produit')),
      );
      return;
    }

    final qty = int.tryParse(_qtyController.text) ?? 0;
    final prix = int.tryParse(_prixController.text) ?? 0;

    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer une quantité valide')),
      );
      return;
    }

    // Find product by ID
    final produit = _produits.firstWhere(
      (p) => p['id'] == _selectedProduit,
      orElse: () => <String, dynamic>{},
    );
    if (produit.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Produit non trouvé')));
      return;
    }

    final item = CommandeItem(
      name: produit['nom'] as String? ?? '',
      code: produit['cip'] as String? ?? '',
      lab: produit['laboratoire'] as String? ?? '',
      productId: produit['id'] as String? ?? '',
      note: _notesController.text.trim(),
      stockActuel: 0,
      seuil: 0,
      suggere: 0,
      qtyCommandee: qty,
      prixUnitaire: prix,
    );

    setState(() {
      _itemsToOrder.add(item);
      _qtyController.clear();
      _prixController.clear();
      _notesController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${produit['nom']} ajouté au panier'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildInfosCommande(ThemeColors palette) {
    return Visibility(
      visible: _showInfosCommande,
      replacement: const SizedBox.shrink(),
      child: _card(
        palette,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Informations commande',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _orderAuthorController,
                      decoration: InputDecoration(
                        labelText: 'Auteur / préparateur',
                        hintText: 'Nom du préparateur',
                        filled: true,
                        fillColor: palette.isDark
                            ? Colors.grey[850]
                            : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _orderNotesController,
                      decoration: InputDecoration(
                        labelText: 'Notes commande',
                        hintText: 'Instructions (livraison, franco...)',
                        filled: true,
                        fillColor: palette.isDark
                            ? Colors.grey[850]
                            : Colors.grey[200],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
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

  Widget _buildPanierCommande(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Produits à commander (${_itemsToOrder.length})',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: accent.withOpacity(0.3)),
                  ),
                  child: Text(
                    'Total : $_totalCommande FCFA',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 420),
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                shrinkWrap: true,
                itemCount: _itemsToOrder.length,
                itemBuilder: (context, index) =>
                    _itemCommande(_itemsToOrder[index], palette, accent, index),
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                onPressed: (_loading || _itemsToOrder.isEmpty)
                    ? null
                    : () => _sendOrder(),
                icon: const Icon(Icons.send, size: 28),
                label: const Text(
                  'VALIDER & ENVOYER LA COMMANDE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCommande(
    CommandeItem item,
    ThemeColors palette,
    Color accent,
    int index,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication, color: accent, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: palette.text,
                      ),
                    ),
                    Text(
                      item.code,
                      style: TextStyle(fontSize: 13, color: palette.subText),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip('Stock actuel', '${item.stockActuel} un.', palette),
              const SizedBox(width: 8),
              _infoChip('Seuil', '${item.seuil} un.', palette),
              const SizedBox(width: 8),
              _infoChip('Suggéré', '${item.suggere} un.', palette),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Quantité à commander :',
                style: TextStyle(color: palette.subText),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 120,
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: TextEditingController(
                    text: item.qtyCommandee.toString(),
                  ),
                  onChanged: (v) => setState(
                    () => _itemsToOrder[index].qtyCommandee =
                        int.tryParse(v) ?? item.qtyCommandee,
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: palette.isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 20),
              Text(
                '${(item.qtyCommandee * item.prixUnitaire).toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistoriqueCommandesWithTabs(ThemeColors palette) {
    return _card(
      palette,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'En cours'),
              Tab(text: 'Annulées'),
            ],
            labelColor: Colors.teal,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.teal,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // === Tab En cours ===
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                    ? Center(child: Text('Erreur: $_error'))
                    : _commandesEnCours.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune commande en cours',
                          style: TextStyle(color: palette.subText),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _commandesEnCours.length,
                        itemBuilder: (context, index) =>
                            _commandeRowAvecActions(
                              _commandesEnCours[index],
                              palette,
                            ),
                      ),
                // === Tab Annulées ===
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _commandesAnnulees.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune commande annulée',
                          style: TextStyle(color: palette.subText),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _commandesAnnulees.length,
                        itemBuilder: (context, index) => _commandeRowAnnulee(
                          _commandesAnnulees[index],
                          palette,
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _sendOrder() async {
    if (_selectedFournisseur == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un fournisseur')),
      );
      return;
    }
    if (_itemsToOrder.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ajoutez au moins un article')),
      );
      return;
    }
    try {
      final db = LocalDatabaseService.instance.db;
      final id = 'CMD-${DateTime.now().millisecondsSinceEpoch}';
      final total = _totalCommande;
      await db.insert('commandes', {
        'id': id,
        'fournisseur_id': _selectedFournisseur,
        'date': DateTime.now().toIso8601String(),
        'statut': 'En cours',
        'total': total,
        'auteur': _orderAuthorController.text.trim(),
        'notes': _orderNotesController.text.trim(),
      });
      // persist lines
      for (final item in _itemsToOrder) {
        await db.insert('commande_lignes', {
          'commande_id': id,
          'medicament_id': item.productId,
          'nom': item.name,
          'cip': item.code,
          'quantite': item.qtyCommandee,
          'prix_unitaire': item.prixUnitaire,
          'note': item.note,
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande envoyée avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _itemsToOrder.clear();
        _orderAuthorController.clear();
        _orderNotesController.clear();
      });
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur envoi commande: $e')));
    }
  }

  Widget _commandeRowAvecActions(CommandeEnCours cmd, ThemeColors palette) {
    final color = cmd.statut == 'Livrée'
        ? Colors.green
        : cmd.statut == 'En cours'
        ? Colors.orange
        : Colors.grey;
    return InkWell(
      onTap: () => _showCommandeDetails(cmd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.local_shipping, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cmd.id,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                  Text(
                    '${cmd.fournisseur} • ${cmd.date}',
                    style: TextStyle(color: palette.subText, fontSize: 13),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cmd.statut,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${cmd.montant.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _promptAnnulerCommande(cmd),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => _sendToReception(cmd),
                      child: const Text(
                        'Recevoir',
                        style: TextStyle(color: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _commandeRowAnnulee(CommandeEnCours cmd, ThemeColors palette) {
    final color = Colors.grey;
    return InkWell(
      onTap: () => _showCommandeDetails(cmd),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: palette.divider),
        ),
        child: Row(
          children: [
            Icon(Icons.cancel, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cmd.id,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                  Text(
                    '${cmd.fournisseur} • ${cmd.date}',
                    style: TextStyle(color: palette.subText, fontSize: 13),
                  ),
                  if (cmd.raisonAnnulation.isNotEmpty)
                    Text(
                      'Raison: ${cmd.raisonAnnulation}',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    cmd.statut,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${cmd.montant.toStringAsFixed(0)} FCFA',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.teal,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _promptAnnulerCommande(CommandeEnCours cmd) async {
    final controller = TextEditingController();
    final reason = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Annuler la commande'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Raison de l\'annulation',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );

    if (reason != null && reason.isNotEmpty) {
      await _annulerCommande(cmd.id, reason);
    }
  }

  Future<void> _annulerCommande(String id, String reason) async {
    try {
      final db = LocalDatabaseService.instance.db;
      // Ensure column exists
      final cols = await db.rawQuery("PRAGMA table_info('commandes')");
      final hasReason = cols.any(
        (c) => (c['name'] as String?) == 'raison_annulation',
      );
      if (!hasReason) {
        await db.execute(
          'ALTER TABLE commandes ADD COLUMN raison_annulation TEXT;',
        );
      }
      await db.update(
        'commandes',
        {'statut': 'Annulée', 'raison_annulation': reason},
        where: 'id = ?',
        whereArgs: [id],
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande annulée'),
          backgroundColor: Colors.orange,
        ),
      );
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erreur annulation: $e')));
    }
  }

  Future<void> _sendToReception(CommandeEnCours cmd) async {
    try {
      final db = LocalDatabaseService.instance.db;

      // create a reception entry for this commande
      final recId = 'REC-${DateTime.now().millisecondsSinceEpoch}';
      await db.insert('receptions', {
        'id': recId,
        'commande_id': cmd.id,
        'date': DateTime.now().toIso8601String(),
        'statut': 'En attente',
      });

      // update commande status to indicate it's sent to reception
      await db.update(
        'commandes',
        {'statut': 'En réception'},
        where: 'id = ?',
        whereArgs: [cmd.id],
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande envoyée à la réception'),
          backgroundColor: Colors.teal,
        ),
      );
      await _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur envoi à la réception: $e')),
      );
    }
  }

  void _showCommandeDetails(CommandeEnCours cmd) async {
    final db = LocalDatabaseService.instance.db;

    // Try to fetch supplier details (match by id or name)
    Map<String, dynamic>? fournisseurInfo;
    try {
      final rowsById = await db.query(
        'fournisseurs',
        where: 'id = ?',
        whereArgs: [cmd.fournisseur],
      );
      if (rowsById.isNotEmpty)
        fournisseurInfo = rowsById.first;
      else {
        final rowsByName = await db.query(
          'fournisseurs',
          where: 'nom = ?',
          whereArgs: [cmd.fournisseur],
        );
        if (rowsByName.isNotEmpty) fournisseurInfo = rowsByName.first;
      }
    } catch (_) {
      fournisseurInfo = null;
    }

    // Fetch receptions related to this commande
    List<Map<String, dynamic>> receptions = [];
    try {
      receptions = await db.query(
        'receptions',
        where: 'commande_id = ?',
        whereArgs: [cmd.id],
        orderBy: 'date DESC',
      );
    } catch (_) {
      receptions = [];
    }

    // Fetch lignes de commande
    List<Map<String, dynamic>> lignes = [];
    try {
      lignes = await db.query(
        'commande_lignes',
        where: 'commande_id = ?',
        whereArgs: [cmd.id],
      );
    } catch (_) {
      lignes = [];
    }

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Détails commande ${cmd.id}'),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fournisseur: ${cmd.fournisseur}'),
                  if (fournisseurInfo != null) ...[
                    const SizedBox(height: 6),
                    Text('Contact: ${fournisseurInfo['contact'] ?? '-'}'),
                    const SizedBox(height: 4),
                    Text('Email: ${fournisseurInfo['email'] ?? '-'}'),
                  ],
                  const SizedBox(height: 8),
                  Text('Date: ${cmd.date}'),
                  const SizedBox(height: 6),
                  Text('Statut: ${cmd.statut}'),
                  const SizedBox(height: 6),
                  Text('Montant: ${cmd.montant.toStringAsFixed(0)} FCFA'),
                  if (cmd.raisonAnnulation.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Raison annulation: ${cmd.raisonAnnulation}',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Réceptions (${receptions.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (receptions.isEmpty)
                    Text(
                      'Aucune réception enregistrée pour cette commande',
                      style: TextStyle(
                        color: ThemeColors.from(context).subText,
                      ),
                    )
                  else
                    Column(
                      children: receptions.map((r) {
                        final rawDate = r['date'] as String? ?? '';
                        String prettyDate;
                        try {
                          final dt = DateTime.parse(rawDate);
                          prettyDate = DateFormat('dd/MM/yyyy').format(dt);
                        } catch (_) {
                          prettyDate = rawDate;
                        }
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text('Réception: $prettyDate'),
                          subtitle: Text('Statut: ${r['statut'] ?? '-'}'),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 12),
                  Text(
                    'Articles (${lignes.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  if (lignes.isEmpty)
                    Text(
                      'Aucune ligne enregistrée',
                      style: TextStyle(
                        color: ThemeColors.from(context).subText,
                      ),
                    )
                  else
                    Column(
                      children: lignes.map((l) {
                        final nom = l['nom'] as String? ?? '';
                        final cip = l['cip'] as String? ?? '';
                        final qte = l['quantite'] as int? ?? 0;
                        final prix = l['prix_unitaire'] as int? ?? 0;
                        final note = l['note'] as String? ?? '';
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(nom),
                          subtitle: Text(
                            'CIP: $cip • Qté: $qte • PU: $prix FCFA${note.isNotEmpty ? ' • $note' : ''}',
                          ),
                        );
                      }).toList(),
                    ),
                  if (cmd.notes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text('Notes commande: ${cmd.notes}'),
                  ],
                  if (cmd.auteur.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text('Auteur: ${cmd.auteur}'),
                  ],
                ],
              ),
            ),
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

  Widget _infoChip(String label, String value, ThemeColors palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: palette.isDark
            ? Colors.white.withOpacity(0.08)
            : Colors.grey[200],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          fontSize: 12.5,
          color: palette.text.withOpacity(0.9),
          fontWeight: FontWeight.w600,
        ),
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
class CommandeItem {
  final String name, code, lab;
  final String? productId;
  final String note;
  final int stockActuel, seuil, suggere, prixUnitaire;
  int qtyCommandee;

  CommandeItem({
    required this.name,
    required this.code,
    required this.lab,
    this.productId,
    this.note = '',
    required this.stockActuel,
    required this.seuil,
    required this.suggere,
    required this.qtyCommandee,
    required this.prixUnitaire,
  });
}

class CommandeEnCours {
  final String id, date, fournisseur, statut;
  final int montant;
  final String raisonAnnulation;
  final String auteur;
  final String notes;

  const CommandeEnCours({
    required this.id,
    required this.date,
    required this.fournisseur,
    required this.statut,
    required this.montant,
    this.raisonAnnulation = '',
    this.auteur = '',
    this.notes = '',
  });
}
