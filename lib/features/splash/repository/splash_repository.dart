import '../../../core/core.dart';

class SplashRepository with CommonRepository {
  static SplashRepository get to => SplashRepository();

  Future<StatusCode> checkCode(String? code) async {
    var result = await post(checkCodeUrl, body: {'code': code}, loginRequest: false);
    switch (result.$1) {
      case StatusCode.success:
        return result.$1;
      case StatusCode.unAuthorized:
      case StatusCode.notFound:
      case StatusCode.badRequest:
      case StatusCode.forbidden:
      case StatusCode.timeout:
      case StatusCode.error:
        throw result.$1;
    }
  }
}
