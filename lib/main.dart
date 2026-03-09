import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/settings_screen.dart';
import 'services/local_db_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化本地数据库
  await LocalDbService().init();

  runApp(
    ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: const DailyPriceApp(),
    ),
  );
}

class DailyPriceApp extends StatefulWidget {
  const DailyPriceApp({super.key});

  @override
  State<DailyPriceApp> createState() => _DailyPriceAppState();
}

class _DailyPriceAppState extends State<DailyPriceApp> {
  /// 获取主题数据
  ThemeData _getThemeData(AppTheme theme) {
    switch (theme) {
      case AppTheme.dark:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.dark,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );
      case AppTheme.light:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2196F3),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        );
      case AppTheme.green:
        return ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4CAF50),
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFFE8F5E9),
            foregroundColor: Color(0xFF2E7D32),
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            color: const Color(0xFFF1F8E9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF81C784)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF4CAF50), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          scaffoldBackgroundColor: const Color(0xFFF1F8E9),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          title: '个人资产管理',
          debugShowCheckedModeBanner: false,
          theme: _getThemeData(appProvider.theme),
          home: const AuthWrapper(),
          routes: {
            '/settings': (context) => const SettingsScreen(),
          },
        );
      },
    );
  }
}

/// 认证包装器 - 根据登录状态决定显示哪个页面
/// TODO: 替换为 PocketBase 认证逻辑
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  // TODO: 替换为 PocketBase 认证状态流
  // late final Stream<AuthState> _authStateStream;

  @override
  void initState() {
    super.initState();
    // TODO: 替换为 PocketBase 认证状态监听
    // _authStateStream = Supabase.instance.client.auth.onAuthStateChange;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: 替换为 PocketBase 认证逻辑
    // 暂时直接显示主页，后续添加 PocketBase 认证
    return const HomeScreen();
    
    /* 原 Supabase 认证逻辑
    return StreamBuilder<AuthState>(
      stream: _authStateStream,
      builder: (context, snapshot) {
        // 检查当前会话状态
        final session = Supabase.instance.client.auth.currentSession;
        
        if (session != null) {
          // 已登录，显示主页
          return const HomeScreen();
        } else {
          // 未登录，显示登录页
          return const LoginScreen();
        }
      },
    );
    */
  }
}
