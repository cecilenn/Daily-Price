import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegisterMode = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// 将 AuthException 错误信息翻译为中文
  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return '账号或密码错误';
    } else if (message.contains('User already registered')) {
      return '该邮箱已被注册，请直接登录';
    } else if (message.contains('Email not confirmed')) {
      return '邮箱未验证，请查收验证邮件';
    } else if (message.contains('Password should be at least')) {
      return '密码长度至少为6位';
    } else if (message.contains('Unable to validate email address')) {
      return '邮箱格式不正确';
    } else if (message.contains('Signups not allowed')) {
      return '注册功能已关闭';
    }
    return '操作失败，请重试';
  }

  Future<void> _signIn() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('请输入邮箱和密码');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } on AuthException catch (e) {
      _showError(_translateAuthError(e.message));
    } catch (e) {
      _showError('登录失败，请重试');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signUp() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('请输入邮箱和密码');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('密码长度至少为6位');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (response.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('注册成功，请前往邮箱点击验证链接'),
            backgroundColor: Colors.green,
          ),
        );
        // 注册成功后自动切换回登录模式
        setState(() {
          _isRegisterMode = false;
        });
      }
    } on AuthException catch (e) {
      _showError(_translateAuthError(e.message));
    } catch (e) {
      _showError('注册失败，请重试');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          // 限制网页端宽度，防止输入框被无限拉伸
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  '资产管理',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 48),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: '邮箱',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: '密码',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator())
                else ...[
                  ElevatedButton(
                    onPressed: _isRegisterMode ? _signUp : _signIn,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(_isRegisterMode ? '注册新账号' : '登录'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isRegisterMode = !_isRegisterMode;
                      });
                    },
                    child: Text(_isRegisterMode ? '已有账号？直接登录' : '没有账号？点击注册'),
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