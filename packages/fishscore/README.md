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

## Calibration des espèces

La calibration n'est **jamais codée en dur** : la source de vérité est le
dossier [`knowledge/species`](../../knowledge/species) à la racine du dépôt.
Chaque fiche `<slug>.json` est convertie en `SpeciesProfile` via
`SpeciesProfile.fromJson`, et `SpeciesProfile.toJson` fait l'opération inverse.

Le `SpeciesCatalog` embarqué sert de valeur par défaut hors-ligne ; un test
(`test/species_knowledge_test.dart`) vérifie qu'il reste cohérent avec les
fiches. Pour ajuster la calibration, on modifie la fiche JSON, pas le code.

```dart
final profile = SpeciesProfile.fromJson(jsonDecode(sheetContent));
final engine = FishScoreEngine(speciesProfiles: {profile.slug: profile});
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
