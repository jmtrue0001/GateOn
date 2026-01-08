import 'package:sse/client/sse_client.dart';

void connectToKotlinBackend() {
  // 1. 클라이언트 생성 (Kotlin Spring Boot 엔드포인트)
  final client = SseClient(Uri.parse('http://localhost:8080/api/sse/subscribe'));

  // 2. 메시지 수신 대기
  client.stream?.listen((String message) {
    if (message.isNotEmpty) {
      print('수신된 데이터: $message');
      // 여기서 JSON 파싱 등을 진행하세요.
    }
  }, onError: (error) {
    print('SSE 에러 발생: $error');
  }, onDone: () {
    print('SSE 연결 종료');
  });
}
