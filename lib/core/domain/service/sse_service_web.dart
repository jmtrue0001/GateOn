import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import '../../core.dart';

class SseService {
  static final SseService _instance = SseService._internal();
  factory SseService() => _instance;
  SseService._internal();

  static SseService get to => _instance;

  html.EventSource? _dashboardEventSource;
  html.EventSource? _visitorEventSource;

  final StreamController<DashboardSseData> _dashboardController = StreamController<DashboardSseData>.broadcast();
  final StreamController<VisitorSseData> _visitorController = StreamController<VisitorSseData>.broadcast();

  Stream<DashboardSseData> get dashboardStream => _dashboardController.stream;
  Stream<VisitorSseData> get visitorStream => _visitorController.stream;

  bool _isDashboardConnected = false;
  bool _isVisitorConnected = false;

  int _dashboardRetryCount = 0;
  int _visitorRetryCount = 0;
  final int _maxRetries = 3;

  Timer? _dashboardReconnectTimer;
  Timer? _visitorReconnectTimer;

  bool get isDashboardConnected => _isDashboardConnected;
  bool get isVisitorConnected => _isVisitorConnected;

  /// Dashboard SSE 연결
  void connectDashboard(String accessToken) {
    try {
      // 기존 연결이 있으면 종료
      _dashboardEventSource?.close();
      _dashboardReconnectTimer?.cancel();

      // EventSource는 커스텀 헤더를 지원하지 않으므로 토큰을 쿼리 파라미터로 전달
      final url = '$serverUrl/visitor/sse/dashboard?token=$accessToken';

      _dashboardEventSource = html.EventSource(url, withCredentials: true);

      // 연결 성공
      _dashboardEventSource!.onOpen.listen((event) {
        logger.d('Dashboard SSE connected');
        _isDashboardConnected = true;
        _dashboardRetryCount = 0;
      });

      // dashboard-update 이벤트 수신
      _dashboardEventSource!.addEventListener('dashboard-update', (event) {
        try {
          final messageEvent = event as html.MessageEvent;
          final data = jsonDecode(messageEvent.data as String);
          final sseData = DashboardSseData.fromJson(data);
          _dashboardController.add(sseData);
          logger.d('Dashboard SSE data received: ${sseData.toJson()}');
        } catch (e) {
          logger.e('Dashboard SSE parse error: $e');
        }
      });

      // 에러 처리
      _dashboardEventSource!.onError.listen((event) {
        logger.e('Dashboard SSE error');
        _isDashboardConnected = false;
        _handleDashboardReconnect(accessToken);
      });

    } catch (e) {
      logger.e('Dashboard SSE connection failed: $e');
      _handleDashboardReconnect(accessToken);
    }
  }

  /// Visitor List SSE 연결
  void connectVisitor(String accessToken) {
    try {
      // 기존 연결이 있으면 종료
      _visitorEventSource?.close();
      _visitorReconnectTimer?.cancel();

      // EventSource는 커스텀 헤더를 지원하지 않으므로 토큰을 쿼리 파라미터로 전달
      final url = '$serverUrl/visitor/sse/list?token=$accessToken';

      _visitorEventSource = html.EventSource(url, withCredentials: true);

      // 연결 성공
      _visitorEventSource!.onOpen.listen((event) {
        logger.d('Visitor SSE connected');
        _isVisitorConnected = true;
        _visitorRetryCount = 0;
      });

      // visitor-update 이벤트 수신
      _visitorEventSource!.addEventListener('visitor-update', (event) {
        try {
          final messageEvent = event as html.MessageEvent;
          final data = jsonDecode(messageEvent.data as String);
          final sseData = VisitorSseData.fromJson(data);
          _visitorController.add(sseData);
          logger.d('Visitor SSE data received: ${sseData.toJson()}');
        } catch (e) {
          logger.e('Visitor SSE parse error: $e');
        }
      });

      // 에러 처리
      _visitorEventSource!.onError.listen((event) {
        logger.e('Visitor SSE error');
        _isVisitorConnected = false;
        _handleVisitorReconnect(accessToken);
      });

    } catch (e) {
      logger.e('Visitor SSE connection failed: $e');
      _handleVisitorReconnect(accessToken);
    }
  }

