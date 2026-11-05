import '../../../core/core.dart';

class MainApi with CommonRepository {
  static MainApi get to => MainApi();

  Future<Model<EnterpriseInfo>> getEnterpriseData() async {
    try {
      var result = await get(enterpriseUrl, token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<EnterpriseInfo>.fromJson(result.$2);
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

  /// 관리자 계정(아이디/비밀번호) 변경. body: {username, password}
  Future<void> changeAccount(Map<String, dynamic> data) async {
    try {
      var result = await patch(accountUrl, token: TokenType.accessToken, body: data);
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
