import 'dart:io';

import 'package:test/test.dart';

/// Vérifie la règle d'architecture du dépôt :
///
/// > Les packages métier ne dépendent que de `core`, jamais entre eux. Seules
/// > les couches de composition peuvent dépendre de plusieurs packages métier.
///
/// Ce test échoue si quelqu'un ajoute une dépendance croisée, ce qui rendrait
/// impossible la suppression d'un package sans casser les autres.
void main() {
  /// Packages métier : ne doivent dépendre d'aucun autre package du dépôt
  /// hormis `core`.
  const Set<String> businessPackages = <String>{'fishscore', 'weather'};

  /// Couches de composition : autorisées à assembler plusieurs packages.
  const Set<String> compositionPackages = <String>{'scoring_pipeline'};

  /// Adaptateurs : implémentent le contrat d'un seul package métier (leur
  /// port) et ne dépendent donc que de `core` et de ce package.
  const Map<String, String> adapterPackages = <String, String>{
    'weather_openmeteo': 'weather',
  };

  final Directory packagesDir = _findPackagesDir();

  Set<String> localDependenciesOf(String package) {
    final File pubspec = File('${packagesDir.path}/$package/pubspec.yaml');
    expect(pubspec.existsSync(), isTrue, reason: 'pubspec manquant: $package');

    // Repère les dépendances par chemin : "  <nom>:\n    path: ../<nom>".
    final RegExp pathDependency = RegExp(
      r'^\s{2}(\w+):\s*\n\s+path:\s*\.\./(\w+)\s*$',
      multiLine: true,
    );
    return pathDependency
        .allMatches(pubspec.readAsStringSync())
        .map((RegExpMatch m) => m.group(2)!)
        .toSet();
  }

  group('règles d\'architecture', () {
    test('core ne dépend d\'aucun package du dépôt', () {
      expect(localDependenciesOf('core'), isEmpty,
          reason: 'core doit rester le socle sans dépendance interne');
    });

    for (final String package in businessPackages) {
      test('$package ne dépend que de core', () {
        final Set<String> deps = localDependenciesOf(package);
        final Set<String> forbidden = deps.difference(<String>{'core'});
        expect(
          forbidden,
          isEmpty,
          reason: '$package dépend de $forbidden : un package métier ne doit '
              'jamais dépendre d\'un autre package métier. Déplacer '
              'l\'assemblage dans une couche de composition '
              '(${compositionPackages.join(', ')}).',
        );
      });
    }

    test('aucun package métier ne se cite mutuellement', () {
      for (final String package in businessPackages) {
        final Set<String> deps = localDependenciesOf(package);
        for (final String other in businessPackages) {
          if (other == package) continue;
          expect(deps.contains(other), isFalse,
              reason: '$package dépend de $other');
        }
      }
    });

    test('les couches de composition dépendent bien de core', () {
      for (final String package in compositionPackages) {
        expect(localDependenciesOf(package), contains('core'));
      }
    });

    for (final MapEntry<String, String> entry in adapterPackages.entries) {
      test('${entry.key} ne dépend que de core et de ${entry.value}', () {
        final Set<String> deps = localDependenciesOf(entry.key);
        final Set<String> forbidden =
            deps.difference(<String>{'core', entry.value});
        expect(
          forbidden,
          isEmpty,
          reason: '${entry.key} dépend de $forbidden : un adaptateur ne doit '
              'connaître que son port (${entry.value}) et core.',
        );
        expect(deps, contains(entry.value),
            reason: '${entry.key} doit implémenter le contrat de '
                '${entry.value}');
      });
    }

    test('aucun package métier ne dépend d\'un adaptateur', () {
      for (final String package in businessPackages) {
        final Set<String> deps = localDependenciesOf(package);
        for (final String adapter in adapterPackages.keys) {
          expect(deps.contains(adapter), isFalse,
              reason: '$package dépend de l\'adaptateur $adapter : '
                  'l\'inversion de dépendance est cassée');
        }
      }
    });
  });
}

Directory _findPackagesDir() {
  Directory dir = Directory.current;
  for (int i = 0; i < 8; i++) {
    final Directory candidate = Directory('${dir.path}/packages');
    if (candidate.existsSync()) return candidate;
    dir = dir.parent;
  }
  fail('Dossier packages introuvable depuis ${Directory.current.path}');
}
