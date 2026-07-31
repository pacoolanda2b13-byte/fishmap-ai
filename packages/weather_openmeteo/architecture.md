# weather_openmeteo — Architecture

Version : 0.1

## Objectif

Fournir des données météo **réelles** à FishMap AI, sans que le reste du
projet ne sache d'où elles viennent.

## Position dans le dépôt

```
              ┌────────────────────┐
              │ weather_openmeteo  │  ← adaptateur (ce package)
              │  HTTP · JSON · unités │
              └──────────┬─────────┘
                         │ implémente WeatherProvider
              ┌──────────▼─────────┐
              │      weather       │  ← port (contrat + modèles)
              └──────────┬─────────┘
                         │
                    ┌────▼────┐
                    │  core   │
                    └─────────┘
```

**Inversion de dépendance** : `weather` définit le contrat et ignore
totalement Open-Meteo ; c'est l'adaptateur qui dépend du port, jamais
l'inverse. Vérifié par
`packages/core/test/architecture_rules_test.dart`.

## Chaîne complète

```
Coordonnées + fenêtre temporelle
        │
        ▼
┌───────────────────┐   api.open-meteo.com/v1/forecast
│ OpenMeteoProvider │──▶ marine-api.open-meteo.com/v1/marine
└─────────┬─────────┘
          │ JSON brut
          ▼
┌───────────────────┐   lit hourly_units, convertit via core.Units,
│  OpenMeteoMapper  │   fusionne les deux séries sur les horodatages
└─────────┬─────────┘
          │ List<WeatherData> normalisées
          ▼
┌───────────────────┐   repli automatique · comparaison · hors ligne
│ WeatherRepository │
└─────────┬─────────┘
          ▼
┌───────────────────┐   + SpotContext
│   WeatherMapper   │   (scoring_pipeline)
└─────────┬─────────┘
          ▼
┌───────────────────┐
│  FishScoreEngine  │
└─────────┬─────────┘
          ▼
    ScoredForecast   (score · confiance · explication · provenance)
```

## Décisions

### 1. Un paquet séparé plutôt qu'un fournisseur embarqué

`weather` reste sans dépendance HTTP. Conséquences : ses modèles restent purs,
un consommateur qui n'a besoin que des modèles n'embarque pas de client
réseau, et ajouter StormGlass ou OpenWeather se fait en créant un paquet frère
— sans toucher au code existant, comme demandé.

### 2. Conversion pilotée par la réponse, pas par la requête

On demande `wind_speed_unit=kmh`, mais on **vérifie** ce que l'API déclare dans
`hourly_units` et on convertit en conséquence. Un changement de défaut côté
Open-Meteo, un miroir mal configuré ou un paramètre ignoré ne peut donc pas
corrompre les données silencieusement. Une unité inconnue lève une erreur.

### 3. La houle est optionnelle, pas l'atmosphère

L'API marine ne couvre pas tous les points du globe (lacs, intérieur des
terres). Son échec dégrade la réponse au lieu de l'annuler : le moteur
FishScore renormalise sans la composante houle et abaisse la confiance.
L'échec de l'API prévision reste bloquant.

### 4. Horodatages traités comme de l'UTC

Avec `timezone=UTC`, Open-Meteo renvoie `2026-10-15T19:00`, sans suffixe de
fuseau. `DateTime.parse` en ferait une date locale ; le mapper ajoute
explicitement le `Z`. Erreur classique, cause de décalages silencieux.

### 5. Bornage côté client

L'API raisonne en jours pleins (`start_date` / `end_date`). Le fournisseur
filtre ensuite la série sur la fenêtre réellement demandée.

### 6. Client HTTP injectable

`OpenMeteoProvider` accepte un `http.Client`, ce qui permet de rejouer les
tests sur fixtures sans réseau, et plus tard d'introduire un pooling ou un
proxy sans modifier le fournisseur.

### 7. Les erreurs applicatives priment sur le statut HTTP

Open-Meteo renvoie parfois un 400 accompagné d'un corps
`{"error": true, "reason": "..."}`. La raison est plus utile qu'un code : elle
est extraite et remontée en priorité.

## Limites connues

- pas de cache : chaque appel interroge l'API (le cache est prévu, aligné sur
  la table `weather_snapshots`) ;
- pas de nouvelle tentative automatique : le repli du `WeatherRepository` joue
  ce rôle pour l'instant ;
- pas de limitation de débit côté client.

## Évolutions prévues

- cache de prévisions avec date de validité ;
- `weather_stormglass` et `weather_openweather` en paquets frères ;
- fusion pondérée de plusieurs fournisseurs via
  `WeatherRepository.fetchFromAll`.
