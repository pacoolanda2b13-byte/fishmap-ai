// Démonstration FishMap AI — Dart pur, sans Flutter.
//
// Interroge réellement Open-Meteo, calcule le FishScore de chaque espèce MVP
// et affiche score, confiance, explication et provenance.
//
// Usage :
//   dart run bin/evaluate.dart                                  # Solenzara, maintenant
//   dart run bin/evaluate.dart 41.86 9.40                       # coordonnées
//   dart run bin/evaluate.dart 41.86 9.40 2026-10-15T19:00Z     # + instant
//   dart run bin/evaluate.dart --verbose 41.86 9.40
import 'dart:io';

import 'package:core/core.dart';
import 'package:fishmap_example/evaluate.dart';

/// Zone pilote par défaut : Solenzara, côte est de la Corse.
const double defaultLatitude = 41.86;
const double defaultLongitude = 9.40;

Future<void> main(List<String> args) async {
  final List<String> positional =
      args.where((String a) => !a.startsWith('--')).toList();
  final bool verbose = args.contains('--verbose');

  final double latitude = positional.isNotEmpty
      ? double.tryParse(positional[0]) ?? defaultLatitude
      : defaultLatitude;
  final double longitude = positional.length > 1
      ? double.tryParse(positional[1]) ?? defaultLongitude
      : defaultLongitude;
  final DateTime date = positional.length > 2
      ? (DateTime.tryParse(positional[2])?.toUtc() ?? DateTime.now().toUtc())
      : DateTime.now().toUtc();

  stdout
    ..writeln('FishMap AI — évaluation')
    ..writeln('Position : $latitude, $longitude')
    ..writeln('Instant  : ${date.toIso8601String()}')
    ..writeln('Source   : Open-Meteo (données réelles)')
    ..writeln('');

  final Result<List<SpeciesEvaluation>> result = await evaluate(
    latitude: latitude,
    longitude: longitude,
    date: date,
    logger: verbose ? ConsoleLogger(minLevel: LogLevel.debug) : const NoopLogger(),
  );

  result.fold(
    onSuccess: _printEvaluations,
    onFailure: (Failure failure) {
      stderr
        ..writeln('Évaluation impossible : ${failure.code}')
        ..writeln(failure.message);
      exitCode = 1;
    },
  );
}

void _printEvaluations(List<SpeciesEvaluation> evaluations) {
  for (final SpeciesEvaluation e in evaluations) {
    stdout
      ..writeln('── ${e.commonNameFr} ' '─' * (28 - e.commonNameFr.length))
      ..writeln('Score       : ${e.score}/100 (${e.scored.result.level.labelFr})')
      ..writeln('Confiance   : ${e.confidence}/100'
          '${e.scored.result.hasLimitedData ? '  ⚠ données limitées' : ''}')
      ..writeln('Explication : ${e.explanation}')
      ..writeln('Provenance  : ${e.provenance}')
      ..writeln('');
  }

  final SpeciesEvaluation best = evaluations.first;
  stdout.writeln(
    'Recommandation : ${best.commonNameFr} (${best.score}/100).',
  );
}
