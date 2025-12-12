import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';
import '../models/caisse_settings.dart';
import '../models/app_settings.dart';
import '../models/tiers_payant.dart';
import '../models/marges_settings.dart';
import '../models/preparation_magistrale.dart';
import '../models/stupefiant_mouvement.dart';
import '../models/patient_model.dart';

/// SQLite-backed local database service (offline-first).
class LocalDatabaseService {
  LocalDatabaseService._internal();
  static final LocalDatabaseService instance = LocalDatabaseService._internal();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;
    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'pharmaxy.db');
    _db = await openDatabase(
      dbPath,
      version: 21,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _migrateV2(db);
        if (oldVersion < 3) await _migrateV3(db);
        if (oldVersion < 4) await _migrateV4(db);
        if (oldVersion < 5) {
          await _migrateV4(db); // repeat to ensure table exists
        }
        if (oldVersion < 6) await _migrateV6(db);
        if (oldVersion < 7) await _migrateV7(db);
        if (oldVersion < 8) await _migrateV8(db);
        if (oldVersion < 9) await _migrateV9(db);
        if (oldVersion < 10) await _migrateV10(db);
        if (oldVersion < 11) await _migrateV11(db);
        if (oldVersion < 12) await _migrateV12(db);
        if (oldVersion < 13) await _migrateV13(db);
        if (oldVersion < 14) await _migrateV14(db);
        if (oldVersion < 15) await _migrateV15(db);
        if (oldVersion < 16) await _migrateV16(db);
        if (oldVersion < 17) await _migrateV17(db);
        if (oldVersion < 18) await _migrateV18(db);
        if (oldVersion < 19) await _migrateV19(db);
        if (oldVersion < 20) await _migrateV20(db);
        if (oldVersion < 21) await _migrateV21(db);
      },
    );
    await _seedDemoData();
    await _ensureTables();
  }

  Database get db => _db ?? (throw StateError('Database not initialized'));

  Future<List<AppUser>> getUsers() async {
    final rows = await db.query('utilisateurs', orderBy: 'created_at DESC');
    return rows.map(AppUser.fromMap).toList();
  }

  Future<List<PatientModel>> getPatientsLite() async {
    final rows = await db.query('patients', orderBy: 'name ASC');
    return rows
        .map((r) => PatientModel.fromMap(Map<String, Object?>.from(r)))
        .toList();
  }

  Future<String> insertQuickPatient({
    required String name,
    String phone = '',
  }) async {
    final patientId = 'PAT-${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('patients', {
      'id': patientId,
      'name': name,
      'phone': phone,
      'email': '',
      'mutuelle': '',
      'nir': '',
      'date_of_birth': '',
      'allergies': '',
      'contraindications': '',
      'points': 0,
      'created_at': DateTime.now().toIso8601String(),
    });
    return patientId;
  }

  Future<List<Map<String, Object?>>> getFournisseursLite() async {
    final rows = await db.query('fournisseurs', orderBy: 'nom ASC');
    return rows.map((r) => Map<String, Object?>.from(r)).toList();
  }

  Future<String> insertQuickFournisseur({
    required String nom,
    String contact = '',
  }) async {
    final fournisseurId = 'FRN-${DateTime.now().millisecondsSinceEpoch}';
    await db.insert('fournisseurs', {
      'id': fournisseurId,
      'nom': nom,
      'contact': contact,
      'email': '',
    });
    return fournisseurId;
  }

  Future<void> insertUser(AppUser user) async {
    await db.insert(
      'utilisateurs',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateUser(AppUser user) async {
    await db.update(
      'utilisateurs',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<void> deleteUser(String id) async {
    await db.delete('utilisateurs', where: 'id = ?', whereArgs: [id]);
  }

  Future<AppSettings> getSettings() async {
    final rows = await db.query('parametres');
    final map = {
      for (final row in rows)
        (row['cle'] as String): (row['valeur'] as String?) ?? '',
    };
    return AppSettings.fromMap(map);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final data = settings.toMap();
    for (final entry in data.entries) {
      await _upsertParameter(entry.key, entry.value as String? ?? '');
    }
  }

  Future<void> _upsertParameter(String key, String value) async {
    await db.insert('parametres', {
      'cle': key,
      'valeur': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<CaisseSettings> getCaisseSettings() async {
    final rows = await db.query(
      'parametres',
      where: 'cle = ?',
      whereArgs: ['caisse'],
      limit: 1,
    );
    if (rows.isEmpty) return CaisseSettings.defaults();
    final value = rows.first['valeur'] as String? ?? '';
    if (value.isEmpty) return CaisseSettings.defaults();
    try {
      return CaisseSettings.fromJsonString(value);
    } catch (_) {
      return CaisseSettings.defaults();
    }
  }

  Future<void> saveCaisseSettings(CaisseSettings settings) async {
    await db.insert('parametres', {
      'cle': 'caisse',
      'valeur': settings.toJsonString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<MargesSettings> getMargesSettings() async {
    final rows = await db.query(
      'parametres',
      where: 'cle = ?',
      whereArgs: ['marges'],
      limit: 1,
    );
    if (rows.isEmpty) return MargesSettings.defaults();
    final value = rows.first['valeur'] as String? ?? '';
    if (value.isEmpty) return MargesSettings.defaults();
    try {
      return MargesSettings.fromJsonString(value);
    } catch (_) {
      return MargesSettings.defaults();
    }
  }

  Future<void> saveMargesSettings(MargesSettings settings) async {
    await db.insert('parametres', {
      'cle': 'marges',
      'valeur': settings.toJsonString(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TiersPayant>> getTiersPayants() async {
    final rows = await db.query('tiers_payants', orderBy: 'created_at DESC');
    return rows.map(TiersPayant.fromMap).toList();
  }

  Future<void> upsertTiersPayant(TiersPayant tiers) async {
    await db.insert(
      'tiers_payants',
      tiers.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTiersPayant(String id) async {
    await db.delete('tiers_payants', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<PreparationMagistrale>> getPreparationsMagistrales() async {
    final rows = await db.query(
      'preparation_magistrales',
      orderBy: 'created_at DESC',
    );
    return rows.map(PreparationMagistrale.fromMap).toList();
  }

  Future<void> upsertPreparationMagistrale(
    PreparationMagistrale preparation,
  ) async {
    await db.insert(
      'preparation_magistrales',
      preparation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deletePreparationMagistrale(String id) async {
    await db.delete(
      'preparation_magistrales',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<StupefiantMouvement>> getStupefiantMouvements() async {
    final rows = await db.query('stupefiant_registre', orderBy: 'date DESC');
    return rows.map(StupefiantMouvement.fromMap).toList();
  }

  Future<int> insertStupefiantMouvement(StupefiantMouvement mouvement) async {
    return db.insert(
      'stupefiant_registre',
      mouvement.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateStupefiantMouvement(StupefiantMouvement mouvement) async {
    await db.update(
      'stupefiant_registre',
      mouvement.toMap(),
      where: 'id = ?',
      whereArgs: [mouvement.id],
    );
  }

  Future<void> deleteStupefiantMouvement(int id) async {
    await db.delete('stupefiant_registre', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> _createSchema(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS utilisateurs (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT UNIQUE,
        password TEXT,
        role TEXT,
        created_at TEXT,
        last_login TEXT,
        is_active INTEGER,
        two_factor_enabled INTEGER DEFAULT 1,
        totp_secret TEXT,
        allowed_screens TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parametres (
        cle TEXT PRIMARY KEY,
        valeur TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS patients (
        id TEXT PRIMARY KEY,
        name TEXT,
        phone TEXT,
        email TEXT,
        mutuelle TEXT,
        nir TEXT,
        date_of_birth TEXT,
        allergies TEXT,
        contraindications TEXT,
        points INTEGER DEFAULT 0,
        created_at TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medicaments (
        id TEXT PRIMARY KEY,
        nom TEXT,
        sku TEXT,
        type TEXT,
        statut TEXT,
        dci TEXT,
        cip TEXT,
        dosage TEXT,
        forme TEXT,
        famille TEXT,
        laboratoire TEXT,
        prix_achat REAL,
        prix_vente REAL,
        tva REAL,
        remboursement REAL,
        ordonnance INTEGER DEFAULT 0,
        controle INTEGER DEFAULT 0,
        stupefiant INTEGER DEFAULT 0,
        description TEXT,
        fournisseur TEXT,
        localisation TEXT,
        notice TEXT,
        image TEXT,
        conditionnement TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stocks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicament_id TEXT,
        reserve INTEGER,
        officine INTEGER,
        seuil INTEGER,
        seuil_max INTEGER,
        peremption TEXT,
        lot TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicament_id TEXT,
        lot TEXT,
        peremption TEXT,
        quantite INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ventes (
        id TEXT PRIMARY KEY,
        date TEXT,
        montant REAL,
        mode TEXT,
        client_id TEXT,
        vendeur TEXT,
        cancellation_reason TEXT,
        details TEXT,
        type TEXT,
        statut TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lignes_vente (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vente_id TEXT,
        medicament_id TEXT,
        quantite INTEGER,
        prix REAL,
        remise REAL
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ordonnances (
        id TEXT PRIMARY KEY,
        patient_id TEXT,
        prescripteur TEXT,
        date TEXT,
        tiers_payant INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS prescriptions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ordonnance_id TEXT,
        medicament_id TEXT,
        quantite INTEGER,
        posologie TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fournisseurs (
        id TEXT PRIMARY KEY,
        nom TEXT,
        contact TEXT,
        email TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS commandes (
        id TEXT PRIMARY KEY,
        fournisseur_id TEXT,
        date TEXT,
        statut TEXT,
        total REAL,
        auteur TEXT,
        notes TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lignes_commande (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commande_id TEXT,
        medicament_id TEXT,
        nom_produit TEXT,
        quantite INTEGER,
        prix_unitaire REAL,
        lot TEXT,
        peremption TEXT,
        note TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS receptions (
        id TEXT PRIMARY KEY,
        commande_id TEXT,
        date TEXT,
        statut TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS retours (
        id TEXT PRIMARY KEY,
        numero TEXT,
        type TEXT,
        date TEXT,
        entity_id TEXT,
        entity_name TEXT,
        product_id TEXT,
        product_name TEXT,
        lot TEXT,
        commande_date TEXT,
        quantite INTEGER,
        montant REAL,
        motif TEXT,
        commentaire TEXT,
        declared_by TEXT,
        statut TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mouvements_stock (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicament_id TEXT,
        type TEXT,
        quantite INTEGER,
        source TEXT,
        date TEXT,
        commentaire TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tiers_payant (
        id TEXT PRIMARY KEY,
        organisme TEXT,
        numero TEXT,
        statut TEXT,
        solde REAL
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS factures (
        id TEXT PRIMARY KEY,
        client_id TEXT,
        date TEXT,
        montant REAL,
        statut TEXT,
        echeance TEXT,
        type TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS preparation_magistrales (
        id TEXT PRIMARY KEY,
        nom TEXT,
        description TEXT,
        categorie TEXT,
        quantite_totale INTEGER,
        unite TEXT,
        composants_json TEXT,
        instructions TEXT,
        conservation TEXT,
        posologie TEXT,
        statut TEXT,
        cout REAL,
        prix REAL,
        created_at TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS stupefiant_registre (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        produit TEXT,
        lot TEXT,
        type TEXT,
        quantite INTEGER,
        date TEXT,
        agent TEXT,
        motif TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS interactions_medicamenteuses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        med_a TEXT,
        med_b TEXT,
        risque TEXT,
        action TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parametres_pharmacie (
        key TEXT PRIMARY KEY,
        value TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tiers_payants (
        id TEXT PRIMARY KEY,
        nom TEXT,
        type TEXT,
        taux_prise_en_charge INTEGER,
        delai_paiement INTEGER,
        actif INTEGER DEFAULT 1,
        nb_patients INTEGER DEFAULT 0,
        montant_en_attente INTEGER DEFAULT 0,
        created_at TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mouvements_stocks (
        id TEXT PRIMARY KEY,
        medicament_id TEXT,
        type TEXT,
        quantite INTEGER,
        quantite_avant INTEGER,
        quantite_apres INTEGER,
        raison TEXT,
        reference TEXT,
        notes TEXT,
        utilisateur TEXT,
        date TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventaires (
        id TEXT PRIMARY KEY,
        date TEXT,
        type TEXT,
        responsable TEXT,
        statut TEXT,
        nb_produits INTEGER,
        ecart_qte INTEGER,
        ecart_valeur INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventaire_lignes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inventaire_id TEXT,
        medicament_id TEXT,
        code TEXT,
        nom TEXT,
        qty_theorique INTEGER,
        qty_reelle INTEGER,
        prix_achat INTEGER,
        prix_vente INTEGER,
        lot TEXT,
        peremption TEXT,
        categorie TEXT,
        emplacement TEXT,
        date_ajout TEXT
      );
    ''');
    final userCols = await db.rawQuery("PRAGMA table_info('utilisateurs')");
    final userNames = userCols.map((c) => (c['name'] as String?) ?? '').toSet();
    if (!userNames.contains('two_factor_enabled')) {
      await db.execute(
        'ALTER TABLE utilisateurs ADD COLUMN two_factor_enabled INTEGER NOT NULL DEFAULT 0;',
      );
    }
    if (!userNames.contains('totp_secret')) {
      await db.execute('ALTER TABLE utilisateurs ADD COLUMN totp_secret TEXT;');
    }
  }

  Future<void> _migrateV21(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lots (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        medicament_id TEXT,
        lot TEXT,
        peremption TEXT,
        quantite INTEGER
      );
    ''');
    // Seed lots from legacy stocks.lot/peremption if lots empty per product.
    final legacyStocks = await db.query('stocks');
    for (final s in legacyStocks) {
      final medicamentId = s['medicament_id'] as String? ?? '';
      final lot = (s['lot'] as String?)?.trim() ?? '';
      final peremption = (s['peremption'] as String?) ?? '';
      final officine = (s['officine'] as int?) ?? 0;
      if (medicamentId.isEmpty || lot.isEmpty || officine <= 0) continue;
      final existingLot = await db.query(
        'lots',
        where: 'medicament_id = ?',
        whereArgs: [medicamentId],
        limit: 1,
      );
      if (existingLot.isEmpty) {
        await db.insert('lots', {
          'medicament_id': medicamentId,
          'lot': lot,
          'peremption': peremption,
          'quantite': officine,
        });
      }
    }
  }

  Future<void> _migrateV2(Database db) async {
    // Add advanced product fields (SKU, type, statut, traçabilité, seuil max).
    await db.execute('ALTER TABLE medicaments ADD COLUMN sku TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN type TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN statut TEXT;');
    await db.execute(
      'ALTER TABLE medicaments ADD COLUMN ordonnance INTEGER DEFAULT 0;',
    );
    await db.execute(
      'ALTER TABLE medicaments ADD COLUMN controle INTEGER DEFAULT 0;',
    );
    await db.execute('ALTER TABLE medicaments ADD COLUMN description TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN fournisseur TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN localisation TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN notice TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN image TEXT;');
    await db.execute('ALTER TABLE stocks ADD COLUMN seuil_max INTEGER;');
  }

  Future<void> _migrateV3(Database db) async {
    await db.execute(
      'ALTER TABLE medicaments ADD COLUMN conditionnement TEXT;',
    );
  }

  Future<void> _migrateV4(Database db) async {
    // Ensure mouvements_stocks table exists for stock movement history.
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mouvements_stocks (
        id TEXT PRIMARY KEY,
        medicament_id TEXT,
        type TEXT,
        quantite INTEGER,
        quantite_avant INTEGER,
        quantite_apres INTEGER,
        raison TEXT,
        reference TEXT,
        notes TEXT,
        utilisateur TEXT,
        date TEXT
      );
    ''');
    // Ensure lignes_commande exists for older DBs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lignes_commande (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commande_id TEXT,
        medicament_id TEXT,
        nom_produit TEXT,
        quantite INTEGER,
        prix_unitaire REAL,
        lot TEXT,
        peremption TEXT,
        note TEXT
      );
    ''');
  }

  Future<void> _ensureTables() async {
    // Defensive: ensure mouvements_stocks exists even if migrations were skipped.
    final db = _db;
    if (db == null) return;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mouvements_stocks (
        id TEXT PRIMARY KEY,
        medicament_id TEXT,
        type TEXT,
        quantite INTEGER,
        quantite_avant INTEGER,
        quantite_apres INTEGER,
        raison TEXT,
        reference TEXT,
        notes TEXT,
        utilisateur TEXT,
        date TEXT
      );
    ''');
    // Defensive: ensure lignes_commande exists
    await db.execute('''
      CREATE TABLE IF NOT EXISTS lignes_commande (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commande_id TEXT,
        medicament_id TEXT,
        nom_produit TEXT,
        quantite INTEGER,
        prix_unitaire REAL,
        lot TEXT,
        peremption TEXT,
        note TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS commande_lignes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commande_id TEXT,
        medicament_id TEXT,
        nom TEXT,
        cip TEXT,
        quantite INTEGER,
        prix_unitaire INTEGER,
        note TEXT
      );
    ''');
    final venteCols = await db.rawQuery("PRAGMA table_info('ventes')");
    final venteNames = venteCols
        .map((c) => (c['name'] as String?) ?? '')
        .toSet();
    if (!venteNames.contains('details')) {
      await db.execute('ALTER TABLE ventes ADD COLUMN details TEXT;');
    }
    final cols = await db.rawQuery("PRAGMA table_info('commandes')");
    final names = cols.map((c) => (c['name'] as String?) ?? '').toSet();
    if (!names.contains('auteur')) {
      await db.execute('ALTER TABLE commandes ADD COLUMN auteur TEXT;');
    }
    if (!names.contains('notes')) {
      await db.execute('ALTER TABLE commandes ADD COLUMN notes TEXT;');
    }
    final patientCols = await db.rawQuery("PRAGMA table_info('patients')");
    final patientNames = patientCols
        .map((c) => (c['name'] as String?) ?? '')
        .toSet();
    if (!patientNames.contains('date_of_birth')) {
      await db.execute('ALTER TABLE patients ADD COLUMN date_of_birth TEXT;');
    }
    if (!patientNames.contains('nir')) {
      await db.execute('ALTER TABLE patients ADD COLUMN nir TEXT;');
    }
    if (!patientNames.contains('allergies')) {
      await db.execute('ALTER TABLE patients ADD COLUMN allergies TEXT;');
    }
    if (!patientNames.contains('contraindications')) {
      await db.execute(
        'ALTER TABLE patients ADD COLUMN contraindications TEXT;',
      );
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS retours (
        id TEXT PRIMARY KEY,
        numero TEXT,
        type TEXT,
        date TEXT,
        entity_id TEXT,
        entity_name TEXT,
        product_id TEXT,
        product_name TEXT,
        lot TEXT,
        commande_date TEXT,
        quantite INTEGER,
        montant REAL,
        motif TEXT,
        commentaire TEXT,
        declared_by TEXT,
        statut TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS preparation_magistrales (
        id TEXT PRIMARY KEY,
        nom TEXT,
        description TEXT,
        categorie TEXT,
        quantite_totale INTEGER,
        unite TEXT,
        composants_json TEXT,
        instructions TEXT,
        conservation TEXT,
        posologie TEXT,
        statut TEXT,
        cout REAL,
        prix REAL,
        created_at TEXT
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tiers_payants (
        id TEXT PRIMARY KEY,
        nom TEXT,
        type TEXT,
        taux_prise_en_charge INTEGER,
        delai_paiement INTEGER,
        actif INTEGER DEFAULT 1,
        nb_patients INTEGER DEFAULT 0,
        montant_en_attente INTEGER DEFAULT 0,
        created_at TEXT
      );
    ''');
  }

  Future<void> _migrateV9(Database db) async {
    try {
      await db.execute(
        'ALTER TABLE utilisateurs ADD COLUMN allowed_screens TEXT;',
      );
    } catch (_) {
      // Column already exists
    }
  }

  Future<void> _migrateV10(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parametres (
        cle TEXT PRIMARY KEY,
        valeur TEXT
      );
    ''');
  }

  Future<void> _migrateV12(Database db) async {
    final cols = await db.rawQuery("PRAGMA table_info('ventes')");
    final names = cols.map((c) => (c['name'] as String?) ?? '').toSet();
    if (!names.contains('vendeur')) {
      await db.execute('ALTER TABLE ventes ADD COLUMN vendeur TEXT;');
    }
    if (!names.contains('cancellation_reason')) {
      await db.execute(
        'ALTER TABLE ventes ADD COLUMN cancellation_reason TEXT;',
      );
    }
  }

  Future<void> _migrateV11(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS parametres (
        cle TEXT PRIMARY KEY,
        valeur TEXT
      );
    ''');
  }

  Future<void> _migrateV13(Database db) async {
    final cols = await db.rawQuery("PRAGMA table_info('ventes')");
    final names = cols.map((c) => (c['name'] as String?) ?? '').toSet();
    if (!names.contains('details')) {
      await db.execute('ALTER TABLE ventes ADD COLUMN details TEXT;');
    }
  }

  Future<void> _migrateV14(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventaires (
        id TEXT PRIMARY KEY,
        date TEXT,
        type TEXT,
        responsable TEXT,
        statut TEXT,
        nb_produits INTEGER,
        ecart_qte INTEGER,
        ecart_valeur INTEGER
      );
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventaire_lignes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        inventaire_id TEXT,
        medicament_id TEXT,
        code TEXT,
        nom TEXT,
        qty_theorique INTEGER,
        qty_reelle INTEGER,
        prix_achat INTEGER,
        prix_vente INTEGER,
        lot TEXT,
        peremption TEXT,
        categorie TEXT,
        emplacement TEXT,
        date_ajout TEXT
      );
    ''');
  }

  Future<void> _migrateV15(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS retours (
        id TEXT PRIMARY KEY,
        numero TEXT,
        type TEXT,
        date TEXT,
        entity_id TEXT,
        entity_name TEXT,
        product_id TEXT,
        product_name TEXT,
        lot TEXT,
        commande_date TEXT,
        quantite INTEGER,
        montant REAL,
        motif TEXT,
        commentaire TEXT,
        declared_by TEXT,
        statut TEXT
      );
    ''');
  }

  Future<void> _migrateV16(Database db) async {
    final cols = await db.rawQuery("PRAGMA table_info('utilisateurs')");
    final names = cols.map((c) => (c['name'] as String?) ?? '').toSet();
    if (!names.contains('two_factor_enabled')) {
      await db.execute(
        'ALTER TABLE utilisateurs ADD COLUMN two_factor_enabled INTEGER NOT NULL DEFAULT 1;',
      );
    }
  }

  Future<void> _migrateV17(Database db) async {
    final cols = await db.rawQuery("PRAGMA table_info('utilisateurs')");
    final names = cols.map((c) => (c['name'] as String?) ?? '').toSet();
    if (!names.contains('totp_secret')) {
      await db.execute('ALTER TABLE utilisateurs ADD COLUMN totp_secret TEXT;');
    }
  }

  Future<void> _migrateV18(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tiers_payants (
        id TEXT PRIMARY KEY,
        nom TEXT,
        type TEXT,
        taux_prise_en_charge INTEGER,
        delai_paiement INTEGER,
        actif INTEGER DEFAULT 1,
        nb_patients INTEGER DEFAULT 0,
        montant_en_attente INTEGER DEFAULT 0,
        created_at TEXT
      );
    ''');
  }

  Future<void> _migrateV19(Database db) async {
    final cols = await db.rawQuery(
      "PRAGMA table_info('preparation_magistrales')",
    );
    final names = cols.map((c) => (c['name'] as String?) ?? '').toSet();
    Future<void> addIfMissing(String name, String sqlType) async {
      if (!names.contains(name)) {
        await db.execute(
          'ALTER TABLE preparation_magistrales ADD COLUMN $name $sqlType;',
        );
      }
    }

    await addIfMissing('categorie', 'TEXT');
    await addIfMissing('quantite_totale', 'INTEGER');
    await addIfMissing('unite', 'TEXT');
    await addIfMissing('composants_json', 'TEXT');
    await addIfMissing('instructions', 'TEXT');
    await addIfMissing('conservation', 'TEXT');
    await addIfMissing('posologie', 'TEXT');
    await addIfMissing('created_at', 'TEXT');
  }

  Future<void> _migrateV20(Database db) async {
    final cols = await db.rawQuery("PRAGMA table_info('medicaments')");
    final names = cols.map((c) => (c['name'] as String?) ?? '').toSet();
    if (!names.contains('stupefiant')) {
      await db.execute(
        'ALTER TABLE medicaments ADD COLUMN stupefiant INTEGER NOT NULL DEFAULT 0;',
      );
    }
  }

  Future<void> _migrateV6(Database db) async {
    await db.execute('ALTER TABLE patients ADD COLUMN nir TEXT;');
    await db.execute('ALTER TABLE patients ADD COLUMN allergies TEXT;');
    await db.execute('ALTER TABLE patients ADD COLUMN contraindications TEXT;');
  }

  Future<void> _migrateV7(Database db) async {
    await db.execute('ALTER TABLE patients ADD COLUMN date_of_birth TEXT;');
  }

  Future<void> _migrateV8(Database db) async {
    final cols = await db.rawQuery("PRAGMA table_info('commandes')");
    final names = cols.map((c) => (c['name'] as String?) ?? '').toSet();
    if (!names.contains('auteur')) {
      await db.execute('ALTER TABLE commandes ADD COLUMN auteur TEXT;');
    }
    if (!names.contains('notes')) {
      await db.execute('ALTER TABLE commandes ADD COLUMN notes TEXT;');
    }
    await db.execute('''
      CREATE TABLE IF NOT EXISTS commande_lignes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        commande_id TEXT,
        medicament_id TEXT,
        nom TEXT,
        cip TEXT,
        quantite INTEGER,
        prix_unitaire INTEGER,
        note TEXT
      );
    ''');
  }

  Future<void> _seedDemoData() async {
    // Seed users
    final userCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM utilisateurs'),
        ) ??
        0;
    if (userCount == 0) {
      await insertUser(
        AppUser(
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
        ),
      );
    }

    // Seed settings
    final settingsCount =
        Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM parametres'),
        ) ??
        0;
    if (settingsCount == 0) {
      await saveSettings(AppSettings.defaults());
    }

    // Seed patients — disabled: let users create their own patients
    // final patientCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM patients')) ?? 0;
    // if (patientCount == 0) { ... }

    // Medicaments seeding removed — keep database empty so users can add their own data

    // Seed ventes — disabled: let users start with empty sales history
    // final venteCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ventes')) ?? 0;
    // if (venteCount == 0) { ... }
  }
}
