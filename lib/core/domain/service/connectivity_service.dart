import 'dart:async';
import 'package:flutter/material.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import '../../config/logger.dart';

/// 전역 인터넷 연결 감지 서비스
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  static ConnectivityService get to => _instance;

  factory ConnectivityService() => _instance;

  ConnectivityService._internal();

  final InternetConnection _internetConnection = InternetConnection();
  StreamSubscription<InternetStatus>? _subscription;

  /// 현재 인터넷 연결 상태
  bool _isConnected = true;
  bool get isConnected => _isConnected;

  /// 인터넷 상태 변경 스트림 컨트롤러
  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  /// 인터넷 연결 상태 변경 콜백
  VoidCallback? onDisconnected;
  VoidCallback? onConnected;

  /// 서비스 초기화
  Future<void> init() async {
    // 초기 상태 확인
    _isConnected = await _internetConnection.hasInternetAccess;
    logger.d('ConnectivityService 초기화: 인터넷 연결 = $_isConnected');

    // 상태 변화 스트림 구독
    _subscription = _internetConnection.onStatusChange.listen((status) {
      final connected = status == InternetStatus.connected;

      if (_isConnected != connected) {
        _isConnected = connected;
        _statusController.add(_isConnected);
        logger.d('인터넷 연결 상태 변경: $_isConnected');

        if (_isConnected) {
          onConnected?.call();
        } else {
          onDisconnected?.call();
        }
      }
    });
  }

  /// 현재 인터넷 연결 상태 확인 (1회성)
  Future<bool> checkConnection() async {
    _isConnected = await _internetConnection.hasInternetAccess;
    return _isConnected;
  }

  /// 서비스 종료
  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
