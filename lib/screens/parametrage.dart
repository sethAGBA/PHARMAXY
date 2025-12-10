// screens/parametrage.dart
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../app_theme.dart';
import '../models/app_settings.dart';
import '../models/caisse_settings.dart';
import '../models/app_user.dart';
import '../screens/double_authentication_screen.dart';
import '../services/auth_service.dart';
import '../services/local_database_service.dart';

class ParametrageScreen extends StatefulWidget {
  const ParametrageScreen({super.key});

  @override
  State<ParametrageScreen> createState() => _ParametrageScreenState();
}

class _ParametrageScreenState extends State<ParametrageScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  String _categorieSelectionnee = 'Utilisateurs';
  final List<_ScreenAccess> _screenOptions = const [
    _ScreenAccess(id: 'dashboard', label: 'Tableau de bord'),
    _ScreenAccess(id: 'vente', label: 'Vente / Caisse'),
    _ScreenAccess(id: 'ordonnances', label: 'Ordonnances'),
    _ScreenAccess(id: 'stocks', label: 'Stocks'),
    _ScreenAccess(id: 'alertes', label: 'Alertes stock'),
    _ScreenAccess(id: 'mouvements', label: 'Mouvements stocks'),
    _ScreenAccess(id: 'commandes', label: 'Commandes fournisseurs'),
    _ScreenAccess(id: 'receptions', label: 'Réception livraisons'),
    _ScreenAccess(id: 'clients', label: 'Clients / Patients'),
    _ScreenAccess(id: 'facturation', label: 'Facturation & compta'),
    _ScreenAccess(id: 'reporting', label: 'Reporting'),
    _ScreenAccess(id: 'tiers', label: 'Tiers payant'),
    _ScreenAccess(id: 'preparations', label: 'Préparations'),
    _ScreenAccess(id: 'inventaire', label: 'Inventaire'),
    _ScreenAccess(id: 'parametrage', label: 'Paramétrage'),
    _ScreenAccess(id: 'retours', label: 'Retours'),
    _ScreenAccess(id: 'conseil', label: 'Conseil pharma'),
    _ScreenAccess(id: 'stupefiants', label: 'Stupéfiants'),
    _ScreenAccess(id: 'ecommerce', label: 'E-commerce'),
  ];

  final List<String> _categories = [
    'Utilisateurs',
    'Caisse',
    'Tiers Payant',
    'Marges',
    'Périphériques',
    'Général',
  ];

  List<AppUser> _utilisateurs = [];
  bool _loadingUsers = true;
  String? _usersError;
  AppSettings _settings = AppSettings.defaults();
  bool _loadingSettings = true;
  CaisseSettings _caisse = CaisseSettings.defaults();
  bool _loadingCaisse = true;
  late final TextEditingController _logoController = TextEditingController();
  late final TextEditingController _clientFieldController =
      TextEditingController(text: 'Nom / Tel');
  late final TextEditingController _prefixController = TextEditingController(
    text: 'FAC-',
  );
  late final TextEditingController _nextNumberController =
      TextEditingController(text: '25001');
  late final TextEditingController _formatController = TextEditingController(
    text: 'FAC-YYMM-NNNN',
  );
  late final TextEditingController _pharmacyNameController =
      TextEditingController();
  late final TextEditingController _pharmacyAddressController =
      TextEditingController();
  late final TextEditingController _pharmacyPhoneController =
      TextEditingController();
  late final TextEditingController _pharmacyEmailController =
      TextEditingController();
  late final TextEditingController _pharmacyOrderController =
      TextEditingController();
  final FilePicker _filePicker = FilePicker.platform;

  final List<TiersPayant> _tiersPayants = [
    TiersPayant(
      nom: 'INAM',
      type: 'Assurance Maladie',
      tauxPriseEnCharge: 80,
      delaiPaiement: 60,
      actif: true,
      nbPatients: 1245,
      montantEnAttente: 8500000,
    ),
    TiersPayant(
      nom: 'CNSS',
      type: 'Caisse Sociale',
      tauxPriseEnCharge: 70,
      delaiPaiement: 45,
      actif: true,
      nbPatients: 856,
      montantEnAttente: 5200000,
    ),
    TiersPayant(
      nom: 'SAHAM Assurance',
      type: 'Assurance Privée',
      tauxPriseEnCharge: 90,
      delaiPaiement: 30,
      actif: true,
      nbPatients: 423,
      montantEnAttente: 3800000,
    ),
    TiersPayant(
      nom: 'NSIA Assurance',
      type: 'Assurance Privée',
      tauxPriseEnCharge: 85,
      delaiPaiement: 30,
      actif: true,
      nbPatients: 312,
      montantEnAttente: 2900000,
    ),
  ];

  final List<Peripherique> _peripheriques = [
    Peripherique(
      nom: 'Scanner Code-Barres',
      type: 'Scanner',
      modele: 'Datalogic QD2430',
      port: 'USB-001',
      statut: 'Connecté',
      dernierTest: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Peripherique(
      nom: 'Imprimante Ordonnances',
      type: 'Imprimante',
      modele: 'HP LaserJet Pro',
      port: 'USB-002',
      statut: 'Connecté',
      dernierTest: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    Peripherique(
      nom: 'TPE Bancaire',
      type: 'TPE',
      modele: 'Ingenico Desk/5000',
      port: 'Ethernet',
      statut: 'Connecté',
      dernierTest: DateTime.now().subtract(const Duration(hours: 3)),
    ),
    Peripherique(
      nom: 'Balance de Précision',
      type: 'Balance',
      modele: 'Sartorius ED224S',
      port: 'USB-003',
      statut: 'Déconnecté',
      dernierTest: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

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
    _chargerUtilisateurs();
    _chargerSettings();
    _chargerCaisse();
  }

  @override
  void dispose() {
    _controller.dispose();
    _logoController.dispose();
    _prefixController.dispose();
    _nextNumberController.dispose();
    _formatController.dispose();
    _pharmacyNameController.dispose();
    _pharmacyAddressController.dispose();
    _pharmacyPhoneController.dispose();
    _pharmacyEmailController.dispose();
    _pharmacyOrderController.dispose();
    super.dispose();
  }

  Future<void> _chargerSettings() async {
    setState(() => _loadingSettings = true);
    final settings = await LocalDatabaseService.instance.getSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _logoController.text = settings.logoPath;
      _pharmacyNameController.text = settings.pharmacyName;
      _pharmacyAddressController.text = settings.pharmacyAddress;
      _pharmacyPhoneController.text = settings.pharmacyPhone;
      _pharmacyEmailController.text = settings.pharmacyEmail;
      _pharmacyOrderController.text = settings.pharmacyOrderNumber;
      _loadingSettings = false;
    });
  }

  Future<void> _chargerCaisse() async {
    setState(() => _loadingCaisse = true);
    final caisse = await LocalDatabaseService.instance.getCaisseSettings();
    if (!mounted) return;
    setState(() {
      _caisse = caisse;
      _prefixController.text = caisse.invoicePrefix;
      _nextNumberController.text = caisse.nextNumber;
      _formatController.text = caisse.numberingFormat;
      _clientFieldController.text = caisse.customerField;
      _loadingCaisse = false;
    });
  }

  Future<void> _chargerUtilisateurs() async {
    setState(() {
      _loadingUsers = true;
      _usersError = null;
    });
    try {
      final users = await LocalDatabaseService.instance.getUsers();
      if (!mounted) return;
      setState(() {
        _utilisateurs = users;
        _loadingUsers = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingUsers = false;
        _usersError = 'Erreur lors du chargement: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    final accent = Colors.deepPurple;

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
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 240,
                    child: _buildMenuCategories(palette, accent),
                  ),
                  const SizedBox(width: 24),
                  Expanded(child: _buildContenuCategorie(palette, accent)),
                ],
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
          child: Icon(Icons.settings, color: accent, size: 40),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paramétrage',
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: palette.text,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                'Configuration complète de votre système de gestion',
                style: TextStyle(fontSize: 15, color: palette.subText),
              ),
            ],
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _afficherInfo('Sauvegarde automatique activée'),
          icon: const Icon(Icons.save),
          label: const Text('SAUVEGARDER'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCategories(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final categorie = _categories[index];
          final isSelected = categorie == _categorieSelectionnee;
          final icon = _getIconCategorie(categorie);

          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => setState(() => _categorieSelectionnee = categorie),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? accent.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? accent.withOpacity(0.3)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        color: isSelected ? accent : palette.subText,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          categorie,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected ? accent : palette.text,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(Icons.chevron_right, color: accent, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContenuCategorie(ThemeColors palette, Color accent) {
    switch (_categorieSelectionnee) {
      case 'Utilisateurs':
        return _buildUtilisateurs(palette, accent);
      case 'Caisse':
        return _buildCaisse(palette, accent);
      case 'Tiers Payant':
        return _buildTiersPayant(palette, accent);
      case 'Marges':
        return _buildMarges(palette, accent);
      case 'Périphériques':
        return _buildPeripheriques(palette, accent);
      case 'Général':
        return _buildGeneral(palette, accent);
      default:
        return const SizedBox();
    }
  }

  // ============= UTILISATEURS =============
  Widget _buildUtilisateurs(ThemeColors palette, Color accent) {
    if (_loadingUsers) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_usersError != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_usersError!, style: TextStyle(color: Colors.red[300])),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _chargerUtilisateurs,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          palette,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.people, color: accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gestion des Utilisateurs',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                      ),
                      Text(
                        'Contrôlez les accès et permissions de votre équipe',
                        style: TextStyle(fontSize: 14, color: palette.subText),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _chargerUtilisateurs,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Rafraîchir'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _restaurerAdmin,
                  icon: const Icon(Icons.admin_panel_settings),
                  label: const Text('Restaurer admin'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _ouvrirDialogUtilisateur(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('NOUVEL UTILISATEUR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _card(
            palette,
            child: Column(
              children: [
                _buildEnteteUtilisateurs(palette),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _utilisateurs.length,
                    itemBuilder: (context, index) {
                      return _carteUtilisateur(
                        _utilisateurs[index],
                        palette,
                        accent,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnteteUtilisateurs(ThemeColors palette) {
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
          Expanded(flex: 3, child: Text('UTILISATEUR', style: style)),
          Expanded(flex: 2, child: Text('RÔLE', style: style)),
          Expanded(flex: 2, child: Text('DROITS', style: style)),
          Expanded(flex: 2, child: Text('DERNIÈRE CONNEXION', style: style)),
          SizedBox(width: 100, child: Text('STATUT', style: style)),
          const SizedBox(width: 120),
        ],
      ),
    );
  }

  Widget _carteUtilisateur(AppUser user, ThemeColors palette, Color accent) {
    final isDefaultAdmin = _isDefaultAdmin(user);
    final statutColor = user.isActive ? Colors.green : Colors.grey;

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
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: accent.withOpacity(0.1),
                  child: Text(
                    user.name.split(' ').map((e) => e[0]).take(2).join(),
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 13, color: palette.subText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                user.role,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _buildRightsChips(user, palette),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDate(user.lastLogin),
              style: TextStyle(fontSize: 13, color: palette.subText),
            ),
          ),
          SizedBox(
            width: 100,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statutColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statutColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    user.isActive ? 'Actif' : 'Inactif',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statutColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Switch(
                  value: user.isActive,
                  activeColor: Colors.green,
                  onChanged: isDefaultAdmin
                      ? (_) => _afficherInfo(
                          'Le compte admin ne peut pas être désactivé',
                        )
                      : (value) => _basculerStatut(user, value, palette),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _ouvrirDialogUtilisateur(user: user);
                    } else if (value == 'delete') {
                      _supprimerUtilisateur(user);
                    } else if (value == 'twofa') {
                      _toggleUserTwoFactor(user);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'twofa',
                      child: Text(
                        user.twoFactorEnabled
                            ? 'Désactiver 2FA'
                            : 'Activer 2FA',
                      ),
                    ),
                    const PopupMenuItem(value: 'edit', child: Text('Modifier')),
                    if (!isDefaultAdmin)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============= CAISSE =============
  Widget _buildCaisse(ThemeColors palette, Color accent) {
    if (_loadingCaisse) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            palette,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.point_of_sale, color: accent, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Configuration de la Caisse',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _card(
                  palette,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Modes de paiement',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: palette.text,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _switchOption(
                          'Espèces',
                          _caisse.acceptCash,
                          Icons.money,
                          Colors.green,
                          palette,
                          onChanged: (v) => setState(
                            () => _caisse = _caisse.copyWith(acceptCash: v),
                          ),
                        ),
                        _switchOption(
                          'Carte bancaire',
                          _caisse.acceptCard,
                          Icons.credit_card,
                          Colors.blue,
                          palette,
                          onChanged: (v) => setState(
                            () => _caisse = _caisse.copyWith(acceptCard: v),
                          ),
                        ),
                        _switchOption(
                          'Mobile Money',
                          _caisse.acceptMobileMoney,
                          Icons.phone_android,
                          Colors.orange,
                          palette,
                          onChanged: (v) => setState(
                            () => _caisse = _caisse.copyWith(
                              acceptMobileMoney: v,
                            ),
                          ),
                        ),
                        _switchOption(
                          'Chèque',
                          _caisse.acceptCheque,
                          Icons.receipt,
                          Colors.purple,
                          palette,
                          onChanged: (v) => setState(
                            () => _caisse = _caisse.copyWith(acceptCheque: v),
                          ),
                        ),
                        _switchOption(
                          'Virement',
                          _caisse.acceptTransfer,
                          Icons.account_balance,
                          Colors.indigo,
                          palette,
                          onChanged: (v) => setState(
                            () => _caisse = _caisse.copyWith(acceptTransfer: v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _card(
                      palette,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Numérotation & ticket',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _textField(
                              label: 'Préfixe factures',
                              controller: _prefixController,
                              palette: palette,
                              onChanged: (v) =>
                                  _caisse = _caisse.copyWith(invoicePrefix: v),
                            ),
                            const SizedBox(height: 12),
                            _textField(
                              label: 'Numéro suivant',
                              controller: _nextNumberController,
                              palette: palette,
                              keyboard: TextInputType.number,
                              onChanged: (v) => _caisse = _caisse.copyWith(
                                nextNumber: v.trim(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _textField(
                              label: 'Format',
                              controller: _formatController,
                              palette: palette,
                              onChanged: (v) => _caisse = _caisse.copyWith(
                                numberingFormat: v.trim(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _textField(
                              label: 'Champs client sur ticket (nom/numéro)',
                              controller: _clientFieldController,
                              palette: palette,
                              onChanged: (v) => _caisse = _caisse.copyWith(
                                customerField: v.trim(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      palette,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Options',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _switchOption(
                              'Impression automatique',
                              _caisse.autoPrint,
                              Icons.print,
                              Colors.teal,
                              palette,
                              onChanged: (v) => setState(
                                () => _caisse = _caisse.copyWith(autoPrint: v),
                              ),
                            ),
                            _switchOption(
                              'Ouverture tiroir caisse',
                              _caisse.openDrawer,
                              Icons.sensor_door,
                              Colors.brown,
                              palette,
                              onChanged: (v) => setState(
                                () => _caisse = _caisse.copyWith(openDrawer: v),
                              ),
                            ),
                            _switchOption(
                              'Demander signature',
                              _caisse.requireSignature,
                              Icons.edit,
                              Colors.pink,
                              palette,
                              onChanged: (v) => setState(
                                () => _caisse = _caisse.copyWith(
                                  requireSignature: v,
                                ),
                              ),
                            ),
                            _switchOption(
                              'Imprimer ticket client',
                              _caisse.printCustomerReceipt,
                              Icons.receipt_long,
                              Colors.indigo,
                              palette,
                              onChanged: (v) => setState(
                                () => _caisse = _caisse.copyWith(
                                  printCustomerReceipt: v,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _enregistrerCaisse,
                                icon: const Icon(Icons.save),
                                label: const Text('Enregistrer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============= TIERS PAYANT =============
  Widget _buildTiersPayant(ThemeColors palette, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          palette,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.business, color: accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tiers Payants',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                      ),
                      Text(
                        'Gestion des mutuelles et assurances',
                        style: TextStyle(fontSize: 14, color: palette.subText),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _afficherInfo('Ajout de tiers payant'),
                  icon: const Icon(Icons.add),
                  label: const Text('NOUVEAU TIERS'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _tiersPayants.length,
            itemBuilder: (context, index) {
              return _carteTiersPayant(_tiersPayants[index], palette, accent);
            },
          ),
        ),
      ],
    );
  }

  Widget _carteTiersPayant(
    TiersPayant tiers,
    ThemeColors palette,
    Color accent,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _card(
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
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.business,
                      color: Colors.blue,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tiers.nom,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: palette.text,
                          ),
                        ),
                        Text(
                          tiers.type,
                          style: TextStyle(
                            fontSize: 14,
                            color: palette.subText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: tiers.actif,
                    onChanged: (value) {
                      setState(() => tiers.actif = value);
                    },
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    onPressed: () => _afficherInfo('Modifier ${tiers.nom}'),
                    icon: const Icon(Icons.edit),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _infoTiers(
                      'Taux prise en charge',
                      '${tiers.tauxPriseEnCharge}%',
                      Icons.percent,
                      Colors.green,
                      palette,
                    ),
                  ),
                  Expanded(
                    child: _infoTiers(
                      'Délai paiement',
                      '${tiers.delaiPaiement} jours',
                      Icons.schedule,
                      Colors.orange,
                      palette,
                    ),
                  ),
                  Expanded(
                    child: _infoTiers(
                      'Patients',
                      '${tiers.nbPatients}',
                      Icons.people,
                      Colors.blue,
                      palette,
                    ),
                  ),
                  Expanded(
                    child: _infoTiers(
                      'En attente',
                      '${_formatMontant(tiers.montantEnAttente)} F',
                      Icons.pending,
                      Colors.red,
                      palette,
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

  Widget _infoTiers(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeColors palette,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: palette.text,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: palette.subText),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ============= MARGES =============
  Widget _buildMarges(ThemeColors palette, Color accent) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            palette,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: accent, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Configuration des Marges',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _card(
            palette,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Marges par catégorie de produits',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _margeCategorie(
                    'Médicaments génériques',
                    15,
                    25,
                    Colors.green,
                    palette,
                  ),
                  const SizedBox(height: 16),
                  _margeCategorie(
                    'Médicaments de marque',
                    20,
                    35,
                    Colors.blue,
                    palette,
                  ),
                  const SizedBox(height: 16),
                  _margeCategorie(
                    'Parapharmacie',
                    30,
                    50,
                    Colors.orange,
                    palette,
                  ),
                  const SizedBox(height: 16),
                  _margeCategorie(
                    'Cosmétiques',
                    35,
                    60,
                    Colors.purple,
                    palette,
                  ),
                  const SizedBox(height: 16),
                  _margeCategorie(
                    'Matériel médical',
                    25,
                    40,
                    Colors.teal,
                    palette,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _margeCategorie(
    String nom,
    int margeMin,
    int margeMax,
    Color color,
    ThemeColors palette,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: palette.isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: Text(
              nom,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marge min',
                  style: TextStyle(fontSize: 12, color: palette.subText),
                ),
                const SizedBox(height: 4),
                Text(
                  '$margeMin%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Marge max',
                  style: TextStyle(fontSize: 12, color: palette.subText),
                ),
                const SizedBox(height: 4),
                Text(
                  '$margeMax%',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _afficherInfo('Modifier les marges de $nom'),
            icon: const Icon(Icons.edit, size: 20),
            tooltip: 'Modifier',
          ),
        ],
      ),
    );
  }

  // ============= PÉRIPHÉRIQUES =============
  Widget _buildPeripheriques(ThemeColors palette, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _card(
          palette,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.devices, color: accent, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Périphériques',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                      ),
                      Text(
                        'Gestion des équipements connectés',
                        style: TextStyle(fontSize: 14, color: palette.subText),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () => _afficherInfo('Recherche de périphériques'),
                  icon: const Icon(Icons.search),
                  label: const Text('DÉTECTER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _peripheriques.length,
            itemBuilder: (context, index) {
              return _cartePeripherique(_peripheriques[index], palette, accent);
            },
          ),
        ),
      ],
    );
  }

  Widget _cartePeripherique(
    Peripherique peripherique,
    ThemeColors palette,
    Color accent,
  ) {
    final statutColor = peripherique.statut == 'Connecté'
        ? Colors.green
        : Colors.red;
    final iconData = _getIconPeripherique(peripherique.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _card(
        palette,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: statutColor, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      peripherique.nom,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: palette.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      peripherique.modele,
                      style: TextStyle(fontSize: 14, color: palette.subText),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.usb, size: 16, color: palette.subText),
                        const SizedBox(width: 4),
                        Text(
                          peripherique.port,
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.subText,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Icon(
                          Icons.access_time,
                          size: 16,
                          color: palette.subText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Testé ${_formatDuree(DateTime.now().difference(peripherique.dernierTest))}',
                          style: TextStyle(
                            fontSize: 13,
                            color: palette.subText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: statutColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statutColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      peripherique.statut,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: statutColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: () => _afficherInfo('Test de ${peripherique.nom}'),
                icon: const Icon(Icons.play_arrow),
                tooltip: 'Tester',
              ),
              IconButton(
                onPressed: () =>
                    _afficherInfo('Configuration de ${peripherique.nom}'),
                icon: const Icon(Icons.settings),
                tooltip: 'Configurer',
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============= GÉNÉRAL =============
  Widget _buildGeneral(ThemeColors palette, Color accent) {
    if (_loadingSettings) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _card(
            palette,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Icon(Icons.tune, color: accent, size: 28),
                  const SizedBox(width: 12),
                  Text(
                    'Paramètres Généraux',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: palette.text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  children: [
                    _card(
                      palette,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informations Pharmacie',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _controlledInput(
                              'Nom de la pharmacie',
                              _pharmacyNameController,
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _controlledInput(
                              'Adresse',
                              _pharmacyAddressController,
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _controlledInput(
                              'Téléphone',
                              _pharmacyPhoneController,
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _controlledInput(
                              'Email',
                              _pharmacyEmailController,
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _controlledInput(
                              'N° Ordre',
                              _pharmacyOrderController,
                              palette,
                              hint: 'ORD-2024-001',
                            ),
                            const SizedBox(height: 12),
                            _dropdownOption(
                              'Devise',
                              _settings.currency,
                              ['XOF', 'EUR', 'USD', 'XAF'],
                              (val) {
                                setState(() {
                                  _settings = _settings.copyWith(
                                    currency: val ?? 'XOF',
                                  );
                                });
                              },
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _logoPicker(palette),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                onPressed: _enregistrerSettings,
                                icon: const Icon(Icons.save),
                                label: const Text('Enregistrer'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accent,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      palette,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Horaires d\'ouverture',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _inputOption(
                              'Lundi - Vendredi',
                              '08:00 - 19:00',
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _inputOption('Samedi', '08:00 - 18:00', palette),
                            const SizedBox(height: 12),
                            _inputOption('Dimanche', '09:00 - 13:00', palette),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _card(
                      palette,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Préférences',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _switchOption(
                              'Mode sombre',
                              palette.isDark,
                              Icons.dark_mode,
                              Colors.indigo,
                              palette,
                            ),
                            _switchOption(
                              'Notifications',
                              true,
                              Icons.notifications,
                              Colors.orange,
                              palette,
                            ),
                            _switchOption(
                              'Sauvegarde automatique',
                              true,
                              Icons.cloud_upload,
                              Colors.blue,
                              palette,
                            ),
                            _switchOption(
                              'Sons système',
                              false,
                              Icons.volume_up,
                              Colors.green,
                              palette,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      palette,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sécurité',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _switchOption(
                              'Verrouillage auto',
                              true,
                              Icons.lock_clock,
                              Colors.purple,
                              palette,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _afficherInfo('Changement de mot de passe'),
                                icon: const Icon(Icons.vpn_key),
                                label: const Text('CHANGER MOT DE PASSE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.deepOrange,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _card(
                      palette,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Base de données',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dernière sauvegarde',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: palette.subText,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Il y a 2 heures',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: palette.text,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: () =>
                                      _afficherInfo('Sauvegarde en cours...'),
                                  icon: const Icon(Icons.backup, size: 18),
                                  label: const Text('SAUVEGARDER'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============= WIDGETS COMMUNS =============
  Widget _card(ThemeColors palette, {required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: palette.isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(palette.isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _switchOption(
    String label,
    bool value,
    IconData icon,
    Color color,
    ThemeColors palette, {
    ValueChanged<bool>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 15, color: palette.text),
            ),
          ),
          Switch(
            value: value,
            onChanged: (val) {
              if (onChanged != null) onChanged(val);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserTwoFactor(AppUser user) async {
    if (user.twoFactorEnabled) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Désactiver la double authentification'),
          content: const Text(
            'Confirmez-vous la désactivation de la double authentification pour cet utilisateur ?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Désactiver'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
      final updatedUser = user.copyWith(
        twoFactorEnabled: false,
        totpSecret: null,
      );
      await LocalDatabaseService.instance.updateUser(updatedUser);
      await _chargerUtilisateurs();
      _afficherInfo('Double authentification désactivée pour ${user.name}');
      return;
    }

    final secret = await _showTwoFactorSetupDialog(user);
    if (secret == null) return;
    final updatedUser = user.copyWith(
      twoFactorEnabled: true,
      totpSecret: secret,
    );
    await LocalDatabaseService.instance.updateUser(updatedUser);
    await _chargerUtilisateurs();
    _afficherInfo('Double authentification activée pour ${user.name}');
  }

  Future<String?> _showTwoFactorSetupDialog(AppUser user) async {
    final secret = AuthService.instance.generateTwoFactorSecret();
    final provisioningUri = AuthService.instance.buildTwoFactorProvisioningUri(
      account: user.email,
      secret: secret,
    );
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => TwoFactorSetupDialog(
        provisioningUri: provisioningUri,
        secret: secret,
      ),
    );
  }

  Widget _inputOption(String label, String value, ThemeColors palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.subText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: TextEditingController(text: value),
          style: TextStyle(fontSize: 15, color: palette.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.isDark ? Colors.grey[850] : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: palette.isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: palette.isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _controlledInput(
    String label,
    TextEditingController controller,
    ThemeColors palette, {
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.subText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: TextStyle(fontSize: 15, color: palette.text),
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: palette.isDark ? Colors.grey[850] : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: palette.isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: palette.isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.deepPurple, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdownOption(
    String label,
    String current,
    List<String> values,
    ValueChanged<String?> onChanged,
    ThemeColors palette,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.subText,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: palette.isDark ? Colors.grey[850] : Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: palette.isDark ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: DropdownButton<String>(
            value: current,
            items: values
                .map((v) => DropdownMenuItem<String>(value: v, child: Text(v)))
                .toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  Widget _textField({
    required String label,
    required TextEditingController controller,
    required ThemeColors palette,
    TextInputType keyboard = TextInputType.text,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.subText,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboard,
          onChanged: onChanged,
          style: TextStyle(fontSize: 15, color: palette.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.isDark ? Colors.grey[850] : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: palette.isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _logoPicker(ThemeColors palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Logo (depuis la galerie)',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: palette.subText,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _logoController,
                readOnly: true,
                style: TextStyle(fontSize: 15, color: palette.text),
                decoration: InputDecoration(
                  hintText: 'Sélectionnez un logo',
                  filled: true,
                  fillColor: palette.isDark
                      ? Colors.grey[850]
                      : Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: palette.isDark
                          ? Colors.grey[700]!
                          : Colors.grey[300]!,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: _selectLogoFromGallery,
              icon: const Icon(Icons.folder_open),
              label: const Text('Parcourir'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildLogoPreview(palette),
      ],
    );
  }

  Widget _buildLogoPreview(ThemeColors palette) {
    if (_settings.logoPath.isEmpty) {
      return Text(
        'Aucun logo sélectionné',
        style: TextStyle(color: palette.subText),
      );
    }
    if (kIsWeb || _settings.logoPath.startsWith('http')) {
      return SizedBox(
        height: 80,
        child: Image.network(
          _settings.logoPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _logoErrorPlaceholder(palette),
        ),
      );
    }
    return SizedBox(
      height: 80,
      child: Image.file(
        File(_settings.logoPath),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _logoErrorPlaceholder(palette),
      ),
    );
  }

  Widget _logoErrorPlaceholder(ThemeColors palette) {
    return Container(
      color: palette.isDark ? Colors.white12 : Colors.grey[200],
      child: Center(
        child: Text(
          'Aperçu indisponible',
          style: TextStyle(color: palette.subText),
        ),
      ),
    );
  }

  // ============= MÉTHODES UTILITAIRES =============
  IconData _getIconCategorie(String categorie) {
    switch (categorie) {
      case 'Utilisateurs':
        return Icons.people;
      case 'Caisse':
        return Icons.point_of_sale;
      case 'Tiers Payant':
        return Icons.business;
      case 'Marges':
        return Icons.trending_up;
      case 'Périphériques':
        return Icons.devices;
      case 'Général':
        return Icons.tune;
      default:
        return Icons.settings;
    }
  }

  IconData _getIconPeripherique(String type) {
    switch (type) {
      case 'Scanner':
        return Icons.qr_code_scanner;
      case 'Imprimante':
        return Icons.print;
      case 'TPE':
        return Icons.credit_card;
      case 'Balance':
        return Icons.balance;
      default:
        return Icons.devices;
    }
  }

  String _formatDuree(Duration duree) {
    if (duree.inDays > 0) {
      return 'Il y a ${duree.inDays} jour${duree.inDays > 1 ? "s" : ""}';
    } else if (duree.inHours > 0) {
      return 'Il y a ${duree.inHours}h';
    } else if (duree.inMinutes > 0) {
      return 'Il y a ${duree.inMinutes}min';
    } else {
      return "À l'instant";
    }
  }

  String _formatMontant(int montant) {
    return montant.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]} ',
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  void _afficherInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _ouvrirDialogUtilisateur({AppUser? user}) async {
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController(text: user?.name ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');
    final roleCtrl = TextEditingController(text: user?.role ?? 'Pharmacien');
    final pwdCtrl = TextEditingController();
    final selectedScreens = <String>{
      if (user == null || user.allowedScreens.isEmpty)
        ..._screenOptions.map((e) => e.id)
      else
        ...user.allowedScreens,
    };

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            user == null ? 'Nouvel utilisateur' : 'Modifier utilisateur',
          ),
          content: Form(
            key: formKey,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: SingleChildScrollView(
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nomCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nom complet',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email / identifiant',
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      TextFormField(
                        controller: roleCtrl,
                        decoration: const InputDecoration(labelText: 'Rôle'),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                      TextFormField(
                        controller: pwdCtrl,
                        decoration: InputDecoration(
                          labelText: user == null
                              ? 'Mot de passe'
                              : 'Nouveau mot de passe (optionnel)',
                        ),
                        obscureText: true,
                        validator: (v) {
                          if (user != null && (v == null || v.isEmpty))
                            return null;
                          if (v == null || v.length < 4)
                            return 'Min. 4 caractères';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Droits d’accès aux écrans',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _screenOptions.map((screen) {
                          final checked = selectedScreens.contains(screen.id);
                          return FilterChip(
                            label: Text(screen.label),
                            selected: checked,
                            onSelected: (val) {
                              if (val) {
                                selectedScreens.add(screen.id);
                              } else {
                                selectedScreens.remove(screen.id);
                              }
                              setState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          selectedScreens.length == _screenOptions.length
                              ? 'Tous les écrans sélectionnés'
                              : '${selectedScreens.length} écran(s) sélectionné(s)',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    );

    if (result != true) return;
    final id = user?.id ?? emailCtrl.text.trim().toLowerCase();
    final now = DateTime.now();
    final newUser = AppUser(
      id: id,
      name: nomCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      password: pwdCtrl.text.isEmpty
          ? (user?.password ?? 'admin123')
          : pwdCtrl.text,
      role: roleCtrl.text.trim(),
      createdAt: user?.createdAt ?? now,
      lastLogin: user?.lastLogin ?? now,
      isActive: user?.isActive ?? true,
      twoFactorEnabled: user?.twoFactorEnabled ?? false,
      totpSecret: user?.totpSecret,
      allowedScreens: selectedScreens.length == _screenOptions.length
          ? const []
          : selectedScreens.toList(),
    );
    await LocalDatabaseService.instance.insertUser(newUser);
    await _chargerUtilisateurs();
    _afficherInfo(
      user == null ? 'Utilisateur ajouté' : 'Utilisateur mis à jour',
    );
  }

  Future<void> _basculerStatut(
    AppUser user,
    bool actif,
    ThemeColors palette,
  ) async {
    if (_isDefaultAdmin(user)) {
      _afficherInfo('Le compte admin ne peut pas être désactivé');
      return;
    }
    final updated = user.copyWith(isActive: actif);
    await LocalDatabaseService.instance.updateUser(updated);
    await _chargerUtilisateurs();
    _afficherInfo(actif ? 'Utilisateur activé' : 'Utilisateur désactivé');
  }

  Future<void> _supprimerUtilisateur(AppUser user) async {
    if (_isDefaultAdmin(user)) {
      _afficherInfo('Le compte admin ne peut pas être supprimé');
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l’utilisateur'),
        content: Text('Confirmer la suppression de ${user.name} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await LocalDatabaseService.instance.deleteUser(user.id);
      await _chargerUtilisateurs();
      _afficherInfo('Utilisateur supprimé');
    }
  }

  Future<void> _restaurerAdmin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restaurer le compte admin'),
        content: const Text(
          'Cette action réinitialise le compte admin (admin@pharmaxy.local / admin123). Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final verified = await _verifyCurrentUserTwoFactor();
    if (!verified) {
      _afficherInfo('Double authentification requise pour restaurer admin');
      return;
    }

    final admin = AppUser(
      id: 'admin',
      name: 'Admin',
      email: 'admin@pharmaxy.local',
      password: 'admin123',
      role: 'admin',
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isActive: true,
      twoFactorEnabled: false,
      totpSecret: null,
      allowedScreens: const [],
    );
    await LocalDatabaseService.instance.insertUser(admin);
    await _chargerUtilisateurs();
    _afficherInfo('Compte admin restauré');
  }

  Future<bool> _verifyCurrentUserTwoFactor() async {
    final current = AuthService.instance.currentUser;
    if (current == null || !current.twoFactorEnabled) return true;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => DoubleAuthenticationScreen(user: current),
      ),
    );
    return result == true;
  }

  bool _isDefaultAdmin(AppUser user) {
    return user.id == 'admin' ||
        user.email.toLowerCase() == 'admin@pharmaxy.local';
  }

  List<Widget> _buildRightsChips(AppUser user, ThemeColors palette) {
    final allowed = user.allowedScreens;
    final allSelected =
        allowed.isEmpty || allowed.length == _screenOptions.length;
    if (allSelected) {
      return [
        Chip(
          label: const Text('Tous les écrans'),
          backgroundColor: palette.isDark
              ? Colors.white12
              : Colors.blue.withOpacity(0.12),
        ),
      ];
    }
    final labels = allowed
        .map(
          (id) => _screenOptions
              .firstWhere(
                (e) => e.id == id,
                orElse: () => _ScreenAccess(id: id, label: id),
              )
              .label,
        )
        .toList();
    final chips = <Widget>[];
    for (final label in labels.take(2)) {
      chips.add(
        Chip(
          label: Text(label, style: const TextStyle(fontSize: 11)),
          backgroundColor: palette.isDark
              ? Colors.white12
              : Colors.orange.withOpacity(0.14),
        ),
      );
    }
    if (labels.length > 2) {
      chips.add(
        Chip(
          label: Text(
            '+${labels.length - 2}',
            style: const TextStyle(fontSize: 11),
          ),
          backgroundColor: palette.isDark
              ? Colors.white12
              : Colors.orange.withOpacity(0.14),
        ),
      );
    }
    return chips;
  }

  Future<void> _enregistrerSettings() async {
    setState(() => _loadingSettings = true);
    final updated = _settings.copyWith(
      logoPath: _logoController.text.trim(),
      pharmacyName: _pharmacyNameController.text.trim(),
      pharmacyAddress: _pharmacyAddressController.text.trim(),
      pharmacyPhone: _pharmacyPhoneController.text.trim(),
      pharmacyEmail: _pharmacyEmailController.text.trim(),
      pharmacyOrderNumber: _pharmacyOrderController.text.trim(),
    );
    await LocalDatabaseService.instance.saveSettings(updated);
    await _chargerSettings();
    _afficherInfo('Paramètres généraux enregistrés');
  }

  Future<void> _selectLogoFromGallery() async {
    try {
      final result = await _filePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      final path = result?.files.single.path;
      if (path == null || path.isEmpty) return;
      final saved = await _persistLogo(File(path));
      if (saved == null) return;
      setState(() {
        _settings = _settings.copyWith(logoPath: saved);
        _logoController.text = saved;
      });
    } catch (e) {
      _afficherInfo('Impossible de récupérer le logo: $e');
    }
  }

  Future<String?> _persistLogo(File file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logosDir = Directory('${directory.path}/logos');
      if (!await logosDir.exists()) {
        await logosDir.create(recursive: true);
      }
      final extension = file.path.split('.').last;
      final logoPath = '${logosDir.path}/logo_pharmaxy.$extension';
      final logoFile = File(logoPath);
      await logoFile.create(recursive: true);
      await file.copy(logoPath);
      try {
        await FileImage(File(logoPath)).evict();
      } catch (_) {}
      return logoPath;
    } catch (e) {
      _afficherInfo('Impossible de copier le logo: $e');
      return null;
    }
  }

  Future<void> _enregistrerCaisse() async {
    final updated = _caisse.copyWith(
      invoicePrefix: _prefixController.text.trim(),
      nextNumber: _nextNumberController.text.trim(),
      numberingFormat: _formatController.text.trim(),
      customerField: _clientFieldController.text.trim(),
    );
    await LocalDatabaseService.instance.saveCaisseSettings(updated);
    await _chargerCaisse();
    _afficherInfo('Paramètres caisse enregistrés');
  }
}

class TwoFactorSetupDialog extends StatefulWidget {
  const TwoFactorSetupDialog({
    super.key,
    required this.provisioningUri,
    required this.secret,
  });

  final String provisioningUri;
  final String secret;

  @override
  State<TwoFactorSetupDialog> createState() => _TwoFactorSetupDialogState();
}

class _TwoFactorSetupDialogState extends State<TwoFactorSetupDialog> {
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _onValidate() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Veuillez saisir le code.');
      return;
    }
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    final verified =
        AuthService.instance.verifyTwoFactorCode(widget.secret, code);
    setState(() => _isVerifying = false);
    if (!verified) {
      setState(() => _error = 'Code invalide');
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop(widget.secret);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text('Activer la double authentification'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Scannez ce QR code avec votre application d\'authentification pour obtenir vos codes temporaires.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 220,
              height: 220,
              child: QrImageView(
                data: widget.provisioningUri,
                version: QrVersions.auto,
                gapless: false,
                errorCorrectionLevel: QrErrorCorrectLevel.M,
                size: 220,
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              widget.secret,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Code à 6 chiffres',
                border: OutlineInputBorder(),
                counterText: '',
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _onValidate,
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Valider le code'),
        ),
      ],
    );
  }
}

class TiersPayant {
  final String nom;
  final String type;
  final int tauxPriseEnCharge;
  final int delaiPaiement;
  bool actif;
  final int nbPatients;
  final int montantEnAttente;

  TiersPayant({
    required this.nom,
    required this.type,
    required this.tauxPriseEnCharge,
    required this.delaiPaiement,
    required this.actif,
    required this.nbPatients,
    required this.montantEnAttente,
  });
}

class Peripherique {
  final String nom;
  final String type;
  final String modele;
  final String port;
  final String statut;
  final DateTime dernierTest;

  Peripherique({
    required this.nom,
    required this.type,
    required this.modele,
    required this.port,
    required this.statut,
    required this.dernierTest,
  });
}

class _ScreenAccess {
  const _ScreenAccess({required this.id, required this.label});

  final String id;
  final String label;
}
