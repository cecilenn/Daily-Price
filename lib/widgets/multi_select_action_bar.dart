import 'package:flutter/material.dart';

class MultiSelectActionBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onDelete;
  final VoidCallback onTag;
  final VoidCallback onCategory;
  final VoidCallback onShare;

  const MultiSelectActionBar({
    super.key,
    required this.enabled,
    required this.onDelete,
    required this.onTag,
    required this.onCategory,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ActionButton(
              icon: Icons.delete,
              label: '删除',
              color: Colors.red,
              onPressed: enabled ? onDelete : null,
            ),
            _ActionButton(
              icon: Icons.label,
              label: '打标签',
              color: Colors.blue,
              onPressed: enabled ? onTag : null,
            ),
            _ActionButton(
              icon: Icons.category,
              label: '改分类',
              color: Colors.orange,
              onPressed: enabled ? onCategory : null,
            ),
            _ActionButton(
              icon: Icons.ios_share,
              label: '分享',
              color: Colors.green,
              onPressed: enabled ? onShare : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 18),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }
}
