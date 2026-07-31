# weather — Architecture

Version : 0.2

## Objectif

Découpler totalement FishMap AI de tout fournisseur météo, et permettre d'en
combiner plusieurs sans que le reste de l'application le sache.

## Principe directeur

> **Un seul modèle normalisé, plusieurs fournisseurs interchangeables, une
> seule porte d'entrée.**

## Couches

```
┌──────────────────────────────────────────────────────────┐
│ Adaptateurs (dans ce package ou externes)                │
│   OpenMeteoProvider · StormGlassProvider · OpenWeather…   │
│   → convertissent les unités natives via core.Units       │
└──────────────────┬───────────────────────────────────────┘
                   │ implémentent
           ┌───────▼────────┐
           │ WeatherProvider│  + StaticWeatherProvider (mémoire)
           └───────┬────────┘
                   │ orchestrés par
          ┌────────▼─────────┐
          │ WeatherRepository│  repli · comparaison · hors ligne
          └────────┬─────────┘
                   │ produit
          ┌────────▼─────────┐
          │ WeatherForecast  │  série triée + nearest + tendance pression
          │   └ WeatherData  │  modèle normalisé, immuable
          └──────────────────┘
                   │ consommé par
          ┌────────▼─────────────────┐
          │ scoring_pipeline (compo.) │  → FishScoreInput
          └───────────────────────────┘
```

## Décisions

### 1. Unités canoniques imposées au bord

`WeatherData` n'accepte que des unités canoniques (km/h, m, s, °C, hPa). La
conversion est faite par les adaptateurs à l'entrée, via `core.Units`.

### 2. Champs optionnels plutôt que valeurs par défaut

Un fournisseur peut ne pas couvrir la houle ou la température d'eau. Les champs
absents restent `null` ; le moteur FishScore gère la donnée manquante
(renormalisation, confiance abaissée). On ne fabrique jamais de fausse valeur.

### 3. La tendance de pression est calculée sur la série

Plutôt que d'exiger la tendance du fournisseur, `WeatherForecast` la dérive de
deux échantillons distants d'environ 3 heures et la ramène à une base de 3 h.
Robuste aux pas d'échantillonnage variables.

### 4. Le dépôt est la seule porte d'entrée

Aucun appelant ne parle directement à un `WeatherProvider`. Cela permet
d'ajouter un fournisseur, de changer l'ordre de préférence ou d'introduire un
cache sans toucher aux appelants.

### 5. Échecs en valeur, pas en exception

`WeatherRepository` renvoie `Result<ProviderForecast>`. Toute exception d'un
fournisseur est capturée et convertie en `Failure` typé ; si tous échouent, un
`CompositeFailure` conserve les causes individuelles pour le diagnostic.

### 6. Une réponse vide vaut une indisponibilité

Un fournisseur qui répond mais ne renvoie aucun échantillon n'est pas
exploitable : le dépôt passe au suivant plutôt que de propager une série vide.

### 7. Aucun fournisseur réseau embarqué

Le package ne dépend d'aucun client HTTP et ne contient aucun secret. Il
fournit l'interface et un fournisseur mémoire déterministe, ce qui rend toute
la chaîne testable hors ligne.

### 8. Aucune connaissance de FishScore

Conformément à la règle d'architecture du dépôt, `weather` ne dépend que de
`core`. Le pont vers le moteur de score vit dans `scoring_pipeline`. On doit
pouvoir supprimer `packages/weather` sans casser `packages/fishscore`, et
inversement — c'est vérifié par un test automatisé
(`packages/core/test/architecture_rules_test.dart`).

## Évolutions prévues

- `OpenMeteoProvider` (marine + atmosphérique) — premier adaptateur réel ;
- cache de prévisions avec date de validité (aligné sur `weather_snapshots`) ;
- fusion pondérée de plusieurs fournisseurs à partir de `fetchFromAll` ;
- interpolation entre échantillons ;
- direction du vent relative à l'exposition du spot.
