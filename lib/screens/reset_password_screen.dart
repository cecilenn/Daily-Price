import 'package:flutter/material.dart';

import '../services/password_reset_service.dart';

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
  bool _codeSent = false;

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
    final error = _validateEmail(email);
    if (error != null) {
      _showError(error);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await PasswordResetService.sendCode(email);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _showSuccess('验证码已发送，请查收邮箱（包含垃圾箱）');
    } on PasswordResetException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('发送验证码失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final emailError = _validateEmail(email);
    if (emailError != null) {
      _showError(emailError);
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showError('请输入 6 位数字验证码');
      return;
    }
    if (newPassword.length < 6) {
      _showError('新密码长度至少为 6 位');
      return;
    }
    if (newPassword != confirmPassword) {
      _showError('两次输入的新密码不一致');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await PasswordResetService.verifyCode(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      if (!mounted) return;
      _showSuccess('密码已重置，请使用新密码登录');
      Navigator.pop(context);
    } on PasswordResetException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('重置密码失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return '请输入邮箱地址';
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return '请输入有效的邮箱地址';
    }
    return null;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, maxLines: 4),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 6),
      ),
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
      appBar: AppBar(title: const Text('重置密码'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Icon(
                  Icons.lock_reset,
                  size: 40,
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
                const SizedBox(height: 16),
                Text(
                  _codeSent
                      ? '验证码已发送到 ${_emailController.text.trim()}，5 分钟内有效。'
                      : '输入注册邮箱，系统会发送 6 位验证码。',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  enabled: !_codeSent && !_isLoading,
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
                  autofocus: true,
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _codeController,
                    decoration: const InputDecoration(
                      labelText: '验证码',
                      hintText: '6 位数字',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: '新密码',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: '确认新密码',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    onFieldSubmitted: (_) =>
                        _isLoading ? null : _resetPassword(),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _codeSent
                              ? _resetPassword
                              : _sendResetCode,
                          child: Text(_codeSent ? '重置密码' : '发送验证码'),
                        ),
                ),
                if (_codeSent) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            _codeController.clear();
                            _newPasswordController.clear();
                            _confirmPasswordController.clear();
                            _sendResetCode();
                          },
                    child: const Text('重新发送验证码'),
                  ),
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () {
                            setState(() {
                              _codeSent = false;
                              _codeController.clear();
                              _newPasswordController.clear();
                              _confirmPasswordController.clear();
                            });
                          },
                    child: const Text('修改邮箱'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
