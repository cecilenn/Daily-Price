/// 头像编辑结果。
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

  Map<String, dynamic> toAssetFields() {
    return {
      'avatar_path': avatarPath,
      'avatar_bg_color': avatarBgColor,
      'avatar_text': avatarText,
      'avatar_icon_code_point': avatarIconCodePoint,
    };
  }
}
