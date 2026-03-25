# 🛠️ 开发与架构指南

> 当前文档描述 Daily Price 项目的**当前固有底层能力**，供新接手开发者快速理解技术选型与架构设计。

---

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/
│   └── asset.dart               # 核心资产数据模型
├── providers/
│   ├── app_provider.dart        # 全局状态管理（主题偏好）
│   └── asset_provider.dart      # 资产数据共享状态管理（新增）
├── screens/
│   ├── main_tab_screen.dart     # 主标签页（悬浮岛导航）
│   ├── home_screen.dart         # 首页：资产列表 + 全局统计
│   ├── asset_detail_screen.dart # 资产详情页
│   ├── add_edit_asset_screen.dart # 添加/编辑资产页
│   ├── analysis_screen.dart     # 统计分析页
│   ├── scanner_screen.dart      # 扫码页面
│   ├── login_screen.dart        # 登录页面（预留）
│   ├── settings_screen.dart     # 设置页面
│   ├── category_settings_screen.dart # 自定义分类设置（新增）
│   ├── tag_settings_screen.dart # 标签设置页面（新增）
│   ├── preference_settings_screen.dart # 偏好设置页面（新增）
│   ├── data_settings_screen.dart # 数据设置页面（新增）
│   └── theme_settings_screen.dart # 主题设置页面（新增）
├── services/
│   ├── local_db_service.dart    # SQLite 数据库服务层
│   └── asset_filter_sorter.dart # 过滤与排序工具类（新增）
├── utils/
│   ├── image_utils.dart         # 图片处理工具
│   ├── stats_calculator.dart    # 统计计算工具类（新增）
│   ├── time_formatter.dart      # 时长格式化工具（新增）
│   └── pref_keys.dart           # 偏好设置键名常量（新增）
└── widgets/
    ├── asset_form_dialog.dart   # 资产表单对话框
    ├── smart_asset_avatar.dart  # 智能头像组件
    └── avatar_editor_sheet.dart # 头像编辑器底部面板
```

### 新增文件说明

| 文件 | 职责 |
|------|------|
| `asset_provider.dart` | 资产数据的集中管理，提供 loadAssets、saveAsset、deleteAsset、importAssets 等方法，所有页面通过 Consumer 或 context.read 访问 |
| `asset_filter_sorter.dart` | 提供 filterAndSort 静态方法，根据分栏、排序方式过滤和排序资产列表 |
| `stats_calculator.dart` | 提供 calculate 静态方法，计算总资产、日均消费、各状态资产数量等统计数据 |

---

## 环境准备

### 必需软件

| 软件 | 版本 | 用途 |
|------|------|------|
| Flutter SDK | ^3.11.0 | 跨平台开发框架 |
| Dart SDK | ^3.11.0 | Dart 语言运行环境 |
| Android Studio | 最新版 | Android 模拟器 + SDK |
| Xcode | 最新版 | iOS/macOS 开发（仅限 Mac） |

### 验证安装

```bash
flutter --version
flutter doctor
```

---

## 项目初始化

```bash
# 克隆仓库
git clone https://github.com/cecilenn/Daily-Price.git
cd daily_price

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

> ⚠️ 本项目使用 sqflite，**无需运行 `build_runner`**。

---

## 数据库架构 (SQLite)

### 当前版本：v7

### assets 表结构

