import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../services/storage_service.dart';
import 'logger.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException({this.statusCode, required this.message});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._internal();
  static final ApiClient instance = ApiClient._internal();
  factory ApiClient() => instance;

  static const Duration timeout = Duration(minutes: 1);
  final StorageService _storage = StorageService();

  late final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      validateStatus: (status) => status! < 500,
    ),
  )..interceptors.add(LoggerInterceptor());

  Future<String?> _getAuthToken() async {
    try {
      return await _storage.getApiKey();
    } catch (e) {
      final log = logger(ApiClient);
      log.e('Error getting auth token: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> _getHeaders({
    bool requiresAuth = false,
    Map<String, String>? additionalHeaders,
  }) async {
    final headers = <String, dynamic>{};

    if (requiresAuth) {
      final token = await _getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        throw ApiException(
          message: 'Authentication token not found. Please login again.',
        );
      }
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  String _extractErrorMessage(dynamic data) {
    if (data is! Map) return 'An error occurred';

    final detail = data['detail'];

    if (detail is List) {
      final messages = <String>[];
      for (final item in detail) {
        if (item is Map) {
          final loc = (item['loc'] as List? ?? const []).skip(1).join('.');
          final msg = item['msg']?.toString();
          if (msg == null) continue;
          messages.add(loc.isNotEmpty ? '$loc: $msg' : msg);
        } else if (item != null) {
          messages.add(item.toString());
        }
      }
      if (messages.isNotEmpty) return messages.join(', ');
    }

    if (detail is String && detail.isNotEmpty) return detail;

    final message = data['message'] ?? data['error'];
    if (message != null) return message.toString();

    return 'An error occurred';
  }

  dynamic _handleError(dynamic error) {
    final log = logger(ApiClient);

    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          log.e('Timeout error: ${error.type} - ${error.message}');
          throw ApiException(
            message:
                'Connection timeout. Please check your internet connection.',
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final data = error.response?.data;
          final message = _extractErrorMessage(data);

          log.e('Bad response error - Status: $statusCode, Message: $message');
          throw ApiException(statusCode: statusCode, message: message);
        case DioExceptionType.cancel:
          log.w('Request was cancelled by user or timeout');
          throw ApiException(message: 'Request cancelled');
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            log.e('Network error - no internet connection', error: error.error);
            throw ApiException(message: 'No internet connection');
          }
          log.e('Unknown DioException occurred', error: error);
          throw ApiException(
            message: 'Unknown error occurred: ${error.message}',
          );
        default:
          log.e('Unhandled DioException type: ${error.type}', error: error);
          throw ApiException(message: 'Something went wrong: ${error.message}');
      }
    }

    log.e('Non-DioException error occurred', error: error);
    throw ApiException(message: 'Unexpected error: $error');
  }

  Future<Map<String, dynamic>?> get({
    required String endpoint,
    bool requiresAuth = false,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? additionalHeaders,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        additionalHeaders: additionalHeaders,
      );

      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (error) {
      return _handleError(error);
    }
  }

  Future<Map<String, dynamic>?> post({
    required String endpoint,
    Object? body,
    bool requiresAuth = false,
    Map<String, String>? additionalHeaders,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        additionalHeaders: additionalHeaders,
      );

      final response = await _dio.post(
        endpoint,
        data: body,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (error) {
      return _handleError(error);
    }
  }

  Future<dynamic> postRaw({
    required String endpoint,
    Object? body,
    bool requiresAuth = false,
    Map<String, String>? additionalHeaders,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        additionalHeaders: additionalHeaders,
      );

      final response = await _dio.post(
        endpoint,
        data: body,
        options: Options(headers: headers, responseType: ResponseType.plain),
        cancelToken: cancelToken,
      );

      final statusCode = response.statusCode ?? 0;
      final raw = response.data?.toString() ?? '';

      if (statusCode >= 200 && statusCode < 300) {
        return _decodeRawBody(raw);
      }

      return _throwRawResponse(statusCode, raw);
    } catch (error) {
      return _handleError(error);
    }
  }

  dynamic _decodeRawBody(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    try {
      return jsonDecode(trimmed);
    } catch (_) {
      return trimmed;
    }
  }

  Never _throwRawResponse(int statusCode, String raw) {
    final trimmed = raw.trim();
    dynamic data;
    if (trimmed.isNotEmpty) {
      try {
        data = jsonDecode(trimmed);
      } catch (_) {
        data = trimmed;
      }
    }

    String message = 'An error occurred';

    if (data is Map) {
      final typed = Map<String, dynamic>.from(data);
      message = _extractErrorMessage(typed);
    } else if (data is String && data.isNotEmpty) {
      message = data;
    }

    throw ApiException(statusCode: statusCode, message: message);
  }

  Future<Map<String, dynamic>?> put({
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Map<String, String>? additionalHeaders,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        additionalHeaders: additionalHeaders,
      );

      final response = await _dio.put(
        endpoint,
        data: body,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (error) {
      return _handleError(error);
    }
  }

  Future<Map<String, dynamic>?> patch({
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Map<String, String>? additionalHeaders,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        additionalHeaders: additionalHeaders,
      );

      final response = await _dio.patch(
        endpoint,
        data: body,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (error) {
      return _handleError(error);
    }
  }

  Future<Map<String, dynamic>?> delete({
    required String endpoint,
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    Map<String, String>? additionalHeaders,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        additionalHeaders: additionalHeaders,
      );

      final response = await _dio.delete(
        endpoint,
        data: body,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (error) {
      return _handleError(error);
    }
  }

  Future<Map<String, dynamic>?> postWithFiles({
    required String endpoint,
    required Map<String, dynamic> fields,
    required List<File> files,
    String fileFieldName = 'files',
    bool requiresAuth = false,
    Map<String, String>? additionalHeaders,
    Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        additionalHeaders: additionalHeaders,
      );
      headers['Content-Type'] = 'multipart/form-data';

      final formData = FormData();

      fields.forEach((key, value) {
        if (value is List) {
          for (var item in value) {
            formData.fields.add(MapEntry(key, item.toString()));
          }
        } else {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = file.path.split('/').last;
        formData.files.add(
          MapEntry(
            files.length == 1 ? fileFieldName : '$fileFieldName[$i]',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );
      }

      final response = await _dio.post(
        endpoint,
        data: formData,
        options: Options(headers: headers),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (error) {
      return _handleError(error);
    }
  }

  Future<Map<String, dynamic>?> putWithFiles({
    required String endpoint,
    required Map<String, dynamic> fields,
    required List<File> files,
    String fileFieldName = 'files',
    bool requiresAuth = false,
    Map<String, String>? additionalHeaders,
    Function(int, int)? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        additionalHeaders: additionalHeaders,
      );
      headers['Content-Type'] = 'multipart/form-data';

      final formData = FormData();

      fields.forEach((key, value) {
        if (value is List) {
          for (var item in value) {
            formData.fields.add(MapEntry(key, item.toString()));
          }
        } else {
          formData.fields.add(MapEntry(key, value.toString()));
        }
      });

      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        final fileName = file.path.split('/').last;
        formData.files.add(
          MapEntry(
            files.length == 1 ? fileFieldName : '$fileFieldName[$i]',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );
      }

      final response = await _dio.put(
        endpoint,
        data: formData,
        options: Options(headers: headers),
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
      );

      if (response.statusCode! >= 200 && response.statusCode! < 300) {
        return response.data;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.badResponse,
        );
      }
    } catch (error) {
      return _handleError(error);
    }
  }

  Future<void> downloadFile({
    required String endpoint,
    required String savePath,
    bool requiresAuth = false,
    Map<String, String>? additionalHeaders,
    Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    try {
      final headers = await _getHeaders(
        requiresAuth: requiresAuth,
        additionalHeaders: additionalHeaders,
      );

      await _dio.download(
        endpoint,
        savePath,
        options: Options(headers: headers),
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
    } catch (error) {
      return _handleError(error);
    }
  }
}
