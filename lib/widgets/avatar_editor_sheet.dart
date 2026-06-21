import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../models/asset.dart';
import 'avatar_edit_result.dart';
import 'avatar_color_picker.dart';
import 'avatar_editor_options.dart';
import 'avatar_editor_sections.dart';

export 'avatar_edit_result.dart';

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

  final List<Color> _presetColors = AvatarEditorOptions.presetColors;
  final List<IconData> _assetIcons = AvatarEditorOptions.assetIcons;

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
      _avatarBgColor = color.toARGB32();
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
                _avatarBgColor = tempColor.toARGB32();
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
                    AvatarPreviewSection(asset: _previewAsset),

                    const SizedBox(height: 24),

                    // 照片控制层
                    AvatarPhotoControlSection(
                      hasPhoto: _avatarPath != null,
                      onTakePhoto: _takePhoto,
                      onPickFromGallery: _pickFromGallery,
                      onRemovePhoto: _removePhoto,
                    ),

                    const SizedBox(height: 24),

                    // 虚拟形象切换层
                    AvatarModeSwitch(
                      mode: _virtualMode,
                      onTextSelected: () {
                        setState(() {
                          _virtualMode = 'text';
                          _avatarIconCodePoint = null;
                        });
                        _notifyChanged();
                      },
                      onIconSelected: () {
                        setState(() {
                          _virtualMode = 'icon';
                          if (_avatarIconCodePoint == null &&
                              _assetIcons.isNotEmpty) {
                            _avatarIconCodePoint = _assetIcons[0].codePoint;
                          }
                          _avatarPath = null;
                        });
                        _notifyChanged();
                      },
                    ),

                    const SizedBox(height: 16),

                    // 根据模式显示文字输入或图标选择
                    if (_virtualMode == 'text')
                      AvatarTextInputSection(
                        controller: _textController,
                        onChanged: (value) {
                          setState(() {
                            _avatarPath = null;
                            _avatarIconCodePoint = null;
                          });
                          _notifyChanged();
                        },
                      )
                    else
                      AvatarIconSelectionSection(
                        icons: _assetIcons,
                        selectedCodePoint: _avatarIconCodePoint,
                        onIconSelected: _selectIcon,
                      ),

                    const SizedBox(height: 24),

                    // 颜色选择层
                    AvatarColorSelectionSection(
                      presetColors: _presetColors,
                      selectedColorValue: _avatarBgColor,
                      onPresetSelected: _selectPresetColor,
                      onCustomColorPressed: _openCustomColorPicker,
                    ),

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
}
