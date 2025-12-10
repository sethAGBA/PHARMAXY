// screens/inventaire.dart
import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'package:intl/intl.dart';

import '../models/inventory_models.dart';
import '../services/inventory_service.dart';
import '../services/auth_service.dart';
import '../models/app_user.dart';

class InventaireScreen extends StatefulWidget {
  const InventaireScreen({super.key});

  @override
  State<InventaireScreen> createState() => _InventaireScreenState();
}

class _InventaireScreenState extends State<InventaireScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController _scanController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final FocusNode _scanFocus = FocusNode();

  bool _inventaireEnCours = false;
  DateTime _dateInventaire = DateTime.now();
  String _typeInventaire = 'Complet'; // Complet, Partiel, Tournant
  String _responsable = 'Préparateur';
  String _filtreVue = 'Tous'; // Tous, Écarts, Excédents, Manquants
  String _triPar = 'Scan'; // Scan, Nom, Écart, Valeur

  final List<InventoryLine> _lignes = [];
  final Set<String> _produitsScannes = {};
  List<InventoryProductSnapshot> _stockSnapshots = [];
  final Map<String, InventoryProductSnapshot> _snapshotByCode = {};
  final Map<String, InventoryProductSnapshot> _snapshotById = {};
  List<InventorySummary> _historique = [];
  bool _loadingStocks = true;
  AppUser? _inventoryUser;

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
    _loadInventoryData();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanController.dispose();
    _qtyController.dispose();
    _scanFocus.dispose();
    super.dispose();
  }

  Future<void> _demarrerInventaire() async {
    final authOk = await _promptInventoryAuthentication();
    if (!authOk) return;
    if (_inventoryUser != null) {
      _responsable = _inventoryUser!.name;
    }
    showDialog(
      context: context,
      builder: (context) => _dialogueConfigInventaire(),
    );
  }

  Future<void> _loadInventoryData() async {
    setState(() => _loadingStocks = true);
    final snapshots = await InventoryService.instance.fetchStockSnapshots();
    final history = await InventoryService.instance.fetchHistory();
    if (!mounted) return;
    _snapshotByCode.clear();
    _snapshotById.clear();
    for (final snapshot in snapshots) {
      final key = snapshot.code.trim().toUpperCase();
      if (key.isNotEmpty) {
        _snapshotByCode[key] = snapshot;
      }
      if (snapshot.medicamentId.isNotEmpty) {
        _snapshotById[snapshot.medicamentId] = snapshot;
        _snapshotById[snapshot.medicamentId.toUpperCase()] = snapshot;
      }
    }
    setState(() {
      _stockSnapshots = snapshots;
      _historique = history;
      _loadingStocks = false;
    });
  }

  Future<bool> _promptInventoryAuthentication() async {
    final identifierCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    String? errorMessage;
    bool loading = false;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Authentification requise'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: identifierCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Identifiant (email ou ID)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: loading
                      ? null
                      : () => Navigator.of(context).pop(false),
                  child: const Text('ANNULER'),
                ),
                ElevatedButton(
                  onPressed: loading
                      ? null
                      : () async {
                          setDialogState(() {
                            loading = true;
                            errorMessage = null;
                          });
                          final user = await AuthService.instance.login(
                            identifierCtrl.text.trim(),
                            passwordCtrl.text,
                            rememberMe: false,
                          );
                          if (user == null) {
                            setDialogState(() {
                              loading = false;
                              errorMessage = 'Identifiants invalides';
                            });
                            return;
                          }
                          _inventoryUser = user;
                          setDialogState(() => loading = false);
                          Navigator.of(context).pop(true);
                        },
                  child: const Text('VALIDER'),
                ),
              ],
            );
          },
        );
      },
    );
    return result == true;
  }

  Widget _dialogueConfigInventaire() {
    return AlertDialog(
      title: const Text('Configuration de l\'inventaire'),
      content: StatefulBuilder(
        builder: (context, setStateDialog) => SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Type d\'inventaire',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'Complet',
                    label: Text('Complet'),
                    icon: Icon(Icons.inventory),
                  ),
                  ButtonSegment(
                    value: 'Partiel',
                    label: Text('Partiel'),
                    icon: Icon(Icons.content_paste),
                  ),
                  ButtonSegment(
                    value: 'Tournant',
                    label: Text('Tournant'),
                    icon: Icon(Icons.rotate_right),
                  ),
                ],
                selected: {_typeInventaire},
                onSelectionChanged: (Set<String> newSelection) {
                  setStateDialog(() => _typeInventaire = newSelection.first);
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Responsable',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Nom du responsable',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                onChanged: (value) => _responsable = value,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ANNULER'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            setState(() {
              _inventaireEnCours = true;
              _lignes.clear();
              _produitsScannes.clear();
              _dateInventaire = DateTime.now();
            });
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('DÉMARRER'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
        ),
      ],
    );
  }

  void _scannerProduit() {
    final code = _scanController.text.trim();
    if (code.isEmpty) return;

    final normalized = code.trim().toUpperCase();
    final produit =
        _snapshotByCode[normalized] ??
        _snapshotById[code] ??
        _snapshotById[normalized];
    if (produit == null || produit.name.isEmpty) {
      _afficherErreur('Produit inconnu - Code: $code');
      _scanController.clear();
      return;
    }

    // Vérification si déjà scanné
    if (_produitsScannes.contains(produit.code)) {
      _afficherInfo('Produit déjà en inventaire - utilisez les boutons +/-');
      _scanController.clear();
      _focusOnScan();
      return;
    }

    // Demander la quantité si le champ est rempli, sinon 1 par défaut
    final qty = int.tryParse(_qtyController.text) ?? 1;

    setState(() {
      _lignes.add(
        InventoryLine(
          medicamentId: produit.medicamentId,
          code: produit.code,
          name: produit.name,
          qtyTheorique: produit.theoreticalQty,
          qtyReelle: qty,
          prixAchat: produit.purchasePrice,
          prixVente: produit.salePrice,
          lot: produit.lot,
          peremption: produit.expiry ?? DateTime.now(),
          categorie: produit.category,
          emplacement: produit.location,
          dateAjout: DateTime.now(),
        ),
      );
      _produitsScannes.add(produit.code);
    });

    _afficherSucces('${produit.name} ajouté (Qté: $qty)');
    _scanController.clear();
    _qtyController.clear();
    _focusOnScan();
  }

  void _saisieManuelle() {
    showDialog(
      context: context,
      builder: (context) => _dialogueSaisieManuelle(),
    );
  }

  Widget _dialogueSaisieManuelle() {
    String? codeSelectionne;
    final qtyManuelleCtrl = TextEditingController();
    String searchTerm = '';

    return AlertDialog(
      title: const Text('Saisie manuelle'),
      content: StatefulBuilder(
        builder: (context, setStateDialog) {
          final seenCodes = <String>{};
          final query = searchTerm.trim().toLowerCase();
          final availableOptions = _stockSnapshots.where((snap) {
            final code = snap.code.trim().toUpperCase();
            if (code.isEmpty || _produitsScannes.contains(code)) return false;
            if (seenCodes.contains(code)) return false;
            seenCodes.add(code);
            if (query.isNotEmpty) {
              final searchable =
                  '${snap.name.toLowerCase()} ${code.toLowerCase()}';
              if (!searchable.contains(query)) return false;
            }
            return true;
          }).toList();
          return SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Rechercher un produit',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (value) =>
                      setStateDialog(() => searchTerm = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Sélectionner un produit',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.medication),
                  ),
                  items: availableOptions
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.code,
                          child: Text('${e.name} (${e.code})'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setStateDialog(() => codeSelectionne = value),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyManuelleCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantité réelle',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.numbers),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ANNULER'),
        ),
        ElevatedButton(
          onPressed: () {
            if (codeSelectionne != null) {
              _scanController.text = codeSelectionne!;
              _qtyController.text = qtyManuelleCtrl.text;
              _scannerProduit();
              Navigator.pop(context);
            }
          },
          child: const Text('AJOUTER'),
        ),
      ],
    );
  }

  void _focusOnScan() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        FocusScope.of(context).requestFocus(_scanFocus);
      }
    });
  }

  void _afficherSucces(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _afficherErreur(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _afficherInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info, color: Colors.white),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  List<InventoryLine> get _lignesFiltrees {
    var lignes = List<InventoryLine>.from(_lignes);

    // Filtrage
    switch (_filtreVue) {
      case 'Écarts':
        lignes = lignes.where((l) => l.ecart != 0).toList();
        break;
      case 'Excédents':
        lignes = lignes.where((l) => l.ecart > 0).toList();
        break;
      case 'Manquants':
        lignes = lignes.where((l) => l.ecart < 0).toList();
        break;
    }

    // Tri
    switch (_triPar) {
      case 'Nom':
        lignes.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Écart':
        lignes.sort((a, b) => b.ecart.abs().compareTo(a.ecart.abs()));
        break;
      case 'Valeur':
        lignes.sort(
          (a, b) => (b.ecart * b.prixAchat).abs().compareTo(
            (a.ecart * a.prixAchat).abs(),
          ),
        );
        break;
      case 'Scan':
      default:
        lignes.sort((a, b) => b.dateAjout.compareTo(a.dateAjout));
    }

    return lignes;
  }

  // Statistiques
  int get _totalEcart => _lignes.fold(0, (sum, l) => sum + l.ecart);
  int get _nbEcarts => _lignes.where((l) => l.ecart != 0).length;
  int get _nbExcedents => _lignes.where((l) => l.ecart > 0).length;
  int get _nbManquants => _lignes.where((l) => l.ecart < 0).length;

  int get _valeurEcartPositif => _lignes
      .where((l) => l.ecart > 0)
      .fold(0, (sum, l) => sum + (l.ecart * l.prixAchat));

  int get _valeurEcartNegatif => _lignes
      .where((l) => l.ecart < 0)
      .fold(0, (sum, l) => sum + (l.ecart.abs() * l.prixAchat));

  int get _valeurTotaleTheorique =>
      _lignes.fold(0, (sum, l) => sum + (l.qtyTheorique * l.prixAchat));

  int get _valeurTotaleReelle =>
      _lignes.fold(0, (sum, l) => sum + (l.qtyReelle * l.prixAchat));

  double get _tauxEcart {
    if (_lignes.isEmpty) return 0.0;
    return (_nbEcarts / _lignes.length) * 100;
  }

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
            _buildHeader(palette, accent),
            const SizedBox(height: 24),
            Expanded(
              child: !_inventaireEnCours
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _buildAccueil(palette, accent),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 3,
                          child: SingleChildScrollView(
                            child: _buildHistorique(palette, accent),
                          ),
                        ),
                      ],
                    )
                  : SingleChildScrollView(
                      child: _buildInventaireEnCours(palette, accent),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.fact_check, color: accent, size: 40),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gestion des Inventaires',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Scan • Saisie • Comparaison • Valorisation • Régularisation',
                style: TextStyle(fontSize: 15, color: palette.subText),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccueil(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.inventory_2_outlined, size: 80, color: accent),
            ),
            const SizedBox(height: 32),
            Text(
              'Aucun inventaire en cours',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Démarrez un nouvel inventaire pour effectuer\nle contrôle de vos stocks',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: palette.subText),
            ),
            const SizedBox(height: 12),
            Text(
              '${_stockSnapshots.length} produits suivis',
              style: TextStyle(
                fontSize: 13,
                color: palette.subText.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _demarrerInventaire,
              icon: const Icon(Icons.play_arrow, size: 28),
              label: const Text(
                'DÉMARRER UN INVENTAIRE',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 24,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventaireEnCours(ThemeColors palette, Color accent) {
    if (_loadingStocks) {
      return SizedBox(
        height: 420,
        child: Center(child: CircularProgressIndicator(color: accent)),
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(flex: 2, child: _buildCarteStatut(palette)),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCarteStats(
                'Produits',
                _lignes.length,
                Icons.inventory,
                Colors.blue,
                palette,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCarteStats(
                'Écarts',
                _nbEcarts,
                Icons.warning,
                Colors.orange,
                palette,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildCarteStats(
                'Taux',
                _tauxEcart,
                Icons.percent,
                Colors.purple,
                palette,
                suffix: '%',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildZoneScan(palette, accent),
        const SizedBox(height: 16),
        _buildBarreControles(palette, accent),
        const SizedBox(height: 16),
        SizedBox(
          height: 420,
          child: _card(
            palette,
            child: Column(
              children: [
                _buildEnteteTableau(palette),
                const Divider(height: 1),
                Expanded(
                  child: _lignesFiltrees.isEmpty
                      ? _buildTableauVide(palette)
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _lignesFiltrees.length,
                          itemBuilder: (context, index) {
                            final ligne = _lignesFiltrees[index];
                            final indexOriginal = _lignes.indexOf(ligne);
                            return _ligneInventaire(
                              ligne,
                              palette,
                              accent,
                              indexOriginal,
                            );
                          },
                        ),
                ),
                const Divider(height: 1),
                _buildPiedTableau(palette, accent),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarteStatut(ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.access_time,
                color: Colors.orange,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Inventaire $_typeInventaire en cours',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'EN COURS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Démarré le ${DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR').format(_dateInventaire)} • Responsable: $_responsable',
                    style: TextStyle(color: palette.subText, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarteStats(
    String label,
    num value,
    IconData icon,
    Color color,
    ThemeColors palette, {
    String suffix = '',
  }) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              '${value is double ? value.toStringAsFixed(1) : value}$suffix',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: palette.subText,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneScan(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: _scanController,
                focusNode: _scanFocus,
                autofocus: true,
                onSubmitted: (_) => _scannerProduit(),
                decoration: InputDecoration(
                  hintText: 'Scanner ou saisir un code-barres...',
                  prefixIcon: Icon(Icons.qr_code_scanner, color: accent),
                  filled: true,
                  fillColor: palette.isDark
                      ? Colors.grey[850]
                      : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  suffixIcon: _scanController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _scanController.clear();
                            _focusOnScan();
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Qté',
                  prefixIcon: const Icon(Icons.numbers),
                  filled: true,
                  fillColor: palette.isDark
                      ? Colors.grey[850]
                      : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _scannerProduit,
              icon: const Icon(Icons.add_circle, size: 24),
              label: const Text(
                'AJOUTER',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 20,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: _saisieManuelle,
              icon: const Icon(Icons.edit),
              label: const Text('SAISIE MANUELLE'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
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

  Widget _buildBarreControles(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Flexible(
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Icon(Icons.filter_list, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Afficher:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Tous', label: Text('Tous')),
                      ButtonSegment(value: 'Écarts', label: Text('Écarts')),
                      ButtonSegment(
                        value: 'Excédents',
                        label: Text('Excédents'),
                      ),
                      ButtonSegment(
                        value: 'Manquants',
                        label: Text('Manquants'),
                      ),
                    ],
                    selected: {_filtreVue},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _filtreVue = newSelection.first);
                    },
                    style: ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                  const SizedBox(width: 32),
                  const Icon(Icons.sort, size: 20),
                  const SizedBox(width: 12),
                  const Text(
                    'Trier par:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 12),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Scan', label: Text('Scan')),
                      ButtonSegment(value: 'Nom', label: Text('Nom')),
                      ButtonSegment(value: 'Écart', label: Text('Écart')),
                      ButtonSegment(value: 'Valeur', label: Text('Valeur')),
                    ],
                    selected: {_triPar},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() => _triPar = newSelection.first);
                    },
                    style: ButtonStyle(visualDensity: VisualDensity.compact),
                  ),
                ],
              ),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: _exporterInventaire,
              icon: const Icon(Icons.file_download),
              label: const Text('EXPORTER'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: _validerInventaire,
              icon: const Icon(Icons.check_circle),
              label: const Text('VALIDER'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: _annulerInventaire,
              icon: const Icon(Icons.close, color: Colors.red),
              tooltip: 'Annuler l\'inventaire',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnteteTableau(ThemeColors palette) {
    final style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 13,
      color: palette.subText,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: palette.isDark ? Colors.grey[850] : Colors.grey[100],
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('PRODUIT', style: style)),
          Expanded(flex: 2, child: Text('CATÉGORIE', style: style)),
          Expanded(child: Text('EMPLACEMENT', style: style)),
          Expanded(child: Text('LOT', style: style)),
          Expanded(child: Text('PÉREMPTION', style: style)),
          SizedBox(
            width: 100,
            child: Text('QTÉ THÉO.', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 100,
            child: Text(
              'QTÉ RÉELLE',
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 100,
            child: Text('ÉCART', style: style, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'VALEUR ÉCART',
              style: style,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 100),
        ],
      ),
    );
  }

  Widget _ligneInventaire(
    InventoryLine ligne,
    ThemeColors palette,
    Color accent,
    int index,
  ) {
    final ecartColor = ligne.ecart == 0
        ? Colors.grey
        : ligne.ecart > 0
        ? Colors.green
        : Colors.red;

    final valeurEcart = ligne.ecart * ligne.prixAchat;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ligne.ecart != 0
              ? ecartColor.withOpacity(0.3)
              : (palette.isDark ? Colors.grey[700]! : Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ligne.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: palette.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ligne.code,
                  style: TextStyle(
                    fontSize: 12,
                    color: palette.subText,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              ligne.categorie,
              style: TextStyle(fontSize: 13, color: palette.subText),
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                ligne.emplacement,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Text(
              ligne.lot,
              style: TextStyle(fontSize: 12, color: palette.subText),
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('dd/MM/yyyy').format(ligne.peremption),
              style: TextStyle(
                fontSize: 12,
                color:
                    ligne.peremption.isBefore(
                      DateTime.now().add(const Duration(days: 90)),
                    )
                    ? Colors.orange
                    : palette.subText,
              ),
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              '${ligne.qtyTheorique}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (ligne.qtyReelle > 0) ligne.qtyReelle--;
                    });
                  },
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text(
                  '${ligne.qtyReelle}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() => ligne.qtyReelle++);
                  },
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: ecartColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${ligne.ecart > 0 ? '+' : ''}${ligne.ecart}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: ecartColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              '${_formatMontant(valeurEcart.abs())} F',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: ecartColor,
              ),
              textAlign: TextAlign.right,
            ),
          ),
          SizedBox(
            width: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => _modifierLigne(index),
                  icon: const Icon(Icons.edit, size: 18),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  onPressed: () => _supprimerLigne(index),
                  icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableauVide(ThemeColors palette) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: palette.subText.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun produit scanné',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: palette.subText,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Commencez à scanner des produits pour remplir l\'inventaire',
            style: TextStyle(
              fontSize: 14,
              color: palette.subText.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPiedTableau(ThemeColors palette, Color accent) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: palette.isDark ? Colors.grey[900] : Colors.grey[50],
      child: Row(
        children: [
          _buildRecapItem(
            'Total produits',
            '${_lignes.length}',
            Icons.inventory,
            Colors.blue,
            palette,
          ),
          const SizedBox(width: 32),
          _buildRecapItem(
            'Écarts détectés',
            '$_nbEcarts',
            Icons.warning,
            Colors.orange,
            palette,
          ),
          const SizedBox(width: 32),
          _buildRecapItem(
            'Excédents',
            '+$_nbExcedents',
            Icons.trending_up,
            Colors.green,
            palette,
          ),
          const SizedBox(width: 32),
          _buildRecapItem(
            'Manquants',
            '-$_nbManquants',
            Icons.trending_down,
            Colors.red,
            palette,
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Valeur totale (théorique)',
                style: TextStyle(fontSize: 12, color: palette.subText),
              ),
              Text(
                '${_formatMontant(_valeurTotaleTheorique)} F',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Valeur totale (réelle)',
                style: TextStyle(fontSize: 12, color: palette.subText),
              ),
              Text(
                '${_formatMontant(_valeurTotaleReelle)} F',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(width: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Écart de valorisation',
                style: TextStyle(fontSize: 12, color: palette.subText),
              ),
              Text(
                '${(_valeurTotaleReelle - _valeurTotaleTheorique) > 0 ? '+' : ''}${_formatMontant(_valeurTotaleReelle - _valeurTotaleTheorique)} F',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: (_valeurTotaleReelle - _valeurTotaleTheorique) >= 0
                      ? Colors.green
                      : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecapItem(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeColors palette,
  ) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: palette.subText)),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: palette.text,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHistorique(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.history, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Historique des inventaires',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SizedBox(
            height: 320,
            child: _historique.isEmpty
                ? Center(
                    child: Text(
                      'Aucun inventaire enregistré',
                      style: TextStyle(color: palette.subText),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _historique.length,
                    itemBuilder: (context, index) {
                      return _carteHistorique(_historique[index], palette);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _carteHistorique(InventorySummary inv, ThemeColors palette) {
    final ecartColor = inv.ecartValeur >= 0 ? Colors.green : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: palette.isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inv.statut,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                inv.id,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd/MM/yyyy', 'fr_FR').format(inv.date),
                style: TextStyle(fontSize: 13, color: palette.subText),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildInfoPastille('Type', inv.type, Icons.category, Colors.blue),
              _buildInfoPastille(
                'Produits',
                '${inv.nbProduits}',
                Icons.inventory,
                Colors.purple,
              ),
              _buildInfoPastille(
                'Responsable',
                inv.responsable,
                Icons.person,
                Colors.orange,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Écart valorisation: ',
                style: TextStyle(fontSize: 13, color: palette.subText),
              ),
              Text(
                '${inv.ecartValeur >= 0 ? '+' : ''}${_formatMontant(inv.ecartValeur)} F',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: ecartColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '(${inv.ecartQte >= 0 ? '+' : ''}${inv.ecartQte} unités)',
                style: TextStyle(fontSize: 12, color: palette.subText),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPastille(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text('$label: ', style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  void _modifierLigne(int index) {
    final ligne = _lignes[index];
    final qtyCtrl = TextEditingController(text: '${ligne.qtyReelle}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier la quantité'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ligne.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Code: ${ligne.code}', style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Quantité réelle',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              final newQty = int.tryParse(qtyCtrl.text);
              if (newQty != null && newQty >= 0) {
                setState(() => ligne.qtyReelle = newQty);
                Navigator.pop(context);
                _afficherSucces('Quantité modifiée');
              }
            },
            child: const Text('MODIFIER'),
          ),
        ],
      ),
    );
  }

  void _supprimerLigne(int index) {
    final ligne = _lignes[index];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce produit ?'),
        content: Text(
          'Êtes-vous sûr de vouloir retirer "${ligne.name}" de l\'inventaire ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _produitsScannes.remove(ligne.code);
                _lignes.removeAt(index);
              });
              Navigator.pop(context);
              _afficherSucces('Produit retiré de l\'inventaire');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
  }

  void _exporterInventaire() {
    _afficherInfo('Export en cours... (fonctionnalité à implémenter)');
  }

  Future<void> _validerInventaire() async {
    if (_lignes.isEmpty) {
      _afficherErreur('Aucun produit à valider');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Valider l\'inventaire'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Résumé de l\'inventaire:'),
            const SizedBox(height: 16),
            Text('• ${_lignes.length} produits scannés'),
            Text('• $_nbEcarts écarts détectés'),
            Text(
              '• Écart de valorisation: ${_formatMontant(_valeurTotaleReelle - _valeurTotaleTheorique)} F',
            ),
            const SizedBox(height: 16),
            const Text(
              'La validation enregistrera définitivement cet inventaire et mettra à jour les stocks.',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('VALIDER'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await InventoryService.instance.saveInventory(
      type: _typeInventaire,
      responsable: _responsable.isNotEmpty ? _responsable : 'Équipe',
      lines: List<InventoryLine>.from(_lignes),
    );
    _afficherSucces('Inventaire validé avec succès');
    setState(() {
      _inventaireEnCours = false;
      _lignes.clear();
      _produitsScannes.clear();
    });
    await _loadInventoryData();
  }

  Future<void> _annulerInventaire() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler l\'inventaire'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cet inventaire ? Toutes les données saisies seront perdues.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('NON'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _inventaireEnCours = false;
                _lignes.clear();
                _produitsScannes.clear();
              });
              _afficherInfo('Inventaire annulé');
              await _loadInventoryData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('OUI, ANNULER'),
          ),
        ],
      ),
    );
  }

  Widget _card(ThemeColors palette, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: palette.isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: child,
    );
  }

  String _formatMontant(int montant) {
    return NumberFormat('#,###', 'fr_FR').format(montant);
  }
}
