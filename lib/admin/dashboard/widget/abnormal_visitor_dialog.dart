import 'package:GateON/core/core.dart';
import 'package:flutter/material.dart';

import '../repository/dashboard_repository.dart';

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

  static const _accent = Color(0xff2F80ED); // 파괴적 동작이 아니므로(레코드 유지) 파란색 계열

  @override
  void initState() {
    super.initState();
    _fetch();
  }

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

  Future<void> _clearAbnormalSelected() async {
    if (_selected.isEmpty || _deleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        content: Text('선택한 ${_selected.length}건의 비정상 상태를 해제하시겠습니까?', style: textTheme(context).krBody1),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('해제', style: TextStyle(color: _accent))),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _deleting = true);
    try {
      await DashboardApi.to.clearAbnormalVisitors(_selected.toList());
      widget.onChanged?.call(); // 대시보드 카운트 새로고침 트리거
      await _fetch();
      if (mounted) setState(() => _deleting = false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      // 삭제 실패 안내를 토스트(SnackBar) 대신 다이얼로그로 표시
      await showDialog(
        context: context,
        builder: (dctx) => AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('알림'),
          content: Text('비정상 해제에 실패했습니다.', style: textTheme(context).krBody1),
          actions: [
            TextButton(onPressed: () => Navigator.of(dctx).pop(), child: const Text('확인')),
          ],
        ),
      );
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
      content: SizedBox(width: 640, height: 420, child: _buildBody()),
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
        // 전체 선택 헤더
        Row(
          children: [
            Checkbox(value: _allSelected, onChanged: _toggleAll, activeColor: _accent),
            Text('전체 선택', style: textTheme(context).krSubtext1),
            const Spacer(),
            Text('선택 ${_selected.length}건', style: textTheme(context).krSubtext1.copyWith(color: gray2)),
          ],
        ),
        const Divider(height: 1),
        Expanded(
          child: Scrollbar(
            thumbVisibility: true,
            child: ListView.separated(
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (ctx, i) => _row(_items[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(User u) {
    final selected = _selected.contains(u.id);
    return InkWell(
      onTap: () => _toggleOne(u.id!, !selected),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Checkbox(value: selected, onChanged: (v) => _toggleOne(u.id!, v ?? false), activeColor: _accent),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 굵은 제목 = 기기 ID
                  Text(
                    u.deviceId ?? '-',
                    style: textTheme(context).krSubtitle1,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  // 부제 = 모델 / iOS버전 / 앱버전 3줄 세로 배치
                  Text('모델: ${u.deviceModel ?? '-'}',
                      style: textTheme(context).krSubtext1.copyWith(color: gray2),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('iOS: ${u.osVersion ?? '-'}',
                      style: textTheme(context).krSubtext1.copyWith(color: gray2),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text('앱: v${u.appVersion ?? '-'}',
                      style: textTheme(context).krSubtext1.copyWith(color: gray2),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(timeParser(u.disabledAt, true, second: false), style: textTheme(context).krSubtext1.copyWith(color: gray2)),
          ],
        ),
      ),
    );
  }
}
