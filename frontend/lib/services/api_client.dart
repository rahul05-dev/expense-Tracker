import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? httpClient, FlutterSecureStorage? storage})
      : _http = httpClient ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  final http.Client _http;
  final FlutterSecureStorage _storage;
  static const _timeout = Duration(seconds: 20);

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth) {
      final token = await _storage.read(key: ApiConstants.tokenKey);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  Uri _uri(String baseUrl, String path, [Map<String, dynamic>? query]) {
    final filtered = <String, String>{};
    query?.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        filtered[key] = value.toString();
      }
    });
    return Uri.parse('$baseUrl$path').replace(
      queryParameters: filtered.isEmpty ? null : filtered,
    );
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query, bool auth = true}) {
    return _send((baseUrl) async {
      return _http
          .get(_uri(baseUrl, path, query), headers: await _headers(auth: auth))
          .timeout(_timeout);
    });
  }

  Future<dynamic> post(String path, {Object? body, bool auth = true}) {
    return _send((baseUrl) async {
      return _http
          .post(
            _uri(baseUrl, path),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    });
  }

  Future<dynamic> put(String path, {Object? body, bool auth = true}) {
    return _send((baseUrl) async {
      return _http
          .put(
            _uri(baseUrl, path),
            headers: await _headers(auth: auth),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
    });
  }

  Future<dynamic> delete(String path, {bool auth = true}) {
    return _send((baseUrl) async {
      return _http.delete(_uri(baseUrl, path), headers: await _headers(auth: auth)).timeout(_timeout);
    });
  }

  Future<dynamic> _send(Future<http.Response> Function(String baseUrl) request) async {
    ApiException? lastError;

    for (final baseUrl in ApiConstants.baseUrls) {
      try {
        final response = await request(baseUrl);
        return _decode(response);
      } on TimeoutException {
        lastError = ApiException('The server took too long to respond. Please try again.');
      } on ApiException {
        rethrow;
      } catch (_) {
        lastError = ApiException(
          'Cannot reach the server. Check that the API is running and the base URL is correct.',
        );
      }
    }

    if (lastError != null) throw lastError;
    throw ApiException(
      'Cannot reach the server. Check that the API is running and the base URL is correct.',
    );
  }

  dynamic _decode(http.Response response) {
    dynamic data;
    if (response.body.isNotEmpty) {
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    final message = _extractMessage(data) ?? 'Something went wrong. Please try again.';
    throw ApiException(message, statusCode: response.statusCode);
  }

  String? _extractMessage(dynamic data) {
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return detail;
      return detail.toString();
    }
    return null;
  }
}
