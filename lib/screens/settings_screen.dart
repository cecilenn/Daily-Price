import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/app_provider.dart';
import '../services/data_export_service.dart';

/// 设置页面
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isSyncing = false;
  String? _lastSyncMessage;
  int _assetCount = 0;
  double _totalValue = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  /// 加载统计数据
  Future<void> _loadStatistics() async {
    try {
      final response = await Supabase.instance.client
          .from('assets')
          .select('purchase_price, is_sold');
      
      setState(() {
        _assetCount = response.length;
        _totalValue = response
            .where((item) => !(item['is_sold'] as bool))
            .fold<double>(0, (sum, item) => sum + (item['purchase_price'] as num).toDouble());
      });
    } catch (e) {
      // 忽略错误，统计数据只是展示用
    }
  }

  /// 同步数据
  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
      _lastSyncMessage = null;
    });

    try {
      await _loadStatistics();
      context.read<AppProvider>().updateSyncTime(DateTime.now());
      
      setState(() {
        _lastSyncMessage = '同步成功！';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据同步成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _lastSyncMessage = '同步失败：$e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
