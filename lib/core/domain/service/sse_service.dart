import 'dart:convert';

import 'package:TPASS/core/core.dart';
import 'package:fetch_client/fetch_client.dart';
import 'package:http/http.dart' as http;

import '../../../main.dart';

class SseService with CommonRepository{
  static SseService get to => SseService();
  Future<void> sseConnect(String url) async {
    final client = FetchClient(mode: RequestMode.cors, streamRequests: true);
    final request = http.Request('GET', Uri.parse(url));
    request.headers['Accept'] = 'text/event-stream';
    request.headers['Cache-Control'] = 'no-cache';

    String? secureString = AppConfig.to.shared.getString('secureInfo');

    Future<TokenData> _getTokenData() async {
      String? secureString;
      secureString = AppConfig.to.shared.getString('secureInfo');

      if (secureString != null) {
        return SecureModel.fromJson(jsonDecode(secureString)).tokenData;
      } else {
        return TokenData(accessToken: "", refreshToken: "");
      }
    }


    request.headers.addAll({'X-AUTH-TOKEN-ACCESS': (await _getTokenData()).accessToken});
// 이 방식은 sseClientId 같은 강제 파라미터를 붙이지 않습니다.
    final response = await client.send(request);
    response.stream.toStringStream().listen((data) {
      // Spring Boot의 SseEmitter에서 보낸 내용이 그대로 들어옵니다.
      logger.d('수신된 데이터: ${data}');
    }, onError: (error) {
      logger.d('SSE 에러 발생: ${error.toString()}');
    }, onDone: () {
      logger.d('SSE 연결종료');
    });
  }

}