  /// Dashboard 재연결 처리
  void _handleDashboardReconnect(String accessToken) {
    if (_dashboardRetryCount >= _maxRetries) {
      logger.e('Dashboard SSE max retries reached');
      return;
    }

    _dashboardRetryCount++;
    logger.d('Dashboard SSE reconnecting... (attempt $_dashboardRetryCount/$_maxRetries)');

    _dashboardReconnectTimer?.cancel();
    _dashboardReconnectTimer = Timer(const Duration(seconds: 5), () {
      connectDashboard(accessToken);
    });
  }

  /// Visitor 재연결 처리
  void _handleVisitorReconnect(String accessToken) {
    if (_visitorRetryCount >= _maxRetries) {
      logger.e('Visitor SSE max retries reached');
      return;
    }

    _visitorRetryCount++;
    logger.d('Visitor SSE reconnecting... (attempt $_visitorRetryCount/$_maxRetries)');

    _visitorReconnectTimer?.cancel();
    _visitorReconnectTimer = Timer(const Duration(seconds: 5), () {
      connectVisitor(accessToken);
    });
  }

  /// 모든 SSE 연결
  void connectAll(String accessToken) {
    connectDashboard(accessToken);
    connectVisitor(accessToken);
  }

  /// Dashboard SSE 연결 해제
  void disconnectDashboard() {
    _dashboardEventSource?.close();
    _dashboardEventSource = null;
    _dashboardReconnectTimer?.cancel();
    _isDashboardConnected = false;
    _dashboardRetryCount = 0;
    logger.d('Dashboard SSE disconnected');
  }

  /// Visitor SSE 연결 해제
  void disconnectVisitor() {
    _visitorEventSource?.close();
    _visitorEventSource = null;
    _visitorReconnectTimer?.cancel();
    _isVisitorConnected = false;
    _visitorRetryCount = 0;
    logger.d('Visitor SSE disconnected');
  }

  /// 모든 SSE 연결 해제
  void disconnectAll() {
    disconnectDashboard();
    disconnectVisitor();
    logger.d('All SSE connections disconnected');
  }

  /// 리소스 정리
  void dispose() {
    disconnectAll();
    _dashboardController.close();
    _visitorController.close();
  }
}

/// Dashboard SSE 데이터 모델
class DashboardSseData {
  final int? allCount;
  final int? todayCount;
  final int? disableCount;
  final int? disableTotalCount;
  final int? abnormalCount;
  final String? timestamp;

  DashboardSseData({
    this.allCount,
    this.todayCount,
    this.disableCount,
    this.disableTotalCount,
    this.abnormalCount,
    this.timestamp,
  });

  factory DashboardSseData.fromJson(Map<String, dynamic> json) {
    return DashboardSseData(
      allCount: json['allCount'] as int?,
      todayCount: json['todayCount'] as int?,
      disableCount: json['disableCount'] as int?,
      disableTotalCount: json['disableTotalCount'] as int?,
      abnormalCount: json['abnormalCount'] as int?,
      timestamp: json['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allCount': allCount,
      'todayCount': todayCount,
      'disableCount': disableCount,
      'disableTotalCount': disableTotalCount,
      'abnormalCount': abnormalCount,
      'timestamp': timestamp,
    };
  }
}

/// Visitor SSE 데이터 모델
class VisitorSseData {
  final String? type;
  final int? enabledCnt;
  final int? disabledCnt;
  final String? message;
  final String? timestamp;

  VisitorSseData({
    this.type,
    this.enabledCnt,
    this.disabledCnt,
    this.message,
    this.timestamp,
  });

  factory VisitorSseData.fromJson(Map<String, dynamic> json) {
    return VisitorSseData(
      type: json['type'] as String?,
      enabledCnt: json['enabledCnt'] as int?,
      disabledCnt: json['disabledCnt'] as int?,
      message: json['message'] as String?,
      timestamp: json['timestamp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'enabledCnt': enabledCnt,
      'disabledCnt': disabledCnt,
      'message': message,
      'timestamp': timestamp,
    };
  }
}
