import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../main.dart';
import '../../core.dart';

mixin CommonRepository {
  static (StatusCode, dynamic) _checkStatus(http.StreamedResponse response, dynamic body, url, {bool? loginRequest}) {
    logger.d('$url\n=============================================================== \n${jsonEncode(body)}');
    if (response.statusCode == 200) {
      return (StatusCode.success, body);
    } else if (response.statusCode == 201) {
      return (StatusCode.success, body);
    } else if (response.statusCode == 400) {
      final exceptionModel = ExceptionModel.fromJson(body);
      return (StatusCode.badRequest, exceptionModel.exceptionMessage);
    } else if (response.statusCode == 401) {
      final exceptionModel = ExceptionModel.fromJson(body);
      if (loginRequest ?? true && navigatorKey.currentContext != null) {
        navigatorKey.currentContext!.push('/login/false');
      }
      return (StatusCode.unAuthorized, exceptionModel.exceptionMessage);
    } else if (response.statusCode == 403) {
      if (loginRequest ?? true && navigatorKey.currentContext != null) {
        navigatorKey.currentContext!.push('/login/false');
      }
      final exceptionModel = ExceptionModel.fromJson(body);
      return (StatusCode.forbidden, exceptionModel.exceptionMessage);
    } else if (response.statusCode == 404) {
      final exceptionModel = ExceptionModel.fromJson(body);
      return (StatusCode.notFound, exceptionModel.exceptionMessage);
    } else {
      final exceptionModel = ExceptionModel.fromJson(body);
      return (StatusCode.error, exceptionModel.exceptionMessage);
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

  Future<(StatusCode, dynamic)> get(String url, {TokenType token = TokenType.none, String? param, String? query, Map<String, dynamic>? body, Map<String, String>? header}) async {
    final request = http.Request('GET', _getUrl(url, param: param, query: query));
    if (header != null) request.headers.addAll(header);
    request.headers.addAll({'Content-Type': 'application/json'});
    switch (token) {
      case TokenType.none:
      case TokenType.refreshToken:
      case TokenType.customToken:
        break;
      case TokenType.accessToken:
        request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).accessToken});
        break;
    }
    if (body != null) request.body = jsonEncode(body);
    http.StreamedResponse response = await request.send();
    return _checkStatus(response, await jsonDecode(await response.stream.bytesToString()), request.url);
  }

  Future<(StatusCode, dynamic)> post(String url, {TokenType token = TokenType.none, String? param, String? query, String? customToken, Map<String, dynamic>? body, bool loginRequest = true}) async {
    logger.d(body);
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
    http.StreamedResponse response = await request.send();
    return _checkStatus(response, await jsonDecode(await response.stream.bytesToString()), request.url, loginRequest: loginRequest);
  }

  Future<(StatusCode, dynamic)> postWithImage(String url, {TokenType token = TokenType.none, String? param, String? query, Map<String, dynamic> body = const {}, List<int>? imageByte, List<http.MultipartFile>? images, String? extension}) async {
    final request = _jsonToRequestFormData(http.MultipartRequest('POST', _getUrl(url, param: param, query: query)), body);
    if (token == TokenType.accessToken) request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).accessToken});
    if (imageByte != null && imageByte.isNotEmpty) request.files.add(http.MultipartFile.fromBytes('file', imageByte, filename: 'brandImage.$extension', contentType: MediaType('file', 'brandImage')));
    if (images != null && images.isNotEmpty) request.files.addAll(images);
    http.StreamedResponse response = await request.send();
    return _checkStatus(response, await jsonDecode(await response.stream.bytesToString()), request.url);
  }

  Future<(StatusCode, dynamic)> patch(String url, {TokenType token = TokenType.none, String? param, String? query, String? customToken, Map<String, dynamic>? body, bool loginRequest = true}) async {
    var request = http.Request('PATCH', _getUrl(url, param: param, query: query));
    request.headers.addAll({'Content-Type': 'application/json'});
    if (token == TokenType.accessToken) request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).accessToken});
    request.body = jsonEncode(body);
    http.StreamedResponse response = await request.send();
    return _checkStatus(response, await jsonDecode(await response.stream.bytesToString()), request.url);
  }

  Future<(StatusCode, dynamic)> patchWithImage(String url, {TokenType token = TokenType.none, String? param, String? query, Map<String, dynamic> body = const {}, List<int>? imageByte, String? extension, List<http.MultipartFile>? images}) async {
    final request = _jsonToRequestFormData(http.MultipartRequest('PATCH', _getUrl(url, param: param, query: query)), body);
    if (token == TokenType.accessToken) request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).accessToken});
    if (imageByte != null && imageByte.isNotEmpty) request.files.add(http.MultipartFile.fromBytes('file', imageByte, filename: 'brandImage.$extension', contentType: MediaType('file', 'brandImage')));
    if (images != null && images.isNotEmpty) request.files.addAll(images);
    http.StreamedResponse response = await request.send();
    return _checkStatus(response, await jsonDecode(await response.stream.bytesToString()), request.url);
  }

  Future<(StatusCode, dynamic)> delete(String url, {TokenType token = TokenType.none, String? param, String? query, Map<String, dynamic>? body}) async {
    final request = http.Request('DELETE', _getUrl(url, param: param, query: query));
    if (token == TokenType.accessToken) request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).accessToken});
    if (body != null) request.body = jsonEncode(body);
    http.StreamedResponse response = await request.send();
    return _checkStatus(response, await jsonDecode(await response.stream.bytesToString()), request.url);
  }
}
