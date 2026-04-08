import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/inspection_provider.dart';

class ImportSessionScreen extends StatefulWidget {
  const ImportSessionScreen({super.key});

  @override
  State<ImportSessionScreen> createState() => _ImportSessionScreenState();
}

class _ImportSessionScreenState extends State<ImportSessionScreen> {
  final _shareCodeCtrl = TextEditingController();
  bool _importing = false;

  Future<void> _importSession() async {
    final code = _shareCodeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入分享码'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _importing = true);
    try {
      final session = await context
          .read<InspectionProvider>()
          .downloadAndImportSession(code);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入成功：${session.name}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败：${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  void dispose() {
    _shareCodeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('从云端导入'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.cloud_download,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              '输入分享码',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              '请输入同事分享的 6 位分享码',
              style: TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _shareCodeCtrl,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'ABC123',
                counterText: '',
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _importing ? null : _importSession,
              icon: _importing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.download),
              label: Text(_importing ? '正在导入...' : '导入检查任务'),
            ),
          ],
        ),
      ),
    );
  }
}
