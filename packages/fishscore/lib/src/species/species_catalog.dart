import 'species_catalog.g.dart';
import 'species_profile.dart';

/// Catalogue des profils d'espèces.
///
/// Le contenu est **généré automatiquement** depuis `knowledge/species/*.json`
/// (voir `species_catalog.g.dart`). Ne jamais modifier un profil à la main :
/// éditer la fiche JSON puis relancer
/// `dart run tool/generate_species_catalog.dart`.
class SpeciesCatalog {
  const SpeciesCatalog._();

  /// Tous les profils, indexés par slug.
  static const Map<String, SpeciesProfile> all = kGeneratedSpeciesProfiles;

  /// Retourne le profil correspondant au slug, ou `null` s'il est inconnu.
  static SpeciesProfile? bySlug(String slug) => all[slug];
}
