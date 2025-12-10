// screens/reception_livraisons.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_theme.dart';
import '../services/local_database_service.dart';

class ReceptionLivraisonsScreen extends StatefulWidget {
  const ReceptionLivraisonsScreen({super.key});

  @override
  State<ReceptionLivraisonsScreen> createState() =>
      _ReceptionLivraisonsScreenState();
}

class _ReceptionLivraisonsScreenState extends State<ReceptionLivraisonsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController _scanController = TextEditingController();
  bool _bonScanne = false;
  bool _isScanning = false;

  final List<ReceptionItem> _itemsRecus = [];

  // Bon de livraison chargé (initialement vide — pas de données codées en dur)
  final List<ReceptionItem> _bonDeLivraison = [];
  // Receptions en attente chargées depuis la BDD
  final List<Map<String, dynamic>> _pendingReceptions = [];

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
    _loadPendingReceptions();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _scannerBon() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _bonScanne = true;
      _isScanning = false;
      _itemsRecus.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bon de livraison scanné – Commencez le scan des produits',
          ),
          backgroundColor: Colors.teal,
        ),
      );
    });
  }

  void _scannerProduit() async {
    if (!_bonScanne) return;
    final code = _scanController.text.trim();
    if (code.isEmpty) return;

    final attendu = _bonDeLivraison.firstWhere(
      (i) => i.code == code,
      orElse: () => ReceptionItem(
        name: 'Produit inconnu',
        code: code,
        qtyCommandee: 0,
        prixUnitaire: 0,
        lot: '',
        peremption: '',
      ),
    );

    if (attendu.qtyCommandee == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit non attendu dans cette livraison'),
          backgroundColor: Colors.red,
        ),
      );
      _scanController.clear();
      return;
    }

    final dejaRecu = _itemsRecus.any((i) => i.code == code);
    if (dejaRecu) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Produit déjà scanné'),
          backgroundColor: Colors.orange,
        ),
      );
      _scanController.clear();
      return;
    }

    setState(() {
      _itemsRecus.add(
        ReceptionItem(
          name: attendu.name,
          code: attendu.code,
          qtyCommandee: attendu.qtyCommandee,
          qtyRecue: attendu.qtyCommandee, // par défaut
          prixUnitaire: attendu.prixUnitaire,
          lot: attendu.lot,
          peremption: attendu.peremption,
        ),
      );
      _scanController.clear();
    });
  }

  Future<void> _loadPendingReceptions() async {
    try {
      await LocalDatabaseService.instance.init();
      final db = LocalDatabaseService.instance.db;
      final rows = await db.query(
        'receptions',
        where: 'statut = ?',
        whereArgs: ['En attente'],
        orderBy: 'date DESC',
      );
      setState(() {
        _pendingReceptions.clear();
        _pendingReceptions.addAll(rows);
      });
    } catch (e) {
      // ignore — keep empty list
    }
  }

  Future<void> _openReception(String receptionId) async {
    try {
      await LocalDatabaseService.instance.init();
      final db = LocalDatabaseService.instance.db;
      final recRows = await db.query(
        'receptions',
        where: 'id = ?',
        whereArgs: [receptionId],
      );
      if (recRows.isEmpty) return;
      final rec = recRows.first;
      final commandeId = rec['commande_id'] as String? ?? '';

      // Try to load lines for this commande
      List<Map<String, dynamic>> lines = [];
      try {
        lines = await db.query(
          'commande_lignes',
          where: 'commande_id = ?',
          whereArgs: [commandeId],
        );
      } catch (_) {
        lines = [];
      }

      final List<ReceptionItem> bon = [];
      for (final l in lines) {
        String name = '';
        if (l.containsKey('nom_produit') && l['nom_produit'] != null) {
          name = l['nom_produit'] as String;
        } else if (l.containsKey('medicament_id') &&
            l['medicament_id'] != null) {
          final med = await db.query(
            'medicaments',
            where: 'id = ?',
            whereArgs: [l['medicament_id']],
          );
          if (med.isNotEmpty)
            name = med.first['nom'] as String? ?? l['medicament_id'].toString();
          else
            name = l['medicament_id'].toString();
        }
        final qty = (l['quantite'] is int)
            ? l['quantite'] as int
            : int.tryParse('${l['quantite']}') ?? 0;
        final prix = (l['prix_unitaire'] is num)
            ? (l['prix_unitaire'] as num).toInt()
            : int.tryParse('${l['prix_unitaire']}') ?? 0;
        final lot = l['lot']?.toString() ?? '';
        final peremption = l['peremption']?.toString() ?? '';
        bon.add(
          ReceptionItem(
            name: name,
            code: l['medicament_id']?.toString() ?? '',
            qtyCommandee: qty,
            prixUnitaire: prix,
            lot: lot,
            peremption: peremption,
          ),
        );
      }

      setState(() {
        _bonDeLivraison.clear();
        _bonDeLivraison.addAll(bon);
        _itemsRecus.clear();
        _bonScanne = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur ouverture réception: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _validateReception() async {
    if (_bonDeLivraison.isEmpty) return;
    final allReceived = _itemsRecus.length == _bonDeLivraison.length;
    if (!allReceived) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Tous les produits doivent être scannés avant validation',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await LocalDatabaseService.instance.init();
      final db = LocalDatabaseService.instance.db;

      // Find reception for current bon: match by commande id via lignes_commande
      final commandeIds = <String>{};
      for (final l in _bonDeLivraison) {
        // l.code holds medicament_id, need to find commande via lignes_commande
        // We'll query the lignes_commande table to find the commande_id for the first matching medicament
        final rows = await db.query(
          'lignes_commande',
          where: 'medicament_id = ?',
          whereArgs: [l.code],
        );
        if (rows.isNotEmpty)
          commandeIds.add(rows.first['commande_id'] as String? ?? '');
      }

      final commandeId = commandeIds.isNotEmpty ? commandeIds.first : null;

      // Update reception(s) and commande status
      if (commandeId != null && commandeId.isNotEmpty) {
        await db.rawUpdate(
          'UPDATE receptions SET statut = ? WHERE commande_id = ?',
          ['Reçue', commandeId],
        );
        await db.rawUpdate('UPDATE commandes SET statut = ? WHERE id = ?', [
          'Livrée',
          commandeId,
        ]);
      }

      // Update stocks and add mouvements_stocks
      for (int i = 0; i < _itemsRecus.length; i++) {
        final rec = _itemsRecus[i];
        final medId = rec.code;
        final qty = rec.qtyRecue;

        // find existing stock row (same med & lot)
        final existing = await db.query(
          'stocks',
          where: 'medicament_id = ? AND lot = ?',
          whereArgs: [medId, rec.lot],
        );
        int quantiteAvant = 0;
        if (existing.isNotEmpty) {
          final row = existing.first;
          quantiteAvant = (row['officine'] is int)
              ? row['officine'] as int
              : int.tryParse('${row['officine']}') ?? 0;
          final newQ = quantiteAvant + qty;
          await db.update(
            'stocks',
            {'officine': newQ},
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        } else {
          // insert new stock record
          await db.insert('stocks', {
            'medicament_id': medId,
            'reserve': 0,
            'officine': qty,
            'seuil': 0,
            'seuil_max': 0,
            'peremption': rec.peremption,
            'lot': rec.lot,
          });
        }

        final quantiteApres = quantiteAvant + qty;
        final msId = 'MS-${DateTime.now().millisecondsSinceEpoch}-$i';
        await db.insert('mouvements_stocks', {
          'id': msId,
          'medicament_id': medId,
          'type': 'reception',
          'quantite': qty,
          'quantite_avant': quantiteAvant,
          'quantite_apres': quantiteApres,
          'raison': 'Réception commande',
          'reference': commandeId ?? '',
          'notes': '',
          'utilisateur': '',
          'date': DateTime.now().toIso8601String(),
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Livraison validée et mise en stock !'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() {
        _bonScanne = false;
        _bonDeLivraison.clear();
        _itemsRecus.clear();
      });
      await _loadPendingReceptions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur validation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  int get _ecartTotal =>
      _bonDeLivraison.fold(0, (sum, i) => sum + i.qtyCommandee) -
      _itemsRecus.fold(0, (sum, i) => sum + i.qtyRecue);
  int get _totalAttendu => _bonDeLivraison.fold(
    0,
    (sum, i) => sum + (i.qtyCommandee * i.prixUnitaire),
  );
  int get _totalRecupere =>
      _itemsRecus.fold(0, (sum, i) => sum + (i.qtyRecue * i.prixUnitaire));

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    final accent = Colors.teal;

    return FadeTransition(
      opacity: _fade,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(palette),
            const SizedBox(height: 24),
            _buildScanBon(palette, accent),
            const SizedBox(height: 24),
            if (_bonScanne) ...[
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildListeReception(palette, accent),
                    ),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: _buildResume(palette, accent)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Réception livraisons',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: palette.text,
            letterSpacing: 1.2,
          ),
        ),
        Text(
          'Scan produits • Contrôle quantités • Lots & péremption • Validation',
          style: TextStyle(fontSize: 16, color: palette.subText),
        ),
      ],
    );
  }

  Widget _buildScanBon(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            // Pending receptions list
            if (!_bonScanne)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Réceptions en attente',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: _pendingReceptions.isEmpty
                        ? Center(
                            child: Text(
                              'Aucune réception en attente',
                              style: TextStyle(color: palette.subText),
                            ),
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _pendingReceptions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 12),
                            itemBuilder: (context, idx) {
                              final r = _pendingReceptions[idx];
                              final date = r['date'] ?? '';
                              final commandeId = r['commande_id'] ?? '';
                              return ElevatedButton(
                                onPressed: () =>
                                    _openReception(r['id'] as String),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: palette.isDark
                                      ? Colors.blueGrey
                                      : accent,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Bon: ${r['id']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Cmd: $commandeId • $date',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: palette.subText,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            Row(
              children: [
                Icon(Icons.inbox_outlined, color: palette.text, size: 32),
                const SizedBox(width: 16),
                Text(
                  _bonScanne
                      ? 'Bon de livraison chargé'
                      : 'Scanner le bon de livraison',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (!_bonScanne)
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      enabled: false,
                      decoration: InputDecoration(
                        hintText: 'Scannez le QR ou code du bon de livraison',
                        prefixIcon: const Icon(Icons.qr_code_scanner),
                        filled: true,
                        fillColor: palette.isDark
                            ? Colors.grey[850]
                            : Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _isScanning ? null : _scannerBon,
                    icon: _isScanning
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.document_scanner, size: 26),
                    label: Text(_isScanning ? 'Analyse...' : 'Scanner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 32,
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Bon de livraison chargé – ${_bonDeLivraison.length} produits attendus',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: palette.text,
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

  Widget _buildListeReception(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner, color: accent, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Scanner les produits reçus',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _scanController,
              autofocus: true,
              onSubmitted: (_) => _scannerProduit(),
              decoration: InputDecoration(
                hintText: 'Scannez le code-barres du produit...',
                prefixIcon: const Icon(Icons.medication),
                filled: true,
                fillColor: palette.isDark ? Colors.grey[850] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _itemsRecus.length,
              itemBuilder: (context, index) =>
                  _itemReception(_itemsRecus[index], palette, accent, index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemReception(
    ReceptionItem item,
    ThemeColors palette,
    Color accent,
    int index,
  ) {
    final attendu = _bonDeLivraison.firstWhere((i) => i.code == item.code);
    final ecart = item.qtyRecue - attendu.qtyCommandee;
    final hasEcart = ecart != 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasEcart ? Colors.orange.withOpacity(0.4) : palette.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.medication, color: accent, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ),
              if (hasEcart)
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 26,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _infoChip('Lot', item.lot, palette),
              const SizedBox(width: 8),
              _infoChip('Péremption', item.peremption, palette),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _receptionRow(
                      'Quantité commandée',
                      attendu.qtyCommandee,
                      palette,
                    ),
                    _receptionRow(
                      'Quantité reçue',
                      item.qtyRecue,
                      palette,
                      bold: true,
                    ),
                    if (hasEcart)
                      _receptionRow(
                        'Écart détecté',
                        ecart > 0 ? '+$ecart' : '$ecart',
                        palette,
                        color: Colors.orange,
                        bold: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 32),
              Text(
                '${(item.qtyRecue * item.prixUnitaire).toStringAsFixed(0)} FCFA',
                style: TextStyle(
                  fontSize: 18,
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

  Widget _receptionRow(
    String label,
    dynamic value,
    ThemeColors palette, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: TextStyle(color: palette.subText, fontSize: 14),
            ),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: bold ? 17 : 15,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color ?? palette.text,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResume(ThemeColors palette, Color accent) {
    final allReceived = _itemsRecus.length == _bonDeLivraison.length;
    final hasEcart = _ecartTotal != 0;

    return _card(
      palette,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              children: [
                Text(
                  'Résumé réception',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 24),
                _summaryRow(
                  'Produits attendus',
                  _bonDeLivraison.length,
                  palette,
                ),
                _summaryRow(
                  'Produits reçus',
                  _itemsRecus.length,
                  palette,
                  bold: true,
                ),
                _summaryRow(
                  'Écart total',
                  _ecartTotal == 0 ? 'Aucun' : _ecartTotal.toString(),
                  palette,
                  color: hasEcart ? Colors.orange : Colors.green,
                ),
                const Divider(height: 40),
                _summaryRow(
                  'Valeur attendue',
                  '${NumberFormat('#,###', 'fr_FR').format(_totalAttendu)} FCFA',
                  palette,
                  color: palette.subText,
                ),
                _summaryRow(
                  'Valeur reçue',
                  '${NumberFormat('#,###', 'fr_FR').format(_totalRecupere)} FCFA',
                  palette,
                  bold: true,
                  color: accent,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: allReceived ? _validateReception : null,
                          icon: const Icon(Icons.check_circle, size: 20),
                          label: const Text(
                            'Valider & Mettre en stock',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: palette.isDark
                                ? const Color(0xFF22C55E)
                                : Colors.green,
                            disabledBackgroundColor: palette.isDark
                                ? Colors.green.withOpacity(0.25)
                                : Colors.grey[400],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Annuler la réception'),
                                content: const Text(
                                  'Confirmer l\'annulation de cette réception ?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('Non'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('Oui, annuler'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              setState(() {
                                _bonScanne = false;
                                _bonDeLivraison.clear();
                                _itemsRecus.clear();
                              });
                              await _loadPendingReceptions();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Réception annulée'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.cancel_outlined, size: 18),
                          label: const Text(
                            'Annuler',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.redAccent),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
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
      ),
    );
  }

  Widget _summaryRow(
    String label,
    dynamic value,
    ThemeColors palette, {
    Color? color,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: bold ? 17 : 16, color: palette.subText),
          ),
          Text(
            value.toString(),
            style: TextStyle(
              fontSize: bold ? 20 : 18,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: color ?? palette.text,
            ),
          ),
        ],
      ),
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

class ReceptionItem {
  final String name, code, lot, peremption;
  final int qtyCommandee, qtyRecue, prixUnitaire;

  const ReceptionItem({
    required this.name,
    required this.code,
    required this.qtyCommandee,
    this.qtyRecue = 0,
    required this.prixUnitaire,
    required this.lot,
    required this.peremption,
  });
}
