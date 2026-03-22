import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/asset.dart';
import 'smart_asset_avatar.dart';

/// AvatarEditorSheet V3.0 - 头像编辑器底部面板
///
/// 支持三种模式：照片、文字、图标
/// 支持 12 色矩阵选择和专业调色板
///
/// 使用示例：
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   builder: (context) => AvatarEditorSheet(
///     initialAsset: myAsset,
///     onAvatarChanged: (avatarData) { ... },
///   ),
/// );
/// ```
class AvatarEditorSheet extends StatefulWidget {
  /// 初始资产状态（用于获取当前头像设置）
  final Asset initialAsset;

  /// 头像变更回调
  final Function(AvatarEditResult result) onAvatarChanged;

  const AvatarEditorSheet({
    super.key,
    required this.initialAsset,
    required this.onAvatarChanged,
  });

  @override
  State<AvatarEditorSheet> createState() => _AvatarEditorSheetState();
}

class _AvatarEditorSheetState extends State<AvatarEditorSheet> {
  // 状态
  late String? _avatarPath;
  late int? _avatarBgColor;
  late String? _avatarText;
  late int? _avatarIconCodePoint;

  // 当前虚拟形象模式: 'text' 或 'icon'
  String _virtualMode = 'text';

  // 文字控制器
  final TextEditingController _textController = TextEditingController();

  // 图片选择器
  final ImagePicker _imagePicker = ImagePicker();

  // 预定义颜色矩阵 (11个高级纯色 + 1个自定义)
  final List<Color> _presetColors = [
    // 莫兰迪色系 (前6个)
    const Color(0xFFB8A9C9), // 莫兰迪紫
    const Color(0xFFA8C5D9), // 莫兰迪蓝
    const Color(0xFF9DBF9E), // 莫兰迪绿
    const Color(0xFFD4A5A5), // 莫兰迪粉
    const Color(0xFFE6C9A8), // 莫兰迪杏
    const Color(0xFFC9B8A8), // 莫兰迪棕
    // Material 强调色 (接下来5个)
    const Color(0xFF2196F3), // 蓝
    const Color(0xFF4CAF50), // 绿
    const Color(0xFFFF9800), // 橙
    const Color(0xFFE91E63), // 粉
    const Color(0xFF9C27B0), // 紫
  ];

  // 10个常用资产图标
  final List<IconData> _assetIcons = [
    Icons.computer,
    Icons.phone_iphone,
    Icons.camera_alt,
    Icons.watch,
    Icons.headphones,
    Icons.videogame_asset,
    Icons.fitness_center,
    Icons.pedal_bike,
    Icons.directions_car,
    Icons.home,
  ];

  @override
  void initState() {
    super.initState();
    // 初始化状态
    _avatarPath = widget.initialAsset.avatarPath;
    _avatarBgColor = widget.initialAsset.avatarBgColor;
    _avatarText = widget.initialAsset.avatarText;
    _avatarIconCodePoint = widget.initialAsset.avatarIconCodePoint;

    // 初始化控制器
    _textController.text = _avatarText ?? '';

    // 确定初始虚拟形象模式
    if (_avatarIconCodePoint != null) {
      _virtualMode = 'icon';
    } else {
      _virtualMode = 'text';
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // 构建预览用的临时 Asset
  Asset get _previewAsset {
    return widget.initialAsset.copyWith(
      avatarPath: _avatarPath,
      avatarBgColor: _avatarBgColor,
      avatarText: _textController.text.isNotEmpty ? _textController.text : null,
      avatarIconCodePoint: _virtualMode == 'icon' ? _avatarIconCodePoint : null,
    );
  }

  // 处理拍照
  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (photo != null) {
        await _cropImage(photo.path);
      }
    } catch (e) {
      _showError('拍照失败: $e');
    }
  }

  // 处理相册选择
  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image != null) {
        await _cropImage(image.path);
      }
    } catch (e) {
      _showError('选择图片失败: $e');
    }
  }

  // 裁剪图片 (1:1 比例)
  Future<void> _cropImage(String sourcePath) async {
    try {
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: sourcePath,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 85,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '裁剪头像',
            toolbarColor: Theme.of(context).primaryColor,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: '裁剪头像', aspectRatioLockEnabled: true),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _avatarPath = croppedFile.path;
          // 清除图标和文字设置
          _avatarIconCodePoint = null;
          _virtualMode = 'text';
        });
        _notifyChanged();
      }
    } catch (e) {
      _showError('裁剪图片失败: $e');
    }
  }

  // 移除照片
  void _removePhoto() {
    setState(() {
      _avatarPath = null;
    });
    _notifyChanged();
  }

  // 选择预设颜色
  void _selectPresetColor(Color color) {
    setState(() {
      _avatarBgColor = color.value;
    });
    _notifyChanged();
  }

  // 打开自定义颜色选择器 - 使用 flutter_colorpicker
  void _openCustomColorPicker() {
    Color tempColor = _avatarBgColor != null
        ? Color(_avatarBgColor!)
        : const Color(0xFFE0E0E0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('选择自定义颜色'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: tempColor,
            onColorChanged: (color) {
              tempColor = color;
            },
            enableAlpha: false, // 关闭透明度，强制实色
            hexInputBar: true, // 开启HEX色号输入框
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _avatarBgColor = tempColor.value;
              });
              _notifyChanged();
              Navigator.pop(context);
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  // 选择图标
  void _selectIcon(int index) {
    setState(() {
      _avatarIconCodePoint = _assetIcons[index].codePoint;
      _virtualMode = 'icon';
      // 清除照片
      _avatarPath = null;
    });
    _notifyChanged();
  }

  // 通知外部变更
  void _notifyChanged() {
    widget.onAvatarChanged(
      AvatarEditResult(
        avatarPath: _avatarPath,
        avatarBgColor: _avatarBgColor,
        avatarText: _textController.text.isNotEmpty
            ? _textController.text
            : null,
        avatarIconCodePoint: _virtualMode == 'icon'
            ? _avatarIconCodePoint
            : null,
      ),
    );
  }

  // 显示错误
  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// 获取当前编辑结果
  AvatarEditResult get _currentResult {
    return AvatarEditResult(
      avatarPath: _avatarPath,
      avatarBgColor: _avatarBgColor,
      avatarText: _textController.text.isNotEmpty ? _textController.text : null,
      avatarIconCodePoint: _virtualMode == 'icon' ? _avatarIconCodePoint : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 顶部拖拽指示器
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // 标题
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Text(
                      '编辑头像',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(context, _currentResult),
                      child: const Text('完成'),
                    ),
                  ],
                ),
              ),

              // 可滚动内容区域
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 16),

                    // 预览区
                    _buildPreviewSection(),

                    const SizedBox(height: 24),

                    // 照片控制层
                    _buildPhotoControlSection(),

                    const SizedBox(height: 24),

                    // 虚拟形象切换层
                    _buildVirtualModeSwitch(),

                    const SizedBox(height: 16),

                    // 根据模式显示文字输入或图标选择
                    if (_virtualMode == 'text')
                      _buildTextInputSection()
                    else
                      _buildIconSelectionSection(),

                    const SizedBox(height: 24),

                    // 颜色选择层
                    _buildColorSelectionSection(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 预览区
  Widget _buildPreviewSection() {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SmartAssetAvatar(asset: _previewAsset, radius: 60),
      ),
    );
  }

  // 照片控制层
  Widget _buildPhotoControlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '照片',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.camera_alt,
                label: '拍照',
                onTap: _takePhoto,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                icon: Icons.photo_library,
                label: '相册',
                onTap: _pickFromGallery,
              ),
            ),
            if (_avatarPath != null) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.delete_outline,
                  label: '移除',
                  onTap: _removePhoto,
                  isDestructive: true,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  // 虚拟形象模式切换
  Widget _buildVirtualModeSwitch() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '虚拟形象',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildModeButton(
                  label: '文字',
                  isSelected: _virtualMode == 'text',
                  onTap: () {
                    setState(() {
                      _virtualMode = 'text';
                      _avatarIconCodePoint = null;
                      // 如果有照片，切换时保留
                    });
                    _notifyChanged();
                  },
                ),
              ),
              Expanded(
                child: _buildModeButton(
                  label: '图标',
                  isSelected: _virtualMode == 'icon',
                  onTap: () {
                    setState(() {
                      _virtualMode = 'icon';
                      // 如果没有选中的图标，默认选第一个
                      if (_avatarIconCodePoint == null &&
                          _assetIcons.isNotEmpty) {
                        _avatarIconCodePoint = _assetIcons[0].codePoint;
                      }
                      // 清除照片
                      _avatarPath = null;
                    });
                    _notifyChanged();
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 文字输入区
  Widget _buildTextInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '自定义文字 (最多2个字符)',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _textController,
          maxLength: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
          decoration: InputDecoration(
            hintText: '输入1-2个字符',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (value) {
            setState(() {
              // 清除照片和图标
              _avatarPath = null;
              _avatarIconCodePoint = null;
            });
            _notifyChanged();
          },
        ),
      ],
    );
  }

  // 图标选择区
  Widget _buildIconSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('选择图标', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _assetIcons.length,
            itemBuilder: (context, index) {
              final isSelected =
                  _avatarIconCodePoint == _assetIcons[index].codePoint;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _selectIcon(index),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).primaryColor,
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      _assetIcons[index],
                      color: isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.grey[700],
                      size: 28,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 颜色选择区
  Widget _buildColorSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '背景颜色',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // 11个预设颜色
            for (int i = 0; i < _presetColors.length; i++)
              _buildColorCircle(_presetColors[i]),
            // 自定义颜色按钮
            _buildCustomColorButton(),
          ],
        ),
      ],
    );
  }

  // 构建操作按钮
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive ? Colors.red.withOpacity(0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.grey[700],
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDestructive ? Colors.red : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 构建模式按钮
  Widget _buildModeButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? Colors.black : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }

  // 构建颜色圆圈
  Widget _buildColorCircle(Color color) {
    final isSelected = _avatarBgColor == color.value;
    return GestureDetector(
      onTap: () => _selectPresetColor(color),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
            if (isSelected)
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                spreadRadius: 2,
              ),
          ],
        ),
        child: isSelected
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : null,
      ),
    );
  }

  // 构建自定义颜色按钮
  Widget _buildCustomColorButton() {
    final isCustom =
        _avatarBgColor != null &&
        !_presetColors.any((c) => c.value == _avatarBgColor);

    return GestureDetector(
      onTap: _openCustomColorPicker,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Colors.red,
              Colors.orange,
              Colors.yellow,
              Colors.green,
              Colors.blue,
              Colors.purple,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          border: isCustom
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: Colors.grey[300]!, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isCustom
            ? Container(
                decoration: BoxDecoration(
                  color: Color(_avatarBgColor!),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              )
            : const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }
}

/// 头像编辑结果
class AvatarEditResult {
  final String? avatarPath;
  final int? avatarBgColor;
  final String? avatarText;
  final int? avatarIconCodePoint;

  const AvatarEditResult({
    this.avatarPath,
    this.avatarBgColor,
    this.avatarText,
    this.avatarIconCodePoint,
  });

  /// 转换为 Asset 字段的 Map
  Map<String, dynamic> toAssetFields() {
    return {
      'avatar_path': avatarPath,
      'avatar_bg_color': avatarBgColor,
      'avatar_text': avatarText,
      'avatar_icon_code_point': avatarIconCodePoint,
    };
  }
}
