import 'package:flutter/material.dart';

/// 图标水平选择区
class AvatarIconSelectionSection extends StatelessWidget {
  final List<IconData> icons;
  final int? selectedCodePoint;
  final ValueChanged<int> onIconSelected;

  const AvatarIconSelectionSection({
    super.key,
    required this.icons,
    required this.selectedCodePoint,
    required this.onIconSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('选择图标', style: TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 12),
        SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: icons.length,
            itemBuilder: (context, index) {
              final icon = icons[index];
              final isSelected = selectedCodePoint == icon.codePoint;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => onIconSelected(index),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Theme.of(
                              context,
                            ).primaryColor.withValues(alpha: 0.2)
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
                      icon,
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
}

/// 预设颜色 + 自定义颜色按钮区
class AvatarColorSelectionSection extends StatelessWidget {
  final List<Color> presetColors;
  final int? selectedColorValue;
  final ValueChanged<Color> onPresetSelected;
  final VoidCallback onCustomColorPressed;

  const AvatarColorSelectionSection({
    super.key,
    required this.presetColors,
    required this.selectedColorValue,
    required this.onPresetSelected,
    required this.onCustomColorPressed,
  });

  @override
  Widget build(BuildContext context) {
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
            for (final color in presetColors)
              _ColorCircle(
                color: color,
                isSelected: selectedColorValue == color.toARGB32(),
                onTap: () => onPresetSelected(color),
              ),
            _CustomColorButton(
              selectedColorValue: selectedColorValue,
              isCustom:
                  selectedColorValue != null &&
                  !presetColors.any(
                    (color) => color.toARGB32() == selectedColorValue,
                  ),
              onTap: onCustomColorPressed,
            ),
          ],
        ),
      ],
    );
  }
}

class _ColorCircle extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorCircle({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
            if (isSelected)
              BoxShadow(
                color: color.withValues(alpha: 0.4),
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
}

class _CustomColorButton extends StatelessWidget {
  final int? selectedColorValue;
  final bool isCustom;
  final VoidCallback onTap;

  const _CustomColorButton({
    required this.selectedColorValue,
    required this.isCustom,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: isCustom && selectedColorValue != null
            ? Container(
                decoration: BoxDecoration(
                  color: Color(selectedColorValue!),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 20),
              )
            : const Icon(Icons.add, color: Colors.white, size: 20),
      ),
    );
  }
}
