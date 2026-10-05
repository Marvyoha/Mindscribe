import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

Logger logger(Type type) => Logger(printer: CustomPrinter(type.toString()));

class CustomPrinter extends LogPrinter {
  final String className;
  CustomPrinter(this.className);
  @override
  List<String> log(LogEvent event) {
    final color = PrettyPrinter.defaultLevelColors[event.level];
    final emoji = PrettyPrinter.defaultLevelEmojis[event.level];
    final message = event.message;

    return [color!('$emoji $className : $message')];
  }
}

/// Colored replacement for Dio's built-in [LogInterceptor].
///
/// Logs one compact summary line per request/response/error plus the
/// (redacted) request & response bodies. Colors come from the logger
/// package via [logger]:
///   • green  = 2xx / request sent
///   • yellow = 4xx client errors (these arrive as *responses* because the
///              app's BaseOptions uses validateStatus: status < 500)
///   • red    = 5xx, timeouts, socket failures
///
/// Only add this interceptor in kDebugMode.
class LoggerInterceptor extends Interceptor {
  static const String _sentAtKey = '__logger_sent_at';

  /// Keys whose values are masked before anything hits the console.
  static const Set<String> _sensitiveKeys = {
    'password',
    'newpassword',
    'confirmpassword',
    'authorization',
    'token',
    'access_token',
    'refresh_token',
    'verification_token'
        'otp',
    'pin',
  };

  final Logger _log;

  LoggerInterceptor() : _log = logger(LoggerInterceptor);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_sentAtKey] = DateTime.now();
    _log.i('→ ${options.method} ${options.uri}');

    final body = options.data;
    if (body != null && body.toString().isNotEmpty) {
      _log.d('Request body:\n${_pretty(body)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final options = response.requestOptions;
    final elapsed = _elapsedMs(options);
    final statusCode = response.statusCode ?? 0;

    final message =
        '← $statusCode ${options.method} ${options.uri}'
        '${elapsed != null ? ' ($elapsed ms)' : ''}';

    // validateStatus allows statuses < 500 through, so client errors land here.
    if (statusCode >= 400) {
      _log.w(message);
      _log.w('Response body:\n${_pretty(response.data)}');
    } else {
      _log.i(message);
      if (response.data != null) {
        _log.d('Response body:\n${_pretty(response.data)}');
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final options = err.requestOptions;
    final elapsed = _elapsedMs(options);
    final status = err.response?.statusCode;

    _log.e(
      '✗ ${status ?? '--'} ${options.method} ${options.uri} '
      '${elapsed != null ? '($elapsed ms) ' : ''}'
      '[${err.type.name}] ${err.message ?? ''}',
    );

    final body = err.response?.data;
    if (body != null) {
      _log.e('Error body:\n${_pretty(body)}');
    }
    handler.next(err);
  }

  int? _elapsedMs(RequestOptions options) {
    final sentAt = options.extra[_sentAtKey];
    return sentAt is DateTime
        ? DateTime.now().difference(sentAt).inMilliseconds
        : null;
  }

  String _pretty(Object? data) {
    try {
      return const JsonEncoder.withIndent('  ').convert(_redact(data));
    } catch (_) {
      // FormData, streams, binary… fall back to plain toString().
      return _maskSensitiveText(data.toString());
    }
  }

  dynamic _redact(dynamic value) => switch (value) {
    Map() => {
      for (final entry in value.entries)
        entry.key.toString():
            _sensitiveKeys.contains(entry.key.toString().toLowerCase())
            ? '••••••'
            : _redact(entry.value),
    },
    List() => [for (final item in value) _redact(item)],
    _ => value,
  };

  /// Best-effort masking for non-JSON payloads (e.g. form-data strings).
  String _maskSensitiveText(String text) {
    var masked = text;
    for (final key in _sensitiveKeys) {
      masked = masked.replaceAllMapped(
        RegExp('"?$key"?\\s*[:=]\\s*"?[^&,"]+', caseSensitive: false),
        (m) => '${m.group(0)?.split(RegExp('[:=]')).first}=••••••',
      );
    }
    return masked;
  }
}
