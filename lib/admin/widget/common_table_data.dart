import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CommonColumn extends DataColumn {
  final dynamic data;
  final Alignment alignment;
  final double maxWidth;
  final bool isNumber;

  const CommonColumn(this.data, {this.alignment = Alignment.centerLeft, this.maxWidth = double.infinity, this.isNumber = false}) : super(label: const Text(''));

  @override
  bool get numeric => isNumber;

  @override
  Widget get label => Container(constraints: BoxConstraints(maxWidth: maxWidth), child: dataWidget(data, alignment: alignment));
}

class CommonCell extends DataCell {
  final dynamic data;
  final double maxWidth;

  const CommonCell(this.data, {this.maxWidth = double.infinity}) : super(const Text(''));

  @override
  Widget get child => Container(constraints: BoxConstraints(maxWidth: maxWidth), child: dataWidget(data));
}

Widget dataWidget(dynamic data, {Alignment alignment = Alignment.centerLeft}) {
  switch (data.runtimeType) {
    case int:
    case double:
      return Align(alignment: Alignment.centerRight, child: Text(NumberFormat('###,###,###,###').format(data), maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.end));
    case String:
      return Align(alignment: alignment, child: Text(data, maxLines: 2, overflow: TextOverflow.ellipsis));
    case IconButton:
      return Align(alignment: Alignment.centerRight, child: data);
    case bool:
      return Align(alignment: Alignment.centerLeft, child: Icon(data ? Icons.check : Icons.close, color: data ? Colors.green : Colors.red));
    default:
      return const Text('-', maxLines: 1, overflow: TextOverflow.ellipsis);
  }
}
