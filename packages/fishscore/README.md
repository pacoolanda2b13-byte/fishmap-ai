# fishscore

Moteur de scoring **FishScore v1** de FishMap AI.

Pur Dart, sans dépendance à Flutter : le moteur est réutilisable côté
application mobile, côté fonction serveur Supabase et testable en isolation.

## Ce que fait le moteur

À partir des conditions (vent, houle, pression, température de l'eau, phase
lunaire, heure, saison, profondeur, type de fond) et de l'historique local, il
produit un résultat **explicable** :

- `score` — entier 0-100 comparant créneaux et spots ;
- `confidence` — entier 0-100 selon la couverture et la qualité des données ;
- `positiveFactors` / `negativeFactors` — au maximum trois de chaque ;
- `components` — détail par composante ;
- `explanation` — texte prêt pour l'affichage ;
- `bestWindow` — meilleur créneau (balayage temporel optionnel).

> Le score compare des conditions ; ce n'est **jamais** une probabilité de
> capture ni une garantie.

## Composantes et poids (v1)

| Composante | Poids | Disponibilité |
|---|---:|---|
| Compatibilité spot / espèce | 25 % | fond, profondeur ou compatibilité connue |
| Vent | 15 % | vitesse du vent |
| Houle | 15 % | hauteur de houle |
| Créneau horaire | 15 % | toujours (heure) |
| Saison et température | 15 % | toujours (saison) |
| Historique local | 10 % | observations / captures |
| Lune | 5 % | phase lunaire |

Les poids sont **renormalisés** sur les composantes réellement disponibles. La
pression atmosphérique applique un modificateur borné (±6 %) au score final.

## Utilisation

```dart
import 'package:fishscore/fishscore.dart';

final engine = FishScoreEngine();
final result = engine.evaluate(FishScoreInput(
  speciesSlug: 'loup',
  evaluatedAt: DateTime.utc(2026, 10, 15, 19),
  windSpeedKmh: 16,
  waveHeightM: 0.7,
  seaTemperatureC: 17.5,
  pressureTrendHpaPer3h: -2.0,
));

print('${result.score}/100 — ${result.level.labelFr}');
print(result.explanation);
```

Voir `example/fishscore_example.dart` pour une démonstration complète.

## Calibration des espèces (générée, jamais codée en dur)

La **seule source de vérité** est le dossier
[`knowledge/species`](../../knowledge/species). Le catalogue Dart embarqué est
**généré automatiquement** :

```
knowledge/species/*.json ──▶ tool/generate_species_catalog.dart ──▶ species_catalog.g.dart
```

Après modification d'une fiche :

```bash
dart run tool/generate_species_catalog.dart        # régénère le catalogue
dart run tool/generate_species_catalog.dart --check # vérification (CI)
```

Aucun profil n'est modifié à la main. `SpeciesProfile.fromJson` reste
disponible pour charger une fiche dynamiquement (backend, mises à jour à
chaud).

### Traçabilité

Chaque profil porte son niveau de confiance (`hypothesis` / `observed` /
`validated`) et ses **sources typées** (Ifremer, publications scientifiques,
guides de pêche, observations terrain). Le résumé de provenance est exposé :

```dart
SpeciesCatalog.bySlug('loup')!.provenanceSummaryFr;
// ex. « 42 observations terrain + 3 publications scientifiques »
```

## Extensibilité

Le moteur accepte une liste de composantes et un catalogue d'espèces
personnalisés, et chaque espèce peut surcharger les poids par composante
(`weightOverrides`). Faire évoluer le modèle ne casse pas le reste de
l'application.

## Développement

```bash
dart pub get
dart analyze
dart test
```
