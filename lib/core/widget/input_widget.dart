import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core.dart';

class InputWidget extends StatefulWidget {
  const InputWidget({Key? key, required this.controller, this.onFieldSubmitted, this.isPhone = false, this.enabled = true, this.hint = '', this.onChange, this.errorWidget, this.maxLength, this.isPassword = false, this.label = '', this.suffixWidget, this.isNumber = false, this.filled, this.isId = false, this.height, this.width, this.done = false}) : super(key: key);

  final TextEditingController controller;
  final Function(String)? onFieldSubmitted;
  final Function(String)? onChange;
  final bool enabled;
  final bool isId;
  final bool isPhone;
  final String hint;
  final Widget? errorWidget;
  final bool isPassword;
  final String label;
  final Widget? suffixWidget;
  final bool? filled;
  final int? maxLength;
  final bool isNumber;
  final double? height;
  final double? width;
  final bool done;

  @override
  State<InputWidget> createState() => _InputWidgetState();
}

class _InputWidgetState extends State<InputWidget> {
  bool obscureText = false;
  @override
  void initState() {
    super.initState();
    obscureText = widget.isPassword;
  }

  @override
  void dispose() {
    // TODO: implement dispose

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.max,
      children: [
        if (widget.label.isNotEmpty) Text(widget.label, style: textTheme(context).krBody1),
        if (widget.label.isNotEmpty) const SizedBox(height: 8),
        SizedBox(
          height: widget.height,
          width: widget.width,
          child: TextFormField(
            // focusNode: FocusNode(),
            // autofocus: true,
            textInputAction: TextInputAction.done,
            maxLines: 1,
            minLines: 1,
            maxLength: widget.maxLength,
            enabled: widget.enabled,
            controller: widget.controller,
            onFieldSubmitted: widget.onFieldSubmitted,
            keyboardType: widget.isNumber ? TextInputType.number : TextInputType.text,
            inputFormatters: [
              if (widget.isNumber) FilteringTextInputFormatter.digitsOnly,
              if (widget.isPhone) MultiMaskedTextInputFormatter(masks: ['xxx-xxxx-xxxx', 'xxx-xxx-xxxx'], separator: '-')
            ],
            autofillHints: [
              if (widget.isId) AutofillHints.username,
              if (widget.isPhone) AutofillHints.telephoneNumber,
              if (widget.isPassword) AutofillHints.password,
            ],
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              return null;
            },
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              filled: widget.filled ?? !widget.enabled,
              hintText: widget.hint,
              counterText: "",
              suffixIcon: widget.isPassword
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          obscureText = !obscureText;
                        });
                      },
                      icon: obscureText ? const Icon(Icons.visibility_outlined) : const Icon(Icons.visibility_off_outlined))
                  : widget.done
                      ? const Icon(Icons.done, color: Colors.green)
                      : widget.suffixWidget,
              hintStyle: textTheme(context).krSubtext1.copyWith(color: gray0),
            ),
            obscureText: obscureText,
            autocorrect: !widget.isPassword,
            onChanged: (text) {
              setState(() {
                if (widget.onChange != null) {
                  widget.onChange!(text);
                }
              });
            },
            style: textTheme(context).krSubtext1.copyWith(color: Theme.of(context).primaryColor),
            cursorColor: Theme.of(context).primaryColor,
          ),
        ),
        if (widget.errorWidget != null) Container(margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8), child: widget.errorWidget),
      ],
    );
  }
}

class MultiMaskedTextInputFormatter extends TextInputFormatter {
  late List<String> _masks;
  late String _separator;
  String? _prevMask;

  MultiMaskedTextInputFormatter({required List<String> masks, required String separator}) {
    _separator = (separator.isNotEmpty) ? separator : '';

    if (masks.isNotEmpty) {
      _masks = masks;
      _masks.sort((l, r) => l.length.compareTo(r.length));
      _prevMask = masks[0];
    }
  }

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final newText = newValue.text;
    final oldText = oldValue.text;

    if (newText.isEmpty || newText.length < oldText.length) {
      return newValue;
    }

    final pasted = (newText.length - oldText.length).abs() > 1;
    final mask = _masks.firstWhere((value) {
      final maskValue = pasted ? value.replaceAll(_separator, '') : value;
      return newText.length <= maskValue.length;
    }, orElse: () => '');

    if (mask.isEmpty) {
      return oldValue;
    }

    final needReset = (_prevMask != mask || newText.length - oldText.length > 1);
    _prevMask = mask;

    if (needReset) {
      final text = newText.replaceAll(_separator, '');
      String resetValue = '';
      int sep = 0;

      for (int i = 0; i < text.length; i++) {
        if (mask[i + sep] == _separator) {
          resetValue += _separator;
          ++sep;
        }
        resetValue += text[i];
      }

      return TextEditingValue(
        text: resetValue,
        selection: TextSelection.collapsed(offset: resetValue.length),
      );
    }

    if (newText.length < mask.length && mask[newText.length - 1] == _separator) {
      final text = '$oldText$_separator${newText.substring(newText.length - 1)}';
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    return newValue;
  }
}
