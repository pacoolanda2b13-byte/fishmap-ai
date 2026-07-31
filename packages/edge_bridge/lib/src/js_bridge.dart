import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:core/core.dart';
import 'package:weather/weather.dart';
import 'package:weather_openmeteo/weather_openmeteo.dart';

import 'evaluate_request.dart';
import 'evaluation_handler.dart';
import 'js_http_client.dart';

@JS('globalThis')
external JSObject get _globalThis;

/// Nom sous lequel la fonction d'évaluation est exposée à l'hôte JavaScript.
const String bridgeFunctionName = 'fishmapEvaluate';

/// Installe le pont sur l'objet global.
///
/// L'hôte TypeScript appelle ensuite :
///
/// ```ts
/// const responseJson = await globalThis.fishmapEvaluate(
///   requestJson, httpGet, cacheRead, cacheWrite,
/// );
/// ```
///
/// Toute l'orchestration — cache, repli entre fournisseurs, mapping,
/// scoring — reste en Dart. TypeScript ne fournit que les entrées/sorties,
/// ce qui évite de dupliquer la logique métier côté Deno.
void installBridge() {
  _globalThis[bridgeFunctionName] = ((
    JSString requestJson,
    JSFunction httpGet,
    JSFunction cacheRead,
    JSFunction cacheWrite,
    JSNumber cacheTtlSeconds,
  ) {
    return _evaluate(
      requestJson.toDart,
      httpGet,
      cacheRead,
      cacheWrite,
      Duration(seconds: cacheTtlSeconds.toDartInt),
    ).then((String json) => json.toJS).toJS;
  }).toJS;
}

Future<String> _evaluate(
  String requestJson,
  JSFunction httpGet,
  JSFunction cacheRead,
  JSFunction cacheWrite,
  Duration cacheTtl,
) async {
  Map<String, dynamic> decoded;
  try {
    decoded = jsonDecode(requestJson) as Map<String, dynamic>;
  } on FormatException catch (e) {
    return _errorResponse(
        ValidationFailure('Corps JSON invalide : ${e.message}'));
  }

  final Result<EvaluateRequest> parsed = EvaluateRequest.parse(decoded);
  final EvaluateRequest? request = parsed.valueOrNull;
  if (request == null) {
    return _errorResponse(parsed.failureOrNull!);
  }

  // Le cache est branché sur PostgreSQL via les rappels fournis par l'hôte.
  final WeatherCache cache = WeatherCache(
    ttl: cacheTtl,
    store: SerializedWeatherCacheStore(
      readJson: (String key) async {
        final JSPromise<JSAny?> p =
            cacheRead.callAsFunction(null, key.toJS)! as JSPromise<JSAny?>;
        final JSAny? value = await p.toDart;
        return value.isUndefinedOrNull ? null : (value! as JSString).toDart;
      },
      writeJson: (String key, String json) async {
        final JSPromise<JSAny?> p = cacheWrite.callAsFunction(
          null,
          key.toJS,
          json.toJS,
        )! as JSPromise<JSAny?>;
        await p.toDart;
      },
      deleteKey: (String key) async {
        // Une entrée périmée est écrasée à la prochaine écriture ; la purge
        // en base est assurée par `purge_expired_weather_cache()`.
      },
    ),
  );

  final WeatherRepository repository = WeatherRepository(
    providers: <WeatherProvider>[
      OpenMeteoProvider(httpClient: JsHttpClient(httpGet)),
    ],
    cache: cache,
  );

  final Result<Map<String, dynamic>> response =
      await EvaluationHandler(weatherRepository: repository).handle(request);

  return response.fold(
    onSuccess: (Map<String, dynamic> body) => jsonEncode(<String, dynamic>{
      'status': 200,
      'body': body,
    }),
    onFailure: _errorResponse,
  );
}

String _errorResponse(Failure failure) => jsonEncode(<String, dynamic>{
      'status': EvaluationHandler.httpStatusFor(failure),
      'body': EvaluationHandler.errorBody(failure),
    });
