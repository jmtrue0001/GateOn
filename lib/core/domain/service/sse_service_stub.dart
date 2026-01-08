import 'dart:async';

/// SSE는 웹 전용입니다. 모바일 앱에서는 사용되지 않습니다.
class SseService {
  static final SseService _instance = SseService._internal();
  factory SseService() => _instance;
  SseService._internal();

  static SseService get to => _instance;

  final StreamController<DashboardSseData> _dashboardController = StreamController<DashboardSseData>.broadcast();
  final StreamController<VisitorSseData> _visitorController = StreamController<VisitorSseData>.broadcast();

  Stream<DashboardSseData> get dashboardStream => _dashboardController.stream;
  Stream<VisitorSseData> get visitorStream => _visitorController.stream;

  bool get isDashboardConnected => false;
  bool get isVisitorConnected => false;

  void connectDashboard(String accessToken) {
    // 모바일에서는 사용하지 않음
  }

  void connectVisitor(String accessToken) {
    // 모바일에서는 사용하지 않음
  }

  void connectAll(String accessToken) {
    // 모바일에서는 사용하지 않음
  }

  void disconnectDashboard() {
    // 모바일에서는 사용하지 않음
  }

  void disconnectVisitor() {
    // 모바일에서는 사용하지 않음
  }

  void disconnectAll() {
    // 모바일에서는 사용하지 않음
  }

  void dispose() {
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
