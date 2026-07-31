# Fixtures Open-Meteo

Réponses JSON figées reproduisant le format réel des API Open-Meteo, utilisées
par les tests pour valider le mapping **sans appel réseau**.

| Fichier | Contenu |
|---|---|
| `forecast_solenzara.json` | réponse nominale de l'API prévision (unités métriques) |
| `marine_solenzara.json` | réponse nominale de l'API marine |
| `forecast_imperial_units.json` | mêmes variables déclarées en °F, mp/h, nœuds, pouces — valide la conversion pilotée par `hourly_units` |
| `forecast_partial_data.json` | séries trouées (`null`) et série entièrement vide |
| `error_invalid_latitude.json` | erreur applicative Open-Meteo (`error: true`) |

Les coordonnées correspondent à la zone pilote (Solenzara, côte est de la
Corse). Les horodatages sont exprimés en UTC sans suffixe de fuseau, comme le
fait l'API avec `timezone=UTC`.
