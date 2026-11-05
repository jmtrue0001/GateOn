import 'package:GateON/core/core.dart';
import 'package:flutter/material.dart';

import '../repository/dashboard_repository.dart';

// 글자수 제한 상수 (담당자/사유). 입력은 자르지 않고(웹 IME assertion 방지),
// 제출 시 이 값으로 검증한다. 카운터는 초과 시 빨갛게 표시한다.
const int _managerMax = 10;
const int _reasonMax = 40;

/// 아이폰 비정상 방문객 목록을 보여주고, 체크박스로 여러 명을 선택해 한 번에 삭제하는 다이얼로그.
/// - 목록: DashboardApi.abnormalVisitors()  (GET /visitor/today/abnormal)
/// - 삭제: DashboardApi.deleteVisitors(ids) (DELETE /visitor, body {ids:[...]})
/// 백엔드 스펙: docs/backend_abnormal_visitor_api.md
class AbnormalVisitorDialog extends StatefulWidget {
  const AbnormalVisitorDialog({super.key, this.onChanged});

  /// 삭제로 목록이 바뀌어 대시보드 카운트 새로고침이 필요할 때 호출.
  final VoidCallback? onChanged;

  @override
  State<AbnormalVisitorDialog> createState() => _AbnormalVisitorDialogState();
}

class _AbnormalVisitorDialogState extends State<AbnormalVisitorDialog> {
  bool _loading = true;
  bool _deleting = false;
  String? _error;
  List<User> _items = [];
  final Set<int> _selected = {};
  // 건(방문객 id)별 담당자·사유 입력 컨트롤러. 선택된 건만 입력칸이 노출된다.
  final Map<int, TextEditingController> _managerCtrls = {};
  final Map<int, TextEditingController> _reasonCtrls = {};