```sql
CREATE TABLE assets(
  id TEXT PRIMARY KEY,                    -- UUID v4 字符串
  asset_name TEXT NOT NULL,               -- 资产名称
  purchase_price REAL,                    -- 购入价格
  purchase_date INTEGER NOT NULL,         -- 购买日期时间戳（毫秒）
  is_pinned INTEGER DEFAULT 0,            -- 是否置顶（0 或 1）
  category TEXT DEFAULT 'physical',       -- 资产分类
  tags TEXT DEFAULT '[]',                 -- 标签列表（JSON 字符串）
  created_at INTEGER NOT NULL,            -- 创建时间时间戳（毫秒）
  status INTEGER DEFAULT 0,               -- 状态：0=服役中, 1=已退役, 2=已卖出
  expected_lifespan_days INTEGER,         -- 预计使用天数
  expire_date INTEGER,                    -- 过期日期时间戳（毫秒）
  sold_price REAL,                        -- 卖出价格
  sold_date INTEGER,                      -- 卖出/退役日期时间戳（毫秒）
  avatar_path TEXT,                       -- 头像本地图片路径
  avatar_bg_color INTEGER,                -- 头像背景色（ARGB 整数）
  avatar_text TEXT,                       -- 头像自定义文字
  avatar_icon_code_point INTEGER,         -- Material 图标 Unicode 码点
  exclude_from_total INTEGER DEFAULT 0,   -- 不计入总资产（0 或 1）
  exclude_from_daily INTEGER DEFAULT 0,   -- 不计入日均消费（0 或 1）
  ownership_type TEXT DEFAULT 'buyout',   -- 所有权类型：buyout/subscription
  renewals TEXT DEFAULT '[]'              -- 续费记录列表（JSON 字符串）
)
```

### RenewalRecord 数据结构

```dart
class RenewalRecord {
  final DateTime date;      // 续费日期
  final double amount;      // 续费金额
  final int days;           // 续费天数
  
  RenewalRecord({
    required this.date,
    required this.amount,
    required this.days,
  });
}
```

### 字段配合逻辑

| 字段组合 | 用途 |
|----------|------|
| `status` + `soldDate` | 状态为 1(退役) 或 2(卖出) 时，`soldDate` 冻结时间用于计算实际使用天数 |
| `status` + `soldPrice` | 状态为 2(卖出) 时，`soldPrice` 用于回血抵扣成本计算 |
| `expectedLifespanDays` + `purchaseDate` | 计算剩余天数与预期寿命进度 |
| `avatarPath` / `avatarIconCodePoint` / `avatarText` | 复合头像引擎的三级渲染优先级 |
| `excludeFromTotal` / `excludeFromDaily` | 统计过滤标记，用于全局统计卡片的计算排除 |

### 核心数据库操作

```dart
// 单例获取
final db = LocalDbService();

// 初始化（应用启动时）
await db.init();

// Upsert 操作（导入时使用）
await db.insert(
  'assets',
  asset.toMap(),
  conflictAlgorithm: ConflictAlgorithm.replace,  // 冲突时替换
);
```

### importAssetsWithUpsert 性能优化

V2.0 性能优化：使用 WHERE IN 批量查询 + 内存 Set 判断 + batch 统一 commit，避免逐条 SELECT 查询。

```dart
// 优化前：对每条资产逐条 SELECT 查重
for (final asset in parsedAssets) {
  final existing = await db.query('assets', where: 'id = ?', whereArgs: [asset.id]);
  // ...
}

// 优化后：一次性批量查询
final allIds = parsedAssets.map((asset) => asset.id).toList();
final placeholders = List.filled(allIds.length, '?').join(',');
final existingMaps = await db.query(
  'assets',
  columns: ['id'],
  where: 'id IN ($placeholders)',
  whereArgs: allIds,
);
final existingIds = existingMaps.map((map) => map['id'] as String).toSet();
```

---

## 订阅续费计算逻辑

### 计算方式

| 所有权类型 | 计算公式 | 说明 |
|------------|----------|------|
| `buyout` | 总成本 / 使用天数 | 传统买断方式，一次购买价 / 使用天数 |
| `subscription` | 总续费金额 / 总实际订阅天数 | 订阅方式，累计所有续费记录的金额和天数 |

### 续费顺沿规则

当续费日期仍在上一次订阅期限内时，新期限从原到期日开始计算：

```dart
// 续费顺沿逻辑示例
DateTime lastExpireDate = ... // 上一次到期日
DateTime renewalDate = DateTime.now(); // 续费日期

// 如果续费日期早于或等于上次到期日，则从上次到期日开始计算
DateTime newExpireDate = renewalDate.isBefore(lastExpireDate) || renewalDate.isAtSameMomentAs(lastExpireDate)
    ? lastExpireDate.add(Duration(days: renewalDays))
    : renewalDate.add(Duration(days: renewalDays));
```

### 日均成本计算

