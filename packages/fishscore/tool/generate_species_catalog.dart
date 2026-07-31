// Générateur du catalogue d'espèces.
//
// Lit les fiches `knowledge/species/*.json` (seule source de vérité) et
// produit `lib/src/species/species_catalog.g.dart`. Le catalogue Dart n'est
// jamais modifié à la main.
//
// Usage :
//   dart run tool/generate_species_catalog.dart          # (ré)génère
//   dart run tool/generate_species_catalog.dart --check  # vérifie (CI)
import 'dart:convert';
import 'dart:io';

const String outputPath = 'lib/src/species/species_catalog.g.dart';

void main(List<String> args) {
  final bool checkOnly = args.contains('--check');

  final Directory knowledgeDir = _findKnowledgeDir();
  final List<File> sheets = knowledgeDir
      .listSync()
      .whereType<File>()
      .where((File f) =>
          f.path.endsWith('.json') && !f.path.endsWith('schema.json'))
      .toList()
    ..sort((File a, File b) => a.path.compareTo(b.path));

  if (sheets.isEmpty) {
    stderr.writeln('Aucune fiche trouvée dans ${knowledgeDir.path}');
    exit(1);
  }

  final String generated = _format(_generate(sheets));

  final File output = File(outputPath);
  if (checkOnly) {
    final String current = output.existsSync() ? output.readAsStringSync() : '';
    if (current != generated) {
      stderr.writeln(
        'Catalogue obsolète : lancez '
        '"dart run tool/generate_species_catalog.dart" puis committez '
        '$outputPath',
      );
      exit(1);
    }
    stdout.writeln('Catalogue à jour (${sheets.length} espèces).');
    return;
  }

  output.writeAsStringSync(generated);
  stdout.writeln('Généré $outputPath (${sheets.length} espèces).');
}

/// Passe le code généré par `dart format` (via un fichier temporaire) pour
/// garantir une sortie stable et conforme au vérificateur de format de la CI.
String _format(String source) {
  final Directory tmp = Directory.systemTemp.createTempSync('fishscore_gen');
  try {
    final File f = File('${tmp.path}/generated.dart')
      ..writeAsStringSync(source);
    final ProcessResult result =
        Process.runSync('dart', <String>['format', f.path]);
    if (result.exitCode != 0) {
      stderr.writeln('dart format a échoué : ${result.stderr}');
      exit(1);
    }
    return f.readAsStringSync();
  } finally {
    tmp.deleteSync(recursive: true);
  }
}

Directory _findKnowledgeDir() {
  Directory dir = Directory.current;
  for (int i = 0; i < 8; i++) {
    final Directory candidate = Directory('${dir.path}/knowledge/species');
    if (candidate.existsSync()) return candidate;
    dir = dir.parent;
  }
  stderr.writeln(
      'Dossier knowledge/species introuvable depuis ${Directory.current.path}');
  exit(1);
}

String _generate(List<File> sheets) {
  final StringBuffer b = StringBuffer()
    ..writeln('// GENERATED FILE — DO NOT EDIT.')
    ..writeln('//')
    ..writeln('// Source de vérité : knowledge/species/*.json')
    ..writeln('// Régénérer avec : dart run tool/generate_species_catalog.dart')
    ..writeln()
    ..writeln("import '../models/enums.dart';")
    ..writeln("import '../models/knowledge.dart';")
    ..writeln("import 'species_profile.dart';")
    ..writeln()
    ..writeln('/// Profils générés depuis les fiches de connaissances.')
    ..writeln('const Map<String, SpeciesProfile> kGeneratedSpeciesProfiles =')
    ..writeln('    <String, SpeciesProfile>{');

  for (final File sheet in sheets) {
    final Map<String, dynamic> json =
        jsonDecode(sheet.readAsStringSync()) as Map<String, dynamic>;
    b.write(_profileEntry(json));
  }

  b.writeln('};');
  return b.toString();
}

