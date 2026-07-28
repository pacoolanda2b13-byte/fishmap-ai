# FishScore v1

## Objectif

FishScore aide à comparer des créneaux et des spots. Ce n’est pas une probabilité de capture et il ne doit jamais être présenté comme une garantie.

## Sorties

- `score` : entier de 0 à 100 ;
- `confidence` : entier de 0 à 100 selon la quantité et la qualité des données ;
- facteurs positifs ;
- facteurs négatifs ;
- détail des composantes ;
- version du modèle.

## Composantes initiales

| Composante | Poids de base |
|---|---:|
| Compatibilité spot/espèce | 25 % |
| Vent | 15 % |
| Houle | 15 % |
| Créneau horaire | 15 % |
| Saison et température | 15 % |
| Historique local | 10 % |
| Lune | 5 % |

Les poids sont configurables par espèce. Ils sont renormalisés lorsque certaines données sont absentes.

## Formule

Pour chaque composante disponible, on calcule une note entre 0 et 100.

`score = somme(note_i × poids_i_disponible) / somme(poids_i_disponible)`

Le résultat est arrondi à l’entier le plus proche et limité à l’intervalle 0–100.

## Confiance

La confiance dépend de :

- couverture des données : 40 % ;
- fraîcheur météo : 20 % ;
- qualité de la source du spot : 20 % ;
- quantité d’observations locales : 20 %.

Une confiance inférieure à 40 doit afficher un avertissement « données limitées ».

## Règles produit

1. Ne jamais écrire « 80 % de chances d’attraper un poisson ».
2. Afficher au maximum trois facteurs positifs et trois facteurs négatifs.
3. Signaler les données manquantes.
4. Conserver la version du modèle pour rendre les résultats reproductibles.
5. Ne pas utiliser de données privées d’autres utilisateurs sans agrégation et consentement appropriés.

## Première calibration — zone Solenzara à Aléria

Les quatre espèces prioritaires sont : barracuda, dorade royale, loup et liche amie.

La calibration initiale doit rester prudente. Les règles biologiques et locales non vérifiées seront marquées comme hypothèses jusqu’à validation par des sources fiables ou par un volume suffisant d’observations terrain.

## Exemple de résultat

```json
{
  "score": 74,
  "confidence": 61,
  "model_version": "fishscore-v1.0.0",
  "positive_factors": [
    "Créneau favorable pour l’espèce ciblée",
    "Vent compatible avec l’exposition du spot"
  ],
  "negative_factors": [
    "Historique local encore limité"
  ],
  "component_scores": {
    "spot_species": 85,
    "wind": 72,
    "waves": 65,
    "time_window": 80,
    "season_temperature": 70,
    "history": 45,
    "moon": 55
  }
}
```

## Tests attendus

- résultat toujours compris entre 0 et 100 ;
- renormalisation correcte avec données manquantes ;
- résultat déterministe pour les mêmes entrées ;
- confiance faible lorsque les données sont incomplètes ;
- aucune formulation assimilant le score à une garantie de capture.
