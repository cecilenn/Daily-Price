import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:csv/csv.dart';
import 'package:universal_html/html.dart' as html;
import '../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;

  /// 导出 CSV 文件逻辑
  Future<void> _exportToCSV() async {
    setState(() {
      _isExporting = true;
    });

    try {
      // 1. 从 Supabase 拉取所有资产数据
      final response = await Supabase.instance.client
          .from('assets')
          .select()
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> rawAssets = List<Map<String, dynamic>>.from(response);

      // 2. 构建 CSV 表头和数据行
      final List<List<dynamic>> csvData = [
        ['资产名称', '购入价格', '预计使用天数', '购买日期', '是否置顶', '是否已出售', '卖出价格', '出售日期', '创建时间'],
        ...rawAssets.map((item) => [
          item['asset_name'] ?? '',
          item['purchase_price'] ?? '',
          item['expected_lifespan_days'] ?? '',
          item['purchase_date'] ?? '',
          item['is_pinned'] == true ? '是' : '否',
          item['is_sold'] == true ? '是' : '否',
          item['sold_price'] ?? '',
          item['sold_date'] ?? '',
          item['created_at'] ?? '',
        ]),
      ];

      // 3. 转换为带 BOM 头（防止 Excel 中文乱码）的 CSV 格式
      final csvString = const ListToCsvConverter().convert(csvData);
      final bytes = utf8.encode(csvString);
      // 添加 UTF-8 BOM
      final bytesWithBom = [0xEF, 0xBB, 0xBF, ...bytes]; 
      final blob = html.Blob([bytesWithBom], 'text/csv;charset=utf-8');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // 4. 触发 Web 端下载
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'assets_export_${DateTime.now().toIso8601String().split('T')[0]}.csv')
        ..click();

      html.Url.revokeObjectUrl(url);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出成功！已开始下载'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('导出本地存档'),
            subtitle: const Text('将当前云端资产数据导出为 CSV 文件'),
            trailing: _isExporting
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            onTap: _isExporting ? null : _exportToCSV,
          ),
          const Divider(),
          ListTile(
            title: const Text('主题设置'),
            subtitle: const Text('选择应用的主题风格'),
            trailing: DropdownButton<AppTheme>(
              value: appProvider.theme,
              onChanged: (AppTheme? newValue) {
                if (newValue != null) {
                  appProvider.setTheme(newValue);
                }
              },
              items: AppTheme.values.map((AppTheme theme) {
                return DropdownMenuItem<AppTheme>(
                  value: theme,
                  child: Text(theme == AppTheme.dark ? '默认暗黑' : (theme == AppTheme.light ? '极简留白' : '复古护眼')),
                );
              }).toList(),
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('日期显示格式'),
            subtitle: const Text('资产卡片上的期限显示方式'),
            trailing: DropdownButton<DateFormatStyle>(
              value: appProvider.dateFormatStyle,
              onChanged: (DateFormatStyle? newValue) {
                if (newValue != null) {
                  appProvider.setDateFormatStyle(newValue);
                }
              },
              items: DateFormatStyle.values.map((DateFormatStyle style) {
                return DropdownMenuItem<DateFormatStyle>(
                  value: style,
                  child: Text(style == DateFormatStyle.days ? '纯天数' : '年月日组合'),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}