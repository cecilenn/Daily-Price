import 'package:flutter/material.dart';

import '../models/asset.dart';
import 'smart_asset_avatar.dart';

class AvatarPreviewSection extends StatelessWidget {
  final Asset asset;

  const AvatarPreviewSection({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SmartAssetAvatar(asset: asset, radius: 60),
      ),
    );
  }
}

class AvatarPhotoControlSection extends StatelessWidget {
  final bool hasPhoto;
  final VoidCallback onTakePhoto;
  final VoidCallback onPickFromGallery;
  final VoidCallback onRemovePhoto;

  const AvatarPhotoControlSection({
    super.key,
    required this.hasPhoto,
    required this.onTakePhoto,
    required this.onPickFromGallery,
    required this.onRemovePhoto,
  });

  @override
  Widget build(BuildContext context) {
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
              child: _ActionButton(
                icon: Icons.camera_alt,
                label: '拍照',
                onTap: onTakePhoto,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionButton(
                icon: Icons.photo_library,
                label: '相册',
                onTap: onPickFromGallery,
              ),
            ),
            if (hasPhoto) ...[
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.delete_outline,
                  label: '移除',
                  onTap: onRemovePhoto,
                  isDestructive: true,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class AvatarModeSwitch extends StatelessWidget {
  final String mode;
  final VoidCallback onTextSelected;
  final VoidCallback onIconSelected;

  const AvatarModeSwitch({
    super.key,
    required this.mode,
    required this.onTextSelected,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
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
                child: _ModeButton(
                  label: '文字',
                  isSelected: mode == 'text',
                  onTap: onTextSelected,
                ),
              ),
              Expanded(
                child: _ModeButton(
                  label: '图标',
                  isSelected: mode == 'icon',
                  onTap: onIconSelected,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class AvatarTextInputSection extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const AvatarTextInputSection({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '自定义文字 (最多2个字符)',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLength: 2,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 20),
          decoration: InputDecoration(
            hintText: '输入1-2个字符',
            counterText: '',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.grey[200],
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
}

class _ModeButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                    color: Colors.black.withValues(alpha: 0.1),
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
}
