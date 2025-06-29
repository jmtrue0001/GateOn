import '../../../core/core.dart';

class SubApi with CommonRepository {
  static SubApi get to => SubApi();

  Future<ListModel<SubAdmin>> getSubAdminList(int page, {String? query, FilterType? filterType, OrderType? orderType}) async {
    try {
      final queryData = query == null || query.isEmpty ? '' : '&query=$query';
      final sortData = filterType == FilterType.none || filterType == null || orderType == null ? '' : '&sort=${filterType.name},${orderType.name}';
      var result = await get(subAdminUrl, query: 'page=$page&size=20$queryData$sortData', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return ListModel<SubAdmin>.fromJson(result.$2);
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

  Future<Model<SubAdmin>> getSubAdminDetail(String id) async {
    try {
      var result = await get(subAdminUrl, param: id, token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<SubAdmin>.fromJson(result.$2);
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

  Future<void> addSubAdmin(Map<String, dynamic> data) async {
    try {
      var result = await post(subAdminAddUrl, body: data, token: TokenType.accessToken);
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

  Future<Model<SubAdmin>> patchSubAdminDetail(String id, Map<String, dynamic> data) async {
    try {
      var result = await patch(subAdminPatchUrl, param: id, body: data, token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<SubAdmin>.fromJson(result.$2);
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

  Future<void> deleteSubAdmin(String id) async {
    try {
      var result = await delete(subAdminUrl, param: id, token: TokenType.accessToken);
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
