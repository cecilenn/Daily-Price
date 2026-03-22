import 'dart:io';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// 图片处理工具类
class ImageUtils {
  static final ImagePicker _picker = ImagePicker();
  static final ImageCropper _cropper = ImageCropper();
  static const Uuid _uuid = Uuid();

  /// 选择并裁剪图片（1:1 正方形）
  /// 返回裁剪后的图片文件路径，如果用户取消则返回 null
  static Future<String?> pickAndCropImage() async {
    try {
      // 从相册选择图片
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (pickedFile == null) {
        return null; // 用户取消选择
      }

      // 裁剪图片为 1:1 正方形
      final CroppedFile? croppedFile = await _cropper.cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: '裁剪头像',
            toolbarColor: const Color(0xFF2196F3),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.original,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: '裁剪头像',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: true,
          ),
        ],
      );

      if (croppedFile == null) {
        return null; // 用户取消裁剪
      }

      // 保存到应用文档目录
      return await _saveImageToAppDirectory(croppedFile);
    } catch (e) {
      log('[ImageUtils] 选择裁剪失败：$e');
      return null;
    }
  }

  /// 保存图片到应用文档目录
  static Future<String> _saveImageToAppDirectory(
    CroppedFile croppedFile,
  ) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imageDirPath = '${appDir.path}/assets/avatars';
    final Directory imageDir = Directory(imageDirPath);

    // 创建目录（如果不存在）
    if (!await imageDir.exists()) {
      await imageDir.create(recursive: true);
    }

    // 使用 UUID 生成唯一文件名
    final String fileName = '${_uuid.v4()}.jpg';
    final String filePath = '$imageDirPath/$fileName';

    // 复制文件
    final File savedFile = await File(croppedFile.path).copy(filePath);
    return savedFile.path;
  }

  /// 删除指定图片
  static Future<void> deleteImage(String imagePath) async {
    try {
      final File file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      log('[ImageUtils] 删除图片失败：$e');
    }
  }
}
