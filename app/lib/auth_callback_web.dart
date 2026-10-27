import 'package:web/web.dart' as web;

/// Адрес, с которым вернулись после входа (Google, ссылка из письма), если в нём есть параметры авторизации.
Uri? webAuthCallback() {
  final uri = Uri.base;
  final frag = uri.fragment.contains('=') && !uri.fragment.startsWith('/') ? Uri.splitQueryString(uri.fragment) : const <String, String>{};
  bool has(String k) => uri.queryParameters.containsKey(k) || frag.containsKey(k);
  final ok = has('code') || has('access_token') || has('error') || has('error_code') || has('error_description');
  return ok ? uri : null;
}

/// Убирает из адреса одноразовый код, чтобы он не остался в истории и не обменивался повторно.
void clearWebAuthCallback() {
  try {
    final l = web.window.location;
    web.window.history.replaceState(null, '', l.pathname);
  } catch (_) {}
}
