// GENERATED FILE — DO NOT EDIT.
//
// Source de vérité : knowledge/species/*.json
// Régénérer avec : dart run tool/generate_species_catalog.dart

import '../models/enums.dart';
import '../models/knowledge.dart';
import 'species_profile.dart';

/// Profils générés depuis les fiches de connaissances.
const Map<String, SpeciesProfile> kGeneratedSpeciesProfiles =
    <String, SpeciesProfile>{
  'barracuda': SpeciesProfile(
    slug: 'barracuda',
    commonNameFr: 'Barracuda',
    windIdealMaxKmh: 20,
    windTolerableMaxKmh: 42,
    waveIdealMinM: 0.1,
    waveIdealMaxM: 0.6,
    waveFalloffM: 0.9,
    primeHours: <HourWindow>[HourWindow(5, 8), HourWindow(18, 22)],
    goodHours: <HourWindow>[HourWindow(8, 10), HourWindow(16, 18)],
    baselineHourScore: 25,
    thermal: ThermalPreference(
      idealMinC: 18,
      idealMaxC: 24,
      toleranceC: 6,
      seasonScores: <Season, int>{
        Season.summer: 85,
        Season.autumn: 100,
        Season.spring: 55,
        Season.winter: 25
      },
    ),
    preferredBottoms: <BottomType, int>{
      BottomType.rock: 90,
      BottomType.posidonia: 80,
      BottomType.mixed: 70,
      BottomType.gravel: 55,
      BottomType.sand: 40,
      BottomType.mud: 25
    },
    depthIdealMinM: 3,
    depthIdealMaxM: 25,
    depthFalloffM: 20,
    favorsSpringTide: true,
    weightOverrides: <String, double>{},
    confidence: KnowledgeConfidence.hypothesis,
    sources: <KnowledgeSource>[],
  ),
  'dorade-royale': SpeciesProfile(
    slug: 'dorade-royale',
    commonNameFr: 'Dorade royale',
    windIdealMaxKmh: 15,
    windTolerableMaxKmh: 32,
    waveIdealMinM: 0,
    waveIdealMaxM: 0.4,
    waveFalloffM: 0.7,
    primeHours: <HourWindow>[HourWindow(5, 9), HourWindow(17, 20)],
    goodHours: <HourWindow>[HourWindow(9, 17)],
    baselineHourScore: 35,
    thermal: ThermalPreference(
      idealMinC: 18,
      idealMaxC: 24,
      toleranceC: 5,
      seasonScores: <Season, int>{
        Season.summer: 100,
        Season.autumn: 85,
        Season.spring: 55,
        Season.winter: 25
      },
    ),
    preferredBottoms: <BottomType, int>{
      BottomType.sand: 90,
      BottomType.posidonia: 85,
      BottomType.gravel: 75,
      BottomType.mixed: 65,
      BottomType.mud: 60,
      BottomType.rock: 45
    },
    depthIdealMinM: 2,
    depthIdealMaxM: 15,
    depthFalloffM: 15,
    favorsSpringTide: false,
    weightOverrides: <String, double>{},
    confidence: KnowledgeConfidence.hypothesis,
    sources: <KnowledgeSource>[],
  ),
  'liche': SpeciesProfile(
    slug: 'liche',
    commonNameFr: 'Liche amie',
    windIdealMaxKmh: 22,
    windTolerableMaxKmh: 46,
    waveIdealMinM: 0.2,
    waveIdealMaxM: 0.9,
    waveFalloffM: 1.0,
    primeHours: <HourWindow>[HourWindow(5, 8), HourWindow(18, 21)],
    goodHours: <HourWindow>[HourWindow(8, 10), HourWindow(16, 18)],
    baselineHourScore: 25,
    thermal: ThermalPreference(
      idealMinC: 20,
      idealMaxC: 26,
      toleranceC: 5,
      seasonScores: <Season, int>{
        Season.summer: 100,
        Season.autumn: 70,
        Season.spring: 45,
        Season.winter: 15
      },
    ),
    preferredBottoms: <BottomType, int>{
      BottomType.sand: 80,
      BottomType.mixed: 75,
      BottomType.posidonia: 70,
      BottomType.gravel: 70,
      BottomType.rock: 65,
      BottomType.mud: 40
    },
    depthIdealMinM: 2,
    depthIdealMaxM: 20,
    depthFalloffM: 18,
    favorsSpringTide: true,
    weightOverrides: <String, double>{},
    confidence: KnowledgeConfidence.hypothesis,
    sources: <KnowledgeSource>[],
  ),
  'loup': SpeciesProfile(
    slug: 'loup',
    commonNameFr: 'Loup',
    windIdealMaxKmh: 30,
    windTolerableMaxKmh: 55,
    waveIdealMinM: 0.3,
    waveIdealMaxM: 1.2,
    waveFalloffM: 1.1,
    primeHours: <HourWindow>[
      HourWindow(5, 8),
      HourWindow(18, 23),
      HourWindow(0, 2)
    ],
    goodHours: <HourWindow>[HourWindow(8, 10), HourWindow(16, 18)],
    baselineHourScore: 30,
    thermal: ThermalPreference(
      idealMinC: 12,
      idealMaxC: 20,
      toleranceC: 6,
      seasonScores: <Season, int>{
        Season.autumn: 100,
        Season.spring: 90,
        Season.winter: 75,
        Season.summer: 55
      },
    ),
    preferredBottoms: <BottomType, int>{
      BottomType.rock: 85,
      BottomType.mixed: 80,
      BottomType.sand: 70,
      BottomType.gravel: 65,
      BottomType.posidonia: 60,
      BottomType.mud: 40
    },
    depthIdealMinM: 1,
    depthIdealMaxM: 15,
    depthFalloffM: 18,
    favorsSpringTide: true,
    weightOverrides: <String, double>{},
    confidence: KnowledgeConfidence.hypothesis,
    sources: <KnowledgeSource>[],
  ),
};
