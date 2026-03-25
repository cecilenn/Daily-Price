import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _isCodeSent = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  int _countdown = 0;

  static const String _supabaseUrl = 'https://yfkzdoputwygnfqwtrck.supabase.co';

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('请输入邮箱地址');
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      _showError('请输入有效的邮箱地址');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/functions/v1/send-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        setState(() {
          _isCodeSent = true;
          _countdown = 60;
        });
        _startCountdown();
        _showSuccess('验证码已发送，请查收邮箱');
      } else {
        _showError(data['error'] ?? '发送验证码失败');
      }
    } catch (e) {
      _showError('网络错误，请重试');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startCountdown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() {
        _countdown--;
      });
      return _countdown > 0;
    });
  }

  Future<void> _verifyAndReset() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    // 验证输入
    if (code.isEmpty) {
      _showError('请输入验证码');
      return;
    }

    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      _showError('验证码必须是6位数字');
      return;
    }

    if (newPassword.isEmpty) {
      _showError('请输入新密码');
      return;
    }

    if (newPassword.length < 6) {
      _showError('密码长度至少为6位');
      return;
    }

    if (newPassword != confirmPassword) {
      _showError('两次输入的密码不一致');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$_supabaseUrl/functions/v1/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'code': code,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        _showSuccess('密码重置成功');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context);
      } else {
        _showError(data['error'] ?? '重置密码失败');
      }
    } catch (e) {
      _showError('网络错误，请重试');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('重置密码'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.lock_reset,
                  size: 36,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 8),
                Text(
                  '重置密码',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                // 邮箱输入框
                TextFormField(
                  controller: _emailController,
                  enabled: !_isCodeSent,
                  decoration: const InputDecoration(
                    labelText: '邮箱地址',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // 发送验证码按钮或重新发送按钮
                SizedBox(
                  height: 48,
                  child: _isLoading && !_isCodeSent
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: (_isLoading || _countdown > 0)
                              ? null
                              : _sendResetCode,
                          child: Text(
                            _countdown > 0
                                ? '重新发送 ($_countdown)'
                                : (_isCodeSent ? '重新发送' : '发送验证码'),
                          ),
                        ),
                ),

                if (_isCodeSent) ...[
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // 验证码输入框
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: '验证码（6位数字）',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(),
                      helperText: '请输入邮箱收到的6位验证码',
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 16),

                  // 新密码输入框
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: '新密码',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureNewPassword,
                  ),
                  const SizedBox(height: 16),

                  // 确认密码输入框
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: '确认新密码',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    obscureText: _obscureConfirmPassword,
                    onFieldSubmitted: (_) => _verifyAndReset(),
                  ),
                  const SizedBox(height: 24),

                  // 确认重置按钮
                  SizedBox(
                    height: 48,
                    child: _isLoading && _isCodeSent
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _isLoading ? null : _verifyAndReset,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text('确认重置密码'),
                          ),
                  ),
                ],

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
