import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:GateON/core/core.dart';
import 'package:bloc/bloc.dart';
import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:http/http.dart' as http;

import '../../../main.dart';
import '../../home/repository/home_repository.dart';

part 'ban_event.dart';
part 'ban_state.dart';
part 'generated/ban_bloc.g.dart';

class BanBloc extends Bloc<CommonEvent, BanState> {
  BanBloc() : super(const BanState()) {
    on<Initial>(_onInitial);
    on<Released>(_onReleased);
  }

  // 관리자 원격 해제 감지용 SSE 연결. (GET /device/{deviceId}/events?code={업체코드})
  http.Client? _sseClient;
  StreamSubscription<String>? _sseSub;
  bool _closed = false; // bloc 종료/해제 완료 시 재연결 중단 플래그

  _onInitial(Initial event, Emitter<BanState> emit) async {
    AppConfig.to.writeProfileStatus('ban');
    final installedTime = await AppConfig.getTimeInstalled();
    final code = await AppConfig.to.storage.read(key: 'code'); // 업체코드 (SSE/상태조회 인증용)
    if (code != null) {
      emit(state.copyWith(code: code, installedTime: installedTime));
      await HomeRepository.to.checkCode(code).then((v) => emit(state.copyWith(enterPrise: v.data))).catchError((e) => e);
    }
    // 기기 식별은 서버 보고와 동일한 값을 사용한다. (비정상 보고 시 AppConfig.getDeviceId() 사용)
    final deviceId = await AppConfig.getDeviceId();
    emit(state.copyWith(deviceId: deviceId));

    // 초기 진실: 상태를 먼저 조회해 이미 해제됐으면 바로 복귀. (SSE 연결 전/실패 대비)
    if (deviceId != null && deviceId.isNotEmpty && code != null && code.isNotEmpty) {
      try {
        final active = await HomeRepository.to.getDeviceActive(deviceId, code);
        if (active) {
          add(const Released());
          return;
        }
      } catch (_) {}
    }
    _connectSse(deviceId, code); // 차단 화면 진입과 동시에 실시간 해제 감시 시작
  }

  /// 차단 화면이 열려 있는 동안 SSE 연결을 유지하며 해제 이벤트를 기다린다.
  /// 서버는 연결 직후 status 이벤트(isActive)를 1회 주고, 관리자 해제 시 unban 이벤트(released)를 준다.
  void _connectSse(String? deviceId, String? code) async {
    if (_closed || deviceId == null || deviceId.isEmpty || code == null || code.isEmpty) return;
    await _sseSub?.cancel();
    _sseClient?.close();
    _sseClient = http.Client();
    try {
      final uri = Uri.parse('$deviceUrl/$deviceId/events').replace(queryParameters: {'code': code});
      final request = http.Request('GET', uri);
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      final response = await _sseClient!.send(request);
      if (response.statusCode != 200) {
        _scheduleReconnect(deviceId, code);
        return;
      }
      // text/event-stream 줄 단위 파싱. event:/주석(:)/빈 줄은 무시하고 data 줄만 본다.
      _sseSub = response.stream.transform(utf8.decoder).transform(const LineSplitter()).listen(
        (line) {
          if (!line.startsWith('data:')) return;
          final payload = line.substring(5).trim();
          if (payload.isEmpty) return;
          bool release = false;
          try {
            final json = jsonDecode(payload);
            // status 이벤트(isActive:true) 또는 unban 이벤트(released:true) → 해제.
            // status 이벤트라도 isActive:false 면 밴 유지(release=false).
            release = json is Map && (json['released'] == true || json['isActive'] == true);
          } catch (_) {
            release = payload.contains('true') && (payload.contains('released') || payload.contains('isActive'));
          }
          if (release) add(const Released());
        },
        onError: (_) => _scheduleReconnect(deviceId, code),
        onDone: () => _scheduleReconnect(deviceId, code),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleReconnect(deviceId, code);
    }
  }

  /// 연결 끊김/오류 시 잠시 뒤 재연결. (차단 화면이 살아있는 동안 계속 재시도)
  void _scheduleReconnect(String? deviceId, String? code) {
    if (_closed) return;
    Future.delayed(const Duration(seconds: 5), () {
      if (!_closed) _connectSse(deviceId, code);
    });
  }

  /// 해제 확정: SSE 정리 → 차단 플래그 제거 → success 로 알려 화면이 홈(splash 재진입)으로 복귀하게 한다.
  _onReleased(Released event, Emitter<BanState> emit) async {
    _closed = true;
    await _sseSub?.cancel();
    _sseClient?.close();
    // splash가 profile_status=='ban' 이면 다시 /ban 으로 보내므로, 해제 시 반드시 제거한다.
    await AppConfig.to.storage.delete(key: 'profile_status');
    emit(state.copyWith(status: CommonStatus.success)); // ban_page 리스너가 /splash 로 재진입
  }

  @override
  Future<void> close() {
    _closed = true;
    _sseSub?.cancel();
    _sseClient?.close();
    return super.close();
  }
}
