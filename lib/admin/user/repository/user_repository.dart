import '../../../core/core.dart';

class UserApi with CommonRepository {
  static UserApi get to => UserApi();

  Future<ListModel<User>> getUsers(int page, String query, FilterType? filterType, OrderType? orderType) async {
    try {
      final sortData = filterType == FilterType.none || filterType == null || orderType == null ? '' : '&sort=${filterType.name},${orderType.name}';
      var result = await get(visitorUrl, query: 'page=$page&size=10&query=$query$sortData', token: TokenType.accessToken);
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

  Future<Model<UserCount>> statusVisitors() async {
    try {
      var result = await get(visitorUrl, param: 'count/today/status', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<UserCount>.fromJson(result.$2);
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

  Future<User?> detailUser(String id) async {
    try {
      var result = await get(visitorUrl, param: id, token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<User>.fromJson(result.$2).data;
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

  Future<ListModel<History>> userHistory({
    required String id,
    int? page,
    String? query,
    FilterType? filterType,
    OrderType? orderType,
  }) async {
    try {
      final queryData = query == null || query.isEmpty ? '' : '&query=$query';
      final sortData = filterType == FilterType.none || filterType == null || orderType == null ? '' : '&sort=${filterType.name},${orderType.name}';
      var result = await get(historyUrl, param: id, query: 'page=${page ?? 1}&size=10$queryData$sortData', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return ListModel<History>.fromJson(result.$2);
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
