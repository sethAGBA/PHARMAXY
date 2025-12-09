// screens/preparations_magistrales.dart
import 'package:flutter/material.dart';
import '../app_theme.dart';
import 'package:intl/intl.dart';

class PreparationsMagistralesScreen extends StatefulWidget {
  const PreparationsMagistralesScreen({super.key});

  @override
  State<PreparationsMagistralesScreen> createState() => _PreparationsMagistralesScreenState();
}

class _PreparationsMagistralesScreenState extends State<PreparationsMagistralesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  String _searchQuery = '';
  String _selectedFormule = 'Toutes';
  Formula? _formuleSelectionnee;

  final List<Formula> _formules = [
    Formula(
      nom: 'Sirop antitussif maison',
      categorie: 'Sirop',
      quantiteTotale: 200,
      unite: 'ml',
      composants: [
        Composant(nom: 'Codéine phosphate', quantite: 0.2, unite: 'g'),
        Composant(nom: 'Sirop simple', quantite: 180, unite: 'ml'),
        Composant(nom: 'Eau purifiée', quantite: 20, unite: 'ml'),
        Composant(nom: 'Arôme cerise', quantite: 1, unite: 'ml'),
      ],
      instructions: 'Dissoudre la codéine dans 10 ml d\'eau chaude, ajouter au sirop simple, compléter avec eau purifiée, ajouter arôme, homogénéiser.',
      conservation: '15 jours à température ambiante',
      posologie: '5 ml × 3/jour',
    ),
    Formula(
      nom: 'Crème émolliente 20%',
      categorie: 'Crème',
      quantiteTotale: 100,
      unite: 'g',
      composants: [
        Composant(nom: 'Vaseline', quantite: 30, unite: 'g'),
        Composant(nom: 'Lanoline', quantite: 10, unite: 'g'),
        Composant(nom: 'Paraffine liquide', quantite: 40, unite: 'g'),
        Composant(nom: 'Cire émulsifiante', quantite: 15, unite: 'g'),
        Composant(nom: 'Eau purifiée', quantite: 5, unite: 'g'),
      ],
      instructions: 'Faire fondre la phase grasse au bain-marie, incorporer l\'eau tiède progressivement en agitant, laisser refroidir en remuant.',
      conservation: '3 mois au réfrigérateur',
      posologie: 'Application 2 fois par jour',
    ),
  ];

  final List<Preparation> _preparations = [
    Preparation(id: 'PRP-2025-187', date: DateTime(2025, 12, 9), formule: 'Sirop antitussif maison', quantite: 200, preparateur: 'Marie K.', statut: 'Validée'),
    Preparation(id: 'PRP-2025-186', date: DateTime(2025, 12, 8), formule: 'Crème émolliente 20%', quantite: 100, preparateur: 'Jean A.', statut: 'En cours'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
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
            _buildFiltres(palette, accent),
            const SizedBox(height: 24),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildBibliotheque(palette, accent)),
                  const SizedBox(width: 24),
                  Expanded(flex: 3, child: _formuleSelectionnee == null ? _buildAccueil() : _buildDetailFormule(_formuleSelectionnee!, palette, accent)),
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
            Text('Préparations magistrales', style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold, color: palette.text, letterSpacing: 1.2)),
          ],
        ),
        Text('Formules • Dosages • Fabrication • Étiquetage • Traçabilité', style: TextStyle(fontSize: 16, color: palette.subText)),
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
                  fillColor: palette.isDark ? Colors.grey[850] : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _selectedFormule,
              items: ['Toutes', 'Sirop', 'Crème', 'Gélule', 'Pommade'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _selectedFormule = v!),
              style: TextStyle(color: palette.text),
              dropdownColor: palette.isDark ? Colors.grey[900] : Colors.white,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add),
              label: const Text('Nouvelle formule'),
              style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.all(16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBibliotheque(ThemeColors palette, Color accent) {
    final filtered = _formules.where((f) => f.nom.toLowerCase().contains(_searchQuery.toLowerCase()) && (_selectedFormule == 'Toutes' || f.categorie == _selectedFormule)).toList();

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
                Text('Bibliothèque de formules', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: palette.text)),
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
                    border: Border.all(color: isSelected ? accent : palette.divider),
                  ),
                  child: ListTile(
                    leading: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: accent.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.science, color: Colors.white)),
                    title: Text(formule.nom, style: TextStyle(fontWeight: FontWeight.bold, color: palette.text)),
                    subtitle: Text('${formule.categorie} • ${formule.quantiteTotale}${formule.unite}', style: TextStyle(color: palette.subText)),
                    trailing: const Icon(Icons.chevron_right),
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
          Text('Sélectionnez une formule dans la bibliothèque', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          const SizedBox(height: 8),
          Text('ou créez-en une nouvelle', style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildDetailFormule(Formula formule, ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(16)), child: const Icon(Icons.science, color: Colors.white, size: 32)),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(formule.nom, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: palette.text)),
                      Text('${formule.categorie} • ${formule.quantiteTotale}${formule.unite}', style: TextStyle(fontSize: 16, color: palette.subText)),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Démarrer préparation'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16)),
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
            _section('Instructions de fabrication', Icons.format_list_numbered, palette),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: palette.isDark ? Colors.grey[850] : Colors.grey[50], borderRadius: BorderRadius.circular(16)),
              child: Text(formule.instructions, style: TextStyle(fontSize: 15, height: 1.6, color: palette.text)),
            ),

            const SizedBox(height: 32),

            // === INFOS COMPLÉMENTAIRES ===
            Row(
              children: [
                Expanded(child: _infoBox('Conservation', formule.conservation, Icons.info_outline, Colors.blue, palette)),
                const SizedBox(width: 16),
                Expanded(child: _infoBox('Posologie', formule.posologie, Icons.medication, Colors.green, palette)),
              ],
            ),

            const SizedBox(height: 32),

            // === TRAÇABILITÉ RÉCENTE ===
            _section('Dernières préparations', Icons.history, palette),
            const SizedBox(height: 16),
            ..._preparations.where((p) => p.formule == formule.nom).map((p) => _prepaRow(p, palette, accent)),
          ],
        ),
      ),
    );
  }

  Widget _composantRow(Composant c, ThemeColors palette) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: palette.isDark ? Colors.grey[850] : Colors.grey[50], borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: Colors.teal),
          const SizedBox(width: 16),
          Expanded(child: Text(c.nom, style: TextStyle(fontWeight: FontWeight.w600, color: palette.text))),
          Text('${c.quantite} ${c.unite}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
        ],
      ),
    );
  }

  Widget _infoBox(String label, String value, IconData icon, Color color, ThemeColors palette) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, color: color), const SizedBox(width: 8), Text(label, style: TextStyle(color: palette.subText))]),
          const SizedBox(height: 12),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text)),
        ],
      ),
    );
  }

  Widget _prepaRow(Preparation p, ThemeColors palette, Color accent) {
    final color = p.statut == 'Validée' ? Colors.green : Colors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: palette.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Row(
        children: [
          Icon(p.statut == 'Validée' ? Icons.check_circle : Icons.pending, color: color),
          const SizedBox(width: 16),
          Expanded(child: Text(p.id, style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
          Text(DateFormat('dd/MM/yyyy').format(p.date), style: TextStyle(color: palette.subText)),
          const SizedBox(width: 20),
          Text(p.preparateur, style: TextStyle(color: accent, fontWeight: FontWeight.w600)),
          const Spacer(),
          Text('${p.quantite} ml', style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _section(String title, IconData icon, ThemeColors palette) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 28),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: palette.text)),
      ],
    );
  }

  Widget _card(ThemeColors palette, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(palette.isDark ? 0.4 : 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }
}

// === MODÈLES ===
class Formula {
  final String nom, categorie, conservation, posologie, instructions;
  final int quantiteTotale;
  final String unite;
  final List<Composant> composants;
  const Formula({required this.nom, required this.categorie, required this.quantiteTotale, required this.unite, required this.composants, required this.instructions, required this.conservation, required this.posologie});
}

class Composant {
  final String nom, unite;
  final double quantite;
  const Composant({required this.nom, required this.quantite, required this.unite});
}

class Preparation {
  final String id, formule, preparateur, statut;
  final DateTime date;
  final int quantite;
  const Preparation({required this.id, required this.date, required this.formule, required this.quantite, required this.preparateur, required this.statut});
}