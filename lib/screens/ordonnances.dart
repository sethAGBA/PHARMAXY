// screens/ordonnances.dart
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/ordonnance_models.dart';

class OrdonnancesScreen extends StatefulWidget {
  const OrdonnancesScreen({super.key});

  @override
  State<OrdonnancesScreen> createState() => _OrdonnancesScreenState();
}

class _OrdonnancesScreenState extends State<OrdonnancesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController _scanController = TextEditingController();

  Patient? _selectedPatient;
  List<PrescribedDrug> _drugs = [];
  bool _isScanning = false;
  bool _teletransmissionDone = false;

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
    _scanController.dispose();
    super.dispose();
  }

  void _simulateScan() async {
    setState(() => _isScanning = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      // Demo scan disabled — do not inject hard-coded patient/drugs
      _selectedPatient = null;
      _drugs = [];
      _isScanning = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Scan simulé désactivé — utilisez la fonctionnalité réelle')));
  }

  void _teletransmit() async {
    setState(() => _teletransmissionDone = false);
    await Future.delayed(const Duration(milliseconds: 1600));
    setState(() => _teletransmissionDone = true);
  }

  double get _total => _drugs.fold(0, (sum, d) => sum + d.price);
  double get _ssCoverage => _total * 0.65;
  double get _mutuelleCoverage => _total * 0.30;
  double get _patientAmount => _total - _ssCoverage - _mutuelleCoverage;

  @override
  Widget build(BuildContext context) {
    final palette = ThemeColors.from(context);

    return FadeTransition(
      opacity: _fade,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(palette),
                const SizedBox(height: 28),
                _buildScanCard(palette),
                const SizedBox(height: 28),

                // Contenu principal
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // === COLONNE GAUCHE : Patient + Médicaments ===
                      Expanded(
                        flex: 3,
                        child: _drugs.isEmpty
                            ? const Center(child: Text('Aucune ordonnance scannée', style: TextStyle(fontSize: 18, color: Colors.grey)))
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    _buildPatientCard(_selectedPatient!, palette),
                                    const SizedBox(height: 20),
                                    _buildDrugList(palette),
                                  ],
                                ),
                              ),
                      ),

                      const SizedBox(width: 28),

                      // === COLONNE DROITE : Tiers payant + Télétransmission + Validation ===
                      Expanded(
                        flex: 2,
                        child: _drugs.isNotEmpty
                            ? SingleChildScrollView(
                                child: _buildRightColumn(palette),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // === HEADER (inchangé, parfait comme ça) ===
  Widget _buildHeader(ThemeColors palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dispensation d\'ordonnance',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: palette.text, letterSpacing: 1.2),
        ),
        Text(
          'Scan • Analyse • Substitution • Tiers payant • Télétransmission',
          style: TextStyle(fontSize: 16, color: palette.subText),
        ),
      ],
    );
  }

  // === SCAN CARD (centré, élégant) ===
  Widget _buildScanCard(ThemeColors palette) {
    return Align(
      alignment: Alignment.center,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: _card(
          palette,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.teal, size: 36),
                    const SizedBox(width: 16),
                    Text('Scanner l\'ordonnance', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: palette.text)),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _scanController,
                        enabled: !_isScanning,
                        decoration: InputDecoration(
                          hintText: 'Code ordonnance • QR Code • NIR patient',
                          prefixIcon: const Icon(Icons.document_scanner),
                          filled: true,
                          fillColor: palette.isDark ? Colors.grey[800] : Colors.grey[200],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _isScanning ? null : _simulateScan,
                      icon: _isScanning
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Icon(Icons.camera_alt, size: 28),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(_isScanning ? 'Analyse...' : 'SCAN', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 22),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildPatientCard(Patient patient, ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(radius: 36, backgroundColor: Colors.teal, child: const Icon(Icons.person, color: Colors.white, size: 40)),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(patient.name, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: palette.text)),
                const SizedBox(height: 4),
                Text('NIR : ${patient.nir}', style: TextStyle(color: palette.subText, fontSize: 14)),
                Text('Mutuelle : ${patient.mutuelle}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrugList(ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Médicaments prescrits (${_drugs.length})', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: palette.text)),
            const SizedBox(height: 20),
            ..._drugs.map((drug) => _drugItem(drug, palette)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _drugItem(PrescribedDrug drug, ThemeColors palette) {
    final (color, icon) = switch (drug.interaction) {
      InteractionLevel.danger => (Colors.red, Icons.dangerous),
      InteractionLevel.warning => (Colors.amber, Icons.warning_amber_rounded),
      _ => (Colors.green, Icons.check_circle),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.isDark ? Colors.grey[800]!.withOpacity(0.6) : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(drug.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: palette.text)),
                const SizedBox(height: 4),
                Text(drug.dosage, style: TextStyle(fontSize: 13, color: palette.subText)),
                if (drug.generic)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                    child: const Text('Générique disponible', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
              ],
            ),
          ),
          Text('${drug.price} F', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.teal)),
        ],
      ),
    );
  }

  Widget _buildRightColumn(ThemeColors palette) {
    return Column(
      children: [
        _buildTiersPayantCard(palette),
        const SizedBox(height: 20),
        _buildTeletransmissionCard(palette),
        const SizedBox(height: 20),
        _buildValidationButton(palette),
      ],
    );
  }

  Widget _buildTiersPayantCard(ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tiers Payant', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 24),
            _coverageRow('Sécurité Sociale', _ssCoverage, Colors.blue, palette),
            _coverageRow('Mutuelle', _mutuelleCoverage, Colors.purple, palette),
            _coverageRow('Reste à charge', _patientAmount, Colors.orange, palette),
            const Divider(height: 40, thickness: 1),
            _totalRow('Total ordonnance', _total.toInt(), Colors.teal.shade600),
            _totalRow('À payer par le patient', _patientAmount.toInt(), Colors.orange, isBig: true),
          ],
        ),
      ),
    );
  }

  Widget _coverageRow(String label, double amount, Color color, ThemeColors palette) {
    final percent = _total == 0 ? 0.0 : (amount / _total) * 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text('${percent.toStringAsFixed(0)}%')]),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: percent / 100, backgroundColor: palette.divider, valueColor: AlwaysStoppedAnimation(color), minHeight: 8),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _totalRow(String label, int amount, Color color, {bool isBig = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isBig ? 18 : 16, fontWeight: isBig ? FontWeight.bold : FontWeight.w500)),
          Text('$amount FCFA', style: TextStyle(fontSize: isBig ? 28 : 20, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildTeletransmissionCard(ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _teletransmissionDone
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.green)),
                child: const Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 36), SizedBox(width: 16), Text('Télétransmission réussie !', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
              )
            : ElevatedButton.icon(
                onPressed: _teletransmit,
                icon: const Icon(Icons.send, size: 26),
                label: const Text('Envoyer à SESAM-Vitale', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, padding: const EdgeInsets.all(20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
              ),
      ),
    );
  }

  Widget _buildValidationButton(ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton.icon(
            onPressed: _drugs.isEmpty ? null : () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ordonnance délivrée avec succès !'), backgroundColor: Colors.green)),
            icon: const Icon(Icons.check_circle_outline, size: 32),
            label: const Text('VALIDER & DÉLIVRER', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.grey[400],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 8,
            ),
          ),
        ),
      ),
    );
  }

  // === CARD UNIVERSELLE (ta fonction, juste un peu plus propre) ===
  Widget _card(ThemeColors palette, {required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(palette.isDark ? 0.4 : 0.08), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: child,
    );
  }
}