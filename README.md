# PHARMAXY

Offline-first Flutter app for pharmacy management (desktop/web/mobile ready) with local SQLite storage. Modules cover caisse/vente, ordonnances, stocks, alertes, commandes, receptions, clients/patients, facturation/compta, reporting, tiers payant, preparations magistrales, inventaire, retours, conseil pharma, stupéfiants, et e-commerce.

## Architecture rapide
- Entrée: `lib/main.dart` (thème clair/sombre, navigation latérale).
- Thème: `lib/app_theme.dart` et palette `ThemeColors`.
- Ecrans: `lib/screens/` (ex: `vente_caisse.dart`, `ordonnances.dart`, `inventaire.dart`, `retours.dart`).
- Widgets partagés: `lib/widgets/` (sidebar, stats, quick actions, charts...).
- Modèles: `lib/models/` (utilisateurs, ventes, ordonnances).
- Services: `lib/services/` (SQLite via `LocalDatabaseService`, produits, ventes).
- Tests: `test/` doit mirrorer `lib/` (le test par défaut est à remplacer).

## Données locales et seeds
- Base SQLite initialisée via `LocalDatabaseService` (fichier `pharmaxy.db` dans les documents app).
- Utilisateur par défaut: `admin@pharmaxy.local` / `admin123`.
- Données de demo: quelques patients, médicaments/stocks et ventes récentes pour alimenter les écrans.

## Lancer le projet
```bash
flutter pub get
flutter run -d chrome   # ou un autre device
```

## Qualité et tests
```bash
dart format lib test
flutter analyze
flutter test
```
Ajoutez des widget tests ciblés pour les nouveaux écrans/flux (headers, tabs, scrollables, calculs).

## Notes pratiques
- Plusieurs écrans affichent encore des listes mockées; branchez-les aux services SQLite au besoin.
- Evitez de toucher aux dossiers platformes (`android/`, `ios/`, `web/`, etc.) sauf besoin spécifique.
- Pour toute modification de `pubspec.yaml`, exécutez `flutter pub get` avant de compiler.
# PHARMAXY
