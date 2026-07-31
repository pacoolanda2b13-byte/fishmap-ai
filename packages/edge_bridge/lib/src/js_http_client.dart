import 'dart:convert';
import 'dart:js_interop';

import 'package:http/http.dart' as http;

/// Client HTTP délégant les requêtes à une fonction JavaScript.
///
/// `package:http` s'appuie sur `dart:io` (indisponible après compilation JS)
/// ou sur `XMLHttpRequest` (absent de Deno). Ce client contourne les deux en
/// déléguant à un `fetch` fourni par l'hôte TypeScript.
///
/// La fonction injectée reçoit une URL et renvoie une promesse résolue avec
/// une chaîne JSON `{"status": <int>, "body": "<texte>"}`. Un échange par
/// chaînes évite toute conversion de types complexe entre Dart et JS.
class JsHttpClient extends http.BaseClient {
  JsHttpClient(this._fetch);

  final JSFunction _fetch;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final JSPromise<JSString> promise = _fetch.callAsFunction(
        null, request.url.toString().toJS)! as JSPromise<JSString>;

    final String raw = (await promise.toDart).toDart;
    final Map<String, dynamic> decoded =
        jsonDecode(raw) as Map<String, dynamic>;

    final int status = (decoded['status'] as num).toInt();
    final String body = decoded['body'] as String? ?? '';
    final List<int> bytes = utf8.encode(body);

    return http.StreamedResponse(
      Stream<List<int>>.value(bytes),
      status,
      contentLength: bytes.length,
      request: request,
      headers: <String, String>{'content-type': 'application/json'},
    );
  }
}
