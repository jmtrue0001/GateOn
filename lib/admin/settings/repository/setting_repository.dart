import '../../../core/core.dart';

class SettingApi with CommonRepository {
  static SettingApi get to => SettingApi();

  Future<GeoLocation> getGeo(String address) async {
    try {

      var result = await get(addressUrl, query: 'query=$address&start=1&display=10');
      // var result = await get(addressUrl, header: {'Authorization': 'KakaoAK 66f1b6a55900baadbc77f2499977fe0a'}, query: 'query=$address&analyze_type=similar&page=1&size=10');
      logger.d(result.$1);
      logger.d(result.$2);

      switch (result.$1) {
        case StatusCode.success:
          return GeoLocation.fromJson(result.$2);
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

  Future<Model<EnterpriseInfo>> submit(Map<String, dynamic> data, {List<int>? imageBytes, String? extension}) async {
    try {
      var result = await patchWithImage(enterpriseUrl, token: TokenType.accessToken, body: data, imageByte: imageBytes, extension: extension);
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

  Future<Model<EnterpriseInfo>> submitIdPw(Map<String, dynamic> data, {List<int>? imageBytes, String? extension}) async {
    try {
      var result = await patch(enterpriseUrl, param: 'auth', token: TokenType.accessToken, body: data);
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
