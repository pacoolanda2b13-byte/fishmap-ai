// Point d'entrée compilé en JavaScript pour les Edge Functions Supabase.
//
// Construire avec :
//   dart compile js -O2 -o ../../supabase/functions/_shared/bridge.js bin/bridge.dart
import 'package:edge_bridge/src/js_bridge.dart';

void main() => installBridge();
