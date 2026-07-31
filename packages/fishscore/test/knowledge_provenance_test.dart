import 'package:fishscore/fishscore.dart';
import 'package:test/test.dart';

void main() {
  group('KnowledgeSource', () {
    test('fromJson/toJson round-trip', () {
      final KnowledgeSource s = KnowledgeSource.fromJson(const {
        'type': 'scientific_publication',
        'count': 3,
        'reference': 'Étude Sparus aurata 2024',
      });
      expect(s.type, KnowledgeSourceType.scientificPublication);
      expect(s.count, 3);
      expect(s.toJson()['type'], 'scientific_publication');
      expect(s.toJson()['count'], 3);
    });

    test('type inconnu rejeté', () {
      expect(
        () => KnowledgeSource.fromJson(const {'type': 'blog'}),
        throwsArgumentError,
      );
    });
  });

  group('summarizeSourcesFr', () {
    test('produit le résumé attendu par le produit', () {
      final String? summary = summarizeSourcesFr(const <KnowledgeSource>[
        KnowledgeSource(type: KnowledgeSourceType.fieldObservation, count: 42),
        KnowledgeSource(
            type: KnowledgeSourceType.scientificPublication, count: 3),
      ]);
      expect(summary, '42 observations terrain + 3 publications scientifiques');
    });

    test('agrège les entrées de même type et gère le singulier', () {
      final String? summary = summarizeSourcesFr(const <KnowledgeSource>[
        KnowledgeSource(type: KnowledgeSourceType.fishingGuide),
        KnowledgeSource(type: KnowledgeSourceType.fieldObservation, count: 5),
        KnowledgeSource(type: KnowledgeSourceType.fieldObservation, count: 2),
      ]);
      expect(summary, '7 observations terrain + 1 guide de pêche');
    });

    test('null sans source', () {
      expect(summarizeSourcesFr(const <KnowledgeSource>[]), isNull);
    });
  });

  group('SpeciesProfile provenance', () {
    test('le catalogue généré porte le niveau de confiance des fiches', () {
      for (final SpeciesProfile p in SpeciesCatalog.all.values) {
        expect(p.confidence, KnowledgeConfidence.hypothesis,
            reason: '${p.slug} devrait être en hypothèse pour le MVP');
      }
    });

    test('résumé de repli honnête sans source', () {
      final SpeciesProfile p = SpeciesCatalog.bySlug('loup')!;
      expect(p.provenanceSummaryFr, contains('hypothèse'));
      expect(p.provenanceSummaryFr, contains('aucune source'));
    });

    test('fromJson lit confidence et sources', () {
      final SpeciesProfile base = SpeciesCatalog.bySlug('barracuda')!;
      final Map<String, dynamic> sheet = base.toJson()
        ..['confidence'] = 'observed'
        ..['sources'] = <Map<String, dynamic>>[
          {'type': 'field_observation', 'count': 42},
          {'type': 'ifremer', 'count': 2},
        ];
      final SpeciesProfile enriched = SpeciesProfile.fromJson(sheet);
      expect(enriched.confidence, KnowledgeConfidence.observed);
      expect(enriched.provenanceSummaryFr,
          '42 observations terrain + 2 données Ifremer');
    });
  });
}
