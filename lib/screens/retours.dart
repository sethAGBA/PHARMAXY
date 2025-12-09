import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/local_database_service.dart';

class RetoursScreen extends StatefulWidget {
  const RetoursScreen({super.key});

  @override
  State<RetoursScreen> createState() => _RetoursScreenState();
}

class _RetoursScreenState extends State<RetoursScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _controller;
  late Animation<double> _fade;
  String _selectedFilter = 'Tous';
  bool _loading = true;
  String? _error;

  List<_RetourClient> _retoursClients = [];
  List<_RetourFournisseur> _retoursFournisseurs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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
      final db = LocalDatabaseService.instance.db;

      // retours clients from ventes negative? (type retour) - fallback demo
      _retoursClients.clear();
      try {
        final rows = await db.rawQuery('''
          SELECT v.id, v.date, v.montant, v.client_id
          FROM ventes v
          WHERE v.type LIKE '%Retour%' OR v.montant < 0
          ORDER BY v.date DESC
        ''');
        for (final r in rows) {
          final date = DateTime.tryParse(r['date'] as String? ?? '') ?? DateTime.now();
        final montant = (r['montant'] as num?)?.abs().toInt() ?? 0;
        _retoursClients.add(_RetourClient(
          r['id'] as String? ?? '',
          DateFormat('dd/MM/yyyy').format(date),
          r['client_id'] as String? ?? '',
          'Voir vente',
          '1',
          'Retour client',
          montant.toString(),
          'Traitée',
          Colors.teal,
        ));
        }
      } catch (_) {}

      // retours fournisseurs from commande_lignes with negative qty? fallback empty
      _retoursFournisseurs.clear();

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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final palette = _ThemeColors(isDark);
    const accent = Colors.teal;

    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(child: Text('Erreur: $_error', style: TextStyle(color: palette.text)));
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
            Text('Gestion des Retours', 
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: palette.text, letterSpacing: 1.2)),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _showNewReturnDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Nouveau retour'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text('Retours clients/fournisseurs • Avoirs • Suivi processus', 
          style: TextStyle(fontSize: 16, color: palette.subText)),
      ],
    );
  }

  Widget _buildKpis(_ThemeColors palette) {
    return Row(
      children: [
        Expanded(child: _kpiCard('En attente', '8', Icons.pending_actions, Colors.orange, palette)),
        const SizedBox(width: 16),
        Expanded(child: _kpiCard('Traités', '24', Icons.check_circle, Colors.green, palette)),
        const SizedBox(width: 16),
        Expanded(child: _kpiCard('Avoirs ce mois', '1 245 000 FCFA', Icons.euro, Colors.blue, palette)),
        const SizedBox(width: 16),
        Expanded(child: _kpiCard('En litige', '2', Icons.warning, Colors.red, palette)),
      ],
    );
  }

  Widget _kpiCard(String label, String value, IconData icon, Color color, _ThemeColors palette) {
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
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: palette.text)),
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
                      .map((filter) => DropdownMenuItem(value: filter, child: Text(filter)))
                      .toList(),
                  onChanged: (value) => setState(() => _selectedFilter = value!),
                  style: TextStyle(color: palette.text, fontWeight: FontWeight.w600),
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
    final retours = _retoursClients;

    return _card(
      palette,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(palette.card),
            columns: [
              DataColumn(label: Text('N° Retour', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Client', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Produit', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Qté', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Motif', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
            ],
            rows: retours.map((r) => _buildRetourClientRow(r, palette, accent)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildRetoursFournisseursList(_ThemeColors palette, Color accent) {
    final retours = _retoursFournisseurs;

    return _card(
      palette,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(palette.card),
            columns: [
              DataColumn(label: Text('N° Retour', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Fournisseur', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Produit', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Lot', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Qté', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Motif', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Montant', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Statut', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
              DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
            ],
            rows: retours.map((r) => _buildRetourFournisseurRow(r, palette, accent)).toList(),
          ),
        ),
      ),
    );
  }

  DataRow _buildRetourClientRow(_RetourClient r, _ThemeColors palette, Color accent) {
    return DataRow(
      cells: [
        DataCell(Text(r.numero, style: TextStyle(fontWeight: FontWeight.w600, color: accent))),
        DataCell(Text(r.date, style: TextStyle(color: palette.text))),
        DataCell(Text(r.client, style: TextStyle(color: palette.text))),
        DataCell(Text(r.produit, style: TextStyle(color: palette.text))),
        DataCell(Text(r.quantite, style: TextStyle(color: palette.text))),
        DataCell(Text(r.motif, style: TextStyle(color: palette.text))),
        DataCell(Text('${r.montant} FCFA', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: r.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(r.statut, style: TextStyle(color: r.statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                color: Colors.blue,
                onPressed: () => _showRetourDetails(r.numero, 'client', palette, accent),
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

  DataRow _buildRetourFournisseurRow(_RetourFournisseur r, _ThemeColors palette, Color accent) {
    return DataRow(
      cells: [
        DataCell(Text(r.numero, style: TextStyle(fontWeight: FontWeight.w600, color: accent))),
        DataCell(Text(r.date, style: TextStyle(color: palette.text))),
        DataCell(Text(r.fournisseur, style: TextStyle(color: palette.text))),
        DataCell(Text(r.produit, style: TextStyle(color: palette.text))),
        DataCell(Text(r.lot, style: TextStyle(color: palette.text))),
        DataCell(Text(r.quantite, style: TextStyle(color: palette.text))),
        DataCell(Text(r.motif, style: TextStyle(color: palette.text))),
        DataCell(Text('${r.montant} FCFA', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: r.statusColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(r.statut, style: TextStyle(color: r.statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
          ),
        ),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                color: Colors.blue,
                onPressed: () => _showRetourDetails(r.numero, 'fournisseur', palette, accent),
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
    final palette = _ThemeColors(Theme.of(context).brightness == Brightness.dark);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: palette.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nouveau retour', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: palette.text)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Type de retour',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: palette.card,
                ),
                items: ['Retour client', 'Retour fournisseur']
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Client / Fournisseur',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: palette.card,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Produit concerné',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.medication),
                  filled: true,
                  fillColor: palette.card,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Quantité',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: palette.card,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Montant',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        suffixText: 'FCFA',
                        filled: true,
                        fillColor: palette.card,
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Motif du retour',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: palette.card,
                ),
                items: ['Périmé', 'Défectueux', 'Non conforme', 'Erreur dispensation', 'Effet indésirable', 'Rappel de lot', 'Autre']
                    .map((motif) => DropdownMenuItem(value: motif, child: Text(motif)))
                    .toList(),
                onChanged: (value) {},
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Commentaire',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
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
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Retour enregistré avec succès'), backgroundColor: Colors.green),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRetourDetails(String numero, String type, _ThemeColors palette, Color accent) {
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
                  Text('Détails du retour $numero', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: palette.text)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              Divider(height: 40, color: palette.divider),
              _buildDetailRow('Type', type == 'client' ? 'Retour client' : 'Retour fournisseur', palette),
              _buildDetailRow('Date', '08/12/2024 à 14:32', palette),
              _buildDetailRow(type == 'client' ? 'Client' : 'Fournisseur', 
                type == 'client' ? 'Dupont Marie' : 'Grossiste A', palette),
              _buildDetailRow('Produit', type == 'client' ? 'Doliprane 1000mg' : 'Amoxicilline 500mg', palette),
              if (type == 'fournisseur') _buildDetailRow('Lot', 'LOT2024A', palette),
              _buildDetailRow('Quantité', type == 'client' ? '2' : '50', palette),
              _buildDetailRow('Montant', type == 'client' ? '5 000 FCFA' : '145 000 FCFA', palette),
              _buildDetailRow('Motif', type == 'client' ? 'Non conforme' : 'Périmé', palette),
              Divider(height: 40, color: palette.divider),
              Text('Historique du traitement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text)),
              const SizedBox(height: 16),
              _buildHistoryItem('08/12/2024 14:32', 'Retour créé', 'Admin', palette, accent),
              _buildHistoryItem('08/12/2024 15:10', 'Vérification effectuée', 'Pharmacien', palette, accent),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.print),
                    label: const Text('Imprimer'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {},
                    icon: Icon(type == 'fournisseur' ? Icons.description : Icons.check),
                    label: Text(type == 'fournisseur' ? 'Générer avoir' : 'Valider remboursement'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          SizedBox(width: 160, child: Text('$label:', style: TextStyle(fontWeight: FontWeight.w600, color: palette.subText))),
          Expanded(child: Text(value, style: TextStyle(fontSize: 15, color: palette.text))),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(String date, String action, String user, _ThemeColors palette, Color accent) {
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
                Text(action, style: TextStyle(fontWeight: FontWeight.w600, color: palette.text)),
                Text('$date - $user', style: TextStyle(fontSize: 12, color: palette.subText)),
              ],
            ),
          ),
        ],
      ),
    );
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
class _RetourClient {
  final String numero, date, client, produit, quantite, motif, montant, statut;
  final Color statusColor;
  _RetourClient(this.numero, this.date, this.client, this.produit, this.quantite, this.motif, this.montant, this.statut, this.statusColor);
}

class _RetourFournisseur {
  final String numero, date, fournisseur, produit, lot, quantite, motif, montant, statut;
  final Color statusColor;
  _RetourFournisseur(this.numero, this.date, this.fournisseur, this.produit, this.lot, this.quantite, this.motif, this.montant, this.statut, this.statusColor);
}

class _ThemeColors {
  final bool isDark;
  _ThemeColors(this.isDark);
  
  Color get text => isDark ? Colors.white : Colors.black87;
  Color get subText => isDark ? Colors.grey[400]! : Colors.grey[600]!;
  Color get card => isDark ? const Color(0xFF1E1E1E) : Colors.white;
  Color get divider => isDark ? Colors.grey[800]! : Colors.grey[300]!;
}
