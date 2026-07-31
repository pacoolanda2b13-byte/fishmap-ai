import 'package:meta/meta.dart';

/// Niveau de confiance d'une calibration d'espèce.
///
/// Aligné sur le champ `confidence` des fiches `knowledge/species`.
enum KnowledgeConfidence {
  /// Valeurs prudentes non encore vérifiées.
  hypothesis,

  /// Valeurs appuyées par un volume d'observations terrain.
  observed,

  /// Valeurs confirmées par des sources fiables et référencées.
  validated;

  /// Libellé français court.
  String get labelFr => switch (this) {
        KnowledgeConfidence.hypothesis => 'hypothèse',
        KnowledgeConfidence.observed => 'observé',
        KnowledgeConfidence.validated => 'validé',
      };
}

/// Type de source justifiant une calibration.
enum KnowledgeSourceType {
  ifremer('ifremer'),
  scientificPublication('scientific_publication'),
  fishingGuide('fishing_guide'),
  fieldObservation('field_observation');

  const KnowledgeSourceType(this.jsonName);

  /// Nom utilisé dans les fiches JSON.
  final String jsonName;

  static KnowledgeSourceType fromJsonName(String name) =>
      KnowledgeSourceType.values.firstWhere(
        (KnowledgeSourceType t) => t.jsonName == name,
        orElse: () => throw ArgumentError('Type de source inconnu : "$name"'),
      );

  /// Libellés français singulier/pluriel pour les résumés de provenance.
  String labelFr(int count) => switch (this) {
        KnowledgeSourceType.ifremer =>
          count > 1 ? 'données Ifremer' : 'donnée Ifremer',
        KnowledgeSourceType.scientificPublication =>
          count > 1 ? 'publications scientifiques' : 'publication scientifique',
        KnowledgeSourceType.fishingGuide =>
          count > 1 ? 'guides de pêche' : 'guide de pêche',
        KnowledgeSourceType.fieldObservation =>
          count > 1 ? 'observations terrain' : 'observation terrain',
      };
}

/// Source traçable justifiant une calibration d'espèce.
@immutable
class KnowledgeSource {
  const KnowledgeSource({
    required this.type,
    this.count = 1,
    this.reference,
  }) : assert(count >= 1, 'count doit être >= 1');

  /// Nature de la source.
  final KnowledgeSourceType type;

  /// Nombre d'éléments couverts par cette entrée (ex. 42 observations).
  final int count;

  /// Référence lisible (titre, DOI, nom du guide…).
  final String? reference;

  factory KnowledgeSource.fromJson(Map<String, dynamic> json) =>
      KnowledgeSource(
        type: KnowledgeSourceType.fromJsonName(json['type'] as String),
        count: (json['count'] as num?)?.toInt() ?? 1,
        reference: json['reference'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type.jsonName,
        if (count != 1) 'count': count,
        if (reference != null) 'reference': reference,
      };
}

/// Résume une liste de sources en français.
///
/// Exemple : « 42 observations terrain + 3 publications scientifiques ».
/// Renvoie `null` si la liste est vide.
String? summarizeSourcesFr(List<KnowledgeSource> sources) {
  if (sources.isEmpty) return null;
  final Map<KnowledgeSourceType, int> totals = <KnowledgeSourceType, int>{};
  for (final KnowledgeSource source in sources) {
    totals.update(source.type, (int c) => c + source.count,
        ifAbsent: () => source.count);
  }
  // Ordre stable : volume décroissant, puis ordre de l'enum.
  final List<KnowledgeSourceType> ordered = totals.keys.toList()
    ..sort((KnowledgeSourceType a, KnowledgeSourceType b) {
      final int byCount = totals[b]!.compareTo(totals[a]!);
      return byCount != 0 ? byCount : a.index.compareTo(b.index);
    });
  return ordered
      .map((KnowledgeSourceType t) => '${totals[t]} ${t.labelFr(totals[t]!)}')
      .join(' + ');
}
