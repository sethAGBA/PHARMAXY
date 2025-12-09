import 'package:flutter/material.dart';

import '../app_theme.dart';

class ConseilPharmaScreen extends StatefulWidget {
  const ConseilPharmaScreen({super.key});

  @override
  State<ConseilPharmaScreen> createState() => _ConseilPharmaScreenState();
}

class _ConseilPharmaScreenState extends State<ConseilPharmaScreen> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  Animation<double> _fade = const AlwaysStoppedAnimation<double>(1);
  final TextEditingController _searchController = TextEditingController();
  String _profil = 'Tous';

  final List<_Medication> _base = [
    _Medication(
      nom: 'Doliprane 1000mg',
      dci: 'Paracétamol',
      indication: 'Douleur modérée, fièvre',
      profil: 'Adulte',
      posologie: '1 cp toutes les 6h (max 3g/j)',
      interactions: ['Warfarine (surveillance INR)', 'Alcool (hépatotoxicité)'],
      conseils: ['Prendre après repas', 'Éviter alcool', 'Hydratation conseillée'],
    ),
    _Medication(
      nom: 'Amoxicilline 1g',
      dci: 'Amoxicilline',
      indication: 'Infections ORL, pulmonaires',
      profil: 'Adulte',
      posologie: '1g matin et soir pendant 7 jours',
      interactions: ['Méthotrexate (toxicité ↑)', 'Anticoagulants oraux (INR)'],
      conseils: ['Prendre au début du repas', 'Poursuivre le traitement 7 jours', 'Surveiller réactions allergiques'],
    ),
    _Medication(
      nom: 'Ibuprofène 400mg',
      dci: 'Ibuprofène',
      indication: 'Douleurs et inflammations',
      profil: 'Adulte',
      posologie: '1 cp toutes les 8h si besoin (max 1200mg/j)',
      interactions: ['AVK/DOAC (risque hémorragique)', 'AINS/aspirine (irritation GI)'],
      conseils: ['Prendre pendant un repas', 'Éviter grossesse T3', 'Hydratation suffisante'],
    ),
    _Medication(
      nom: 'Cétirizine 10mg',
      dci: 'Cétirizine',
      indication: 'Allergies, rhinite',
      profil: 'Adulte/Enfant >6 ans',
      posologie: '1 cp le soir, 5mg chez l\'enfant',
      interactions: ['Alcool (somnolence)', 'Sédatifs (effet additif)'],
      conseils: ['Prendre le soir si somnolence', 'Éviter conduire si effets'],
    ),
  ];

  final List<_Interaction> _interactions = const [
    _Interaction(medicaments: 'Paracétamol + Alcool', risque: 'Hépatotoxicité', action: 'Éviter, informer patient'),
    _Interaction(medicaments: 'Ibuprofène + AVK', risque: 'Hémorragie', action: 'Proscrire, proposer paracétamol'),
    _Interaction(medicaments: 'Amoxicilline + Méthotrexate', risque: 'Toxicité MTX', action: 'Surveiller, adapter dose MTX'),
    _Interaction(medicaments: 'Antihistaminiques + Alcool', risque: 'Somnolence', action: 'Conseil d\'éviter la conduite'),
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

  List<_Medication> get _filtered {
    return _base.where((med) {
      final query = _searchController.text.toLowerCase();
      final matchesText = med.nom.toLowerCase().contains(query) || med.dci.toLowerCase().contains(query) || med.indication.toLowerCase().contains(query);
      final matchesProfil = _profil == 'Tous' || med.profil.contains(_profil);
      return matchesText && matchesProfil;
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
                    _buildQuickActions(palette, accent),
                    const SizedBox(height: 16),
                    _buildSearchFilters(palette, accent),
                    const SizedBox(height: 16),
                    _buildMedicationLibrary(palette, accent),
                    const SizedBox(height: 16),
                    _buildInteractions(palette, accent),
                    const SizedBox(height: 16),
                    _buildPosologyAndConseils(palette, accent),
                    const SizedBox(height: 16),
                    _buildFiches(palette, accent),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: accent.withOpacity(0.12), shape: BoxShape.circle),
              child: Icon(Icons.medical_information, color: accent, size: 28),
            ),
            const SizedBox(width: 12),
            Text('Conseil pharmaceutique', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: palette.text)),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf, size: 18),
              label: const Text('Exporter PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: accent.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Base médicaments • Interactions • Posologies • Conseils patient',
          style: TextStyle(color: palette.subText),
        ),
      ],
    );
  }

  Widget _buildQuickActions(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _actionChip(Icons.print, 'Imprimer fiche patient', accent, palette),
            _actionChip(Icons.science, 'Vérifier interactions', Colors.orange, palette),
            _actionChip(Icons.medical_services, 'Posologies pédiatriques', Colors.indigo, palette),
            _actionChip(Icons.tips_and_updates, 'Conseils personnalisés', Colors.green, palette),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(IconData icon, String label, Color color, ThemeColors palette) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(palette.isDark ? 0.15 : 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: palette.text, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchFilters(ThemeColors palette, Color accent) {
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
              width: 340,
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Rechercher un médicament, DCI, indication...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: palette.isDark ? Colors.grey[850] : Colors.grey[100],
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            SizedBox(
              width: 200,
              child: DropdownButtonFormField<String>(
                value: _profil,
                items: const ['Tous', 'Adulte', 'Enfant', 'Grossesse', 'Allaitement']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _profil = v ?? 'Tous'),
                decoration: InputDecoration(
                  labelText: 'Profil patient',
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
                  Icon(Icons.lightbulb, color: accent, size: 18),
                  const SizedBox(width: 8),
                  Text('${_filtered.length} résultats', style: TextStyle(color: palette.text, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationLibrary(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medication_liquid, color: accent),
                const SizedBox(width: 8),
                Text('Base médicaments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text)),
              ],
            ),
            const SizedBox(height: 12),
            Column(
              children: _filtered.map((med) => _medCard(med, palette, accent)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _medCard(_Medication med, ThemeColors palette, Color accent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.divider),
        boxShadow: [
          BoxShadow(
            color: palette.isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.08),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Icon(Icons.healing, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.nom, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text)),
                    Text('${med.dci} • ${med.indication}', style: TextStyle(color: palette.subText)),
                  ],
                ),
              ),
              _pillChip(med.profil, accent, palette),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.schedule, size: 18, color: palette.subText),
              const SizedBox(width: 6),
              Expanded(child: Text('Posologie: ${med.posologie}', style: TextStyle(color: palette.text))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
              const SizedBox(width: 6),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: med.interactions
                      .map((i) => Chip(
                            label: Text(i, style: TextStyle(color: palette.text)),
                            backgroundColor: palette.isDark ? Colors.grey[800] : Colors.grey[100],
                          ))
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.tips_and_updates, size: 18, color: Colors.green),
              const SizedBox(width: 6),
              Expanded(child: Text(med.conseils.join(' • '), style: TextStyle(color: palette.text))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.print),
                label: const Text('Fiche patient'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.science_outlined),
                label: const Text('Interactions'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pillChip(String label, Color color, ThemeColors palette) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: palette.text, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInteractions(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sync_problem, color: Colors.orange),
                const SizedBox(width: 8),
                Text('Interactions critiques', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text)),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: 28,
                columns: [
                  DataColumn(label: Text('Association', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
                  DataColumn(label: Text('Risque', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
                  DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, color: palette.text))),
                ],
                rows: _interactions
                    .map(
                      (i) => DataRow(
                        cells: [
                          DataCell(Text(i.medicaments, style: TextStyle(color: palette.text))),
                          DataCell(Text(i.risque, style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600))),
                          DataCell(Text(i.action, style: TextStyle(color: palette.text))),
                        ],
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPosologyAndConseils(ThemeColors palette, Color accent) {
    final cards = [
      _infoCard('Douleur légère', 'Paracétamol 500mg toutes les 6h, max 3g/j', Icons.vaccines, accent),
      _infoCard('Enfant >6 ans', 'Cétirizine 5mg le soir, surveiller somnolence', Icons.child_care, Colors.indigo),
      _infoCard('Grossesse', 'Paracétamol privilégié, éviter AINS T3', Icons.pregnant_woman, Colors.pink),
      _infoCard('Allergies', 'Prévenir antihistaminiques sédatifs + alcool', Icons.warning, Colors.orange),
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
                Icon(Icons.menu_book, color: accent),
                const SizedBox(width: 8),
                Text('Posologies & Conseils', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text)),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards,
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String title, String content, IconData icon, Color color) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color))),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFiches(ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.picture_as_pdf, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Fiches patient imprimables', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text)),
                  const SizedBox(height: 6),
                  Text('Générez une fiche avec posologie, conseils, interactions et signatures.', style: TextStyle(color: palette.subText)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.print),
              label: const Text('Imprimer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
            color: palette.isDark ? Colors.black.withOpacity(0.25) : Colors.grey.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Medication {
  final String nom;
  final String dci;
  final String indication;
  final String profil;
  final String posologie;
  final List<String> interactions;
  final List<String> conseils;

  const _Medication({
    required this.nom,
    required this.dci,
    required this.indication,
    required this.profil,
    required this.posologie,
    required this.interactions,
    required this.conseils,
  });
}

class _Interaction {
  final String medicaments;
  final String risque;
  final String action;

  const _Interaction({required this.medicaments, required this.risque, required this.action});
}
