import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 무작업(Idle) 자동 로그아웃 감지 위젯.
///
/// 자식 위젯 전체를 감싸서 마우스(클릭/이동/스크롤)와 키보드 입력을 감지합니다.
/// [timeout] 동안 아무 입력이 없으면 [onTimeout] 을 호출합니다.
///
/// 매 입력마다 타이머를 재생성하는 대신, "마지막 활동 시각"만 갱신하고
/// [checkInterval] 주기로 초과 여부를 확인하여 마우스 이동 시 부하를 줄입니다.
class IdleTimeoutWrapper extends StatefulWidget {
  const IdleTimeoutWrapper({
    super.key,
    required this.child,
    required this.timeout,
    required this.onTimeout,
    this.checkInterval = const Duration(seconds: 10),
  });

  final Widget child;
  final Duration timeout;
  final Duration checkInterval;
  final VoidCallback onTimeout;

  @override
  State<IdleTimeoutWrapper> createState() => _IdleTimeoutWrapperState();
}

class _IdleTimeoutWrapperState extends State<IdleTimeoutWrapper> {
  DateTime _lastActivity = DateTime.now();
  Timer? _ticker;
  bool _firedTimeout = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    // timeout 이 0 이하이면 자동 로그아웃 비활성화(타이머를 아예 돌리지 않음).
    if (widget.timeout <= Duration.zero) return;
    _ticker = Timer.periodic(widget.checkInterval, (_) {
      if (_firedTimeout) return;
      if (DateTime.now().difference(_lastActivity) >= widget.timeout) {
        _firedTimeout = true;
        _ticker?.cancel();
        widget.onTimeout();
      }
    });
  }

  /// 사용자 활동 발생 시 마지막 활동 시각 갱신.
  void _bump() {
    _lastActivity = DateTime.now();
    // 로그아웃 후 다시 활동이 감지되면(재로그인 등) 감지 재개.
    if (_firedTimeout) {
      _firedTimeout = false;
      _startTicker();
    }
  }

  bool _onKey(KeyEvent event) {
    _bump();
    return false; // 이벤트를 소비하지 않고 그대로 전달
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _bump(),
      onPointerMove: (_) => _bump(),
      onPointerHover: (_) => _bump(),
      onPointerSignal: (_) => _bump(),
      child: widget.child,
    );
  }
}
