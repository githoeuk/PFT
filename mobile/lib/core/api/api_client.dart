import 'dart:convert';

import 'package:http/http.dart' as http;

import '../storage/token_storage.dart';

/// 백엔드 REST API와 통신하는 공통 HTTP 클라이언트입니다.
class ApiClient {
  static const String _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );

  /// 테스트나 실행 환경에 따라 HTTP 클라이언트와 API 기본 주소를 바꿀 수 있게 합니다.
  ApiClient({http.Client? httpClient, String? baseUrl})
    : _httpClient = httpClient ?? http.Client(),
      baseUrl = _normalizeBaseUrl(baseUrl ?? _defaultBaseUrl);

  final http.Client _httpClient;
  final String baseUrl;

  static String _normalizeBaseUrl(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }

    return value;
  }

  /// JSON 요청 본문을 가진 POST 요청을 보내고 공통 응답 형식으로 해석합니다.
  Future<Map<String, dynamic>> postJson(
    String path, {
    required Map<String, dynamic> body,
    String? accessToken,
  }) async {
    final response = await _httpClient.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  /// JSON 요청에 필요한 기본 헤더를 만들고, 토큰이 있으면 인증 헤더를 추가합니다.
  Map<String, String> _headers(String? accessToken) {
    return {
      'Content-Type': 'application/json',
      if (accessToken != null) 'Authorization': 'Bearer $accessToken',
    };
  }

  /// 백엔드의 공통 응답을 해석하고, 실패 응답이면 ApiException으로 변환합니다.
  Map<String, dynamic> _decodeResponse(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));

    if (decoded is! Map<String, dynamic>) {
      throw ApiException('INVALID_RESPONSE', '응답 형식이 올바르지 않습니다.');
    }

    if (decoded['success'] == true) {
      return decoded;
    }

    final error = decoded['error'];
    if (error is Map<String, dynamic>) {
      throw ApiException(
        error['code']?.toString() ?? 'API_ERROR',
        error['message']?.toString() ?? '요청 처리 중 오류가 발생했습니다.',
      );
    }

    throw ApiException('API_ERROR', '요청 처리 중 오류가 발생했습니다.');
  }

  /// 조회용 GET 요청을 보내고, 필요한 경우 URL 쿼리 파라미터를 함께 전달합니다.
  Future<Map<String, dynamic>> getJson(
    String path, {
    String? accessToken,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$baseUrl$path')
        .replace(queryParameters: queryParameters);

    final response = await _httpClient.get(uri, headers: _headers(accessToken));

    return _decodeResponse(response);
  }

  /// JSON 요청 본문을 가진 PATCH 요청을 보내고 공통 응답 형식으로 해석합니다.
  Future<Map<String, dynamic>> patchJson(
    String path, {
    required Map<String, dynamic> body,
    String? accessToken,
  }) async {
    final response = await _httpClient.patch(
      Uri.parse('$baseUrl$path'),
      headers: _headers(accessToken),
      body: jsonEncode(body),
    );

    return _decodeResponse(response);
  }

  /// DELETE 요청을 보내고 공통 응답 형식으로 해석합니다.
  Future<Map<String, dynamic>> deleteJson(
    String path, {
    String? accessToken,
  }) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl$path'),
      headers: _headers(accessToken),
    );

    return _decodeResponse(response);
  }

  Future<Map<String, dynamic>> getJsonWithAuth(
    String path, {
    required TokenStorage tokenStorage,
    Map<String, String>? queryParameters,
  }) {
    return _requestWithTokenRefresh(
      tokenStorage: tokenStorage,
      request: (accessToken) => getJson(
        path,
        accessToken: accessToken,
        queryParameters: queryParameters,
      ),
    );
  }

  Future<Map<String, dynamic>> postJsonWithAuth(
    String path, {
    required TokenStorage tokenStorage,
    required Map<String, dynamic> body,
  }) {
    return _requestWithTokenRefresh(
      tokenStorage: tokenStorage,
      request: (accessToken) => postJson(
        path,
        accessToken: accessToken,
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> patchJsonWithAuth(
    String path, {
    required TokenStorage tokenStorage,
    required Map<String, dynamic> body,
  }) {
    return _requestWithTokenRefresh(
      tokenStorage: tokenStorage,
      request: (accessToken) => patchJson(
        path,
        accessToken: accessToken,
        body: body,
      ),
    );
  }

  Future<Map<String, dynamic>> deleteJsonWithAuth(
    String path, {
    required TokenStorage tokenStorage,
  }) {
    return _requestWithTokenRefresh(
      tokenStorage: tokenStorage,
      request: (accessToken) => deleteJson(
        path,
        accessToken: accessToken,
      ),
    );
  }

  Future<Map<String, dynamic>> _requestWithTokenRefresh({
    required TokenStorage tokenStorage,
    required Future<Map<String, dynamic>> Function(String? accessToken) request,
  }) async {
    final accessToken = await tokenStorage.readAccessToken();

    try {
      return await request(accessToken);
    } on ApiException catch (e) {
      if (e.code != 'UNAUTHORIZED') {
        rethrow;
      }

      final newAccessToken = await _refreshAccessToken(tokenStorage);
      return request(newAccessToken);
    }
  }

  Future<String> _refreshAccessToken(TokenStorage tokenStorage) async {
    final refreshToken = await tokenStorage.readRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) {
      await tokenStorage.clearLoginSession();
      throw const ApiException('NO_REFRESH_TOKEN', '다시 로그인이 필요합니다.');
    }

    try {
      final response = await postJson(
        '/auth/refresh',
        body: {'refreshToken': refreshToken},
      );

      final data = response['data'] as Map<String, dynamic>;
      final accessToken = data['accessToken'] as String;

      await tokenStorage.saveAccessToken(accessToken);

      return accessToken;
    } on ApiException {
      await tokenStorage.clearLoginSession();
      rethrow;
    }
  }

}

/// API 요청 실패 정보를 Flutter 코드에서 다루기 위한 예외 클래스입니다.
class ApiException implements Exception {
  const ApiException(this.code, this.message);

  final String code;
  final String message;

  /// 예외가 문자열로 출력될 때 오류 코드와 메시지가 함께 보이게 합니다.
  @override
  String toString() => 'ApiException($code, $message)';
}
