import 'package:flutter/material.dart';

import '../../../core/core.dart';
import '../model/visitor_filter.dart';

/// 방문객 리스트 상단 상세 검색 패널.
/// 날짜(날짜·시·분)·디바이스ID·제조사·제품명·앱버전·OS버전·현재상태·비정상이력 여부로 검색한다.
class VisitorFilterPanel extends StatefulWidget {
  const VisitorFilterPanel({Key? key, required this.onSearch, required this.onReset, required this.colWidths, this.initialFilter = const VisitorFilter()}) : super(key: key);

  final ValueChanged<VisitorFilter> onSearch;
  final VoidCallback onReset;
  // 방문객 리스트 컬럼과 동일한 폭(세로 정렬용).
  final List<double> colWidths;
  // 상세 → 목록 복귀 시 패널을 현재 적용 중인 필터로 복원하기 위한 초기값.
  final VisitorFilter initialFilter;

  @override
  State<VisitorFilterPanel> createState() => _VisitorFilterPanelState();
}

class _VisitorFilterPanelState extends State<VisitorFilterPanel> {
  final _deviceIdCtrl = TextEditingController();
  final _deviceModelCtrl = TextEditingController();
  final _appVersionCtrl = TextEditingController();
  final _osVersionCtrl = TextEditingController();

  // 날짜/시간: 각 단위 null = '전체'. 위에서부터 연속으로 지정한 만큼만 범위를 좁힌다.
  int? _year;
  int? _month;
  int? _day;
  int? _hour;
  int? _minute;
  String? _osType; // null=전체, SAMSUNG, APPLE
  String? _status; // null=전체, 서버 type enum 값
  bool? _abnormal; // null=전체, true=있음, false=없음

  @override
  void initState() {
    super.initState();
    // 복귀 시 현재 적용 중인 필터값으로 패널을 복원한다.
    final f = widget.initialFilter;
    _deviceIdCtrl.text = f.deviceId ?? '';
    _deviceModelCtrl.text = f.deviceModel ?? '';
    _appVersionCtrl.text = f.appVersion ?? '';
    _osVersionCtrl.text = f.osVersion ?? '';
    _osType = f.osType;
    _status = f.status;
    _abnormal = f.abnormal;
    _year = f.year;
    _month = f.month;
    _day = f.day;
    _hour = f.hour;
    _minute = f.minute;
  }

  // 제조사 선택지 (osType)
  static const List<(String, String?)> _osTypeOptions = [
    ('전체', null),
    ('삼성(SAMSUNG)', 'SAMSUNG'),
    ('애플(APPLE)', 'APPLE'),
  ];

  // 현재 상태 선택지 (라벨, 서버 type enum 값)
  static const List<(String, String?)> _statusOptions = [
    ('전체', null),
    ('차단 완료', 'C_DISABLE'),
    ('해제 완료', 'C_ENABLE'),
    ('차단 시도', 'T_DISABLE'),
    ('해제 시도', 'T_ENABLE'),
    ('비정상 사용', 'ABNORMAL'),
    ('관리자 해제', 'ABNORMAL_RELEASE'),
  ];

  // 비정상 이력 여부 선택지
  static const List<(String, bool?)> _abnormalOptions = [
    ('전체', null),
    ('있음', true),
    ('없음', false),
  ];

