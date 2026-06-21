import 'package:supabase_flutter/supabase_flutter.dart';

class PasswordResetException implements Exception {
  final String message;

  const PasswordResetException(this.message);

  @override
  String toString() => message;
}

class PasswordResetService {
  const PasswordResetService._();

  static Future<void> sendCode(String email) async {
    await _invoke('send-reset-code', {'email': email});
  }

  static Future<void> verifyCode({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _invoke('verify-reset-code', {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  static Future<void> _invoke(
    String functionName,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        functionName,
        body: body,
      );
      final data = response.data;
      if (data is Map && data['success'] == false) {
        throw PasswordResetException(_messageFrom(data));
      }
    } on FunctionException catch (e) {
      throw PasswordResetException(_messageFrom(e.details));
    }
  }

  static String _messageFrom(dynamic data) {
    if (data is Map) {
      final error = data['error']?.toString();
      if (error != null && error.isNotEmpty) return error;
      final message = data['message']?.toString();
      if (message != null && message.isNotEmpty) return message;
    }
    if (data is String && data.isNotEmpty) return data;
    return '请求失败，请稍后重试';
  }
}
