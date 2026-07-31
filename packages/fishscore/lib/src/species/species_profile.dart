import 'package:meta/meta.dart';

import '../models/enums.dart';
import '../models/knowledge.dart';

/// Plage horaire fermée \[startHour, endHour] en heures locales (0-23).
///
/// Peut traverser minuit lorsque [startHour] est supérieur à [endHour]
/// (ex. 21h → 2h).
@immutable
class HourWindow {
  const HourWindow(this.startHour, this.endHour)
      : assert(startHour >= 0 && startHour <= 23),
        assert(endHour >= 0 && endHour <= 23);

  final int startHour;
  final int endHour;

  /// Construit une fenêtre à partir d'un couple `[début, fin]`.
  factory HourWindow.fromJson(List<dynamic> json) => HourWindow(
        (json[0] as num).toInt(),
        (json[1] as num).toInt(),
      );

  /// Vrai si [hour] appartient à la fenêtre (bornes incluses).
  bool contains(int hour) {
    if (startHour <= endHour) {
      return hour >= startHour && hour <= endHour;
    }
    // Fenêtre traversant minuit.
    return hour >= startHour || hour <= endHour;
  }

  /// Sérialise la fenêtre en couple `[début, fin]`.
  List<int> toJson() => <int>[startHour, endHour];
}

/// Préférences de température et de saison d'une espèce.
@immutable
class ThermalPreference {
  const ThermalPreference({
    required this.idealMinC,
    required this.idealMaxC,
    required this.toleranceC,
    required this.seasonScores,
  });

  /// Bornes de la plage de température d'eau idéale.
  final double idealMinC;
  final double idealMaxC;

  /// Largeur de décroissance de part et d'autre de la plage idéale.
  final double toleranceC;

  /// Note de saison (0-100) par saison.
  final Map<Season, int> seasonScores;

  /// Construit une préférence thermique depuis le bloc `thermal` d'une fiche.
  factory ThermalPreference.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawScores =
        (json['season_scores'] as Map<String, dynamic>?) ?? const {};
    return ThermalPreference(
      idealMinC: (json['ideal_min_c'] as num).toDouble(),
      idealMaxC: (json['ideal_max_c'] as num).toDouble(),
      toleranceC: (json['tolerance_c'] as num).toDouble(),
      seasonScores: <Season, int>{
        for (final MapEntry<String, dynamic> e in rawScores.entries)
          Season.values.byName(e.key): (e.value as num).toInt(),
      },
    );
  }

  int seasonScore(Season season) => seasonScores[season] ?? 50;

  /// Sérialise la préférence thermique.
  Map<String, dynamic> toJson() => <String, dynamic>{
        'ideal_min_c': idealMinC,
        'ideal_max_c': idealMaxC,
        'tolerance_c': toleranceC,
        'season_scores': <String, int>{
          for (final MapEntry<Season, int> e in seasonScores.entries)
            e.key.name: e.value,
        },
      };
}

/// Profil de calibration d'une espèce pour le moteur FishScore.
///
/// Les valeurs sont une première calibration prudente pour la zone
/// Solenzara–Aléria. Elles constituent des hypothèses tant qu'elles ne sont
/// pas confirmées par des sources fiables ou un volume suffisant
/// d'observations terrain.
@immutable
class SpeciesProfile {
  const SpeciesProfile({
    required this.slug,
    required this.commonNameFr,
    required this.windIdealMaxKmh,
    required this.windTolerableMaxKmh,
    required this.waveIdealMinM,
    required this.waveIdealMaxM,
    required this.waveFalloffM,
    required this.primeHours,
    required this.goodHours,
    required this.baselineHourScore,
    required this.thermal,
    required this.preferredBottoms,
    required this.depthIdealMinM,
    required this.depthIdealMaxM,
    required this.depthFalloffM,
    required this.favorsSpringTide,
    this.weightOverrides = const {},
    this.confidence = KnowledgeConfidence.hypothesis,
    this.sources = const <KnowledgeSource>[],
  });

