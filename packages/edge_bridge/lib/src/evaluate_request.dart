import 'package:core/core.dart';
import 'package:meta/meta.dart';

/// Requête d'évaluation reçue par `POST /evaluate`.
///
/// La validation est faite ici, en Dart, plutôt que côté TypeScript : les
/// règles restent au même endroit que le reste de la logique et sont
/// testables sans navigateur ni Deno.
@immutable
class EvaluateRequest {
  const EvaluateRequest({
    required this.location,
    required this.evaluatedAt,
    this.speciesSlug,
  });

  /// Position évaluée.
  final Coordinates location;

  /// Instant évalué, en UTC.
  final DateTime evaluatedAt;

  /// Espèce ciblée. Si absent, toutes les espèces actives sont évaluées.
  final String? speciesSlug;

  /// Analyse et valide un corps de requête JSON.
  ///
  /// Renvoie un [ValidationFailure] explicite plutôt que de lever : l'appelant
  /// traduit directement en réponse HTTP 400.
  static Result<EvaluateRequest> parse(Map<String, dynamic> json) {
    final Object? rawLat = json['latitude'];
    final Object? rawLng = json['longitude'];

    if (rawLat is! num) {
      return const Result<EvaluateRequest>.failure(
        ValidationFailure('Champ "latitude" manquant ou non numérique'),
      );
    }
    if (rawLng is! num) {
      return const Result<EvaluateRequest>.failure(
        ValidationFailure('Champ "longitude" manquant ou non numérique'),
      );
    }

    final double latitude = rawLat.toDouble();
    final double longitude = rawLng.toDouble();
    if (latitude < -90 || latitude > 90) {
      return const Result<EvaluateRequest>.failure(
        ValidationFailure('"latitude" doit être comprise entre -90 et 90'),
      );
    }
    if (longitude < -180 || longitude > 180) {
      return const Result<EvaluateRequest>.failure(
        ValidationFailure('"longitude" doit être comprise entre -180 et 180'),
      );
    }

    final Object? rawDate = json['date'];
    DateTime evaluatedAt;
    if (rawDate == null) {
      evaluatedAt = DateTime.now().toUtc();
    } else if (rawDate is String) {
      final DateTime? parsed = DateTime.tryParse(rawDate);
      if (parsed == null) {
        return const Result<EvaluateRequest>.failure(
          ValidationFailure('"date" doit être une date ISO 8601'),
        );
      }
      evaluatedAt = parsed.toUtc();
    } else {
      return const Result<EvaluateRequest>.failure(
        ValidationFailure('"date" doit être une chaîne ISO 8601'),
      );
    }

    final Object? rawSpecies = json['species'];
    if (rawSpecies != null && rawSpecies is! String) {
      return const Result<EvaluateRequest>.failure(
        ValidationFailure('"species" doit être une chaîne'),
      );
    }
    final String? speciesSlug = (rawSpecies as String?)?.trim().isEmpty ?? true
        ? null
        : (rawSpecies as String).trim();

    return Result<EvaluateRequest>.success(
      EvaluateRequest(
        location: Coordinates(latitude: latitude, longitude: longitude),
        evaluatedAt: evaluatedAt,
        speciesSlug: speciesSlug,
      ),
    );
  }
}
