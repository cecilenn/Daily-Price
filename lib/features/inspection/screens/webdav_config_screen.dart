import 'package:flutter/material.dart';
import '../services/webdav_config.dart';
import '../services/webdav_service.dart';
import 'asset_manage_screen.dart';

class WebdavConfigScreen extends StatefulWidget {
  const WebdavConfigScreen({super.key});

  @override
  State<WebdavConfigScreen> createState() => _WebdavConfigScreenState();
}

class _WebdavConfigScreenState extends State<WebdavConfigScreen> {
  final _serverUrlCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _assetsPathCtrl = TextEditingController(text: '/inspection/assets.json');
  final _sessionsPathCtrl = TextEditingController(
    text: '/inspection/sessions/',
  );
  bool _testing = false;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final config = await WebdavConfig.load();
    if (config != null && mounted) {
      setState(() {
        _serverUrlCtrl.text = config.serverUrl;
        _usernameCtrl.text = config.username;
        _passwordCtrl.text = config.password;
        _assetsPathCtrl.text = config.assetsPath;
        _sessionsPathCtrl.text = config.sessionsPath;
      });
    }
  }

  WebdavConfig _buildConfig() => WebdavConfig(
    serverUrl: _serverUrlCtrl.text.trim(),
    username: _usernameCtrl.text.trim(),
    password: _passwordCtrl.text.trim(),
    assetsPath: _assetsPathCtrl.text.trim(),
    sessionsPath: _sessionsPathCtrl.text.trim(),
  );

  Future<void> _testConnection() async {
    setState(() {
      _testing = true;
      _testResult = null;
    });
    try {
      final service = WebdavService(_buildConfig());
      final ok = await service.testConnection();
      if (mounted) {
        setState(() {
          _testResult = ok ? '连接成功' : '连接失败，请检查配置';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _testResult = '连接失败: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    final config = _buildConfig();
    if (config.serverUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请填写服务器地址'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    await config.save();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('配置已保存'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _serverUrlCtrl.dispose();
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    _assetsPathCtrl.dispose();
    _sessionsPathCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WebDAV 配置'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _serverUrlCtrl,
            decoration: const InputDecoration(
              labelText: '服务器地址',
              hintText: 'https://dav.example.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.dns),
            ),
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
              labelText: '用户名',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordCtrl,
            decoration: const InputDecoration(
              labelText: '密码',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _assetsPathCtrl,
            decoration: const InputDecoration(
              labelText: '资产文件路径',
              hintText: '/inspection/assets.json',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _sessionsPathCtrl,
            decoration: const InputDecoration(
              labelText: '会话目录路径',
              hintText: '/inspection/sessions/',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.folder),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testing ? null : _testConnection,
                  icon: _testing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: const Text('测试连接'),
                ),
              ),
            ],
          ),
          if (_testResult != null) ...[
            const SizedBox(height: 8),
            Text(
              _testResult!,
              style: TextStyle(
                color: _testResult == '连接成功' ? Colors.green : Colors.red,
                fontSize: 14,
              ),
            ),
          ],
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('保存配置'),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AssetManageScreen(),
                ),
              );
            },
            icon: const Icon(Icons.inventory),
            label: const Text('管理本地资产库'),
          ),
        ],
      ),
    );
  }
}
