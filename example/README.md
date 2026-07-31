# fishmap_example

Démonstration exécutable de FishMap AI, **en Dart pur, sans Flutter**.

Interroge réellement Open-Meteo et affiche, pour chaque espèce MVP : le score,
la confiance, l'explication et la provenance des données.

## Lancer

```bash
cd example
dart pub get

dart run bin/evaluate.dart                              # Solenzara, maintenant
dart run bin/evaluate.dart 41.86 9.40                   # coordonnées
dart run bin/evaluate.dart 41.86 9.40 2026-10-15T19:00Z # + instant précis
dart run bin/evaluate.dart --verbose 41.86 9.40         # trace les fournisseurs
```

## Sortie attendue

```text
FishMap AI — évaluation
Position : 41.86, 9.4
Instant  : 2026-10-15T19:00:00.000Z
Source   : Open-Meteo (données réelles)

── Loup ────────────────────────
Score       : 78/100 (Bon)
Confiance   : 62/100
Explication : Niveau bon pour le loup (score 78/100). Atouts : Pression en
              baisse, activité souvent meilleure, Créneau favorable pour
              l'espèce ciblée…
Provenance  : Météo : open-meteo. Connaissances : Calibration en hypothèse,
              aucune source référencée.

── Barracuda ───────────────────
…

Recommandation : Loup (78/100).
```

Les valeurs varient selon les conditions réelles au moment de l'exécution.

## Accès réseau requis

La démonstration effectue de véritables appels HTTPS vers :

- `api.open-meteo.com` — vent, rafales, direction, température de l'air,
  pression, précipitations, couverture nuageuse ;
- `marine-api.open-meteo.com` — hauteur, période et direction de houle,
  température de la mer.

Aucune clé d'API n'est nécessaire. Si ces hôtes sont bloqués (pare-feu
d'entreprise, proxy filtrant, environnement CI isolé), la commande se termine
proprement avec le code `1` et le message :

```text
Évaluation impossible : COMPOSITE
Aucun fournisseur météo disponible (UNAVAILABLE)
```

`--verbose` affiche alors la cause exacte pour chaque fournisseur.

## API programmatique

```dart
import 'package:core/core.dart';
import 'package:fishmap_example/evaluate.dart';

final result = await evaluate(
  latitude: 41.86,
  longitude: 9.40,
  date: DateTime.now().toUtc(),
);

result.fold(
  onSuccess: (evaluations) {
    for (final e in evaluations) {
      print('${e.commonNameFr}: ${e.score}/100 — ${e.provenance}');
    }
  },
  onFailure: (failure) => print('indisponible : ${failure.code}'),
);
```

## Tests

Le test de bout en bout rejoue la chaîne complète sur les fixtures Open-Meteo,
**sans réseau** — il valide donc le mapping et le scoring de façon
déterministe, y compris les cas dégradés (API marine indisponible, Open-Meteo
injoignable).

```bash
dart test
```
