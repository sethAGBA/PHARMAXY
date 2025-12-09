import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

import '../models/app_user.dart';

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
      version: 8,
      onCreate: (db, version) async {
        await _createSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _migrateV2(db);
        if (oldVersion < 3) await _migrateV3(db);
        if (oldVersion < 4) await _migrateV4(db);
        if (oldVersion < 5) await _migrateV4(db); // repeat to ensure table exists
        if (oldVersion < 6) await _migrateV6(db);
        if (oldVersion < 7) await _migrateV7(db);
        if (oldVersion < 8) await _migrateV8(db);
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

  Future<void> insertUser(AppUser user) async {
    await db.insert(
      'utilisateurs',
      user.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
        is_active INTEGER
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
        statut TEXT,
        cout REAL,
        prix REAL
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
  }

  Future<void> _migrateV2(Database db) async {
    // Add advanced product fields (SKU, type, statut, traçabilité, seuil max).
    await db.execute('ALTER TABLE medicaments ADD COLUMN sku TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN type TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN statut TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN ordonnance INTEGER DEFAULT 0;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN controle INTEGER DEFAULT 0;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN description TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN fournisseur TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN localisation TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN notice TEXT;');
    await db.execute('ALTER TABLE medicaments ADD COLUMN image TEXT;');
    await db.execute('ALTER TABLE stocks ADD COLUMN seuil_max INTEGER;');
  }

  Future<void> _migrateV3(Database db) async {
    await db.execute('ALTER TABLE medicaments ADD COLUMN conditionnement TEXT;');
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
    final cols = await db.rawQuery("PRAGMA table_info('commandes')");
    final names = cols.map((c) => (c['name'] as String?) ?? '').toSet();
    if (!names.contains('auteur')) {
      await db.execute('ALTER TABLE commandes ADD COLUMN auteur TEXT;');
    }
    if (!names.contains('notes')) {
      await db.execute('ALTER TABLE commandes ADD COLUMN notes TEXT;');
    }
    final patientCols = await db.rawQuery("PRAGMA table_info('patients')");
    final patientNames = patientCols.map((c) => (c['name'] as String?) ?? '').toSet();
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
      await db.execute('ALTER TABLE patients ADD COLUMN contraindications TEXT;');
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
    final userCount = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM utilisateurs')) ?? 0;
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
        ),
      );
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
