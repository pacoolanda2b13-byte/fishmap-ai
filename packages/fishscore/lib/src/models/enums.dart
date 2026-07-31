/// Énumérations partagées du moteur FishScore.
library;

/// Saisons de l'hémisphère nord, utilisées pour la calibration biologique.
enum Season {
  winter,
  spring,
  summer,
  autumn;

  /// Déduit la saison à partir du mois (1 = janvier ... 12 = décembre).
  static Season fromMonth(int month) {
    assert(month >= 1 && month <= 12, 'month must be between 1 and 12');
    return switch (month) {
      12 || 1 || 2 => Season.winter,
      3 || 4 || 5 => Season.spring,
      6 || 7 || 8 => Season.summer,
      _ => Season.autumn,
    };
  }
}

/// Nature du fond marin au niveau du spot.
enum BottomType {
  sand,
  gravel,
  rock,
  posidonia,
  mixed,
  mud,
  unknown,
}

/// Qualité de la source décrivant un spot.
///
/// Reflète l'enum `data_quality` de la base de données.
enum DataQuality {
  estimated,
  observed,
  verified;

  /// Facteur de confiance associé, entre 0 et 1.
  double get confidenceFactor => switch (this) {
        DataQuality.estimated => 0.34,
        DataQuality.observed => 0.67,
        DataQuality.verified => 1.0,
      };
}

/// Niveau qualitatif dérivé du score numérique, pour l'affichage produit.
enum ScoreLevel {
  poor,
  fair,
  good,
  excellent;

  /// Convertit un score 0-100 en niveau qualitatif.
  static ScoreLevel fromScore(int score) {
    if (score >= 80) return ScoreLevel.excellent;
    if (score >= 60) return ScoreLevel.good;
    if (score >= 40) return ScoreLevel.fair;
    return ScoreLevel.poor;
  }

  /// Libellé français court destiné à l'interface.
  String get labelFr => switch (this) {
        ScoreLevel.poor => 'Faible',
        ScoreLevel.fair => 'Moyen',
        ScoreLevel.good => 'Bon',
        ScoreLevel.excellent => 'Excellent',
      };
}
