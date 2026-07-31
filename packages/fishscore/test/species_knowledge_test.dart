import 'dart:convert';
import 'dart:io';

import 'package:fishscore/fishscore.dart';
import 'package:test/test.dart';

/// Localise le dossier `knowledge/species` en remontant depuis le répertoire
/// courant (racine du package en test).
Directory findKnowledgeDir() {
  Directory dir = Directory.current;
  for (int i = 0; i < 8; i++) {
    final Directory candidate = Directory('${dir.path}/knowledge/species');
    if (candidate.existsSync()) return candidate;
    dir = dir.parent;
  }
  fail(
      'Dossier knowledge/species introuvable depuis ${Directory.current.path}');
}

Map<String, dynamic> loadSheet(Directory dir, String slug) {
  final File file = File('${dir.path}/$slug.json');
  expect(file.existsSync(), isTrue, reason: 'fiche manquante : $slug.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

/// Comparaison profonde, insensible à l'ordre des clés de map et tolérante sur
/// les nombres (int vs double).
bool deepEquals(dynamic a, dynamic b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final dynamic key in a.keys) {
      if (!b.containsKey(key)) return false;
      if (!deepEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (!deepEquals(a[i], b[i])) return false;
    }
    return true;
  }
  if (a is num && b is num) return (a - b).abs() < 1e-9;
  return a == b;
}

void main() {
  final Directory knowledgeDir = findKnowledgeDir();
  const List<String> mvpSlugs = <String>[
    'barracuda',
    'loup',
    'dorade-royale',
    'liche',
  ];

  group('fiches de connaissance', () {
    test('les quatre espèces MVP ont une fiche', () {
      for (final String slug in mvpSlugs) {
        expect(File('${knowledgeDir.path}/$slug.json').existsSync(), isTrue,
            reason: slug);
      }
    });

    for (final String slug in mvpSlugs) {
      group(slug, () {
        test('la fiche construit un profil valide', () {
          final SpeciesProfile p =
              SpeciesProfile.fromJson(loadSheet(knowledgeDir, slug));
          expect(p.slug, slug);
          expect(p.windIdealMaxKmh, lessThan(p.windTolerableMaxKmh));
          expect(p.waveIdealMinM, lessThanOrEqualTo(p.waveIdealMaxM));
          expect(p.depthIdealMinM, lessThanOrEqualTo(p.depthIdealMaxM));
          expect(p.thermal.seasonScores, isNotEmpty);
          expect(p.primeHours, isNotEmpty);
        });

        test('fromJson puis toJson préserve la calibration de la fiche', () {
          final Map<String, dynamic> sheet = loadSheet(knowledgeDir, slug);
          final SpeciesProfile p = SpeciesProfile.fromJson(sheet);
          expect(
            deepEquals(p.toJson()['calibration'], sheet['calibration']),
            isTrue,
            reason: 'round-trip incohérent pour $slug',
          );
        });

        test('la fiche est cohérente avec le catalogue embarqué', () {
          final SpeciesProfile fromSheet =
              SpeciesProfile.fromJson(loadSheet(knowledgeDir, slug));
          final SpeciesProfile? fromCatalog = SpeciesCatalog.bySlug(slug);
          expect(fromCatalog, isNotNull);
          expect(
            deepEquals(fromSheet.toJson(), fromCatalog!.toJson()),
            isTrue,
            reason: 'le catalogue embarqué diverge de la fiche $slug ; '
                'régénérer le catalogue depuis knowledge/species',
          );
        });
      });
    }

    test('le catalogue embarqué couvre exactement les fiches présentes', () {
      final Set<String> sheetSlugs = knowledgeDir
          .listSync()
          .whereType<File>()
          .map((File f) => f.uri.pathSegments.last)
          .where((String n) => n.endsWith('.json') && n != 'schema.json')
          .map((String n) => n.substring(0, n.length - '.json'.length))
          .toSet();
      expect(SpeciesCatalog.all.keys.toSet(), sheetSlugs);
    });
  });
}
