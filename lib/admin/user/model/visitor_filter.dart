import 'package:intl/intl.dart';

/// 방문객 리스트 컬럼 폭 비율(weight). 가용 폭에 맞춰 채우되, 테이블 컬럼과 상단 상세검색 필터가
/// 동일 값을 쓰도록 공유해 세로 정렬을 맞춘다.
/// 순서: 번호 · 차단일시 · 허용일시 · 유저디바이스ID · 제조사 · 제품명 · 앱버전 · OS버전 · 현재상태 · 비정상이력
const List<double> kVisitorColumnWeights = [2, 5, 5, 9, 3.5, 4.5, 3, 3.5, 4, 3];

/// 가용 가로 폭(contentWidth)을 비율대로 나눠 각 컬럼의 픽셀 폭을 반환.
/// 합계가 contentWidth와 같아 테이블·필터가 폭을 꽉 채우면서 서로 정렬된다.
List<double> visitorColumnWidths(double contentWidth) {
  final total = kVisitorColumnWeights.reduce((a, b) => a + b);
  return kVisitorColumnWeights.map((w) => contentWidth * w / total).toList();
}

/// 방문객 리스트 상세 검색 필터.
///
/// GET /visitor 에 아래 쿼리 파라미터로 전달된다(값이 없으면 생략):
/// - deviceId    : 유저 디바이스ID (부분 일치)
/// - osType      : 제조사. SAMSUNG | APPLE
/// - deviceModel : 제품명 (부분 일치)
/// - appVersion  : 앱버전 (부분 일치)
/// - osVersion   : OS 버전 (부분 일치)
/// - status      : 현재 상태. 서버 type enum 값(C_DISABLE/C_ENABLE/T_DISABLE/T_ENABLE/ABNORMAL/ABNORMAL_RELEASE)
/// - abnormal    : 비정상 이력 여부. true(있음) | false(없음)
/// - startDate   : 조회 시작 일시(차단일시 기준, ISO 'yyyy-MM-ddTHH:mm:ss')
/// - endDate     : 조회 종료 일시(위 범위의 끝. 날짜만 선택 시 그 날 23:59:59, 시까지면 그 시의 끝 등)
class VisitorFilter {
  const VisitorFilter({
    this.deviceId,
    this.osType,
    this.deviceModel,
    this.appVersion,
    this.osVersion,
    this.status,
    this.abnormal,
    this.year,
    this.month,
    this.day,
    this.hour,
    this.minute,
  });

  final String? deviceId;
  final String? osType; // SAMSUNG | APPLE
  final String? deviceModel;
  final String? appVersion;
  final String? osVersion;
  final String? status; // 서버 type enum 값
  final bool? abnormal; // true=있음, false=없음, null=전체
  // 날짜/시간: 각 단위 null = '전체'. 위에서부터 연속으로 지정된 만큼만 범위를 좁힌다.
  // (예: year=2025, 나머지 null → 2025년 전체 / year=2025,month=10 → 그 달 전체)
  final int? year;
  final int? month;
  final int? day;
  final int? hour;
  final int? minute;

  bool get isEmpty =>
      (deviceId?.isEmpty ?? true) &&
      (osType == null) &&
      (deviceModel?.isEmpty ?? true) &&
      (appVersion?.isEmpty ?? true) &&
      (osVersion?.isEmpty ?? true) &&
      (status == null) &&
      (abnormal == null) &&
      (year == null);

  /// 연속으로 지정된 상위 단위에 맞춘 범위 시작 일시.
  DateTime? get _startDateTime {
    if (year == null) return null;
    if (month == null) return DateTime(year!, 1, 1, 0, 0, 0);
    if (day == null) return DateTime(year!, month!, 1, 0, 0, 0);
    if (hour == null) return DateTime(year!, month!, day!, 0, 0, 0);
    if (minute == null) return DateTime(year!, month!, day!, hour!, 0, 0);
    return DateTime(year!, month!, day!, hour!, minute!, 0);
  }

  /// 연속으로 지정된 상위 단위에 맞춘 범위 종료 일시.
  DateTime? get _endDateTime {
    if (year == null) return null;
    if (month == null) return DateTime(year!, 12, 31, 23, 59, 59);
    if (day == null) return DateTime(year!, month! + 1, 0, 23, 59, 59); // 그 달 마지막 날
    if (hour == null) return DateTime(year!, month!, day!, 23, 59, 59);
    if (minute == null) return DateTime(year!, month!, day!, hour!, 59, 59);
    return DateTime(year!, month!, day!, hour!, minute!, 59);
  }

  /// 쿼리 스트링 조각(선행 '&' 포함, 값 없으면 빈 문자열)을 만든다.
  String toQuery() {
    final fmt = DateFormat("yyyy-MM-dd'T'HH:mm:ss");
    final buffer = StringBuffer();
    void add(String key, String? value) {
      if (value == null || value.isEmpty) return;
      buffer.write('&$key=${Uri.encodeComponent(value)}');
    }

    add('deviceId', deviceId?.trim());
    add('osType', osType);
    add('deviceModel', deviceModel?.trim());
    add('appVersion', appVersion?.trim());
    add('osVersion', osVersion?.trim());
    add('status', status);
    if (abnormal != null) add('abnormal', abnormal! ? 'true' : 'false');
    final start = _startDateTime;
    final end = _endDateTime;
    if (start != null) add('startDate', fmt.format(start));
    if (end != null) add('endDate', fmt.format(end));
    return buffer.toString();
  }
}
