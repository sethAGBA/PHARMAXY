import 'package:flutter/material.dart';

import '../app_theme.dart';

class EcommerceScreen extends StatefulWidget {
  const EcommerceScreen({super.key});

  @override
  State<EcommerceScreen> createState() => _EcommerceScreenState();
}

class _EcommerceScreenState extends State<EcommerceScreen>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double> _fade = const AlwaysStoppedAnimation<double>(1);
  String _fulfillment = 'Tous';
  String _status = 'Tous';
  final TextEditingController _searchController = TextEditingController();

  // No hard-coded ecommerce data — lists will be loaded from services when implemented
  final List<_CommandeWeb> _commandes = [];

  final List<_Produit> _catalogue = [];

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
  }

  @override
  void dispose() {
    _controller?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<_CommandeWeb> get _filteredOrders {
    final q = _searchController.text.toLowerCase();
    return _commandes.where((c) {
      final matchesText =
          c.ref.toLowerCase().contains(q) || c.client.toLowerCase().contains(q);
      final matchesFulfillment =
          _fulfillment == 'Tous' || c.mode == _fulfillment;
      final matchesStatus = _status == 'Tous' || c.statut == _status;
      return matchesText && matchesFulfillment && matchesStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    const accent = Colors.teal;

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
                    _buildOrders(palette, accent),
                    const SizedBox(height: 16),
                    _buildCatalogue(palette, accent),
                    const SizedBox(height: 16),
                    _buildSync(palette, accent),
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
          child: Icon(Icons.shopping_bag, color: accent, size: 26),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'E-commerce',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            Text(
              'Catalogue en ligne • Commandes web • Click & collect',
              style: TextStyle(color: palette.subText),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.sync),
          label: const Text('Sync stocks'),
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKpis(ThemeColors palette, Color accent) {
    return Row(
      children: [
        Expanded(
          child: _kpi(
            'Commandes jour',
            '24',
            Icons.shopping_cart,
            accent,
            palette,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpi(
            'CA web (mois)',
            '1 245 000 FCFA',
            Icons.payments,
            Colors.green,
            palette,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpi(
            'Click & collect prêts',
            '6',
            Icons.store,
            Colors.orange,
            palette,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpi(
            'Panier moyen',
            '22 300 FCFA',
            Icons.bar_chart,
            Colors.indigo,
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                color: palette.subText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: palette.text,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
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
                  hintText: 'Rechercher commande ou client...',
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
            Flexible(
              child: DropdownButtonFormField<String>(
                value: _fulfillment,
                items: const ['Tous', 'Click & collect', 'Livraison']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _fulfillment = v ?? 'Tous'),
                decoration: InputDecoration(
                  labelText: 'Mode de retrait',
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
            Flexible(
              child: DropdownButtonFormField<String>(
                value: _status,
                items:
                    const [
                          'Tous',
                          'En attente paiement',
                          'En préparation',
                          'Expédiée',
                          'Payée',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) => setState(() => _status = v ?? 'Tous'),
                decoration: InputDecoration(
                  labelText: 'Statut',
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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.list_alt, color: accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_filteredOrders.length} commandes',
                    style: TextStyle(
                      color: palette.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrders(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: accent),
                const SizedBox(width: 8),
                Text(
                  'Commandes web',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add),
                  label: const Text('Créer commande'),
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
                  _col('Client', palette),
                  _col('Montant', palette),
                  _col('Statut', palette),
                  _col('Mode', palette),
                  _col('Produits', palette),
                  _col('Actions', palette),
                ],
                rows: _filteredOrders
                    .map((o) => _orderRow(o, palette))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _orderRow(_CommandeWeb o, ThemeColors palette) {
    final statusColor = _statusColor(o.statut);
    return DataRow(
      cells: [
        DataCell(Text(o.ref, style: TextStyle(color: palette.text))),
        DataCell(Text(o.date, style: TextStyle(color: palette.text))),
        DataCell(Text(o.client, style: TextStyle(color: palette.text))),
        DataCell(
          Text(
            '${o.montant} FCFA',
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w600),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              o.statut,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        DataCell(Text(o.mode, style: TextStyle(color: palette.text))),
        DataCell(Text('${o.produits}', style: TextStyle(color: palette.text))),
        DataCell(
          Row(
            children: [
              IconButton(onPressed: () {}, icon: const Icon(Icons.visibility)),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.check_circle_outline),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCatalogue(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.inventory_2, color: accent),
                const SizedBox(width: 8),
                Text(
                  'Catalogue en ligne',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.upload),
                  label: const Text('Publier'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: accent,
                    side: BorderSide(color: accent.withOpacity(0.35)),
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
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _catalogue
                  .map((p) => _productCard(p, palette))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productCard(_Produit p, ThemeColors palette) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.divider),
        boxShadow: [
          BoxShadow(
            color: palette.isDark
                ? Colors.black.withOpacity(0.25)
                : Colors.grey.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medical_services, color: palette.subText),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  p.nom,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${p.prix} FCFA',
            style: TextStyle(color: palette.text, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.inventory, size: 16, color: palette.subText),
              const SizedBox(width: 4),
              Text(
                'Stock: ${p.stock}',
                style: TextStyle(color: palette.subText),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Switch(
                value: p.actif,
                onChanged: (_) {},
                activeColor: Colors.teal,
              ),
              Text(
                p.actif ? 'Publié' : 'Masqué',
                style: TextStyle(color: palette.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSync(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.cloud_sync, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Synchronisation des stocks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Automatisez la mise à jour des stocks web après ventes en officine.',
                    style: TextStyle(color: palette.subText),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.bolt),
              label: const Text('Configurer'),
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
      ),
    );
  }

  Color _statusColor(String statut) {
    switch (statut) {
      case 'En préparation':
        return Colors.orange;
      case 'Expédiée':
        return Colors.blue;
      case 'Payée':
        return Colors.green;
      case 'En attente paiement':
        return Colors.redAccent;
      default:
        return Colors.grey;
    }
  }

  DataColumn _col(String label, ThemeColors palette) {
    return DataColumn(
      label: Text(
        label,
        style: TextStyle(fontWeight: FontWeight.bold, color: palette.text),
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

class _CommandeWeb {
  final String ref;
  final String date;
  final String client;
  final int montant;
  final String statut;
  final String mode;
  final int produits;

  const _CommandeWeb({
    required this.ref,
    required this.date,
    required this.client,
    required this.montant,
    required this.statut,
    required this.mode,
    required this.produits,
  });
}

class _Produit {
  final String nom;
  final int stock;
  final int prix;
  final bool actif;

  const _Produit({
    required this.nom,
    required this.stock,
    required this.prix,
    required this.actif,
  });
}
