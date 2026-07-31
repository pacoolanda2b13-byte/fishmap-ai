# weather — Architecture

Version : 0.1

## Objectif

Découpler totalement FishMap AI de tout fournisseur météo. Le moteur FishScore
ne doit jamais connaître l'origine des données : il consomme un modèle
normalisé et stable.

## Principe directeur

> **Un seul modèle normalisé, plusieurs fournisseurs interchangeables.**

Toutes les données transitent par `WeatherData`, exprimé dans des unités
canoniques. Les fournisseurs sont des détails d'implémentation cachés derrière
l'interface `WeatherProvider`.

## Couches

```
┌─────────────────────────────────────────────────────────────┐
│ Adaptateurs de fournisseurs (hors de ce package)            │
│   OpenMeteoProvider, StormglassProvider, …                  │
│   → convertissent les unités natives via WeatherUnits       │
└───────────────┬─────────────────────────────────────────────┘
                │ implémentent
        ┌───────▼────────┐
        │ WeatherProvider│  (interface)   + StaticWeatherProvider (fake)
        └───────┬────────┘
                │ produisent
        ┌───────▼────────┐
        │ WeatherForecast│  série triée + nearest() + tendance pression
        │  └ WeatherData │  modèle normalisé, immuable
        └───────┬────────┘
                │ consommés par
        ┌───────▼────────┐
        │ WeatherMapper  │  + SpotContext
        └───────┬────────┘
                │ produit
        ┌───────▼────────┐
        │ FishScoreInput │  (package fishscore)
        └────────────────┘
```

## Décisions

### 1. Unités canoniques imposées au bord

`WeatherData` n'accepte que des unités canoniques (km/h, m, s, °C, hPa). La
conversion est faite par les adaptateurs à l'entrée, via `WeatherUnits`. Le
cœur ne manipule ainsi jamais d'ambiguïté d'unité.

### 2. Champs optionnels plutôt que valeurs par défaut

Un fournisseur peut ne pas renseigner la houle ou la température d'eau. Les
champs absents restent `null` ; c'est le moteur FishScore qui gère la donnée
manquante (renormalisation, confiance abaissée). On ne fabrique jamais de
fausse valeur.

### 3. La tendance de pression est calculée sur la série

Plutôt que d'exiger la tendance du fournisseur, `WeatherForecast` la dérive de
deux échantillons distants d'environ 3 heures et la ramène à une base de 3 h.
C'est robuste à des pas d'échantillonnage variables.

### 4. Accès par proximité temporelle

`nearest(instant)` évite d'imposer un alignement exact des horaires entre la
demande utilisateur et les pas du fournisseur. Le mapper s'appuie dessus.

### 5. Aucun fournisseur réseau embarqué

Le package ne dépend d'aucun client HTTP. Il fournit uniquement l'interface et
un `StaticWeatherProvider` (mémoire) avec un générateur déterministe, ce qui
rend toute la chaîne testable hors ligne et sans secret.

### 6. Séparation météo / spot

`WeatherMapper` combine deux sources distinctes : la météo (`WeatherForecast`)
et le contexte du spot (`SpotContext` : compatibilité, fond, profondeur,
qualité, historique). Le mapper ne mélange pas ces responsabilités.

## Dépendances

- `fishscore` (chemin) — pour produire `FishScoreInput` et réutiliser
  `BottomType`, `DataQuality`, `LocalHistory`, `MoonPhase`.
- `meta` — annotations d'immuabilité.

Aucune dépendance à Flutter : le package est utilisable côté application comme
côté fonction serveur.

## Évolutions prévues

- adaptateur Open-Meteo (marine + atmosphérique) comme premier fournisseur réel ;
- cache de prévisions avec date de validité (aligné sur `weather_snapshots`) ;
- interpolation optionnelle entre échantillons ;
- direction du vent relative à l'exposition du spot dans le mapping.
