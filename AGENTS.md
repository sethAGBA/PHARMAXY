# Repository Guidelines

## Project Structure & Module Organization
- Entry point: `lib/main.dart`; theming lives in `lib/app_theme.dart` with the `ThemeColors` palette. Keep new screens under `lib/screens/` (e.g., `vente_caisse.dart`, `ordonnances.dart`, `inventaire.dart`, `retours.dart`) and shared UI in `lib/widgets/` (`sidebar.dart`, `stats_card.dart`, `quick_actions.dart`).
- Domain models sit in `lib/models/` (`sale_models.dart`, `ordonnance_models.dart`). Prefer extending these rather than inlining maps.
- Tests belong in `test/` and should mirror `lib/` paths (e.g., `lib/screens/retours.dart` → `test/screens/retours_test.dart`). Generated/output files in `build/` should stay untracked.
- Platform shells (`android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/`) are managed by Flutter; only touch them for platform-specific features.

## Build, Test, and Development Commands
- `flutter pub get` — install dependencies after editing `pubspec.yaml`.
- `flutter analyze` — static analysis using `analysis_options.yaml` rules; keep this clean before committing.
- `dart format lib test` — apply standard formatting (2-space indent).
- `flutter test` — run automated tests; add focused widget tests for new screens and flows.
- `flutter run -d chrome` or `flutter run` — start the app with hot reload; pick the target device as needed.

## Coding Style & Naming Conventions
- Follow Flutter lints; use `PascalCase` for classes/widgets, `camelCase` for members, and `SCREAMING_SNAKE_CASE` for constants.
- Prefer small, composable widgets; extract reusable cards, tables, and filters into `lib/widgets/`.
- Use `Theme.of(context)` and `ThemeColors` instead of hard-coded colors; mirror the light/dark toggle used in `main_copy.dart` and `lib/app_theme.dart`.
- Keep layouts responsive: favor `Wrap`, `Flexible`, and scrollables over fixed widths to avoid overflows across screens.

## Testing Guidelines
- Name test files with `_test.dart`; cover at least a happy path and an edge case for each new feature.
- For UI, use `WidgetTester` with `pumpWidget` to verify headers, tabs, and scrollable content render without overflows.
- When adding calculations (totals, inventory counts), assert expected numbers and formatting (e.g., `5 000 FCFA`).

## Commit & Pull Request Guidelines
- Write concise, imperative commit messages (e.g., `Refactor inventaire layout`, `Fix retours table overflow`).
- Before opening a PR: run `dart format lib test`, `flutter analyze`, and `flutter test`. Attach screenshots/gifs for UI changes (dashboard, caisse, retours, facturation) and note any theme impacts.
- Keep PRs focused; describe the feature/screen touched, linked issue/task, and any data/model changes or new configs.

### Quelques pistes utiles à ajouter sur le ticket :

  - Info pharmacie: heures d’ouverture, coordonnées urgences, lien site ou réseaux.
  - Référence vente: code-barres/QR pointant vers le ticket complet ou une URL SAV.
  - Fiscalité: détails TVA ou numéro d’identification fiscale.
  - Politique retour/échange: courte ligne pour clarifier.
  - Messages santé: rappel posologie/contre-indications si disponibles, ou hotline conseil.
  - Fidélité: points cumulés ou lien/QR pour rejoindre un programme.
  - Signature numérique: hash/verif pour authentifier le ticket.