  @override
  void dispose() {
    _deviceIdCtrl.dispose();
    _deviceModelCtrl.dispose();
    _appVersionCtrl.dispose();
    _osVersionCtrl.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _deviceIdCtrl.clear();
      _deviceModelCtrl.clear();
      _appVersionCtrl.clear();
      _osVersionCtrl.clear();
      _year = null;
      _month = null;
      _day = null;
      _hour = null;
      _minute = null;
      _osType = null;
      _status = null;
      _abnormal = null;
    });
    widget.onReset();
  }

  void _search() {
    widget.onSearch(VisitorFilter(
      deviceId: _deviceIdCtrl.text.trim(),
      osType: _osType,
      deviceModel: _deviceModelCtrl.text.trim(),
      appVersion: _appVersionCtrl.text.trim(),
      osVersion: _osVersionCtrl.text.trim(),
      status: _status,
      abnormal: _abnormal,
      // null(미선택)·_kAll(전체) 둘 다 '제약 없음'(null)으로 전송
      year: _val(_year),
      month: _val(_month),
      day: _val(_day),
      hour: _val(_hour),
      minute: _val(_minute),
    ));
  }

  /// 미선택(null) / 전체(_kAll) → null, 그 외 실제값 그대로.
  int? _val(int? v) => (v == null || v == _kAll) ? null : v;

  /// 선택된 연·월에 맞는 그 달의 일수(1~28/29/30/31). 연·월 미선택/전체면 31.
  int _daysInMonth() {
    final y = _val(_year);
    final m = _val(_month);
    if (y == null || m == null) return 31;
    return DateTime(y, m + 1, 0).day;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.colWidths; // 테이블 컬럼과 동일 폭
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // '상세 검색' 라벨
          Text('상세 검색', style: textTheme(context).krSubtitle1),
          const SizedBox(height: 16),
          // 아래 방문객 리스트 컬럼과 동일한 고정 폭으로 세로 정렬.
          // 번호(w0) 자리는 비우고, 날짜는 차단일시(w1)+허용일시(w2) 폭을 사용.
          // 좁은 화면에서 넘칠 경우 가로 스크롤.
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: (w[0] - 5).clamp(0.0, w[0])), // 번호 자리: 5px 줄여 이후 전체를 왼쪽으로 이동
              _dateCell(w), // 연월일=차단일시 폭, 시간분=허용일시 폭
              _cell(w[3], '유저 디바이스ID', _textField(_deviceIdCtrl, '')),
              _cell(w[4], '제조사', _dropdown<String?>(_osType, _osTypeOptions, (v) => setState(() => _osType = v))),
              _cell(w[5], '제품명', _textField(_deviceModelCtrl, '')),
              _cell(w[6], '앱버전', _textField(_appVersionCtrl, '')),
              _cell(w[7], 'OS 버전', _textField(_osVersionCtrl, '')),
              _cell(w[8], '현재 상태', _dropdown<String?>(_status, _statusOptions, (v) => setState(() => _status = v))),
              _cell(w[9], '비정상 이력', _dropdown<bool?>(_abnormal, _abnormalOptions, (v) => setState(() => _abnormal = v))),
            ],
            ),
          ),
          const SizedBox(height: 20),
          // 초기화 / 검색 — 우측 하단
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _reset,
                style: OutlinedButton.styleFrom(
                  foregroundColor: black1,
                  side: const BorderSide(color: Color(0xffD2D7DD)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: textTheme(context).krBody1,
                ),
                child: const Text('초기화'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _search,
                style: ElevatedButton.styleFrom(
                  backgroundColor: blue1,
                  foregroundColor: white,
                  elevation: 0, // 그림자 제거 → 초기화 버튼과 같은 평면 모양
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  minimumSize: const Size(0, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  textStyle: textTheme(context).krBody1,
                ),
                child: const Text('검색'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 입력 박스 사이 간격(px) = 고정 10px. 박스 크기를 이만큼 줄여서 확보(패딩 아님).
  // (간격 10 ⇒ textfield 폭 = 컬럼폭 - 10. 이전 5px 대비 박스가 5px 더 좁아짐)
  static const double _gap = 30;

  Widget _labelText(String label) => Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme(context).krSubtext1.copyWith(color: const Color(0xff999999)),
      );

  // 컬럼과 동일한 폭의 셀. 입력 박스는 width-reduce 크기로 줄여 좌측 정렬(셀 간격 확보).
  Widget _cell(double width, String label, Widget child, {double reduce = _gap}) {
    final fieldWidth = (width - reduce).clamp(0.0, width);
    return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelText(label),
          const SizedBox(height: 8),
          SizedBox(width: fieldWidth, child: child),
        ],
      ),
    );
  }

  // '전체'를 명시적으로 고른 상태를 나타내는 센티넬. (미선택 null 과 구분)
  // null=미선택(초기, 힌트 '년' 표시) / _kAll=전체(필드에 '전체' 표시) / 그 외=실제값
  // 검색 시엔 null·_kAll 둘 다 '제약 없음'으로 처리.
  static const int _kAll = -1;

  // 년/월/일/시/분 중 한 단위 드롭다운.
  Widget _unitDropdown({
    required int? value,
    required List<int> values,
    required String suffix, // 년/월/일/시/분
    required bool enabled,
    required ValueChanged<int?> onChanged,
  }) {
    // 실제값인데 선택지에 없으면(월 변경으로 일수 축소 등) 미선택 처리
    final v = (value == null || value == _kAll || values.contains(value)) ? value : null;
    return DropdownButtonFormField<int?>(
      value: v,
      isDense: true,
      isExpanded: true,
      decoration: _inputDecoration(''),
      // 미선택(초기)일 때 필드에 단위(년/월/일/시/분)를 회색 힌트로 표시
      hint: Text(suffix, style: textTheme(context).krBody1.copyWith(color: gray0)),
      // 드롭다운 목록: 맨 위 '전체' + 값들
      items: [
        DropdownMenuItem<int?>(value: _kAll, child: Text('전체', style: textTheme(context).krBody1)),
        for (final n in values)
          DropdownMenuItem<int?>(value: n, child: Text('$n$suffix', style: textTheme(context).krBody1)),
      ],
      // 필드(닫힘) 표시: '전체' 선택 시 '전체', 값 선택 시 값. (미선택은 위 hint)
      selectedItemBuilder: (context) => [
        Text('전체', style: textTheme(context).krBody1),
        for (final n in values)
          Text('$n$suffix', style: textTheme(context).krBody1),
      ],
      onChanged: enabled ? onChanged : null,
    );
  }

  // 차단/허용일시 셀: 년·월·일·시·분 드롭다운 5개(각 '전체').
  // 위에서부터 연속으로 선택한 만큼만 범위를 좁힌다(상위가 전체면 하위 자동 비활성).
  Widget _dateCell(List<double> w) {
    final cellW = w[1] + w[2];
    final boxW = (cellW - _gap).clamp(0.0, cellW);
    final nowYear = DateTime.now().year;
    final years = [for (int y = nowYear; y >= 2020; y--) y];
    final months = [for (int m = 1; m <= 12; m++) m];
    final days = [for (int d = 1; d <= _daysInMonth(); d++) d];
    final hours = [for (int h = 0; h <= 23; h++) h];
    final minutes = [for (int m = 0; m <= 59; m++) m];
    return SizedBox(
      width: cellW,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _labelText('차단/허용일시'),
          const SizedBox(height: 8),
          SizedBox(
            width: boxW,
            child: Row(
              children: [
                // 모두 독립적으로 선택 가능(잠금 없음). 범위는 위에서부터 연속 선택된 만큼만 적용된다.
                Expanded(flex: 5, child: _unitDropdown(
                  value: _year, values: years, suffix: '년', enabled: true,
                  onChanged: (v) => setState(() => _year = v),
                )),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: _unitDropdown(
                  value: _month, values: months, suffix: '월', enabled: _year != null, // 년 선택 후 활성
                  onChanged: (v) => setState(() {
                    _month = v;
                    // 월 변경으로 그 달 일수를 넘는 '일'은 무효화
                    if (_day != null && _day! > _daysInMonth()) _day = null;
                  }),
                )),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: _unitDropdown(
                  value: _day, values: days, suffix: '일', enabled: _month != null, // 월 선택 후 활성
                  onChanged: (v) => setState(() => _day = v),
                )),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: _unitDropdown(
                  value: _hour, values: hours, suffix: '시', enabled: _day != null, // 일 선택 후 활성
                  onChanged: (v) => setState(() => _hour = v),
                )),
                const SizedBox(width: 8),
                Expanded(flex: 4, child: _unitDropdown(
                  value: _minute, values: minutes, suffix: '분', enabled: _hour != null, // 시 선택 후 활성
                  onChanged: (v) => setState(() => _minute = v),
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      style: textTheme(context).krBody1,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _search(),
      decoration: _inputDecoration(hint),
    );
  }

  // (라벨, 값) 선택지 드롭다운
  Widget _dropdown<T>(T value, List<(String, T)> options, ValueChanged<T> onChanged) {
    return DropdownButtonFormField<T>(
      value: value,
      isExpanded: true,
      isDense: true,
      decoration: _inputDecoration('선택'),
      items: options
          .map((o) => DropdownMenuItem<T>(value: o.$2, child: Text(o.$1, style: textTheme(context).krBody1)))
          .toList(),
      onChanged: (v) => onChanged(v as T),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    OutlineInputBorder border() => OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xffD2D7DD), width: 1.0),
        );
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: textTheme(context).krBody1.copyWith(color: gray0),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: border(),
      enabledBorder: border(),
      focusedBorder: border(),
      disabledBorder: border(),
    );
  }
}