```dart
double get dailyCost {
  if (ownershipType == 'subscription') {
    // 订阅方式：总续费金额 / 总实际订阅天数
    double totalAmount = renewals.fold(0, (sum, r) => sum + r.amount);
    int totalDays = renewals.fold(0, (sum, r) => sum + r.days);
    return totalDays > 0 ? totalAmount / totalDays : 0;
  } else {
    // 买断方式：传统计算
    return purchasePrice / calculatedDays;
  }
}
```

---

## 时长显示格式

应用支持五种时长显示模式，通过 `TimeFormatter` 工具类实现：

| 模式 | 格式 | 示例 | 说明 |
|------|------|------|------|
| 自动计算 | `1年3月15天` | `1年3月15天` | 智能拆分年、月、日 |
| 自动合并 | `1.3年` | `1.3年` | 统一换算为年（保留一位小数） |
| 年 | `1.5年` | `1.5年` | 强制以年为单位显示 |
| 月 | `15.5月` | `15.5月` | 强制以月为单位显示 |
| 日 | `450天` | `450天` | 强制以天为单位显示 |

### TimeFormatter 核心方法

```dart
class TimeFormatter {
  /// 格式化时长
  /// - [days] 总天数
  /// - [mode] 显示模式：auto/auto_merge/year/month/day
  static String formatDuration(int days, TimeDisplayMode mode) {
    switch (mode) {
      case TimeDisplayMode.auto:
        return _formatAuto(days);
      case TimeDisplayMode.autoMerge:
        return _formatAutoMerge(days);
      case TimeDisplayMode.year:
        return '${(days / 365.25).toStringAsFixed(1)}年';
      case TimeDisplayMode.month:
        return '${(days / 30.44).toStringAsFixed(1)}月';
      case TimeDisplayMode.day:
        return '${days}天';
    }
  }
  
  static String _formatAuto(int days) {
    if (days < 30) return '${days}天';
    if (days < 365) return '${days ~/ 30}月${days % 30}天';
    final years = days ~/ 365;
    final remainingDays = days % 365;
    final months = remainingDays ~/ 30;
    final finalDays = remainingDays % 30;
    
    String result = '${years}年';
    if (months > 0) result += '${months}月';
    if (finalDays > 0) result += '${finalDays}天';
    return result;
  }
  
  static String _formatAutoMerge(int days) {
    final years = days / 365.25;
    return '${years.toStringAsFixed(1)}年';
  }
}
```

### 用户偏好存储

时长显示模式通过 `shared_preferences` 持久化存储：

```dart
// 保存用户选择
await prefs.setString('time_display_mode', mode.name);

// 读取用户选择
final modeName = prefs.getString('time_display_mode') ?? 'auto';
final mode = TimeDisplayMode.values.firstWhere(
  (m) => m.name == modeName,
  orElse: () => TimeDisplayMode.auto,
);
```

---

## 状态管理架构

当前系统采用双 Provider 架构：

| Provider | 职责 |
|----------|------|
| `AppProvider` | 主题模式、日期格式等用户偏好设置 |
| `AssetProvider` | 资产数据的加载、增删改、导入，所有页面共享 |

### AssetProvider 核心方法

| 方法 | 说明 |
|------|------|
| `loadAssets()` | 加载全部资产数据，启动时自动调用 |
| `saveAsset(asset)` | 新增或更新单个资产 |
| `deleteAsset(id)` | 删除资产并物理删除关联文件 |
| `importAssets(list)` | 批量导入（upsert），内部自动重新加载 |
| `togglePinned(asset)` | 切换置顶状态 |

### 数据流

```
LocalDbService (底层 CRUD)
        ↑
AssetProvider (状态管理 + 通知)
        ↑
Consumer<AssetProvider> (UI 层读取)
        ↓
HomeScreen / AssetDetailScreen / SettingsScreen
```

Screen 层不再直接调用 LocalDbService，统一通过 AssetProvider 操作。

---

## UI/UX 架构

### 悬浮岛导航 (Floating Dock)

当前系统采用底部悬浮岛导航，实现 iOS 风格毛玻璃穿透效果。

