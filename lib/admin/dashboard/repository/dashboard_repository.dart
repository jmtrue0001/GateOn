import '../../../core/core.dart';

/// 비정상 해제 요청 1건(방문객 id + 담당자 + 사유). 건별로 담당자·사유가 다를 수 있다.
class AbnormalClearItem {
  final int id;
  final String manager;
  final String reason;

  const AbnormalClearItem({required this.id, required this.manager, required this.reason});

  Map<String, dynamic> toJson() => {'id': id, 'manager': manager, 'reason': reason};
}

class DashboardApi with CommonRepository {
  static DashboardApi get to => DashboardApi();

  Future<Model<AllCount>> countAllVisitors() async {
    try {
      var result = await get(visitorUrl, param: 'count', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<AllCount>.fromJson(result.$2);
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

  Future<Model<AllCount>> countTodayVisitors() async {
    try {
      var result = await get(visitorUrl, param: 'count/today', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<AllCount>.fromJson(result.$2);
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

  Future<Model<AllCount>> countDisableVisitors() async {
    try {
      var result = await get(visitorUrl, param: 'count/today/disable', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<AllCount>.fromJson(result.$2);
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

  Future<Model<AllCount>> countTotalDisableVisitors() async {
    try {
      var result = await get(visitorUrl, param: 'count/disable', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<AllCount>.fromJson(result.$2);
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

  Future<Model<AllCount>> countAbnormalVisitors() async {
    try {
      var result = await get(visitorUrl, param: 'count/today/abnormal', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<AllCount>.fromJson(result.$2);
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

  Future<Model<List<VisitorModel>>> countMonthVisitors(String date) async {
    try {
      var result = await get(visitorUrl, param: 'count/month', query: 'date=$date', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<List<VisitorModel>>.fromJson(result.$2);
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

  Future<Model<List<VisitorModel>>> countDayVisitors(String date) async {
    try {
      var result = await get(visitorUrl, param: 'count/day', query: 'date=$date', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<List<VisitorModel>>.fromJson(result.$2);
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

  /// 오늘 비정상(type=ABNORMAL) 방문객 목록 조회. (카운트 API `count/today/abnormal`의 목록 버전)
  /// 백엔드 스펙: docs/backend_abnormal_visitor_api.md
  Future<ListModel<User>> abnormalVisitors() async {
    try {
      var result = await get(visitorUrl, param: 'today/abnormal', token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return ListModel<User>.fromJson(result.$2);
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

  /// 선택한 방문객들의 "비정상(ABNORMAL) 상태만 해제"한다. (레코드는 삭제하지 않음)
  /// 건별로 담당자·사유가 다를 수 있어 item 리스트로 전송한다. 반환값 data = 처리된 건수(int).
  /// 백엔드 스펙: docs/backend_abnormal_visitor_api.md
  Future<Model<int>> clearAbnormalVisitors(List<AbnormalClearItem> items) async {
    try {
      var result = await patch(visitorUrl, param: 'abnormal',
          body: {'items': items.map((e) => e.toJson()).toList()}, token: TokenType.accessToken);
      switch (result.$1) {
        case StatusCode.success:
          return Model<int>.fromJson(result.$2);
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
