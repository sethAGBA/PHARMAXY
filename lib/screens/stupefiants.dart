import 'package:flutter/material.dart';

import '../app_theme.dart';

class StupefiantsScreen extends StatefulWidget {
  const StupefiantsScreen({super.key});

  @override
  State<StupefiantsScreen> createState() => _StupefiantsScreenState();
}

class _StupefiantsScreenState extends State<StupefiantsScreen> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double> _fade = const AlwaysStoppedAnimation<double>(1);
  final TextEditingController _searchController = TextEditingController();
  String _type = 'Tous';
  String _periode = 'Ce mois';

  final List<_Mouvement> _mouvements = const [
    _Mouvement(ref: 'STU-2024-1201', date: '08/12/2024', produit: 'Morphine 10mg/1ml', lot: 'MORP-24A', type: 'Entrée', quantite: 120, agent: 'Dupont A.', motif: 'Livraison grossiste'),
    _Mouvement(ref: 'STU-2024-1198', date: '07/12/2024', produit: 'Fentanyl 50mcg patch', lot: 'FENT-24B', type: 'Sortie', quantite: 4, agent: 'Martin L.', motif: 'Dispensation ordonnance'),
    _Mouvement(ref: 'STU-2024-1195', date: '06/12/2024', produit: 'Morphine 10mg/1ml', lot: 'MORP-24A', type: 'Sortie', quantite: 6, agent: 'Bernard S.', motif: 'Dispensation ordonnance'),
    _Mouvement(ref: 'STU-2024-1188', date: '04/12/2024', produit: 'Méthadone 40mg', lot: 'METH-24C', type: 'Entrée', quantite: 80, agent: 'Petit N.', motif: 'Réception fournisseur'),
  ];

  final List<_Controle> _controles = const [
    _Controle(date: '30/11/2024', ecart: '+2 ampoules', statut: 'A justifier', agent: 'Dubois V.'),
    _Controle(date: '31/10/2024', ecart: '0', statut: 'Conforme', agent: 'Martin L.'),
    _Controle(date: '30/09/2024', ecart: '-1 patch', statut: 'Signalé', agent: 'Dupont A.'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeOutCubic));
    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_Mouvement> get _filtered {
    final q = _searchController.text.toLowerCase();
    return _mouvements.where((m) {
      final matchesText = m.produit.toLowerCase().contains(q) || m.ref.toLowerCase().contains(q) || m.lot.toLowerCase().contains(q);
      final matchesType = _type == 'Tous' || m.type == _type;
      return matchesText && matchesType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    const accent = Colors.deepPurple;

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
          decoration: BoxDecoration(color: accent.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(Icons.verified_user, color: accent, size: 26),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Gestion des stupéfiants', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: palette.text)),
            Text('Registre spécifique • Traçabilité renforcée • Déclarations', style: TextStyle(color: palette.subText)),
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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }

  Widget _buildKpis(ThemeColors palette, Color accent) {
    return Row(
      children: [
        Expanded(child: _kpi('Stock théorique', '318 unités', Icons.inventory_2, accent, palette)),
        const SizedBox(width: 12),
        Expanded(child: _kpi('Entrées (mois)', '200', Icons.download, Colors.green, palette)),
        const SizedBox(width: 12),
        Expanded(child: _kpi('Sorties (mois)', '95', Icons.upload, Colors.orange, palette)),
        const SizedBox(width: 12),
        Expanded(child: _kpi('Alertes / écarts', '2', Icons.warning_amber, Colors.redAccent, palette)),
      ],
    );
  }

  Widget _kpi(String title, String value, IconData icon, Color color, ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: palette.subText, fontSize: 13)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: palette.text, fontSize: 22, fontWeight: FontWeight.bold)),
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
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher référence, lot, produit...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: palette.isDark ? Colors.grey[850] : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            SizedBox(
              width: 170,
              child: DropdownButtonFormField<String>(
                value: _type,
                items: const ['Tous', 'Entrée', 'Sortie']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'Tous'),
                decoration: InputDecoration(
                  labelText: 'Type de mouvement',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                dropdownColor: palette.card,
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: _periode,
                items: const ['Ce mois', '30 derniers jours', '90 jours']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _periode = v ?? 'Ce mois'),
                decoration: InputDecoration(
                  labelText: 'Période',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                dropdownColor: palette.card,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fact_check, color: accent, size: 18),
                  const SizedBox(width: 8),
                  Text('${_filtered.length} mouvements', style: TextStyle(color: palette.text, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
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
                Text('Registre des mouvements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Nouvelle écriture'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    return DataColumn(label: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: palette.text)));
  }

  DataRow _row(_Mouvement m, ThemeColors palette) {
    final color = m.type == 'Entrée' ? Colors.green : Colors.orange;
    return DataRow(
      cells: [
        DataCell(Text(m.ref, style: TextStyle(color: palette.text))),
        DataCell(Text(m.date, style: TextStyle(color: palette.text))),
        DataCell(Text(m.produit, style: TextStyle(color: palette.text))),
        DataCell(Text(m.lot, style: TextStyle(color: palette.text))),
        DataCell(Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
          child: Text(m.type, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
        )),
        DataCell(Text('${m.quantite}', style: TextStyle(color: palette.text, fontWeight: FontWeight.w600))),
        DataCell(Text(m.agent, style: TextStyle(color: palette.text))),
        DataCell(Text(m.motif, style: TextStyle(color: palette.subText))),
      ],
    );
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
                Text('Contrôles & écarts', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: palette.text)),
              ],
            ),
            const SizedBox(height: 12),
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
          Text(c.date, style: TextStyle(color: palette.text, fontWeight: FontWeight.w600)),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(10)),
            child: Text(c.statut, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
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
    final upcoming = [
      {'label': 'Déclaration trimestrielle ARS', 'date': '15/01/2025', 'statut': 'A préparer'},
      {'label': 'Registre PDF à signer', 'date': '31/12/2024', 'statut': 'En attente'},
      {'label': 'Export comptable stupéfiants', 'date': 'Hebdo', 'statut': 'Automatisé'},
    ];

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
                Text('Déclarations & traçabilité', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: palette.text)),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: upcoming
                  .map(
                    (d) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: accent.withOpacity(0.12), shape: BoxShape.circle),
                        child: const Icon(Icons.upload_file, color: Colors.deepPurple),
                      ),
                      title: Text(d['label']!, style: TextStyle(color: palette.text, fontWeight: FontWeight.w600)),
                      subtitle: Text('Échéance: ${d['date']}', style: TextStyle(color: palette.subText)),
                      trailing: Text(d['statut']!, style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
                    ),
                  )
                  .toList(),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            color: palette.isDark ? Colors.black.withOpacity(0.25) : Colors.grey.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Mouvement {
  final String ref;
  final String date;
  final String produit;
  final String lot;
  final String type;
  final int quantite;
  final String agent;
  final String motif;

  const _Mouvement({
    required this.ref,
    required this.date,
    required this.produit,
    required this.lot,
    required this.type,
    required this.quantite,
    required this.agent,
    required this.motif,
  });
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