```dart
Scaffold(
  extendBody: true,  // 关键：内容穿透到底部栏下方
  body: IndexedStack(
    index: _selectedIndex,
    children: [HomeScreen(), AnalysisScreen(), SettingsScreen()],
  ),
  bottomNavigationBar: _buildFloatingDock(),
)
```

**毛玻璃实现核心：**

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(30),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65),
        border: Border.all(
          color: Colors.white.withOpacity(0.4),
          width: 1,
        ),
      ),
    ),
  ),
)
```

### 扫码引擎

采用 `mobile_scanner` 插件，实现了防抖与相册解析方案。

```dart
MobileScanner(
  onDetect: _debounce((barcode) {
    // 防抖处理，避免重复扫描
    _handleBarcode(barcode);
  }, duration: Duration(milliseconds: 1500)),
)
```

**相册解析：** 支持从相册选择含二维码的图片进行识别，作为摄像头扫描的补充方案。

### 复合型智能头像引擎 (SmartAssetAvatar)

当前系统采用 `SmartAssetAvatar` 组件，确立了**绝对渲染优先级**：

| 优先级 | 条件 | 渲染结果 |
|--------|------|----------|
| 1 | `avatarPath != null` 且文件存在 | 本地图片文件（`Image.file` + `ClipOval`） |
| 2 | `avatarIconCodePoint != null` | Material 矢量图标（`IconData` + 圆形背景色） |
| 3 | `avatarText != null` | 自定义文字（`FittedBox` 自动缩放防溢出） |
| 4 | 以上皆无 | 资产名称首字（兜底） |

**核心实现逻辑：**

```dart
class SmartAssetAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // 优先级 1: 本地图片（文件不存在时静默降级到下一级）
    if (asset.avatarPath != null && asset.avatarPath!.isNotEmpty) {
      final file = File(asset.avatarPath!);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(file, fit: BoxFit.cover),
        );
      }
      // 文件不存在时静默降级，继续检查下一级
    }

    // 优先级 2: Material 图标
    if (asset.avatarIconCodePoint != null) {
      return CircleAvatar(
        backgroundColor: Color(asset.avatarBgColor ?? 0xFF6C5CE7),
        child: Icon(
          IconData(asset.avatarIconCodePoint!, fontFamily: 'MaterialIcons'),
        ),
      );
    }

    // 优先级 3/4: 文字（自定义或名称首字）
    final displayText = asset.avatarText?.isNotEmpty == true
        ? asset.avatarText![0]
        : asset.assetName[0];
    
    return CircleAvatar(
      backgroundColor: Color(asset.avatarBgColor ?? 0xFF6C5CE7),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(displayText),
      ),
    );
  }
  
  /// 静态方法：获取头像显示文字
  static String getDisplayText(Asset asset) {
    if (asset.avatarText != null && asset.avatarText!.isNotEmpty) {
      return asset.avatarText![0];
    }
    return asset.assetName.isNotEmpty ? asset.assetName[0] : '?';
  }
  
  /// 静态方法：获取头像背景色
  static Color getBgColor(Asset asset) {
    return Color(asset.avatarBgColor ?? 0xFF6C5CE7);
  }
}
```

### 专业调色板定制 (flutter_colorpicker)

当前系统引入 `flutter_colorpicker` 并在底部面板中进行深度定制：

- **屏蔽 Alpha 通道**：`enableAlpha: false` — 头像背景仅支持不透明纯色
- **强制 HEX 输入**：`hexInputBar: true` — 支持专业级十六进制色彩录入
- **12 色预设矩阵**：提供 Material Design 精选纯色快速选择

```dart
ColorPicker(
  pickerColor: currentColor,
  onColorChanged: (color) => setState(() => currentColor = color),
  enableAlpha: false,        // 屏蔽透明度
  hexInputBar: true,         // HEX 输入栏
  colorPickerType: ColorPickerType.custom,
  labelTypes: const [ColorLabelType.hex],
)
```

**12 色预设矩阵：**

```dart
const presetColors = [
  Color(0xFF6C5CE7), // 紫罗兰
  Color(0xFF00B894), // 薄荷绿
  Color(0xFF0984E3), // 深海蓝
  Color(0xFFE17055), // 珊瑚橙
  Color(0xFFFD79A8), // 樱花粉
  Color(0xFFFDCB6E), // 暖黄
  Color(0xFF2D3436), // 炭黑
  Color(0xFFB2BEC3), // 冷灰
  Color(0xFF00CEC9), // 青绿
  Color(0xFFE84393), // 玫红
  Color(0xFFFF7675), // 番茄红
  Color(0xFF74B9FF), // 天空蓝
];
```

---

## 技术选型与坑位记录

### 图片处理流程

选择图片 → 1:1 裁剪 → 保存到应用文档目录 → 数据库存储路径

```dart
// 选择并裁剪
final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
final CroppedFile? cropped = await _cropper.cropImage(
  sourcePath: picked.path,
  aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
);

