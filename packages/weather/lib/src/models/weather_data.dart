import 'package:meta/meta.dart';

/// Observation ou prévision météo/marine à un instant donné, **normalisée**.
///
/// Toutes les valeurs sont exprimées dans les unités canoniques de FishMap AI
/// (km/h, m, s, °C, hPa). Les champs sont optionnels : un fournisseur ne
/// couvre pas toujours l'ensemble des paramètres. La structure est
/// indépendante de tout fournisseur.
@immutable
class WeatherData {
  const WeatherData({
    required this.observedAt,
    required this.source,
    this.windSpeedKmh,
    this.windDirectionDeg,
    this.gustSpeedKmh,
    this.waveHeightM,
    this.wavePeriodS,
    this.waveDirectionDeg,
    this.seaTemperatureC,
    this.airTemperatureC,
    this.pressureHpa,
    this.precipitationMm,
    this.cloudCoverPct,
  })  : assert(windDirectionDeg == null ||
            (windDirectionDeg >= 0 && windDirectionDeg < 360)),
        assert(waveDirectionDeg == null ||
            (waveDirectionDeg >= 0 && waveDirectionDeg < 360)),
        assert(cloudCoverPct == null ||
            (cloudCoverPct >= 0 && cloudCoverPct <= 100));

  /// Instant de validité de la donnée (UTC recommandé).
  final DateTime observedAt;

  /// Nom du fournisseur ayant produit la donnée (traçabilité).
  final String source;

  final double? windSpeedKmh;
  final double? windDirectionDeg;
  final double? gustSpeedKmh;

  final double? waveHeightM;
  final double? wavePeriodS;
  final double? waveDirectionDeg;

  final double? seaTemperatureC;
  final double? airTemperatureC;

  final double? pressureHpa;
  final double? precipitationMm;
  final double? cloudCoverPct;

  /// Vrai si aucun paramètre marin/météo n'est renseigné.
  bool get isEmpty =>
      windSpeedKmh == null &&
      gustSpeedKmh == null &&
      waveHeightM == null &&
      wavePeriodS == null &&
      seaTemperatureC == null &&
      airTemperatureC == null &&
      pressureHpa == null &&
      precipitationMm == null;

  WeatherData copyWith({
    DateTime? observedAt,
    String? source,
    double? windSpeedKmh,
    double? windDirectionDeg,
    double? gustSpeedKmh,
    double? waveHeightM,
    double? wavePeriodS,
    double? waveDirectionDeg,
    double? seaTemperatureC,
    double? airTemperatureC,
    double? pressureHpa,
    double? precipitationMm,
    double? cloudCoverPct,
  }) {
    return WeatherData(
      observedAt: observedAt ?? this.observedAt,
      source: source ?? this.source,
      windSpeedKmh: windSpeedKmh ?? this.windSpeedKmh,
      windDirectionDeg: windDirectionDeg ?? this.windDirectionDeg,
      gustSpeedKmh: gustSpeedKmh ?? this.gustSpeedKmh,
      waveHeightM: waveHeightM ?? this.waveHeightM,
      wavePeriodS: wavePeriodS ?? this.wavePeriodS,
      waveDirectionDeg: waveDirectionDeg ?? this.waveDirectionDeg,
      seaTemperatureC: seaTemperatureC ?? this.seaTemperatureC,
      airTemperatureC: airTemperatureC ?? this.airTemperatureC,
      pressureHpa: pressureHpa ?? this.pressureHpa,
      precipitationMm: precipitationMm ?? this.precipitationMm,
      cloudCoverPct: cloudCoverPct ?? this.cloudCoverPct,
    );
  }

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    double? d(String key) => (json[key] as num?)?.toDouble();
    return WeatherData(
      observedAt: DateTime.parse(json['observed_at'] as String),
      source: json['source'] as String? ?? 'unknown',
      windSpeedKmh: d('wind_speed_kmh'),
      windDirectionDeg: d('wind_direction_deg'),
      gustSpeedKmh: d('gust_speed_kmh'),
      waveHeightM: d('wave_height_m'),
      wavePeriodS: d('wave_period_s'),
      waveDirectionDeg: d('wave_direction_deg'),
      seaTemperatureC: d('sea_temperature_c'),
      airTemperatureC: d('air_temperature_c'),
      pressureHpa: d('pressure_hpa'),
      precipitationMm: d('precipitation_mm'),
      cloudCoverPct: d('cloud_cover_pct'),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'observed_at': observedAt.toIso8601String(),
        'source': source,
        if (windSpeedKmh != null) 'wind_speed_kmh': windSpeedKmh,
        if (windDirectionDeg != null) 'wind_direction_deg': windDirectionDeg,
        if (gustSpeedKmh != null) 'gust_speed_kmh': gustSpeedKmh,
        if (waveHeightM != null) 'wave_height_m': waveHeightM,
        if (wavePeriodS != null) 'wave_period_s': wavePeriodS,
        if (waveDirectionDeg != null) 'wave_direction_deg': waveDirectionDeg,
        if (seaTemperatureC != null) 'sea_temperature_c': seaTemperatureC,
        if (airTemperatureC != null) 'air_temperature_c': airTemperatureC,
        if (pressureHpa != null) 'pressure_hpa': pressureHpa,
        if (precipitationMm != null) 'precipitation_mm': precipitationMm,
        if (cloudCoverPct != null) 'cloud_cover_pct': cloudCoverPct,
      };
}
