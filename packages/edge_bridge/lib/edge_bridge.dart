/// Pont entre la chaîne Dart de FishMap AI et les Edge Functions Supabase.
///
/// La logique d'orchestration ([EvaluationHandler]) et la validation
/// ([EvaluateRequest]) sont en Dart pur, donc testables dans la VM. Seul
/// `src/js_bridge.dart` contient de l'interop JavaScript.
library;

export 'src/evaluate_request.dart';
export 'src/evaluation_handler.dart';
