import 'package:fishscore/fishscore.dart';
import 'package:weather/weather.dart';

import 'spot_context.dart';

/// Transforme des données météo normalisées en entrée FishScore.
///
/// C'est le pont `WeatherData` → `WeatherMapper` → `FishScoreInput`. Il vit
/// dans la couche de composition : ni `weather` ni `fishscore` ne se
/// connaissent, seul ce mapper connaît les deux.
class WeatherMapper {
  const WeatherMapper();

  /// Construit une [FishScoreInput] pour [speciesSlug] à l'instant
  /// [evaluatedAt], en piochant l'échantillon météo le plus proche dans
  /// [forecast] et en calculant la tendance de pression sur 3 heures.
  FishScoreInput toFishScoreInput({
    required WeatherForecast forecast,
    required String speciesSlug,
    required DateTime evaluatedAt,
    SpotContext spot = const SpotContext(),
    MoonPhase? moonPhase,
  }) {
    final WeatherData? sample = forecast.nearest(evaluatedAt);

    return FishScoreInput(
      speciesSlug: speciesSlug,
      evaluatedAt: evaluatedAt,
      spotSuitability: spot.spotSuitability,
      bottomType: spot.bottomType,
      depthMeters: spot.depthMeters,
      windSpeedKmh: sample?.windSpeedKmh,
      gustSpeedKmh: sample?.gustSpeedKmh,
      waveHeightM: sample?.waveHeightM,
      wavePeriodS: sample?.wavePeriodS,
      pressureHpa: sample?.pressureHpa,
      pressureTrendHpaPer3h: forecast.pressureTrendHpaPer3h(evaluatedAt),
      seaTemperatureC: sample?.seaTemperatureC,
      airTemperatureC: sample?.airTemperatureC,
      moonPhase: moonPhase,
      history: spot.history,
      spotQuality: spot.spotQuality,
      weatherObservedAt: sample?.observedAt,
    );
  }
}
