import 'package:flutter/material.dart';
import 'analysis_screen.dart';
import 'check_list_screen.dart';
import '../features/inspection/screens/inspection_list_screen.dart';

class FunctionHubScreen extends StatelessWidget {
  const FunctionHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('功能'), centerTitle: true),
      body: ListView(
        children: [
          _buildFunctionCard(
            context,
            icon: Icons.analytics,
            title: '分析',
            subtitle: '资产价值趋势、分类统计',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AnalysisScreen()),
            ),
          ),
          _buildFunctionCard(
            context,
            icon: Icons.checklist,
            title: '检查',
            subtitle: '展会/出差资产盘点',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckListScreen()),
            ),
          ),
          _buildFunctionCard(
            context,
            icon: Icons.inventory_2,
            title: '特调检查',
            subtitle: '设备资产云端盘点',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const InspectionListScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(icon, size: 32),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(subtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: onTap,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    );
  }
}
