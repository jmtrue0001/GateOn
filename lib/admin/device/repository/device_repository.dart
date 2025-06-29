import 'package:TPASS/core/core.dart';

class DeviceApi with CommonRepository {
  static DeviceApi get to => DeviceApi();

  Future<ListModel<Device>> getDevices(int page, {String? query, FilterType? filterType, OrderType? orderType}) async {
    try {
      final queryData = query == null || query.isEmpty ? '' : '&query=$query';
      final sortData = filterType == FilterType.none || filterType == null || orderType == null ? '' : '&sort=${filterType.name},${orderType.name}';
      var result = await get(deviceUrl, query: 'page=$page&size=20$queryData$sortData', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return ListModel.fromJson(result.$2);
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

  Future<void> addDevice(Map<String, dynamic> data) async {
    try {
      var result = await post(deviceUrl, body: data, token: TokenType.accessToken);

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

  Future<void> editDevice(String? id, Map<String, dynamic> data) async {
    try {
      var result = await patch(deviceUrl, param: '$id', body: data, token: TokenType.accessToken);

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

  Future<void> deleteDevice(String? id) async {
    try {
      var result = await delete(deviceUrl, param: '$id', token: TokenType.accessToken);

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
