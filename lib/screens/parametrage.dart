// screens/parametrage.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_theme.dart';

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

  final List<String> _categories = [
    'Utilisateurs',
    'Caisse',
    'Tiers Payant',
    'Marges',
    'Périphériques',
    'Général',
  ];

  final List<Utilisateur> _utilisateurs = [
    Utilisateur(
      id: '1',
      nom: 'Marie KOUASSI',
      email: 'marie.k@pharmacie.tg',
      role: 'Pharmacien Titulaire',
      droits: ['Tous'],
      statut: 'Actif',
      derniereConnexion: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Utilisateur(
      id: '2',
      nom: 'Jean AGBODJAN',
      email: 'jean.a@pharmacie.tg',
      role: 'Pharmacien Adjoint',
      droits: ['Vente', 'Stock', 'Commandes'],
      statut: 'Actif',
      derniereConnexion: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Utilisateur(
      id: '3',
      nom: 'Sophie LAWSON',
      email: 'sophie.l@pharmacie.tg',
      role: 'Préparateur',
      droits: ['Vente', 'Stock'],
      statut: 'Actif',
      derniereConnexion: DateTime.now().subtract(const Duration(hours: 5)),
    ),
    Utilisateur(
      id: '4',
      nom: 'Paul MENSAH',
      email: 'paul.m@pharmacie.tg',
      role: 'Caissier',
      droits: ['Vente'],
      statut: 'Inactif',
      derniereConnexion: DateTime.now().subtract(const Duration(days: 15)),
    ),
  ];

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
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                  Expanded(
                    child: _buildContenuCategorie(palette, accent),
                  ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.normal,
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
                ElevatedButton.icon(
                  onPressed: () => _ajouterUtilisateur(),
                  icon: const Icon(Icons.person_add),
                  label: const Text('NOUVEL UTILISATEUR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
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
                          _utilisateurs[index], palette, accent);
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

  Widget _carteUtilisateur(
      Utilisateur user, ThemeColors palette, Color accent) {
    final statutColor = user.statut == 'Actif' ? Colors.green : Colors.grey;

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
                    user.nom.split(' ').map((e) => e[0]).take(2).join(),
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
                        user.nom,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: palette.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 13,
                          color: palette.subText,
                        ),
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
              children: user.droits.take(2).map<Widget>((droit) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    droit,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList()
                ..add(
                  user.droits.length > 2
                      ? Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: Text(
                            '+${user.droits.length - 2}',
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.subText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : const SizedBox(),
                ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatDuree(DateTime.now().difference(user.derniereConnexion)),
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
                    user.statut,
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
                IconButton(
                  onPressed: () => _modifierUtilisateur(user),
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Modifier',
                ),
                IconButton(
                  onPressed: () => _supprimerUtilisateur(user),
                  icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                  tooltip: 'Supprimer',
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
                          true,
                          Icons.money,
                          Colors.green,
                          palette,
                        ),
                        _switchOption(
                          'Carte bancaire',
                          true,
                          Icons.credit_card,
                          Colors.blue,
                          palette,
                        ),
                        _switchOption(
                          'Mobile Money',
                          true,
                          Icons.phone_android,
                          Colors.orange,
                          palette,
                        ),
                        _switchOption(
                          'Chèque',
                          false,
                          Icons.receipt,
                          Colors.purple,
                          palette,
                        ),
                        _switchOption(
                          'Virement',
                          false,
                          Icons.account_balance,
                          Colors.indigo,
                          palette,
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
                              'Numérotation',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _inputOption(
                              'Préfixe factures',
                              'FAC-',
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _inputOption(
                              'Numéro suivant',
                              '25001',
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _inputOption(
                              'Format',
                              'FAC-YYMM-NNNN',
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
                              true,
                              Icons.print,
                              Colors.teal,
                              palette,
                            ),
                            _switchOption(
                              'Ouverture tiroir caisse',
                              true,
                              Icons.sensor_door,
                              Colors.brown,
                              palette,
                            ),
                            _switchOption(
                              'Demander signature',
                              false,
                              Icons.edit,
                              Colors.pink,
                              palette,
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
                        horizontal: 24, vertical: 16),
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
              return _carteTiersPayant(
                  _tiersPayants[index], palette, accent);
            },
          ),
        ),
      ],
    );
  }

  Widget _carteTiersPayant(
      TiersPayant tiers, ThemeColors palette, Color accent) {
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
                    child: const Icon(Icons.business, color: Colors.blue, size: 28),
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
                          style: TextStyle(fontSize: 14, color: palette.subText),
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

  Widget _infoTiers(String label, String value, IconData icon, Color color,
      ThemeColors palette) {
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
            child:Padding(
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

  Widget _margeCategorie(String nom, int margeMin, int margeMax, Color color,
      ThemeColors palette) {
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
                        horizontal: 24, vertical: 16),
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
              return _cartePeripherique(
                  _peripheriques[index], palette, accent);
            },
          ),
        ),
      ],
    );
  }

  Widget _cartePeripherique(
      Peripherique peripherique, ThemeColors palette, Color accent) {
    final statutColor =
        peripherique.statut == 'Connecté' ? Colors.green : Colors.red;
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
                          style:
                              TextStyle(fontSize: 13, color: palette.subText),
                        ),
                        const SizedBox(width: 20),
                        Icon(Icons.access_time,
                            size: 16, color: palette.subText),
                        const SizedBox(width: 4),
                        Text(
                          'Testé ${_formatDuree(DateTime.now().difference(peripherique.dernierTest))}',
                          style:
                              TextStyle(fontSize: 13, color: palette.subText),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                onPressed: () =>
                    _afficherInfo('Test de ${peripherique.nom}'),
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
                            _inputOption(
                              'Nom de la pharmacie',
                              'Pharmacie de la Paix',
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _inputOption(
                              'Adresse',
                              '123 Avenue de la Liberté, Lomé',
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _inputOption(
                              'Téléphone',
                              '+228 22 XX XX XX',
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _inputOption(
                              'Email',
                              'contact@pharmaciedelapaix.tg',
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _inputOption(
                              'N° Ordre',
                              'ORD-2024-001',
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
                            _inputOption(
                              'Samedi',
                              '08:00 - 18:00',
                              palette,
                            ),
                            const SizedBox(height: 12),
                            _inputOption(
                              'Dimanche',
                              '09:00 - 13:00',
                              palette,
                            ),
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
                              'Authentification 2 facteurs',
                              true,
                              Icons.security,
                              Colors.red,
                              palette,
                            ),
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
                                      vertical: 16),
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

  Widget _switchOption(String label, bool value, IconData icon, Color color,
      ThemeColors palette) {
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
              setState(() {});
              _afficherInfo('$label ${val ? "activé" : "désactivé"}');
            },
          ),
        ],
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
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

  void _ajouterUtilisateur() {
    _afficherInfo('Ouverture du formulaire d\'ajout d\'utilisateur');
  }

  void _modifierUtilisateur(Utilisateur user) {
    _afficherInfo('Modification de ${user.nom}');
  }

  void _supprimerUtilisateur(Utilisateur user) {
    _afficherInfo('Suppression de ${user.nom}');
  }
}

// ============= MODÈLES DE DONNÉES =============
class Utilisateur {
  final String id;
  final String nom;
  final String email;
  final String role;
  final List<String> droits;
  String statut;
  final DateTime derniereConnexion;

  Utilisateur({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    required this.droits,
    required this.statut,
    required this.derniereConnexion,
  });
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