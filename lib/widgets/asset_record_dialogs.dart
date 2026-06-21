import 'package:flutter/material.dart';

import '../models/asset.dart';
import 'date_text_field.dart';

class RenewalDialogResult {
  final double price;
  final int durationDays;
  final DateTime renewalDate;

  const RenewalDialogResult({
    required this.price,
    required this.durationDays,
    required this.renewalDate,
  });
}

class ConsumableDialogResult {
  final String name;
  final double price;
  final int cycleDays;
  final DateTime purchasedAt;

  const ConsumableDialogResult({
    required this.name,
    required this.price,
    required this.cycleDays,
    required this.purchasedAt,
  });
}

class ReplacementDialogResult {
  final double price;
  final DateTime replacedAt;

  const ReplacementDialogResult({
    required this.price,
    required this.replacedAt,
  });
}

Future<RenewalDialogResult?> showRenewalDialog(BuildContext context) async {
  final priceController = TextEditingController();
  final durationController = TextEditingController(text: '1');
  DateTime? selectedRenewalDate;

  try {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加续费记录'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DateTextField(
              labelText: '续费日期',
              initialDate: null,
              onDateChanged: (date) {
                selectedRenewalDate = date;
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: '续费金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationController,
              decoration: const InputDecoration(
                labelText: '时长',
                hintText: '1年、6个月、365天',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('添加'),
          ),
        ],
      ),
    );

    if (confirmed != true) return null;

    final durationDays = Asset.parseExpectedDays(durationController.text);
    if (durationDays <= 0) return null;

    return RenewalDialogResult(
      price: double.tryParse(priceController.text) ?? 0,
      durationDays: durationDays,
      renewalDate: selectedRenewalDate ?? DateTime.now(),
    );
  } finally {
    priceController.dispose();
    durationController.dispose();
  }
}

Future<ConsumableDialogResult?> showConsumableDialog(
  BuildContext context, {
  ConsumableRecord? initial,
}) async {
  final nameController = TextEditingController(text: initial?.name ?? '');
  final priceController = TextEditingController(
    text: initial == null ? '' : initial.price.toStringAsFixed(0),
  );
  final cycleController = TextEditingController(
    text: initial?.cycleDays.toString() ?? '',
  );
  DateTime? selectedPurchaseDate;

  try {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(initial == null ? '添加耗材' : '编辑耗材'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: '耗材名称',
                  hintText: initial == null ? 'PP棉滤芯' : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '单价',
                  prefixText: '¥ ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: cycleController,
                decoration: const InputDecoration(
                  labelText: '更换周期',
                  hintText: '6个月、180天、1年',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DateTextField(
                labelText: '购买日期',
                initialDate: initial == null
                    ? null
                    : DateTime.fromMillisecondsSinceEpoch(initial.purchasedAt),
                onDateChanged: (date) {
                  selectedPurchaseDate = date;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(initial == null ? '添加' : '保存'),
          ),
        ],
      ),
    );

    if (confirmed != true) return null;

    final name = nameController.text.trim();
    final cycleText = cycleController.text.trim();
    final cycleDays = cycleText.isNotEmpty
        ? Asset.parseExpectedDays(cycleText)
        : 0;
    if (name.isEmpty || cycleDays <= 0) return null;

    return ConsumableDialogResult(
      name: name,
      price: double.tryParse(priceController.text) ?? 0,
      cycleDays: cycleDays,
      purchasedAt:
          selectedPurchaseDate ??
          (initial == null
              ? DateTime.now()
              : DateTime.fromMillisecondsSinceEpoch(initial.purchasedAt)),
    );
  } finally {
    nameController.dispose();
    priceController.dispose();
    cycleController.dispose();
  }
}

Future<ReplacementDialogResult?> showReplacementDialog(
  BuildContext context, {
  required String title,
  required double initialPrice,
  DateTime? initialDate,
  String confirmLabel = '添加',
}) async {
  final priceController = TextEditingController(
    text: initialPrice.toStringAsFixed(0),
  );
  DateTime? selectedDate;

  try {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DateTextField(
              labelText: '更换日期',
              initialDate: initialDate,
              onDateChanged: (date) => selectedDate = date,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: '花费金额',
                prefixText: '¥ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed != true) return null;

    return ReplacementDialogResult(
      price: double.tryParse(priceController.text) ?? initialPrice,
      replacedAt: selectedDate ?? initialDate ?? DateTime.now(),
    );
  } finally {
    priceController.dispose();
  }
}
