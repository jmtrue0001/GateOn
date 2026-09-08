import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:http_parser/http_parser.dart';

import '../../../main.dart';
import '../../core.dart';

mixin CommonRepository {
  static http.Client? _httpClient;
  static http.Client get _client {
    if (kIsWeb) return http.Client();
    _httpClient ??= IOClient(HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true);
    return _httpClient!;
  }

  /// 진행 중인 토큰 재발급(single-flight). 여러 요청이 동시에 401을 받아도
  /// refresh는 딱 1번만 수행한다. (rotation 재사용 감지로 강제 로그아웃되는 것 방지)
  static Future<bool>? _refreshFuture;

  static dynamic _decodeBody(String raw) {
    try {
      return jsonDecode(raw);
    } catch (_) {
      return {'exceptionMessage': raw.isNotEmpty ? raw : 'Unknown error'};
    }
  }

  /// HTTP 상태 → StatusCode 분류만 담당한다. (로그인 리다이렉트는 _execute에서 처리)
  static (StatusCode, dynamic) _checkStatus(http.StreamedResponse response, dynamic body, url) {
    logger.d('$url\n=============================================================== \n${jsonEncode(body)}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return (StatusCode.success, body);
    } else if (response.statusCode == 400) {
      return (StatusCode.badRequest, ExceptionModel.fromJson(body).exceptionMessage);
    } else if (response.statusCode == 401) {
      return (StatusCode.unAuthorized, ExceptionModel.fromJson(body).exceptionMessage);
    } else if (response.statusCode == 403) {
      return (StatusCode.forbidden, ExceptionModel.fromJson(body).exceptionMessage);
    } else if (response.statusCode == 404) {
      return (StatusCode.notFound, ExceptionModel.fromJson(body).exceptionMessage);
    } else {
      return (StatusCode.error, ExceptionModel.fromJson(body).exceptionMessage);
    }
  }

  static Uri _getUrl(String url, {String? param, String? query}) {
    final paramUrl = param != null ? '$url/$param' : url;
    return Uri.parse(query != null ? "$paramUrl?$query" : paramUrl);
  }

  static http.MultipartRequest _jsonToRequestFormData(http.MultipartRequest request, Map<String, dynamic> data) {
    request.files.add(http.MultipartFile.fromString("data", jsonEncode(data), contentType: MediaType.parse('application/json')));
    return request;
  }

  static Future<TokenData> _getTokenData() async {
    String? secureString;

    if (kIsWeb) {
      secureString = AppConfig.to.shared.getString('secureInfo');
    } else {
      secureString = await AppConfig.to.storage.read(key: 'secureInfo');
    }

    if (secureString != null) {
      return SecureModel.fromJson(jsonDecode(secureString)).tokenData;
    } else {
      return TokenData(accessToken: "", refreshToken: "");
    }
  }

  /// 재발급받은 access/refresh 토큰을 저장소의 SecureModel에 교체 저장한다.
  /// (rotation: refresh도 매번 새로 발급되므로 반드시 새 값으로 덮어써야 한다)
  static Future<void> _saveTokens(String access, String refresh) async {
    final secureString = kIsWeb
        ? AppConfig.to.shared.getString('secureInfo')
        : await AppConfig.to.storage.read(key: 'secureInfo');
    if (secureString == null) return;
    final model = SecureModel.fromJson(jsonDecode(secureString));
    model.tokenData.accessToken = access;
    model.tokenData.refreshToken = refresh;
    final updated = jsonEncode(model.toJson());
    if (kIsWeb) {
      await AppConfig.to.shared.setString('secureInfo', updated);
    } else {
      await AppConfig.to.storage.write(key: 'secureInfo', value: updated);
    }
  }

  /// 토큰 재발급을 single-flight로 보장한다.
  static Future<bool> _ensureRefreshed() {
    return _refreshFuture ??= _doRefresh().whenComplete(() => _refreshFuture = null);
  }

  /// POST /auth/refresh — 헤더 X-AUTH-TOKEN-ACCESS=refreshToken, 바디 {token: 기존 accessToken}.
  /// 성공 시 응답 data의 새 access/refresh를 저장하고 true, 실패 시 false.
  static Future<bool> _doRefresh() async {
    try {
      final td = await _getTokenData();
      if (td.refreshToken.isEmpty) return false;
      final request = http.Request('POST', Uri.parse('$authUrl/refresh'));
      request.headers.addAll({'Content-Type': 'application/json', 'X-AUTH-TOKEN-ACCESS': td.refreshToken});
      request.body = jsonEncode({'token': td.accessToken});
      final response = await _client.send(request);
      final body = _decodeBody(await response.stream.bytesToString());
      if (response.statusCode == 200 && body is Map) {
        final data = body['data'];
        if (data is Map) {
          final newAccess = data['accessToken'] as String?;
          final newRefresh = data['refreshToken'] as String?;
          if (newAccess != null && newAccess.isNotEmpty) {
            // refresh는 rotation이므로 새 값이 오면 반드시 교체(없으면 기존 유지)
            await _saveTokens(newAccess, (newRefresh != null && newRefresh.isNotEmpty) ? newRefresh : td.refreshToken);
            return true;
          }
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// 세션 만료 처리가 진행 중인지. (동시 다발 401이 와도 안내/이동은 1번만)
  static bool _handlingSessionExpiry = false;

  /// 저장된 토큰/로그인 상태를 로그아웃 상태로 정리한다. (죽은 토큰 잔재 제거)
  static Future<void> _clearSession() async {
    final logoutModel = SecureModel(tokenData: TokenData(), loginStatus: LoginStatus.logout);
    final json = jsonEncode(logoutModel.toJson());
    if (kIsWeb) {
      await AppConfig.to.shared.setString('secureInfo', json);
      clearBrowserSession(); // 웹: 재접속 시 자동로그인 방지
    } else {
      await AppConfig.to.storage.write(key: 'secureInfo', value: json);
    }
  }

  /// refresh 실패(세션 만료) → 세션 정리 + 안내 다이얼로그 + 로그인 화면 이동. (동시 다발 시 1번만)
  static Future<void> _handleSessionExpired() async {
    if (_handlingSessionExpiry) return;
    _handlingSessionExpiry = true;
    await _clearSession();
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      showDialog(
        context: ctx,
        barrierDismissible: false,
        builder: (dctx) => AlertDialog(
          title: const Text('알림'),
          content: const Text('로그인이 만료되었습니다.\n다시 로그인해 주세요.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dctx).pop();
                dctx.go('/login');
              },
              child: const Text('확인'),
            ),
          ],
        ),
      );
    }
    // 이후 만료도 처리할 수 있도록 잠시 뒤 플래그 해제
    Future.delayed(const Duration(seconds: 2), () => _handlingSessionExpiry = false);
  }

  /// 네트워크/서버 연결 실패 안내가 진행 중인지. (동시 다발 실패에도 다이얼로그는 1번만)
  static bool _handlingNetworkError = false;

  /// 서버 연결 실패(인증서 오류·서버 다운·타임아웃 등) 시 안내 다이얼로그를 띄운다.
  /// HTTP 응답 자체가 오지 않는 실패라 401/403 세션 처리와 별개로 사용자에게 원인을 알린다.
  static Future<void> _handleNetworkError(String message) async {
    if (_handlingNetworkError) return;
    _handlingNetworkError = true;
    final ctx = navigatorKey.currentContext;
    if (ctx != null) {
      showDialog(
        context: ctx,
        builder: (dctx) => AlertDialog(
          title: const Text('알림'),
          content: Text(message),
          actions: [
            TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('확인')),
          ],
        ),
      );
    }
    // 잠깐의 다발성 실패를 1건으로 묶고, 이후 재시도 실패는 다시 안내할 수 있게 해제
    Future.delayed(const Duration(seconds: 3), () => _handlingNetworkError = false);
  }

  /// 요청 실행 + (accessToken 요청이 401이면) 재발급 후 1회 재시도 + 최종 인증 실패 시 로그인 이동.
  /// [build]는 매번 최신 토큰으로 요청을 새로 만든다(재시도 시 새 access가 반영되도록).
  static Future<(StatusCode, dynamic)> _execute(
    Future<http.BaseRequest> Function() build, {
    required TokenType token,
    bool loginRequest = true,
  }) async {
    try {
      http.BaseRequest request = await build();
      http.StreamedResponse response = await _client.send(request).timeout(const Duration(seconds: 30));
      var result = _checkStatus(response, _decodeBody(await response.stream.bytesToString()), request.url);

      // access 토큰 요청이 401/403(만료)이면: refresh 후 새 토큰으로 1회 재시도.
      // (이 백엔드는 access 만료를 401이 아니라 403으로 응답하므로 403도 포함한다)
      if ((result.$1 == StatusCode.unAuthorized || result.$1 == StatusCode.forbidden) &&
          token == TokenType.accessToken) {
        final refreshed = await _ensureRefreshed();
        if (refreshed) {
          request = await build(); // 재발급된 access 토큰으로 재빌드
          response = await _client.send(request).timeout(const Duration(seconds: 30));
          result = _checkStatus(response, _decodeBody(await response.stream.bytesToString()), request.url);
        }
        // 재발급 실패, 또는 재발급 후에도 401이면 세션 만료 처리.
        // (재발급 성공 후 403은 토큰이 아니라 '권한 없음'이므로 로그아웃하지 않고 그대로 반환)
        final sessionDead = !refreshed || result.$1 == StatusCode.unAuthorized;
        if (sessionDead && loginRequest) {
          await _handleSessionExpired();
        }
      }
      return result;
    } on TimeoutException {
      // 응답 지연(서버 과부하/네트워크 지연)
      await _handleNetworkError('서버 응답이 지연되고 있습니다.\n잠시 후 다시 시도해주세요.');
      return (StatusCode.timeout, '서버 응답이 지연되고 있습니다.\n잠시 후 다시 시도해주세요.');
    } catch (e) {
      // HTTP 응답이 오기 전 단계의 실패: 웹 인증서 오류(ERR_CERT_*)·서버 다운(Failed to fetch)·
      // SocketException 등. status code가 없어 401/403 세션 처리와 무관하므로 여기서 안내한다.
      logger.d('네트워크/연결 오류: $e');
      const message = '서버에 연결할 수 없습니다.\n네트워크 또는 서버 상태를 확인해주세요.';
      await _handleNetworkError(message);
      return (StatusCode.error, message);
    }
  }

  Future<(StatusCode, dynamic)> get(String url, {TokenType token = TokenType.none, String? param, String? query, Map<String, dynamic>? body, Map<String, String>? header}) async {
    Future<http.BaseRequest> build() async {
      final request = http.Request('GET', _getUrl(url, param: param, query: query));
      if (header != null) request.headers.addAll(header);
      request.headers.addAll({'Content-Type': 'application/json'});
      if (token == TokenType.accessToken) {
        request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).accessToken});
      }
      if (body != null) request.body = jsonEncode(body);
      return request;
    }

    return _execute(build, token: token);
  }

  Future<(StatusCode, dynamic)> post(String url, {TokenType token = TokenType.none, String? param, String? query, String? customToken, Map<String, dynamic>? body, bool loginRequest = true}) async {
    Future<http.BaseRequest> build() async {
      final request = http.Request('POST', _getUrl(url, param: param, query: query));
      request.headers.addAll({'Content-Type': 'application/json'});
      switch (token) {
        case TokenType.none:
          break;
        case TokenType.refreshToken:
          request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).refreshToken});
          request.body = jsonEncode({'token': (await _getTokenData()).accessToken});
          break;
        case TokenType.customToken:
          request.headers.addAll({'X-AUTH-TOKEN-ACCESS': '$customToken'});
          break;
        case TokenType.accessToken:
          request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).accessToken});
          break;
      }
      if (body != null) request.body = jsonEncode(body);
      return request;
    }

    return _execute(build, token: token, loginRequest: loginRequest);
  }

  Future<(StatusCode, dynamic)> postWithImage(String url, {TokenType token = TokenType.none, String? param, String? query, Map<String, dynamic> body = const {}, List<int>? imageByte, List<http.MultipartFile>? images, String? extension}) async {
    Future<http.BaseRequest> build() async {
      final request = _jsonToRequestFormData(http.MultipartRequest('POST', _getUrl(url, param: param, query: query)), body);
      if (token == TokenType.accessToken) request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).accessToken});
      if (imageByte != null && imageByte.isNotEmpty) request.files.add(http.MultipartFile.fromBytes('file', imageByte, filename: 'brandImage.$extension', contentType: MediaType('file', 'brandImage')));
      if (images != null && images.isNotEmpty) request.files.addAll(images);
      return request;
    }

    return _execute(build, token: token);
  }

  Future<(StatusCode, dynamic)> patch(String url, {TokenType token = TokenType.none, String? param, String? query, String? customToken, Map<String, dynamic>? body, bool loginRequest = true}) async {
    Future<http.BaseRequest> build() async {
      final request = http.Request('PATCH', _getUrl(url, param: param, query: query));
      request.headers.addAll({'Content-Type': 'application/json'});
      if (token == TokenType.accessToken) request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).accessToken});
      request.body = jsonEncode(body);
      return request;
    }

    return _execute(build, token: token, loginRequest: loginRequest);
  }

  Future<(StatusCode, dynamic)> patchWithImage(String url, {TokenType token = TokenType.none, String? param, String? query, Map<String, dynamic> body = const {}, List<int>? imageByte, String? extension, List<http.MultipartFile>? images}) async {
    Future<http.BaseRequest> build() async {
      final request = _jsonToRequestFormData(http.MultipartRequest('PATCH', _getUrl(url, param: param, query: query)), body);
      if (token == TokenType.accessToken) request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).accessToken});
      if (imageByte != null && imageByte.isNotEmpty) request.files.add(http.MultipartFile.fromBytes('file', imageByte, filename: 'brandImage.$extension', contentType: MediaType('file', 'brandImage')));
      if (images != null && images.isNotEmpty) request.files.addAll(images);
      return request;
    }

    return _execute(build, token: token);
  }

  Future<(StatusCode, dynamic)> delete(String url, {TokenType token = TokenType.none, String? param, String? query, Map<String, dynamic>? body}) async {
    Future<http.BaseRequest> build() async {
      final request = http.Request('DELETE', _getUrl(url, param: param, query: query));
      request.headers.addAll({'Content-Type': 'application/json'});
      if (token == TokenType.accessToken) request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).accessToken});
      if (body != null) request.body = jsonEncode(body);
      return request;
    }

    return _execute(build, token: token);
  }
}
