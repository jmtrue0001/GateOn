import 'package:flutter/material.dart';

import '../config/style.dart';

class DropdownMenuWidget<T> extends StatelessWidget {
  const DropdownMenuWidget({Key? key, required this.dropdownList, required this.onChanged, this.value}) : super(key: key);

  final List<T> dropdownList;
  final ValueChanged<T?> onChanged;
  final T? value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: DropdownButtonFormField(
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
          counterText: "",
          filled: false,
          hintStyle: textTheme(context).krSubtext1.copyWith(color: gray0),
        ),
        padding: EdgeInsets.zero,
        elevation: 0,
        isExpanded: true,
        borderRadius: BorderRadius.circular(10),
        value: value,
        style: textTheme(context).krSubtext1,
        items: dropdownList.map((dynamic item) {
          return DropdownMenuItem<T>(
            value: item,
            child: SizedBox(
              child: Text(
                item.data,
                style: textTheme(context).krSubtext1,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            onChanged(value);
          }
        },
      ),
    );
  }
}
