import '../errors/app_exception.dart';

/// Configuration applicative en lecture seule.
///
/// Les valeurs proviennent de variables d'environnement ou d'un fichier de
/// configuration chargé au démarrage. Aucun secret n'est codé en dur : ce
/// composant ne fait que lire ce qu'on lui fournit.
class AppConfig {
  const AppConfig(Map<String, String> values) : _values = values;

  /// Configuration vide (utile par défaut et en tests).
  const AppConfig.empty() : _values = const <String, String>{};

  final Map<String, String> _values;

  /// Valeur brute, ou `null` si absente.
  String? maybe(String key) => _values[key];

  /// Valeur obligatoire. Lève [ConfigException] si absente ou vide.
  String require(String key) {
    final String? value = _values[key];
    if (value == null || value.isEmpty) {
      throw ConfigException('Configuration manquante : "$key"');
    }
    return value;
  }

  /// Valeur chaîne avec défaut.
  String getString(String key, {required String defaultValue}) =>
      _values[key] ?? defaultValue;

  /// Valeur entière avec défaut. Lève [ConfigException] si non numérique.
  int getInt(String key, {required int defaultValue}) {
    final String? raw = _values[key];
    if (raw == null) return defaultValue;
    final int? parsed = int.tryParse(raw);
    if (parsed == null) {
      throw ConfigException('Valeur entière invalide pour "$key" : "$raw"');
    }
    return parsed;
  }

  /// Valeur booléenne avec défaut (`true`/`false`, `1`/`0`, `yes`/`no`).
  bool getBool(String key, {required bool defaultValue}) {
    final String? raw = _values[key]?.toLowerCase();
    if (raw == null) return defaultValue;
    return switch (raw) {
      'true' || '1' || 'yes' => true,
      'false' || '0' || 'no' => false,
      _ =>
        throw ConfigException('Valeur booléenne invalide pour "$key" : "$raw"'),
    };
  }

  /// Vrai si la clé existe.
  bool contains(String key) => _values.containsKey(key);
}
