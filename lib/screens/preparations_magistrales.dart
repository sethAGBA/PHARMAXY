// screens/preparations_magistrales.dart
import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'package:intl/intl.dart';
import '../models/preparation_magistrale.dart';
import '../services/local_database_service.dart';

class PreparationsMagistralesScreen extends StatefulWidget {
  const PreparationsMagistralesScreen({super.key});

  @override
  State<PreparationsMagistralesScreen> createState() =>
      _PreparationsMagistralesScreenState();
}

class _PreparationsMagistralesScreenState
    extends State<PreparationsMagistralesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  String _searchQuery = '';
  String _selectedFormule = 'Toutes';
  PreparationMagistrale? _formuleSelectionnee;
  List<PreparationMagistrale> _formules = [];
  bool _loadingFormules = true;
  String? _formulesError;

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
    _loadFormules();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadFormules() async {
    setState(() {
      _loadingFormules = true;
      _formulesError = null;
    });
    try {
      await LocalDatabaseService.instance.init();
      final formules = await LocalDatabaseService.instance
          .getPreparationsMagistrales();
      if (!mounted) return;
      setState(() {
        _formules = formules;
        _loadingFormules = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingFormules = false;
        _formulesError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);
    final accent = Colors.teal;

    if (_loadingFormules) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_formulesError != null) {
      return Center(
        child: Text(
          'Erreur: $_formulesError',
          style: TextStyle(color: palette.text),
        ),
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
            _buildFiltres(palette, accent),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildBibliotheque(palette, accent)),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 3,
                    child: _formuleSelectionnee == null
                        ? _buildAccueil()
                        : _buildDetailFormule(
                            _formuleSelectionnee!,
                            palette,
                            accent,
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

  Widget _buildHeader(ThemeColors palette, Color accent) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.science, color: accent, size: 40),
            const SizedBox(width: 16),
            Text(
              'Préparations magistrales',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: palette.text,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        Text(
          'Formules • Dosages • Fabrication • Étiquetage • Traçabilité',
          style: TextStyle(fontSize: 16, color: palette.subText),
        ),
      ],
    );
  }

  Widget _buildFiltres(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Rechercher une formule...',
                  prefixIcon: const Icon(Icons.search),
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
            DropdownButton<String>(
              value: _selectedFormule,
              items: [
                'Toutes',
                'Sirop',
                'Crème',
                'Gélule',
                'Pommade',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _selectedFormule = v!),
              style: TextStyle(color: palette.text),
              dropdownColor: palette.isDark ? Colors.grey[900] : Colors.white,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () => _ouvrirDialogFormule(),
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle formule'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBibliotheque(ThemeColors palette, Color accent) {
    final filtered = _formules
        .where(
          (f) =>
              f.nom.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              (_selectedFormule == 'Toutes' || f.categorie == _selectedFormule),
        )
        .toList();

    return _card(
      palette,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.library_books, color: accent, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Bibliothèque de formules',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: palette.text,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final formule = filtered[index];
                final isSelected = _formuleSelectionnee == formule;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? accent.withOpacity(0.15) : palette.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? accent : palette.divider,
                    ),
                  ),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.science, color: Colors.white),
                    ),
                    title: Text(
                      formule.nom,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: palette.text,
                      ),
                    ),
                    subtitle: Text(
                      '${formule.categorie} • ${formule.quantiteTotale}${formule.unite}',
                      style: TextStyle(color: palette.subText),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () =>
                              _ouvrirDialogFormule(existing: formule),
                          icon: const Icon(Icons.edit, size: 20),
                          tooltip: 'Modifier',
                        ),
                        IconButton(
                          onPressed: () => _confirmerSuppression(formule),
                          icon: const Icon(Icons.delete, size: 20),
                          tooltip: 'Supprimer',
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => setState(() => _formuleSelectionnee = formule),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccueil() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.science_outlined, size: 120, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Sélectionnez une formule dans la bibliothèque',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'ou créez-en une nouvelle',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailFormule(
    PreparationMagistrale formule,
    ThemeColors palette,
    Color accent,
  ) {
    return _card(
      palette,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.science,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formule.nom,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: palette.text,
                        ),
                      ),
                      Text(
                        '${formule.categorie} • ${formule.quantiteTotale}${formule.unite}',
                        style: TextStyle(fontSize: 16, color: palette.subText),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Démarrer préparation'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // === COMPOSANTS ===
            _section('Composants nécessaires', Icons.inventory_2, palette),
            const SizedBox(height: 16),
            ...formule.composants.map((c) => _composantRow(c, palette)),

            const SizedBox(height: 32),

            // === INSTRUCTIONS ===
            _section(
              'Instructions de fabrication',
              Icons.format_list_numbered,
              palette,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: palette.isDark ? Colors.grey[850] : Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                formule.instructions,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: palette.text,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // === INFOS COMPLÉMENTAIRES ===
            Row(
              children: [
                Expanded(
                  child: _infoBox(
                    'Conservation',
                    formule.conservation,
                    Icons.info_outline,
                    Colors.blue,
                    palette,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoBox(
                    'Posologie',
                    formule.posologie,
                    Icons.medication,
                    Colors.green,
                    palette,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            _section('Coût & Prix', Icons.attach_money, palette),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _infoBox(
                    'Coût total',
                    '${NumberFormat('#,##0', 'fr_FR').format(formule.cout)} FCFA',
                    Icons.shopping_cart,
                    Colors.orange,
                    palette,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoBox(
                    'Prix de vente',
                    '${NumberFormat('#,##0', 'fr_FR').format(formule.prix)} FCFA',
                    Icons.sell,
                    Colors.teal,
                    palette,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _infoBox(
                    'Marge',
                    '${formule.margePourcentage.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    Colors.purple,
                    palette,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _composantRow(ComposantPreparation c, ThemeColors palette) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.grey[850] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: Colors.teal),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              c.nom,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: palette.text,
              ),
            ),
          ),
          Text(
            '${c.quantite} ${c.unite}',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
          ),
        ],
      ),
    );
  }

  Widget _infoBox(
    String label,
    String value,
    IconData icon,
    Color color,
    ThemeColors palette,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: palette.subText)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: palette.text,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _ouvrirDialogFormule({PreparationMagistrale? existing}) async {
    final formKey = GlobalKey<FormState>();
    final nomCtrl = TextEditingController(text: existing?.nom ?? '');
    final categorieCtrl = TextEditingController(
      text: existing?.categorie ?? 'Sirop',
    );
    final quantiteCtrl = TextEditingController(
      text: existing != null ? existing.quantiteTotale.toString() : '',
    );
    final uniteCtrl = TextEditingController(text: existing?.unite ?? 'ml');
    final instructionsCtrl = TextEditingController(
      text: existing?.instructions ?? '',
    );
    final conservationCtrl = TextEditingController(
      text: existing?.conservation ?? '',
    );
    final posologieCtrl = TextEditingController(
      text: existing?.posologie ?? '',
    );
    final coutCtrl = TextEditingController(
      text: existing != null ? existing.cout.toStringAsFixed(0) : '',
    );
    final prixCtrl = TextEditingController(
      text: existing != null ? existing.prix.toStringAsFixed(0) : '',
    );
    String statut = existing?.statut ?? 'Validée';

    final composantInputs = <Map<String, TextEditingController>>[
      for (final c in existing?.composants ?? const <ComposantPreparation>[])
        {
          'nom': TextEditingController(text: c.nom),
          'quantite': TextEditingController(text: c.quantite.toString()),
          'unite': TextEditingController(text: c.unite),
        },
    ];
    if (composantInputs.isEmpty) {
      composantInputs.add({
        'nom': TextEditingController(),
        'quantite': TextEditingController(),
        'unite': TextEditingController(),
      });
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final palette = ThemeColors.from(context);
        return StatefulBuilder(
          builder: (context, setLocal) {
            return AlertDialog(
              title: Text(
                existing == null ? 'Nouvelle formule' : 'Modifier formule',
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 520,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nomCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nom formule',
                          ),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Requis' : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: categorieCtrl.text.isEmpty
                              ? 'Sirop'
                              : categorieCtrl.text,
                          decoration: const InputDecoration(
                            labelText: 'Catégorie',
                          ),
                          items:
                              const [
                                    'Sirop',
                                    'Crème',
                                    'Gélule',
                                    'Pommade',
                                    'Solution',
                                    'Autre',
                                  ]
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c),
                                    ),
                                  )
                                  .toList(),
                          onChanged: (v) => categorieCtrl.text = v ?? 'Sirop',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: quantiteCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Quantité totale',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) => int.tryParse(v ?? '') == null
                                    ? 'Nombre'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: uniteCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Unité',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              'Composants',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: palette.text,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {
                                composantInputs.add({
                                  'nom': TextEditingController(),
                                  'quantite': TextEditingController(),
                                  'unite': TextEditingController(),
                                });
                                setLocal(() {});
                              },
                              icon: const Icon(Icons.add),
                              tooltip: 'Ajouter composant',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...composantInputs.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final ctrls = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: TextFormField(
                                    controller: ctrls['nom'],
                                    decoration: const InputDecoration(
                                      labelText: 'Nom',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: ctrls['quantite'],
                                    decoration: const InputDecoration(
                                      labelText: 'Qté',
                                    ),
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: ctrls['unite'],
                                    decoration: const InputDecoration(
                                      labelText: 'Unité',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: composantInputs.length <= 1
                                      ? null
                                      : () {
                                          composantInputs.removeAt(idx);
                                          setLocal(() {});
                                        },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: instructionsCtrl,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Instructions fabrication',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: conservationCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Conservation',
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: posologieCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Posologie',
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: coutCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Coût total (FCFA)',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    double.tryParse(v ?? '') == null
                                    ? 'Nombre'
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: prixCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Prix de vente (FCFA)',
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    double.tryParse(v ?? '') == null
                                    ? 'Nombre'
                                    : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: statut,
                          decoration: const InputDecoration(
                            labelText: 'Statut',
                          ),
                          items: const ['Validée', 'En cours', 'Archivée']
                              .map(
                                (s) =>
                                    DropdownMenuItem(value: s, child: Text(s)),
                              )
                              .toList(),
                          onChanged: (v) => setLocal(() {
                            statut = v ?? statut;
                          }),
                        ),
                      ],
                    ),
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
    final now = DateTime.now();
    final composants = composantInputs
        .map((ctrls) {
          final nom = ctrls['nom']!.text.trim();
          final qty = double.tryParse(ctrls['quantite']!.text.trim()) ?? 0;
          final unite = ctrls['unite']!.text.trim();
          if (nom.isEmpty) return null;
          return ComposantPreparation(nom: nom, quantite: qty, unite: unite);
        })
        .whereType<ComposantPreparation>()
        .toList();

    final formule =
        (existing ??
                PreparationMagistrale(
                  id: 'FOR-${now.microsecondsSinceEpoch}',
                  nom: '',
                  categorie: '',
                  quantiteTotale: 0,
                  unite: '',
                  composants: const [],
                  instructions: '',
                  conservation: '',
                  posologie: '',
                  statut: 'Validée',
                  cout: 0,
                  prix: 0,
                  createdAt: now,
                ))
            .copyWith(
              nom: nomCtrl.text.trim(),
              categorie: categorieCtrl.text.trim(),
              quantiteTotale: int.tryParse(quantiteCtrl.text.trim()) ?? 0,
              unite: uniteCtrl.text.trim(),
              composants: composants,
              instructions: instructionsCtrl.text.trim(),
              conservation: conservationCtrl.text.trim(),
              posologie: posologieCtrl.text.trim(),
              statut: statut,
              cout: double.tryParse(coutCtrl.text.trim()) ?? 0,
              prix: double.tryParse(prixCtrl.text.trim()) ?? 0,
            );

    await LocalDatabaseService.instance.upsertPreparationMagistrale(formule);
    await _loadFormules();
    if (!mounted) return;
    setState(() => _formuleSelectionnee = formule);
  }

  Future<void> _confirmerSuppression(PreparationMagistrale formule) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la formule'),
        content: Text('Supprimer "${formule.nom}" ?'),
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
    await LocalDatabaseService.instance.deletePreparationMagistrale(formule.id);
    await _loadFormules();
    if (!mounted) return;
    if (_formuleSelectionnee?.id == formule.id) {
      setState(() => _formuleSelectionnee = null);
    }
  }

  Widget _section(String title, IconData icon, ThemeColors palette) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 28),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: palette.text,
          ),
        ),
      ],
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
