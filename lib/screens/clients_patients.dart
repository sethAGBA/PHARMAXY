// screens/clients_patients.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../app_theme.dart';
import '../services/local_database_service.dart';

class ClientsPatientsScreen extends StatefulWidget {
  const ClientsPatientsScreen({super.key});

  @override
  State<ClientsPatientsScreen> createState() => _ClientsPatientsScreenState();
}

class _ClientsPatientsScreenState extends State<ClientsPatientsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;

  final TextEditingController _searchController = TextEditingController();
  Patient? _selectedPatient;

  // DB-driven data
  List<Patient> _patients = [];
  bool _loading = true;
  String? _error;

  // Form controllers for registration
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _mutuelleController;
  late TextEditingController _nirController;
  late TextEditingController _dobController;
  late TextEditingController _allergiesController;
  late TextEditingController _contreIndicationsController;
  bool _showRegistrationForm = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _controller.forward();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _mutuelleController = TextEditingController();
    _nirController = TextEditingController();
    _dobController = TextEditingController();
    _allergiesController = TextEditingController();
    _contreIndicationsController = TextEditingController();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await LocalDatabaseService.instance.init();
      final db = LocalDatabaseService.instance.db;
      final rows = await db.query('patients', orderBy: 'name ASC');
      _patients = rows.map((r) => Patient.fromMap(r)).toList();
      setState(() {
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _mutuelleController.dispose();
    _nirController.dispose();
    _dobController.dispose();
    _allergiesController.dispose();
    _contreIndicationsController.dispose();
    super.dispose();
  }

  List<Patient> get _filteredPatients {
    final query = _searchController.text.toLowerCase();
    return _patients.where((p) {
      return p.nom.toLowerCase().contains(query) ||
          p.nir.contains(query) ||
          p.telephone.contains(query);
    }).toList();
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
            _buildHeader(palette),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: _buildSearchBar(palette)),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _showRegistrationForm = !_showRegistrationForm),
                  icon: const Icon(Icons.person_add),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_showRegistrationForm) ...[
              _buildRegistrationForm(palette),
              const SizedBox(height: 24),
            ],
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === LISTE DES PATIENTS ===
                  Expanded(
                    flex: 2,
                    child: _buildListePatients(palette, accent),
                  ),
                  const SizedBox(width: 24),
                  // === FICHE DÉTAILLÉE ===
                  Expanded(
                    flex: 3,
                    child: _selectedPatient == null
                        ? Center(child: Text('Sélectionnez un patient pour voir les détails', style: TextStyle(color: palette.subText, fontSize: 18)))
                        : _isEditMode
                            ? _buildEditPatientForm(_selectedPatient!, palette)
                            : _buildFichePatient(_selectedPatient!, palette, accent),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeColors palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Clients / Patients', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: palette.text, letterSpacing: 1.2)),
        Text('Fiches • Historique • Allergies • Fidélité • Relances', style: TextStyle(fontSize: 16, color: palette.subText)),
      ],
    );
  }

  Widget _buildSearchBar(ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Rechercher un patient (nom, NIR, téléphone...)',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: palette.isDark ? Colors.grey[850] : Colors.grey[100],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm(ThemeColors palette) {
    return _card(
      palette,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Enregistrer un nouveau patient', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: palette.text)),
              const SizedBox(height: 20),
              // Row 1: Nom, Téléphone, Email, Mutuelle
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildFormField('Nom', _nameController, palette),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFormField('Téléphone', _phoneController, palette),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFormField('Email', _emailController, palette),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFormField('Mutuelle', _mutuelleController, palette),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row 2: NIR, Date de naissance, Allergies
              Row(
                children: [
                  Expanded(
                    child: _buildFormField('NIR', _nirController, palette),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFormField('Date de naissance', _dobController, palette),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: _buildFormField('Allergies', _allergiesController, palette),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Row 3: Contre-indications + Save button
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildFormField('Contre-indications', _contreIndicationsController, palette),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: ElevatedButton.icon(
                      onPressed: _registerPatient,
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text('Enregistrer'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
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

  Widget _buildFormField(String label, TextEditingController controller, ThemeColors palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, color: palette.subText, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            filled: true,
            fillColor: palette.isDark ? Colors.grey[800] : Colors.grey[200],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          ),
        ),
      ],
    );
  }

  Future<void> _registerPatient() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final mutuelle = _mutuelleController.text.trim();
    final nir = _nirController.text.trim();
    final dob = _dobController.text.trim();
    final allergies = _allergiesController.text.trim();
    final contreIndications = _contreIndicationsController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer un nom'), backgroundColor: Colors.orange));
      return;
    }

    try {
      await LocalDatabaseService.instance.init();
      final db = LocalDatabaseService.instance.db;
      final patientId = 'PAT-${DateTime.now().millisecondsSinceEpoch}';
      await db.insert('patients', {
        'id': patientId,
        'name': name,
        'phone': phone,
        'email': email,
        'mutuelle': mutuelle,
        'nir': nir,
        'date_of_birth': dob,
        'allergies': allergies,
        'contraindications': contreIndications,
        'points': 0,
        'created_at': DateTime.now().toIso8601String(),
      });

      _nameController.clear();
      _phoneController.clear();
      _emailController.clear();
      _mutuelleController.clear();
      _nirController.clear();
      _dobController.clear();
      _allergiesController.clear();
      _contreIndicationsController.clear();
      setState(() => _showRegistrationForm = false);
      await _loadPatients();

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient enregistré avec succès'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _buildListePatients(ThemeColors palette, Color accent) {
    if (_loading) {
      return _card(
        palette,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return _card(
        palette,
        child: Center(child: Text('Erreur: $_error', style: TextStyle(color: Colors.red))),
      );
    }
    if (_filteredPatients.isEmpty) {
      return _card(
        palette,
        child: Center(child: Text('Aucun patient trouvé', style: TextStyle(color: palette.subText, fontSize: 18))),
      );
    }
    return _card(
      palette,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text('${_filteredPatients.length} patients trouvés', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.text)),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _filteredPatients.length,
              itemBuilder: (context, index) {
                final patient = _filteredPatients[index];
                final isSelected = _selectedPatient == patient;
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? accent.withOpacity(0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? accent : Colors.transparent, width: 2),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(backgroundColor: accent, child: Text(patient.nom[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    title: Text(patient.nom, style: TextStyle(fontWeight: FontWeight.bold, color: palette.text)),
                    subtitle: Text('NIR: ${patient.nir}', style: TextStyle(color: palette.subText)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (patient.renouvellementProche) Icon(Icons.notification_important, color: Colors.orange, size: 20),
                        if (patient.dateProchainVaccin != null) Icon(Icons.vaccines, color: Colors.blue, size: 20),
                        Text('${patient.pointsFidelite} pts', style: TextStyle(color: accent, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    onTap: () => setState(() => _selectedPatient = patient),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFichePatient(Patient patient, ThemeColors palette, Color accent) {
    return _card(
      palette,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(radius: 40, backgroundColor: accent, child: Text(patient.nom[0], style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold))),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(patient.nom, style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: palette.text)),
                    Text('NIR : ${patient.nir}', style: TextStyle(fontSize: 16, color: palette.subText)),
                    Text('Dernier achat : ${patient.dateDernierAchat}', style: TextStyle(color: palette.subText)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 32),

            // === INFORMATIONS PERSONNELLES ===
            _sectionTitle('Coordonnées', Icons.person, palette),
            const SizedBox(height: 12),
            _infoRow('Téléphone', patient.telephone, Icons.phone, palette),
            _infoRow('Email', patient.email, Icons.email, palette),
            _infoRow('Mutuelle', patient.mutuelle, Icons.health_and_safety, palette, color: Colors.green),
            const SizedBox(height: 24),

            // === SANTÉ ===
            _sectionTitle('Santé & Sécurité', Icons.local_hospital, palette),
            const SizedBox(height: 12),
            _infoRow('Allergies', patient.allergies, Icons.warning_amber_rounded, palette, color: patient.allergies != 'Non renseignées' && patient.allergies != 'Aucune' ? Colors.red : null),
            _infoRow('Contre-indications', patient.contreIndications, Icons.block, palette, color: patient.contreIndications != 'Non renseignées' && patient.contreIndications != 'Aucune' ? Colors.orange : null),
            const SizedBox(height: 24),

            // === FIDÉLITÉ & POINTS ===
            _sectionTitle('Programme fidélité', Icons.card_giftcard, palette),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: accent.withOpacity(0.4))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Points cumulés', style: TextStyle(color: palette.subText)),
                          Text('${patient.pointsFidelite}', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: accent)),
                        ],
                      ),
                      if (patient.pointsFidelite >= 200)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(30)),
                          child: const Text('-10% sur prochain achat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Add/Remove points buttons
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _updatePatientPoints(patient, 10),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('+10 points'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _updatePatientPoints(patient, 50),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('+50 points'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _updatePatientPoints(patient, -10),
                        icon: const Icon(Icons.remove, size: 18),
                        label: const Text('-10 points'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // === RELANCES ===
            _sectionTitle('Relances & notifications', Icons.notifications_active, palette),
            const SizedBox(height: 12),
            _relanceChip('✓ Patient actif', Colors.green),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _setReminder(patient, 'Renouvellement ordonnance'),
              icon: const Icon(Icons.add_alert, size: 18),
              label: const Text('Ajouter rappel: Renouvellement'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () => _setReminder(patient, 'Visite de contrôle'),
              icon: const Icon(Icons.add_alert, size: 18),
              label: const Text('Ajouter rappel: Visite'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 24),
            // === ACTIONS ===
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditMode = true),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Modifier'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditPatientForm(Patient patient, ThemeColors palette) {
    _nameController.text = patient.nom;
    _phoneController.text = patient.telephone;
    _emailController.text = patient.email;
    _mutuelleController.text = patient.mutuelle;
    _nirController.text = patient.nir;
    _allergiesController.text = patient.allergies;
    _contreIndicationsController.text = patient.contreIndications;

    return _card(
      palette,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifier le patient: ${patient.nom}', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: palette.text)),
            const SizedBox(height: 24),
            // Row 1: Nom, Téléphone, Email, Mutuelle
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildFormField('Nom', _nameController, palette),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormField('Téléphone', _phoneController, palette),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormField('Email', _emailController, palette),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFormField('Mutuelle', _mutuelleController, palette),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Row 2: NIR, Allergies
            Row(
              children: [
                Expanded(
                  child: _buildFormField('NIR', _nirController, palette),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: _buildFormField('Allergies', _allergiesController, palette),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Row 3: Contre-indications
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildFormField('Contre-indications', _contreIndicationsController, palette),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () => _updatePatient(patient),
                  icon: const Icon(Icons.check, size: 20),
                  label: const Text('Enregistrer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => setState(() => _isEditMode = false),
                  icon: const Icon(Icons.close, size: 20),
                  label: const Text('Annuler'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updatePatient(Patient patient) async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final email = _emailController.text.trim();
    final mutuelle = _mutuelleController.text.trim();
    final nir = _nirController.text.trim();
    final allergies = _allergiesController.text.trim();
    final contreIndications = _contreIndicationsController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Veuillez entrer un nom'), backgroundColor: Colors.orange));
      return;
    }

    try {
      await LocalDatabaseService.instance.init();
      final db = LocalDatabaseService.instance.db;
      await db.update('patients', {
        'name': name,
        'phone': phone,
        'email': email,
        'mutuelle': mutuelle,
        'nir': nir,
        'allergies': allergies,
        'contraindications': contreIndications,
      }, where: 'id = ?', whereArgs: [patient.id ?? '']);

      setState(() => _isEditMode = false);
      await _loadPatients();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Patient modifié avec succès'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _updatePatientPoints(Patient patient, int delta) async {
    try {
      await LocalDatabaseService.instance.init();
      final db = LocalDatabaseService.instance.db;
      final newPoints = max(0, patient.pointsFidelite + delta);
      await db.update('patients', {'points': newPoints}, where: 'id = ?', whereArgs: [patient.id ?? '']);
      await _loadPatients();
      if (mounted) {
        final msg = delta > 0 ? '+$delta' : '$delta';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Points mis à jour: $msg'), backgroundColor: Colors.teal));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _setReminder(Patient patient, String reminderType) async {
    try {
      await LocalDatabaseService.instance.init();
      final db = LocalDatabaseService.instance.db;
      final reminderId = 'REM-${DateTime.now().millisecondsSinceEpoch}';
      try {
        await db.insert('reminders', {
          'id': reminderId,
          'patient_id': patient.id ?? '',
          'type': reminderType,
          'date': DateTime.now().toIso8601String(),
          'status': 'active',
        });
      } catch (_) {
        // reminders table may not exist yet, create it
        await db.execute('''
          CREATE TABLE IF NOT EXISTS reminders (
            id TEXT PRIMARY KEY,
            patient_id TEXT,
            type TEXT,
            date TEXT,
            status TEXT
          )
        ''');
        await db.insert('reminders', {
          'id': reminderId,
          'patient_id': patient.id ?? '',
          'type': reminderType,
          'date': DateTime.now().toIso8601String(),
          'status': 'active',
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rappel ajouté: $reminderType'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Widget _sectionTitle(String title, IconData icon, ThemeColors palette) {
    return Row(
      children: [
        Icon(icon, color: Colors.teal, size: 26),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: palette.text)),
      ],
    );
  }

  Widget _infoRow(String label, String value, IconData icon, ThemeColors palette, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: color ?? palette.subText, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: palette.subText, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(child: Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color ?? palette.text))),
        ],
      ),
    );
  }

  Widget _relanceChip(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.4))),
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
        ],
      ),
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

class Patient {
  final String? id;
  final String nom, nir, telephone, email, mutuelle, allergies, contreIndications, dateDernierAchat;
  final int pointsFidelite;
  final String? dateProchainVaccin;
  final bool renouvellementProche;

  const Patient({
    this.id,
    required this.nom, required this.nir, required this.telephone, required this.email,
    required this.mutuelle, required this.pointsFidelite, required this.allergies,
    required this.contreIndications, required this.dateDernierAchat,
    this.dateProchainVaccin, required this.renouvellementProche,
  });

  factory Patient.fromMap(Map<String, dynamic> map) {
    final id = (map['id'] as String?) ?? '';
    final name = (map['name'] as String?) ?? '';
    final phone = (map['phone'] as String?) ?? '';
    final email = (map['email'] as String?) ?? '';
    final mutuelle = (map['mutuelle'] as String?) ?? '';
    final nir = (map['nir'] as String?) ?? '';
    final points = (map['points'] is int) ? map['points'] as int : int.tryParse('${map['points']}') ?? 0;
    final allergies = (map['allergies'] as String?) ?? 'Non renseignées';
    final contraindications = (map['contraindications'] as String?) ?? 'Non renseignées';
    final created = (map['created_at'] as String?) ?? '';
    String prettyDate;
    try {
      final dt = DateTime.parse(created);
      prettyDate = DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      prettyDate = created;
    }
    return Patient(
      id: id,
      nom: name,
      nir: nir,
      telephone: phone,
      email: email,
      mutuelle: mutuelle,
      pointsFidelite: points,
      allergies: allergies,
      contreIndications: contraindications,
      dateDernierAchat: prettyDate,
      dateProchainVaccin: null,
      renouvellementProche: false,
    );
  }
}