  static const _accent = Color(0xff2F80ED); // 파괴적 동작이 아니므로(레코드 유지) 파란색 계열

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    for (final c in _managerCtrls.values) c.dispose();
    for (final c in _reasonCtrls.values) c.dispose();
    super.dispose();
  }

  TextEditingController _managerCtrl(int id) => _managerCtrls.putIfAbsent(id, () => TextEditingController());
  TextEditingController _reasonCtrl(int id) => _reasonCtrls.putIfAbsent(id, () => TextEditingController());

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await DashboardApi.to.abnormalVisitors();
      if (!mounted) return;
      setState(() {
        _items = (res.data?.items ?? []).where((e) => e.id != null).toList();
        _selected.clear();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '목록을 불러오지 못했습니다.';
        _loading = false;
      });
    }
  }

  bool get _allSelected => _items.isNotEmpty && _selected.length == _items.length;

  void _toggleAll(bool? v) {
    setState(() {
      _selected.clear();
      if (v ?? false) _selected.addAll(_items.map((e) => e.id!));
    });
  }

  void _toggleOne(int id, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(id);
      } else {
        _selected.remove(id);
      }
    });
  }

  /// 공통 안내 다이얼로그
  Future<void> _alert(String message) => showDialog(
        context: context,
        builder: (dctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('알림'),
          content: Text(message, style: textTheme(context).krBody1),
          actions: [TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('확인'))],
        ),
      );

  Future<void> _clearAbnormalSelected() async {
    if (_selected.isEmpty || _deleting) return;
    // 선택한 각 건마다 담당자·사유가 모두 입력됐는지 검증. (건별로 다를 수 있으므로 개별 확인)
    final items = <AbnormalClearItem>[];
    for (final id in _selected) {
      final manager = _managerCtrl(id).text.trim();
      final reason = _reasonCtrl(id).text.trim();
      // 필수 입력 검증
      if (manager.isEmpty || reason.isEmpty) {
        await _alert('선택한 건의 담당자와 사유를 모두 입력해주세요.');
        return;
      }
      // 길이 검증 (입력은 자르지 않고 여기서 막는다 → 웹 IME assertion 회피)
      if (manager.characters.length > _managerMax) {
        await _alert('담당자는 $_managerMax자 이내로 입력해주세요.');
        return;
      }
      if (reason.characters.length > _reasonMax) {
        await _alert('사유는 $_reasonMax자 이내로 입력해주세요.');
        return;
      }
      items.add(AbnormalClearItem(id: id, manager: manager, reason: reason));
    }

    setState(() => _deleting = true);
    try {
      await DashboardApi.to.clearAbnormalVisitors(items);
      widget.onChanged?.call(); // 대시보드 카운트 새로고침 트리거
      if (!mounted) return;
      setState(() => _deleting = false);
      await _alert('비정상 해제가 완료되었습니다.'); // 완료 안내
      if (mounted) Navigator.of(context).pop(); // 완료 후 비정상 다이얼로그 닫기
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      await _alert('비정상 해제에 실패했습니다.'); // 실패 안내(다이얼로그는 유지)
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      title: Row(
        children: [
          Text('아이폰 비정상 방문객', style: textTheme(context).krTitle2),
          const Spacer(),
          Text('${_items.length}명', style: textTheme(context).krSubtext1.copyWith(color: gray2)),
          const SizedBox(width: 8),
          // 우상단 X 닫기 버튼 (처리 중에는 비활성화)
          InkWell(
            onTap: _deleting ? null : () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(20),
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.close, size: 20, color: gray2),
            ),
          ),
        ],
      ),
      content: SizedBox(width: 1600, height: 460, child: _buildBody()),
      actions: [
        ElevatedButton(
          onPressed: (_selected.isEmpty || _deleting) ? null : _clearAbnormalSelected,
          style: ElevatedButton.styleFrom(backgroundColor: _accent, disabledBackgroundColor: const Color(0xffBBD3F5)),
          child: _deleting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('비정상 해제${_selected.isEmpty ? '' : ' (${_selected.length})'}', style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: textTheme(context).krSubtitle1.copyWith(color: gray2)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _fetch, child: const Text('다시 시도')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(child: Text('비정상 방문객이 없습니다.', style: textTheme(context).krSubtitle1.copyWith(color: gray2)));
    }
    return Column(
      children: [
        _headerRow(),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xffE8E8E8)),
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xffF0F0F0)),
                itemBuilder: (ctx, i) => _row(_items[i]),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 컬럼 폭 정의 (헤더와 각 행이 동일 flex를 사용해 정렬). 방문객 리스트(user_page)와 동일한 컬럼 구성.
  static const int _flexBlocked = 18; // 차단일시
  static const int _flexDeviceId = 34; // 디바이스ID (UUID 전체가 한 줄에 들어가도록 넓힘)
  static const int _flexMaker = 8; // 제조사
  static const int _flexModel = 12; // 제품명
  static const int _flexApp = 7; // 앱버전
  static const int _flexOs = 8; // OS버전
  static const int _flexManager = 14; // 담당자
  static const int _flexReason = 32; // 사유

  Widget _headerRow() {
    Widget label(String t, int flex) => Expanded(
          flex: flex,
          child: Text(t, style: textTheme(context).krSubtext1.copyWith(color: gray2, fontWeight: FontWeight.w600)),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 12, 10),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Checkbox(value: _allSelected, onChanged: _toggleAll, activeColor: _accent),
          ),
          label('차단일시', _flexBlocked),
          label('디바이스ID', _flexDeviceId),
          label('제조사', _flexMaker),
          label('제품명', _flexModel),
          label('앱버전', _flexApp),
          label('OS버전', _flexOs),
          label('담당자', _flexManager),
          label('해제 사유', _flexReason),
        ],
      ),
    );
  }

  // 기기정보 셀 하나. 컬럼 폭(flex)에 맞춰 세로 중앙 정렬로 텍스트 표시.
  Widget _infoCell(String text, int flex) => Expanded(
        flex: flex,
        child: Align(
          alignment: Alignment.centerLeft, // 세로 중앙 + 좌측 정렬
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              text,
              style: textTheme(context).krSubtext1,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

  Widget _row(User u) {
    final selected = _selected.contains(u.id);
    final bool disabledInput = !selected;
    return Container(
      color: selected ? const Color(0xffF3F8FF) : Colors.transparent, // 선택 행 은은한 강조
      // 행 최소 높이를 확보해, 사유 카운터가 나타나도 행 안에서 소화되어 필드/행이 출렁이지 않게 한다.
      constraints: const BoxConstraints(minHeight: 96),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: IntrinsicHeight(
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 체크박스 (행 높이에 맞춰 세로 중앙 정렬)
          SizedBox(
            width: 40,
            child: Center(
              child: Checkbox(value: selected, onChanged: (v) => _toggleOne(u.id!, v ?? false), activeColor: _accent),
            ),
          ),
          // 기기 정보 컬럼들 (방문객 리스트와 동일: 차단일시/디바이스ID/제조사/제품명/앱버전/OS버전)
          _infoCell(timeParser(u.disabledAt, true, second: true), _flexBlocked),
          _infoCell(u.deviceId ?? '-', _flexDeviceId),
          _infoCell(u.osType ?? '-', _flexMaker),
          _infoCell(u.deviceModel ?? '-', _flexModel),
          _infoCell(u.appVersion ?? '-', _flexApp),
          _infoCell(u.osVersion ?? '-', _flexOs),
          // 담당자 입력 컬럼 (세로 중앙 정렬)
          Expanded(
            flex: _flexManager,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 10),
                child: TextField(
                  controller: _managerCtrl(u.id!),
                  enabled: !disabledInput,
                  style: textTheme(context).krSubtext1,
                  decoration: InputDecoration(
                    counterText: '', // 담당자는 글자수 카운터 숨김
                    filled: true,
                    fillColor: disabledInput ? const Color(0xffF5F5F5) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xffDDDDDD))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _accent)),
                  ),
                ),
              ),
            ),
          ),
          // 사유 입력 컬럼 (세로 중앙 정렬)
          // 내장 카운터는 필드 아래에 붙어 필드를 위로 밀어 중앙 정렬을 깨뜨리므로,
          // counterText:''로 끄고 카운터는 Stack으로 필드 우측 하단에 겹쳐 표시한다.
          Expanded(
            flex: _flexReason,
            child: Center(
              child: Stack(
                children: [
                  TextField(
                    controller: _reasonCtrl(u.id!),
                    enabled: !disabledInput,
                    minLines: 1,
                    maxLines: 3,
                    style: textTheme(context).krSubtext1,
                    decoration: InputDecoration(
                      counterText: '', // 내장 카운터 숨김(높이 영향 제거)
                      filled: true,
                      fillColor: disabledInput ? const Color(0xffF5F5F5) : Colors.white,
                      contentPadding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xffDDDDDD))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: _accent)),
                    ),
                  ),
                  // 카운터: 필드 우측 하단에 겹쳐 표시. 입력 시작하면 부드럽게 나타남.
                  Positioned(
                    right: 8,
                    bottom: 4,
                    child: AnimatedBuilder(
                      animation: _reasonCtrl(u.id!),
                      builder: (context, _) {
                        final len = _reasonCtrl(u.id!).text.characters.length;
                        final over = len > _reasonMax; // 초과 시 빨갛게 경고
                        return AnimatedOpacity(
                          opacity: len > 0 ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text('$len/$_reasonMax',
                              style: textTheme(context).krSubtext1.copyWith(
                                  color: over ? const Color(0xffEB5757) : gray2,
                                  fontSize: 11,
                                  fontWeight: over ? FontWeight.w700 : FontWeight.normal)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