  /// Construit un profil à partir d'une fiche de connaissance
  /// (`knowledge/species/<slug>.json`).
  ///
  /// La calibration reste ainsi pilotée par les données et jamais codée en dur
  /// dans le moteur.
  factory SpeciesProfile.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> cal =
        json['calibration'] as Map<String, dynamic>;
    final Map<String, dynamic> wind = cal['wind'] as Map<String, dynamic>;
    final Map<String, dynamic> waves = cal['waves'] as Map<String, dynamic>;
    final Map<String, dynamic> hours = cal['hours'] as Map<String, dynamic>;
    final Map<String, dynamic> depth = cal['depth'] as Map<String, dynamic>;
    final Map<String, dynamic> moon = cal['moon'] as Map<String, dynamic>;
    final Map<String, dynamic> bottoms =
        (cal['bottoms'] as Map<String, dynamic>?) ?? const {};
    final Map<String, dynamic> overrides =
        (cal['weight_overrides'] as Map<String, dynamic>?) ?? const {};

    List<HourWindow> windows(String key) =>
        ((hours[key] as List<dynamic>?) ?? const <dynamic>[])
            .map((dynamic w) => HourWindow.fromJson(w as List<dynamic>))
            .toList(growable: false);

    return SpeciesProfile(
      slug: json['slug'] as String,
      commonNameFr: json['common_name_fr'] as String,
      windIdealMaxKmh: (wind['ideal_max_kmh'] as num).toDouble(),
      windTolerableMaxKmh: (wind['tolerable_max_kmh'] as num).toDouble(),
      waveIdealMinM: (waves['ideal_min_m'] as num).toDouble(),
      waveIdealMaxM: (waves['ideal_max_m'] as num).toDouble(),
      waveFalloffM: (waves['falloff_m'] as num).toDouble(),
      primeHours: windows('prime'),
      goodHours: windows('good'),
      baselineHourScore: (hours['baseline_score'] as num).toInt(),
      thermal:
          ThermalPreference.fromJson(cal['thermal'] as Map<String, dynamic>),
      preferredBottoms: <BottomType, int>{
        for (final MapEntry<String, dynamic> e in bottoms.entries)
          BottomType.values.byName(e.key): (e.value as num).toInt(),
      },
      depthIdealMinM: (depth['ideal_min_m'] as num).toDouble(),
      depthIdealMaxM: (depth['ideal_max_m'] as num).toDouble(),
      depthFalloffM: (depth['falloff_m'] as num).toDouble(),
      favorsSpringTide: moon['favors_spring_tide'] as bool,
      weightOverrides: <String, double>{
        for (final MapEntry<String, dynamic> e in overrides.entries)
          e.key: (e.value as num).toDouble(),
      },
      confidence: json['confidence'] == null
          ? KnowledgeConfidence.hypothesis
          : KnowledgeConfidence.values.byName(json['confidence'] as String),
      sources: ((json['sources'] as List<dynamic>?) ?? const <dynamic>[])
          .map((dynamic s) =>
              KnowledgeSource.fromJson(s as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  /// Identifiant stable de l'espèce.
  final String slug;

  /// Nom commun français.
  final String commonNameFr;

  /// Vent (km/h) jusqu'auquel les conditions restent idéales.
  final double windIdealMaxKmh;

  /// Vent (km/h) au-delà duquel la note de vent tombe à zéro.
  final double windTolerableMaxKmh;

  /// Bornes de houle (m) considérées comme idéales.
  final double waveIdealMinM;
  final double waveIdealMaxM;

  /// Largeur de décroissance de la note de houle hors de la plage idéale.
  final double waveFalloffM;

  /// Fenêtres horaires les plus favorables (note 100).
  final List<HourWindow> primeHours;

  /// Fenêtres horaires favorables (note intermédiaire).
  final List<HourWindow> goodHours;

  /// Note attribuée aux heures hors fenêtres favorables.
  final int baselineHourScore;

  /// Préférences thermiques et saisonnières.
  final ThermalPreference thermal;

  /// Fonds préférés et note de compatibilité associée (0-100).
  final Map<BottomType, int> preferredBottoms;

  /// Plage de profondeur idéale (m).
  final double depthIdealMinM;
  final double depthIdealMaxM;
  final double depthFalloffM;

  /// Vrai si l'espèce est réputée plus active en vive-eau (hypothèse).
  final bool favorsSpringTide;

  /// Surcharges de poids de composantes propres à l'espèce (identifiant → poids).
  final Map<String, double> weightOverrides;

  /// Niveau de confiance de la calibration (hypothèse / observé / validé).
  final KnowledgeConfidence confidence;

  /// Sources traçables justifiant la calibration.
  final List<KnowledgeSource> sources;

  /// Résumé de provenance en français, pour l'explicabilité produit.
  ///
  /// Exemple : « 42 observations terrain + 3 publications scientifiques ».
  /// Sans source référencée, indique le statut de calibration.
  String get provenanceSummaryFr =>
      summarizeSourcesFr(sources) ??
      'Calibration en ${confidence.labelFr}, aucune source référencée';

  /// Solidité des connaissances derrière la calibration, de 0 à 100.
  ///
  /// À ne pas confondre avec la confiance du FishScore : celle-ci mesure la
  /// qualité des **données du moment** (météo disponible, fraîcheur), tandis
  /// que l'`evidenceScore` mesure la qualité du **savoir sur l'espèce**.
  ///
  /// Combine le niveau déclaré et le volume de sources, avec des rendements
  /// décroissants : une dixième observation pèse moins que la première.
  int get evidenceScore {
    final int base = switch (confidence) {
      KnowledgeConfidence.hypothesis => 20,
      KnowledgeConfidence.observed => 50,
      KnowledgeConfidence.validated => 75,
    };

    final int totalSources =
        sources.fold<int>(0, (int acc, KnowledgeSource s) => acc + s.count);
    if (totalSources == 0) return base;

    // Saturation : 0 source → 0 point, 12 sources → environ la moitié du
    // complément disponible.
    final double bonus = (100 - base) * (totalSources / (totalSources + 12));
    return (base + bonus).round().clamp(0, 100);
  }

  /// Note horaire (0-100) pour une heure locale donnée.
  int hourScore(int hour) {
    if (primeHours.any((HourWindow w) => w.contains(hour))) return 100;
    if (goodHours.any((HourWindow w) => w.contains(hour))) return 70;
    return baselineHourScore;
  }

  /// Note de fond (0-100) pour un type de fond donné.
  int bottomScore(BottomType bottom) {
    if (bottom == BottomType.unknown) return 50;
    return preferredBottoms[bottom] ?? 35;
  }

  /// Sérialise le profil au format d'une fiche de connaissance (identité +
  /// bloc `calibration`). Réciproque de [SpeciesProfile.fromJson].
  Map<String, dynamic> toJson() => <String, dynamic>{
        'slug': slug,
        'common_name_fr': commonNameFr,
        'confidence': confidence.name,
        'sources': sources.map((KnowledgeSource s) => s.toJson()).toList(),
        'calibration': <String, dynamic>{
          'wind': <String, dynamic>{
            'ideal_max_kmh': windIdealMaxKmh,
            'tolerable_max_kmh': windTolerableMaxKmh,
          },
          'waves': <String, dynamic>{
            'ideal_min_m': waveIdealMinM,
            'ideal_max_m': waveIdealMaxM,
            'falloff_m': waveFalloffM,
          },
          'hours': <String, dynamic>{
            'prime': primeHours.map((HourWindow w) => w.toJson()).toList(),
            'good': goodHours.map((HourWindow w) => w.toJson()).toList(),
            'baseline_score': baselineHourScore,
          },
          'thermal': thermal.toJson(),
          'bottoms': <String, int>{
            for (final MapEntry<BottomType, int> e in preferredBottoms.entries)
              e.key.name: e.value,
          },
          'depth': <String, dynamic>{
            'ideal_min_m': depthIdealMinM,
            'ideal_max_m': depthIdealMaxM,
            'falloff_m': depthFalloffM,
          },
          'moon': <String, dynamic>{'favors_spring_tide': favorsSpringTide},
          'weight_overrides': weightOverrides,
        },
      };
}
