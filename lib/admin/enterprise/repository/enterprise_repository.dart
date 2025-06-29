import 'dart:typed_data';

import '../../../core/core.dart';

class EnterpriseApi with CommonRepository {
  static EnterpriseApi get to => EnterpriseApi();

  Future<ListModel<Enterprise>> getEnterprises(int page, {String? query, FilterType? filterType, OrderType? orderType}) async {
    try {
      final queryData = query == null || query.isEmpty ? '' : '&query=$query';
      final sortData = filterType == FilterType.none || filterType == null || orderType == null ? '' : '&sort=${filterType.name},${orderType.name}';
      var result = await get(enterpriseUrl, param: 'list', query: 'page=$page&size=20$queryData$sortData', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return ListModel<Enterprise>.fromJson(result.$2);
        case StatusCode.notFound:
        case StatusCode.unAuthorized:
        case StatusCode.badRequest:
        case StatusCode.timeout:
        case StatusCode.error:
        case StatusCode.forbidden:
          throw result.$2;
      }
    } on String {
      rethrow;
    }
  }

  Future<Model<Enterprise>> enterpriseDetail(String? id) async {
    try {
      var result = await get(enterpriseUrl, param: 'a/$id', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<Enterprise>.fromJson(result.$2);
        case StatusCode.notFound:
        case StatusCode.unAuthorized:
        case StatusCode.badRequest:
        case StatusCode.timeout:
        case StatusCode.error:
        case StatusCode.forbidden:
          throw result.$2;
      }
    } on String {
      rethrow;
    }
  }

  Future<ListModel<Device>> getEnterpriseDevices(int page, {String? id, String? query, FilterType? filterType, OrderType? orderType}) async {
    try {
      final queryData = query == null || query.isEmpty ? '' : '&query=$query';
      final sortData = filterType == FilterType.none || filterType == null || orderType == null ? '' : '&sort=${filterType.name},${orderType.name}';
      var result = await get(deviceUrl, param: 'a/$id', query: 'page=$page&size=10$queryData$sortData', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return ListModel<Device>.fromJson(result.$2);
        case StatusCode.notFound:
        case StatusCode.unAuthorized:
        case StatusCode.badRequest:
        case StatusCode.timeout:
        case StatusCode.error:
        case StatusCode.forbidden:
          throw result.$2;
      }
    } on String {
      rethrow;
    }
  }

  Future<void> addEnterprise(Map<String, dynamic> data, {Uint8List? imageBytes, String? extension}) async {
    try {
      var result = await postWithImage(signupUrl, body: data, imageByte: imageBytes, token: TokenType.accessToken, extension: extension ?? 'jpg');

      switch (result.$1) {
        case StatusCode.success:
          return;
        case StatusCode.notFound:
        case StatusCode.unAuthorized:
        case StatusCode.badRequest:
        case StatusCode.timeout:
        case StatusCode.error:
        case StatusCode.forbidden:
          throw result.$2;
      }
    } on String {
      rethrow;
    }
  }

  Future<void> editEnterprise(String? id, Map<String, dynamic> data, {Uint8List? imageBytes, String? extension}) async {
    try {
      var result = await patchWithImage(enterpriseUrl, param: 'a/$id', body: data, imageByte: imageBytes, token: TokenType.accessToken, extension: extension ?? 'jpg');

      switch (result.$1) {
        case StatusCode.success:
          return;
        case StatusCode.notFound:
        case StatusCode.unAuthorized:
        case StatusCode.badRequest:
        case StatusCode.timeout:
        case StatusCode.error:
        case StatusCode.forbidden:
          throw result.$2;
      }
    } on String {
      rethrow;
    }
  }

  Future<void> deleteEnterprise(String? id) async {
    try {
      var result = await delete(enterpriseUrl, param: 'a/$id', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return;
        case StatusCode.notFound:
        case StatusCode.unAuthorized:
        case StatusCode.badRequest:
        case StatusCode.timeout:
        case StatusCode.error:
        case StatusCode.forbidden:
          throw result.$2;
      }
    } on String {
      rethrow;
    }
  }
}
