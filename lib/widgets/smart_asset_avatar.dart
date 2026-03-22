import 'dart:io';

import 'package:flutter/material.dart';
import '../models/asset.dart';

/// SmartAssetAvatar V3.0 - 智能复合头像组件
///
/// 支持三种渲染模式（按优先级排序）：
/// 1. 照片模式：本地文件存在时显示圆形裁剪图片
/// 2. 图标模式：使用 Material Icon 配合背景色
/// 3. 文字模式：使用 1-2 个字符配合背景色
///
/// 使用示例：
/// ```dart
/// SmartAssetAvatar(asset: myAsset, radius: 40)
/// ```
class SmartAssetAvatar extends StatelessWidget {
  /// 资产对象
  final Asset asset;

  /// 头像半径
  final double radius;

  /// 默认背景色（当 asset.avatarBgColor 为空时使用）
  final Color defaultBgColor;

  /// 默认文字颜色
  final Color defaultTextColor;

  const SmartAssetAvatar({
    super.key,
    required this.asset,
    required this.radius,
    this.defaultBgColor = const Color(0xFFE0E0E0),
    this.defaultTextColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    // 优先级1：照片模式（如果 avatarPath 不为空且文件存在）
    if (asset.avatarPath != null && asset.avatarPath!.isNotEmpty) {
      final file = File(asset.avatarPath!);
      // 异步检查文件是否存在需要 FutureBuilder，但这里简化处理
      // 实际使用时文件通常已经确认存在
      return _buildPhotoAvatar(file);
    }

    // 优先级2：图标模式（如果 avatarIconCodePoint 不为空）
    if (asset.avatarIconCodePoint != null) {
      return _buildIconAvatar();
    }

    // 优先级3：文字模式（默认）
    return _buildTextAvatar();
  }

  /// 构建照片头像（圆形裁剪）
  Widget _buildPhotoAvatar(File file) {
    return ClipOval(
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // 照片加载失败时回退到文字头像
            return _buildTextAvatar();
          },
        ),
      ),
    );
  }

  /// 构建图标头像
  Widget _buildIconAvatar() {
    final bgColor = asset.avatarBgColor != null
        ? Color(asset.avatarBgColor!)
        : defaultBgColor;

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: Icon(
        IconData(asset.avatarIconCodePoint!, fontFamily: 'MaterialIcons'),
        color: defaultTextColor,
        size: radius * 1.2,
      ),
    );
  }

  /// 构建文字头像
  Widget _buildTextAvatar() {
    final bgColor = asset.avatarBgColor != null
        ? Color(asset.avatarBgColor!)
        : defaultBgColor;

    // 获取显示文字：优先使用 avatarText，否则取 assetName 首字符
    String displayText = '';
    if (asset.avatarText != null && asset.avatarText!.isNotEmpty) {
      displayText = asset.avatarText!;
    } else if (asset.assetName.isNotEmpty) {
      displayText = asset.assetName[0];
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bgColor,
      child: FittedBox(
        fit: BoxFit.contain,
        child: Padding(
          padding: EdgeInsets.all(radius * 0.2),
          child: Text(
            displayText,
            style: TextStyle(
              color: defaultTextColor,
              fontSize: radius,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// 便捷方法：获取头像显示文字
String getAvatarDisplayText(Asset asset) {
  if (asset.avatarText != null && asset.avatarText!.isNotEmpty) {
    return asset.avatarText!;
  }
  if (asset.assetName.isNotEmpty) {
    return asset.assetName[0];
  }
  return '';
}

/// 便捷方法：获取头像背景色
Color getAvatarBgColor(
  Asset asset, {
  Color fallback = const Color(0xFFE0E0E0),
}) {
  return asset.avatarBgColor != null ? Color(asset.avatarBgColor!) : fallback;
}
