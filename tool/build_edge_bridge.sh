#!/usr/bin/env bash
#
# Compile le pont Dart en JavaScript pour les Edge Functions Supabase.
#
# À exécuter avant tout déploiement et avant les tests Deno : `bridge.js` est
# un artefact de construction, absent du dépôt.
#
#   ./tool/build_edge_bridge.sh
#
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
bridge_package="$repo_root/packages/edge_bridge"
output="$repo_root/supabase/functions/_shared/bridge.js"

if ! command -v dart >/dev/null 2>&1; then
  echo "Dart SDK introuvable : installez-le avant de construire le pont." >&2
  exit 1
fi

echo "Résolution des dépendances…"
dart pub get --directory "$bridge_package" >/dev/null

mkdir -p "$(dirname "$output")"

echo "Compilation du pont Dart → JavaScript…"
(cd "$bridge_package" && dart compile js -O2 -o "$output" bin/bridge.dart)

# Les fichiers annexes produits par dart2js ne servent pas au déploiement.
rm -f "$output.deps" "$output.map"

size="$(wc -c < "$output" | tr -d ' ')"
echo "Pont construit : $output ($((size / 1024)) Ko)"
