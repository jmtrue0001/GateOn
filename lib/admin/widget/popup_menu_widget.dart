import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/core.dart';

class PopupMenuWidget<T> extends StatelessWidget {
  const PopupMenuWidget({Key? key, required this.dropdownList, required this.onChanged, this.value}) : super(key: key);

  final List<T> dropdownList;
  final ValueChanged<T?> onChanged;
  final T? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: PopupMenuButton<T>(
        icon: SvgPicture.asset(
          'assets/icons/ic_order.svg',
          color: Colors.black,
        ),
        tooltip: '정렬',
        offset: const Offset(0, 40),
        onSelected: (T result) => onChanged(result),
        itemBuilder: (BuildContext context) => dropdownList.map((T item) {
          return PopupMenuItem<T>(
            value: item,
            child: SizedBox(
              child: Center(
                child: Text(
                  (item as (String, dynamic, dynamic)).$1,
                  style: textTheme(context).krBody1.copyWith(color: const Color(0xff868C91)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
