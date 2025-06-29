import '../../../core/core.dart';

class LoginApi with CommonRepository {
  static LoginApi get to => LoginApi();

  Future<Model<LoginInfo>> login(String id, String password) async {
    try {
      var result = await post(loginUrl, body: {"username": id, "password": password});
      switch (result.$1) {
        case StatusCode.success:
          return Model<LoginInfo>.fromJson(result.$2);
        case StatusCode.notFound:
        case StatusCode.unAuthorized:
        case StatusCode.badRequest:
        case StatusCode.timeout:
        case StatusCode.error:
        case StatusCode.forbidden:
          logger.e(result);
          throw result.$2;
      }
    } catch (e) {
      rethrow;
    }
  }
}