String _profileEntry(Map<String, dynamic> json) {
  final String slug = json['slug'] as String;
  final Map<String, dynamic> cal = json['calibration'] as Map<String, dynamic>;
  final Map<String, dynamic> wind = cal['wind'] as Map<String, dynamic>;
  final Map<String, dynamic> waves = cal['waves'] as Map<String, dynamic>;
  final Map<String, dynamic> hours = cal['hours'] as Map<String, dynamic>;
  final Map<String, dynamic> thermal = cal['thermal'] as Map<String, dynamic>;
  final Map<String, dynamic> seasonScores =
      thermal['season_scores'] as Map<String, dynamic>;
  final Map<String, dynamic> bottoms =
      (cal['bottoms'] as Map<String, dynamic>?) ?? const <String, dynamic>{};
  final Map<String, dynamic> depth = cal['depth'] as Map<String, dynamic>;
  final Map<String, dynamic> moon = cal['moon'] as Map<String, dynamic>;
  final Map<String, dynamic> overrides =
      (cal['weight_overrides'] as Map<String, dynamic>?) ??
          const <String, dynamic>{};
  final String confidence = (json['confidence'] as String?) ?? 'hypothesis';
  final List<dynamic> sources =
      (json['sources'] as List<dynamic>?) ?? const <dynamic>[];

  String windows(String key) {
    final List<dynamic> raw =
        (hours[key] as List<dynamic>?) ?? const <dynamic>[];
    if (raw.isEmpty) return '<HourWindow>[]';
    final String items = raw
        .map((dynamic w) => 'HourWindow(${(w as List<dynamic>)[0]}, ${w[1]})')
        .join(', ');
    return '<HourWindow>[$items]';
  }

  String seasonMap() {
    final String items = seasonScores.entries
        .map((MapEntry<String, dynamic> e) => 'Season.${e.key}: ${e.value}')
        .join(', ');
    return '<Season, int>{$items}';
  }

  String bottomsMap() {
    if (bottoms.isEmpty) return '<BottomType, int>{}';
    final String items = bottoms.entries
        .map((MapEntry<String, dynamic> e) => 'BottomType.${e.key}: ${e.value}')
        .join(', ');
    return '<BottomType, int>{$items}';
  }

  String overridesMap() {
    if (overrides.isEmpty) return '<String, double>{}';
    final String items = overrides.entries
        .map((MapEntry<String, dynamic> e) => "'${e.key}': ${e.value}")
        .join(', ');
    return '<String, double>{$items}';
  }

  String sourcesList() {
    if (sources.isEmpty) return '<KnowledgeSource>[]';
    final String items = sources.map((dynamic s) {
      final Map<String, dynamic> src = s as Map<String, dynamic>;
      final String type = _sourceTypeName(src['type'] as String);
      final List<String> fields = <String>['type: KnowledgeSourceType.$type'];
      if (src['count'] != null) fields.add('count: ${src['count']}');
      if (src['reference'] != null) {
        fields.add("reference: ${_dartString(src['reference'] as String)}");
      }
      return 'KnowledgeSource(${fields.join(', ')})';
    }).join(', ');
    return '<KnowledgeSource>[$items]';
  }

  final StringBuffer b = StringBuffer()
    ..writeln("  '$slug': SpeciesProfile(")
    ..writeln("    slug: '$slug',")
    ..writeln(
        '    commonNameFr: ${_dartString(json['common_name_fr'] as String)},')
    ..writeln('    windIdealMaxKmh: ${wind['ideal_max_kmh']},')
    ..writeln('    windTolerableMaxKmh: ${wind['tolerable_max_kmh']},')
    ..writeln('    waveIdealMinM: ${waves['ideal_min_m']},')
    ..writeln('    waveIdealMaxM: ${waves['ideal_max_m']},')
    ..writeln('    waveFalloffM: ${waves['falloff_m']},')
    ..writeln('    primeHours: ${windows('prime')},')
    ..writeln('    goodHours: ${windows('good')},')
    ..writeln('    baselineHourScore: ${hours['baseline_score']},')
    ..writeln('    thermal: ThermalPreference(')
    ..writeln('      idealMinC: ${thermal['ideal_min_c']},')
    ..writeln('      idealMaxC: ${thermal['ideal_max_c']},')
    ..writeln('      toleranceC: ${thermal['tolerance_c']},')
    ..writeln('      seasonScores: ${seasonMap()},')
    ..writeln('    ),')
    ..writeln('    preferredBottoms: ${bottomsMap()},')
    ..writeln('    depthIdealMinM: ${depth['ideal_min_m']},')
    ..writeln('    depthIdealMaxM: ${depth['ideal_max_m']},')
    ..writeln('    depthFalloffM: ${depth['falloff_m']},')
    ..writeln('    favorsSpringTide: ${moon['favors_spring_tide']},')
    ..writeln('    weightOverrides: ${overridesMap()},')
    ..writeln('    confidence: KnowledgeConfidence.$confidence,')
    ..writeln('    sources: ${sourcesList()},')
    ..writeln('  ),');
  return b.toString();
}

String _sourceTypeName(String jsonName) => switch (jsonName) {
      'ifremer' => 'ifremer',
      'scientific_publication' => 'scientificPublication',
      'fishing_guide' => 'fishingGuide',
      'field_observation' => 'fieldObservation',
      _ => throw FormatException('Type de source inconnu : "$jsonName"'),
    };

String _dartString(String value) =>
    "'${value.replaceAll(r'\', r'\\').replaceAll("'", r"\'")}'";
