import 'package:flutter/material.dart';
import '../models/asset.dart';

class DateTextField extends StatelessWidget {
  final DateTime? initialDate;
  final ValueChanged<DateTime?> onDateChanged;
  final String labelText;
  final String? hintText;

  const DateTextField({
    super.key,
    this.initialDate,
    required this.onDateChanged,
    this.labelText = '日期',
    this.hintText = '未填写默认当前日期',
  });

  @override
  Widget build(BuildContext context) {
    final controller = TextEditingController(
      text: initialDate != null
          ? '${initialDate!.year}-${initialDate!.month.toString().padLeft(2, '0')}-${initialDate!.day.toString().padLeft(2, '0')}'
          : '',
    );

    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: const Icon(Icons.event),
        border: const OutlineInputBorder(),
      ),
      onChanged: (value) {
        final parsed = Asset.parseCustomDate(value);
        onDateChanged(parsed);
      },
    );
  }
}
