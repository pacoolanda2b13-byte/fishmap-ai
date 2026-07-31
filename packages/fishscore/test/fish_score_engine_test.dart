import 'package:fishscore/fishscore.dart';
import 'package:test/test.dart';

/// Entrée riche et favorable pour le loup en automne, à l'aube.
FishScoreInput richInput({String species = 'loup'}) => FishScoreInput(
      speciesSlug: species,
      evaluatedAt: DateTime.utc(2026, 10, 15, 7),
      spotSuitability: 80,
      bottomType: BottomType.rock,
      depthMeters: 6,
      windSpeedKmh: 18,
      gustSpeedKmh: 28,
      waveHeightM: 0.6,
      wavePeriodS: 5,
      pressureHpa: 1012,
      pressureTrendHpaPer3h: -2.5,
      seaTemperatureC: 17,
      airTemperatureC: 19,
      moonPhase: MoonPhase.newMoon,
      history: const LocalHistory(observationCount: 8, userCatchCount: 4),
      spotQuality: DataQuality.verified,
      weatherObservedAt: DateTime.utc(2026, 10, 15, 6),
    );

void main() {
  final FishScoreEngine engine = FishScoreEngine();

  group('bornes du score', () {
    test('reste toujours entre 0 et 100 sur des entrées extrêmes', () {
      final List<FishScoreInput> inputs = <FishScoreInput>[
        richInput(),
        FishScoreInput(
          speciesSlug: 'dorade-royale',
          evaluatedAt: DateTime.utc(2026, 1, 3, 3),
          windSpeedKmh: 90,
          gustSpeedKmh: 120,
          waveHeightM: 4,
          seaTemperatureC: 8,
          pressureTrendHpaPer3h: 6,
        ),
        FishScoreInput(
          speciesSlug: 'barracuda',
          evaluatedAt: DateTime.utc(2026, 9, 20, 19),
          windSpeedKmh: 0,
          waveHeightM: 0,
          seaTemperatureC: 22,
          pressureTrendHpaPer3h: -8,
          spotSuitability: 100,
        ),
      ];
      for (final FishScoreInput input in inputs) {
        final FishScoreResult r = engine.evaluate(input);
        expect(r.score, inInclusiveRange(0, 100));
        expect(r.confidence, inInclusiveRange(0, 100));
      }
    });
  });

  group('renormalisation avec données manquantes', () {
    test('les poids des composantes disponibles se somment à ~1', () {
      final FishScoreResult r = engine.evaluate(richInput());
      final double sum = r.components
          .where((ComponentScore c) => c.available)
          .fold<double>(0, (double a, ComponentScore c) => a + c.weight);
      expect(sum, closeTo(1.0, 0.0001));
    });

    test('une composante sans donnée est marquée indisponible et de poids nul',
        () {
      // Aucune météo ni houle fournies : ces composantes doivent disparaître.
      final FishScoreInput input = FishScoreInput(
        speciesSlug: 'loup',
        evaluatedAt: DateTime.utc(2026, 10, 15, 7),
        spotSuitability: 80,
      );
      final FishScoreResult r = engine.evaluate(input);
      final ComponentScore wind =
          r.components.firstWhere((ComponentScore c) => c.id == 'wind');
      expect(wind.available, isFalse);
      expect(wind.weight, 0);
      // La saison reste disponible (déduite de la date).
      final ComponentScore season = r.components
          .firstWhere((ComponentScore c) => c.id == 'season_temperature');
      expect(season.available, isTrue);
    });

    test('un score reste calculable avec un minimum de données', () {
      final FishScoreInput input = FishScoreInput(
        speciesSlug: 'barracuda',
        evaluatedAt: DateTime.utc(2026, 10, 1, 6),
      );
      final FishScoreResult r = engine.evaluate(input);
      expect(r.score, inInclusiveRange(0, 100));
    });
  });

  group('déterminisme', () {
    test('mêmes entrées, même sortie', () {
      final FishScoreResult a = engine.evaluate(richInput());
      final FishScoreResult b = engine.evaluate(richInput());
      expect(a.score, b.score);
      expect(a.confidence, b.confidence);
      expect(a.positiveFactors, b.positiveFactors);
      expect(a.negativeFactors, b.negativeFactors);
      expect(a.explanation, b.explanation);
    });
  });

  group('confiance', () {
    test('élevée quand les données sont complètes et fraîches', () {
      final FishScoreResult r = engine.evaluate(richInput());
      expect(r.confidence, greaterThanOrEqualTo(60));
      expect(r.hasLimitedData, isFalse);
    });

    test('faible quand les données sont incomplètes', () {
      final FishScoreInput input = FishScoreInput(
        speciesSlug: 'loup',
        evaluatedAt: DateTime.utc(2026, 10, 15, 7),
      );
      final FishScoreResult r = engine.evaluate(input);
      expect(r.confidence, lessThan(40));
      expect(r.hasLimitedData, isTrue);
      expect(r.explanation.toLowerCase(), contains('données limitées'));
    });
  });

  group('facteurs explicables', () {
    test('au maximum trois facteurs positifs et trois négatifs', () {
      final FishScoreResult r = engine.evaluate(richInput());
      expect(r.positiveFactors.length, lessThanOrEqualTo(3));
      expect(r.negativeFactors.length, lessThanOrEqualTo(3));
    });

    test('aucune formulation ne présente le score comme une garantie', () {
      final Iterable<FishScoreResult> results = <FishScoreInput>[
        richInput(),
        richInput(species: 'dorade-royale'),
        richInput(species: 'barracuda'),
        richInput(species: 'liche'),
      ].map(engine.evaluate);
      final RegExp forbidden =
          RegExp(r'chance|garanti|% de captur|certitude', caseSensitive: false);
      for (final FishScoreResult r in results) {
        final String text =
            '${(r.positiveFactors + r.negativeFactors).join(' ')} ${r.explanation}';
        expect(forbidden.hasMatch(text), isFalse, reason: text);
      }
    });
  });

  group('modificateur de pression', () {
    test('une pression en baisse améliore le score et ajoute un facteur', () {
      final FishScoreInput falling = richInput();
      final FishScoreInput rising = FishScoreInput(
        speciesSlug: falling.speciesSlug,
        evaluatedAt: falling.evaluatedAt,
        spotSuitability: falling.spotSuitability,
        bottomType: falling.bottomType,
        depthMeters: falling.depthMeters,
        windSpeedKmh: falling.windSpeedKmh,
        gustSpeedKmh: falling.gustSpeedKmh,
        waveHeightM: falling.waveHeightM,
        pressureTrendHpaPer3h: 3,
        seaTemperatureC: falling.seaTemperatureC,
        moonPhase: falling.moonPhase,
        history: falling.history,
        spotQuality: falling.spotQuality,
        weatherObservedAt: falling.weatherObservedAt,
      );
      final FishScoreResult a = engine.evaluate(falling);
      final FishScoreResult b = engine.evaluate(rising);
      expect(a.score, greaterThan(b.score));
      expect(
        a.positiveFactors
            .any((String f) => f.toLowerCase().contains('pression')),
        isTrue,
      );
    });
  });

  group('espèces', () {
    test('espèce inconnue lève une exception', () {
      expect(
        () => engine.evaluate(FishScoreInput(
          speciesSlug: 'thon-rouge',
          evaluatedAt: DateTime.utc(2026, 7, 1, 6),
        )),
        throwsA(isA<UnknownSpeciesException>()),
      );
    });

    test('le catalogue couvre les quatre espèces MVP', () {
      expect(
        SpeciesCatalog.all.keys.toSet(),
        {'barracuda', 'loup', 'dorade-royale', 'liche'},
      );
    });
  });

  group('meilleur créneau', () {
    test('identifie une fenêtre favorable sur la journée', () {
      final FishScoreInput base = richInput();
      final FishScoreResult r = engine.evaluateBestWindow(
        base,
        from: DateTime.utc(2026, 10, 15, 0),
        to: DateTime.utc(2026, 10, 15, 23, 30),
        step: const Duration(minutes: 30),
      );
      expect(r.bestWindow, isNotNull);
      final BestWindow w = r.bestWindow!;
      expect(w.score, r.score);
      expect(w.end.isAfter(w.start), isTrue);
      // Le loup est crépusculaire : le meilleur créneau doit tomber tôt ou tard.
      final int hour = w.start.hour;
      expect(hour <= 9 || hour >= 17, isTrue, reason: 'heure=$hour');
    });
  });

  group('sérialisation', () {
    test('toJson expose les champs du contrat v1', () {
      final Map<String, dynamic> json = engine.evaluate(richInput()).toJson();
      expect(json['model_version'], 'fishscore-v1.0.0');
      expect(json.containsKey('score'), isTrue);
      expect(json.containsKey('confidence'), isTrue);
      expect(json['component_scores'], isA<Map<String, dynamic>>());
    });
  });

  group('extensibilité', () {
    test('un poids surchargé par espèce est pris en compte', () {
      // Profil dérivé qui ignore la lune (poids 0) et renforce l'historique.
      const SpeciesProfile tuned = SpeciesProfile(
        slug: 'loup',
        commonNameFr: 'Loup',
        windIdealMaxKmh: 30,
        windTolerableMaxKmh: 55,
        waveIdealMinM: 0.3,
        waveIdealMaxM: 1.2,
        waveFalloffM: 1.1,
        primeHours: [HourWindow(5, 8)],
        goodHours: [HourWindow(18, 22)],
        baselineHourScore: 30,
        thermal: ThermalPreference(
          idealMinC: 12,
          idealMaxC: 20,
          toleranceC: 6,
          seasonScores: {Season.autumn: 100},
        ),
        preferredBottoms: {BottomType.rock: 85},
        depthIdealMinM: 1,
        depthIdealMaxM: 15,
        depthFalloffM: 18,
        favorsSpringTide: true,
        weightOverrides: {'moon': 0.0},
      );
      final FishScoreEngine custom =
          FishScoreEngine(speciesProfiles: {'loup': tuned});
      final FishScoreResult r = custom.evaluate(richInput());
      final ComponentScore moon =
          r.components.firstWhere((ComponentScore c) => c.id == 'moon');
      // Poids nul => la composante ne pèse pas dans le score renormalisé.
      expect(moon.weight, 0);
    });
  });
}
