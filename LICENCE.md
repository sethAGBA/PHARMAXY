# Licence (PHARMAXY)

Ce document décrit la logique de licence implémentée dans l’application PHARMAXY : saisie, validation, persistance, expiration et “gating” (restriction d’accès).

## Fichiers concernés

- Logique métier : `lib/services/license_service.dart`
- UI (saisie/état) : `lib/screens/parametrage.dart`
- Blocage navigation si non licenciée : `lib/main.dart` (`PharmacyDashboard`)

## Principe général

La licence est une **clé à usage unique** :

- Une clé valide peut être enregistrée **une seule fois** sur un poste.
- Une fois utilisée, elle est ajoutée à une liste de clés consommées et **ne peut plus être réutilisée**, même si on supprime ensuite la licence active.

La validité est de **12 mois** à partir de la date d’enregistrement (pour les clés “standard”), sauf pour des **clés spéciales** (ex: 3 mois / à vie).

## Stockage (SharedPreferences)

La licence est stockée localement via `SharedPreferences` avec ces clés :

- `license_key` : la clé active (forme normalisée)
- `license_registered_at` : date d’enregistrement ISO8601
- `license_expiry` : date d’expiration ISO8601
- `license_used_keys` : liste des clés normalisées déjà utilisées (usage unique)

## Normalisation des clés

Avant validation, la clé est normalisée :

- `toUpperCase()`
- suppression de tout ce qui n’est pas `[A-Z0-9]` (tirets/espaces ignorés)

Cela permet de saisir une clé avec ou sans `-` et avec n’importe quelle casse.

## Types de clés

### 1) Clés “standard”

- Liste des 12 clés dans `LicenseService.validKeys`
- Durée : **12 mois**
- Comptent dans le quota “lot de 12”

Clés actuellement configurées :

- `K9QF-7T3M-ZX82-LN5P`
- `R4VD-1J8H-PQ6T-3XNA`
- `M7CL-9W2K-HD5Q-V8RP`
- `T2NB-X6J4-8QKV-L1DM`
- `H5ZR-3PQN-7M8L-VA2T`
- `Q8TJ-4L9V-N2RD-X7KM`
- `P1MX-6KQ7-T9HL-3VDR`
- `D6VN-2R5T-XQ14-M9KP`
- `X3HL-8N7Q-P6JD-1RTM`
- `N9KQ-5V2L-RT8X-4JHD`
- `V1RP-7X6D-L3MQ-9T2N`
- `L8DM-4H1T-K7VN-Q6XR`

### 2) Clés “spéciales”

- Définies dans `LicenseService._specialKeysMonths`
- Durée : variable (ex: 3 mois, “à vie”)
- Ne comptent pas dans le quota du lot de 12 (elles sont gérées à part)

Clés actuellement configurées :

- `PHARMA-TEST-3M-2025` → 3 mois
- `PHARMAXY-LIFE-2025` → à vie

## Statut licence

Un statut est calculé à partir de la clé et de la date d’expiration :

- **Active** : clé présente + expiration présente + non expirée
- **Expirée** : clé présente + expiration présente + date passée
- **Incomplète** : clé absente ou expiration absente

`daysRemaining` = nombre de jours restants (si expiration).

## Déblocage par “lot consommé”

En plus de la licence active, l’application peut être considérée comme “débloquée” si :

- toutes les clés “standard” ont déjà été utilisées (`allKeysUsed() == true`)

Dans ce cas, l’état affiché est “Application débloquée”.

## UI (Paramétrage → Licence)

Dans `Paramétrage`, une carte “Licence” permet :

- de voir l’état (requise / active / expirée / débloquée)
- d’enregistrer une clé (bouton **ENREGISTRER** → `saveLicense`)
- de supprimer la licence active (bouton **SUPPRIMER** → `clearLicense`)

Suppression : on demande une confirmation en resaisissant **la clé active**.

Important : la suppression retire `license_key`, `license_registered_at`, `license_expiry` mais **ne retire pas** l’entrée dans `license_used_keys`.

## Blocage (“gating”) de l’application

Le `PharmacyDashboard` applique une restriction d’accès :

Si `hasActive() == false` et `allKeysUsed() == false`, alors :

- la navigation est limitée à **Paramétrage** uniquement
- l’utilisateur doit enregistrer une licence pour retrouver l’accès normal

Le dashboard écoute un notifier (`activeNotifier`) pour se mettre à jour dès qu’une licence est enregistrée/supprimée.

## SupAdmin (clé/secret)

Le service prévoit un secret “SupAdmin” fourni au build via :

- `--dart-define=SUPADMIN_PASSWORD=...`

Si non fourni, un `defaultValue` est utilisé (voir `LicenseService`) :

- `PHARMAXY#SupAdmin2025!`

## Notes pratiques / support

- Si une clé a été testée puis supprimée, elle reste “consommée” (usage unique).
- Pour repartir complètement à zéro sur une machine (debug), il faut effacer les `SharedPreferences` de l’app (désinstallation / nettoyage données), sinon `license_used_keys` persiste.