// 保存到本地
final Directory appDir = await getApplicationDocumentsDirectory();
final String filePath = '${appDir.path}/assets/avatars/${Uuid().v4()}.jpg';
await File(cropped.path).copy(filePath);
```

### Release 打包必须配置

**问题**：`image_cropper`（UCrop）内部依赖了未使用的 `okhttp3`，导致 R8 混淆器报错。

**解决**：在 `android/app/proguard-rules.pro` 中添加：

```proguard
# 忽略 UCrop 依赖的 okhttp 缺失警告
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn java.nio.file.**

# 保护 UCrop 核心类
-keep class com.yalantis.ucrop** { *; }
```

**启用 ProGuard：**

```kotlin
// android/app/build.gradle.kts
buildTypes {
    release {
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

**打包命令：**

```bash
flutter clean
flutter pub get
flutter build apk --release --no-tree-shake-icons
```

> ⚠️ **`--no-tree-shake-icons` 必须加上**，防止 Material 图标被摇树优化移除。

### CSV 导入/导出约束

- `csv` 插件版本锁定为 `5.0.2`
- 使用 `const ListToCsvConverter()` 和 `const CsvToListConverter()`
- 导入时使用 `importAssetsWithUpsert()` 实现按 UUID 查重合并

### 自定义 APK 文件名

项目根目录提供 `build_and_rename.sh` 脚本，打包后自动重命名 APK 和 SHA1 文件：

```bash
./build_and_rename.sh
```

输出文件命名：

• `cecilenn.dailyprice_v8a.apk`（arm64）
• `cecilenn.dailyprice_v7a.apk`（armeabi-v7a）
• `cecilenn.dailyprice_x64.apk`（x86_64）

脚本执行：`flutter clean` → `flutter pub get` → `flutter build apk` → rename。

---

## 测试指南

```bash
# 运行所有测试
flutter test

# 运行特定文件
flutter test test/widget_test.dart

# 调试模式运行
flutter run --debug
```

---

## 核心依赖版本

```yaml
dependencies:
  sqflite: ^2.3.0
  provider: ^6.1.2
  shared_preferences: ^2.3.3
  image_picker: ^1.0.0
  image_cropper: ^8.0.0
  mobile_scanner: ^3.5.0
  flutter_colorpicker: ^1.0.3
  csv: 5.0.2  # 版本锁定
  http: ^1.0.0  # HTTP 请求
  supabase_flutter: ^2.0.0  # Supabase 云端同步
```

---

## V1.4.0 新增功能

### 云端同步功能
- 支持 Supabase 云端备份与恢复
- 显示云端存档日期时间（格式：YYYY-MM-DD HH:mm:ss）
- 使用 `CloudSyncService.getLastSyncTime()` 获取最后同步时间

### 密码重置功能
- App 内置密码重置流程（两步验证）
- 发送验证码到邮箱（60秒倒计时重发）
- 验证码验证 + 新密码设置
- 支持密码显示/隐藏切换
- UI 与登录页风格一致

### 新增文件
- `lib/screens/reset_password_screen.dart` - 密码重置页面
- `reset.html` - 密码重置网页（Supabase Deep Link 回调）

### 修改文件
- `lib/screens/login_screen.dart` - 添加密码重置导航
- `lib/screens/data_settings_screen.dart` - 添加云端存档时间显示

---

<div align="center">

**当前架构版本：基于 sqflite + Provider 的本地优先架构**

</div>
