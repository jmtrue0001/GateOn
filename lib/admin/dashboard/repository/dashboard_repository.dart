import '../../../core/core.dart';

class DashboardApi with CommonRepository {
  static DashboardApi get to => DashboardApi();

  Future<Model<AllCount>> countAllVisitors() async {
    try {
      var result = await get(visitorUrl, param: 'count', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<AllCount>.fromJson(result.$2);
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

  Future<Model<AllCount>> countTodayVisitors() async {
    try {
      var result = await get(visitorUrl, param: 'count/today', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<AllCount>.fromJson(result.$2);
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

  Future<Model<AllCount>> countDisableVisitors() async {
    try {
      var result = await get(visitorUrl, param: 'count/today/disable', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<AllCount>.fromJson(result.$2);
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

  Future<Model<List<VisitorModel>>> countMonthVisitors(String date) async {
    try {
      var result = await get(visitorUrl, param: 'count/month', query: 'date=$date', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<List<VisitorModel>>.fromJson(result.$2);
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

  Future<Model<List<VisitorModel>>> countDayVisitors(String date) async {
    try {
      var result = await get(visitorUrl, param: 'count/day', query: 'date=$date', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<List<VisitorModel>>.fromJson(result.$2);
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
