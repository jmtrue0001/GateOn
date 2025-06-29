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
}
