import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/inspection_db.dart';
import '../models/company_asset.dart';
import '../services/webdav_config.dart';

class AssetManageScreen extends StatefulWidget {
  const AssetManageScreen({super.key});

  @override
  State<AssetManageScreen> createState() => _AssetManageScreenState();
}

class _AssetManageScreenState extends State<AssetManageScreen> {
  List<CompanyAsset> _assets = [];
  bool _loading = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final assets = await InspectionDb().getAllAssets();
    if (mounted) {
      setState(() {
        _assets = assets;
        _loading = false;
      });
    }
  }

  void _showAddDialog() {
    _showAssetDialog(null);
  }

  void _showEditDialog(CompanyAsset asset) {
    _showAssetDialog(asset);
  }

  void _showAssetDialog(CompanyAsset? existing) {
    final codeCtrl = TextEditingController(text: existing?.assetCode ?? '');
    final nameCtrl = TextEditingController(text: existing?.assetName ?? '');
    final specCtrl = TextEditingController(text: existing?.spec ?? '');
    final deptCtrl = TextEditingController(text: existing?.department ?? '');
    final userCtrl = TextEditingController(text: existing?.user ?? '');
    final locCtrl = TextEditingController(text: existing?.location ?? '');
    final isEdit = existing != null;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? '编辑资产' : '新增资产'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeCtrl,
                decoration: const InputDecoration(
                  labelText: '资产编码 *',
                  border: OutlineInputBorder(),
                ),
                readOnly: isEdit,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: '资产名称 *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: specCtrl,
                decoration: const InputDecoration(
                  labelText: '规格型号',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: deptCtrl,
                decoration: const InputDecoration(
                  labelText: '使用部门',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(
                  labelText: '使用人',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: locCtrl,
                decoration: const InputDecoration(
                  labelText: '存放位置',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () async {
              final code = codeCtrl.text.trim();
              final name = nameCtrl.text.trim();
              if (code.isEmpty || name.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('资产编码和名称不能为空'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }
              final asset = CompanyAsset(
                assetCode: code,
                assetName: name,
                spec: specCtrl.text.trim(),
                department: deptCtrl.text.trim(),
                user: userCtrl.text.trim(),
                location: locCtrl.text.trim(),
              );
              await InspectionDb().insertOrUpdateAsset(asset);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadAssets();
            },
            child: Text(isEdit ? '保存' : '添加'),
          ),
        ],
      ),
    );
  }

  void _deleteAsset(CompanyAsset asset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除资产'),
        content: Text('确定删除 "${asset.assetName}"（${asset.assetCode}）？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await InspectionDb().deleteAsset(asset.assetCode);
              if (ctx.mounted) Navigator.pop(ctx);
              _loadAssets();
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }

  Future<void> _uploadToWebDav() async {
    setState(() => _uploading = true);
    try {
      final config = await WebdavConfig.load();
      if (config == null || config.serverUrl.isEmpty) {
        throw Exception('请先配置 WebDAV');
      }

      // 构建 JSON 数组
      final jsonList = _assets
          .map((a) => {
                '资产编码': a.assetCode,
                '资产名称': a.assetName,
                '规格型号': a.spec,
                '使用部门': a.department,
                '使用人': a.user,
                '存放位置': a.location,
              })
          .toList();

      final headers = <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
      };
      if (config.username.isNotEmpty) {
        final credentials = base64Encode(
          utf8.encode('${config.username}:${config.password}'),
        );
        headers['Authorization'] = 'Basic $credentials';
      }

      final response = await http.put(
        Uri.parse(config.assetsUrl),
        headers: headers,
        body: utf8.encode(jsonEncode(jsonList)),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('上传成功，共 ${_assets.length} 条资产'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('HTTP ${response.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败：${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('本地资产库'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _uploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload),
            onPressed: _uploading || _assets.isEmpty ? null : _uploadToWebDav,
            tooltip: '上传到 WebDAV',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _assets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        '本地资产库为空',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '请先从 WebDAV 同步，或手动添加',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assets.length,
                  itemBuilder: (context, index) {
                    final asset = _assets[index];
                    return _buildAssetCard(asset);
                  },
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAssetCard(CompanyAsset asset) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(asset.assetName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              asset.assetCode,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            if (asset.spec.isNotEmpty) Text('规格：${asset.spec}'),
            if (asset.department.isNotEmpty || asset.user.isNotEmpty)
              Text('${asset.department}${asset.department.isNotEmpty && asset.user.isNotEmpty ? ' · ' : ''}${asset.user}'),
          ],
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditDialog(asset),
            ),
            IconButton(
              icon: Icon(Icons.delete, size: 20, color: Colors.red.shade400),
              onPressed: () => _deleteAsset(asset),
            ),
          ],
        ),
      ),
    );
  }
}
