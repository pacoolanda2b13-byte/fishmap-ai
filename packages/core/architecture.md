# core — Architecture

Version : 0.1

## Objectif

Fournir le socle commun qui permet aux packages métier de rester totalement
indépendants les uns des autres.

## Position dans le dépôt

```
        ┌────────────┐   ┌────────────┐   ┌──────────────┐
        │ fishscore  │   │  weather   │   │ (futurs pkgs)│
        └─────┬──────┘   └─────┬──────┘   └──────┬───────┘
              │                │                 │
              └───────────┬────┴─────────────────┘
                          ▼
                    ┌──────────┐
                    │   core   │   ← seul point de dépendance autorisé
                    └──────────┘
```

Aucune flèche horizontale : les packages métier ne se connaissent pas. Les
assemblages inter-packages vivent dans des couches de composition explicites
(`packages/scoring_pipeline`, futur backend, future app), qui sont les seules
autorisées à dépendre de plusieurs packages métier.

## Décisions

### 1. `Result`/`Failure` plutôt qu'exceptions pour les échecs attendus

Les frontières faillibles (réseau, parsing, stockage) renvoient `Result<T>`.
L'appelant est forcé par le typage de considérer l'échec. Les exceptions
(`AppException`) restent pour les erreurs de programmation.

### 2. Codes d'échec stables

Chaque `Failure` porte un code SCREAMING_SNAKE_CASE aligné sur les codes
métier du contrat API (`docs/API_CONTRACT.md`), pour une traduction directe
en réponses d'erreur.

### 3. Value objects plutôt que primitives

`Coordinates`, `Distance` : les `double` nus ambigus (degrés ? mètres ? km ?)
sont interdits dans les signatures publiques des packages.

### 4. Horloge injectable

`TimeProvider` rend déterministe tout code dépendant du temps. `DateTime.now()`
est interdit hors `SystemTimeProvider`.

### 5. Journalisation sans données sensibles

Le contrat `Logger` impose des messages expurgés : jamais de coordonnées
exactes de spots privés, jamais de jetons. C'est une exigence de
`docs/QUALITY_AND_SECURITY.md` appliquée au niveau du socle.

## Ce que core ne doit jamais contenir

- de la logique métier (scoring, météo, notifications…) ;
- des dépendances Flutter ou Supabase ;
- des clients HTTP ou du code réseau ;
- des types spécifiques à un fournisseur externe.
