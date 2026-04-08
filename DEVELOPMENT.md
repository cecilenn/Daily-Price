# 🛠️ 开发与架构指南

Daily Price 项目的开发文档，记录技术选型、架构设计、踩坑经验。

---

## 环境配置

| 软件 | 版本 | 用途 |
|------|------|------|
| Flutter SDK | ^3.11.0 | 跨平台开发框架 |
| Dart SDK | ^3.11.0 | Dart 语言运行环境 |
| Android Studio | 最新版 | Android 模拟器 + SDK |
| Xcode | 最新版 | iOS/macOS 开发（仅限 Mac） |

```bash
flutter --version
flutter doctor
```

项目初始化：

```bash
git clone https://github.com/cecilenn/Daily-Price.git
cd Daily-Price
flutter pub get
flutter run
```

> 本项目使用 sqflite，**无需运行 `build_runner`**。

---

## 项目结构

```
lib/
├── main.dart
├── models/
│   ├── asset.dart                    # 核心资产数据模型
│   └── check_session.dart            # 检查任务与检查项模型
├── providers/
│   ├── app_provider.dart             # 全局状态管理（主题偏好）
│   ├── asset_provider.dart           # 资产数据共享状态管理
│   └── check_provider.dart           # 检查任务状态管理
├── screens/
│   ├── main_tab_screen.dart          # 主标签页（悬浮岛导航）
│   ├── home_screen.dart              # 首页：资产列表 + 全局统计
│   ├── asset_detail_screen.dart      # 资产详情页
│   ├── add_edit_asset_screen.dart    # 添加/编辑资产页
│   ├── analysis_screen.dart          # 统计分析页
│   ├── scanner_screen.dart           # 扫码页面
│   ├── login_screen.dart             # 登录页面
│   ├── reset_password_screen.dart    # 密码重置页面
│   ├── settings_screen.dart          # 设置页面
│   ├── category_settings_screen.dart # 分类设置
│   ├── tag_settings_screen.dart      # 标签设置
│   ├── preference_settings_screen.dart # 偏好设置
│   ├── data_settings_screen.dart     # 数据设置
│   ├── theme_settings_screen.dart    # 主题设置
│   ├── function_hub_screen.dart      # 功能入口页
│   ├── check_list_screen.dart        # 检查任务列表页
│   ├── check_detail_screen.dart      # 检查详情页
│   └── check_scan_screen.dart        # 扫码检查页
├── services/
│   ├── local_db_service.dart         # SQLite 数据库服务层
│   ├── cloud_sync_service.dart       # Supabase 云端同步
│   └── asset_filter_sorter.dart      # 过滤与排序工具
├── utils/
│   ├── image_utils.dart              # 图片处理工具
│   ├── stats_calculator.dart         # 统计计算
│   ├── time_formatter.dart           # 时长格式化
│   └── pref_keys.dart                # 偏好设置键名常量
├── widgets/
│   ├── asset_form_dialog.dart        # 资产表单对话框
│   ├── smart_asset_avatar.dart       # 智能头像组件
│   └── avatar_editor_sheet.dart      # 头像编辑器底部面板
└── features/
    └── inspection/                   # 特调检查模块（独立，易于拆分）
        ├── models/
        │   ├── company_asset.dart          # 公司资产模型
        │   ├── company_check_session.dart  # 检查会话模型
        │   └── company_check_item.dart     # 检查项模型
        ├── data/
        │   └── inspection_db.dart          # 独立数据库（inspection.db）
        ├── services/
        │   ├── webdav_config.dart          # WebDAV 配置（SharedPreferences）
        │   └── webdav_service.dart         # WebDAV 客户端
        ├── providers/
        │   └── inspection_provider.dart    # 特调检查状态管理
        └── screens/
            ├── inspection_list_screen.dart    # 会话列表
            ├── inspection_detail_screen.dart  # 检查详情
            ├── inspection_scan_screen.dart    # 扫码录入/确认
            ├── import_session_screen.dart     # 分享码导入
            ├── webdav_config_screen.dart      # WebDAV 配置
            └── asset_manage_screen.dart       # 本地资产管理
```

---

## 架构设计

### 状态管理 — 四 Provider 架构

| Provider | 职责 |
|----------|------|
| `AppProvider` | 主题模式、日期格式等用户偏好 |
| `AssetProvider` | 资产数据的加载、增删改、导入 |
| `CheckProvider` | 检查任务的加载、创建、完成、删除 |
| `InspectionProvider` | 特调检查（独立模块，WebDAV 同步 + 检查任务管理） |

数据流：

```
LocalDbService (底层 CRUD)
        ↑
AssetProvider / CheckProvider (状态管理 + 通知)
        ↑
Consumer<Provider> (UI 层读取)
        ↓
各 Screen 页面
```

Screen 层不再直接调用 LocalDbService，统一通过 Provider 操作。

### AssetProvider 核心方法

| 方法 | 说明 |
|------|------|
| `loadAssets()` | 加载全部资产数据 |
| `saveAsset(asset)` | 新增或更新单个资产 |
| `deleteAsset(id)` | 删除资产并物理删除关联文件 |
| `importAssets(list)` | 批量导入（upsert），内部自动重载 |
| `togglePinned(asset)` | 切换置顶状态 |

### CheckProvider 核心方法

| 方法 | 说明 |
|------|------|
| `loadSessions()` | 加载全部检查任务 |
| `createSession(name)` | 创建新检查任务 |
| `completeSession(id)` | 完成检查任务 |
| `deleteSession(id)` | 删除检查任务及其关联检查项 |
| `getItems(sessionId)` | 获取检查任务的所有检查项 |
| `addItem(...)` | 添加检查项 |
| `confirmItem(id)` | 确认检查项 |
| `deleteItem(id)` | 删除检查项 |
| `exportSession(sessionId)` | 导出为 CSV |
| `importSession(data)` | 从 CSV 导入 |

---

## 数据库

### 当前版本：v8

### 特调检查模块（独立数据库 inspection.db）

#### company_assets 表

```sql
CREATE TABLE company_assets (
  asset_code TEXT PRIMARY KEY,
  asset_name TEXT NOT NULL DEFAULT '',
  spec TEXT NOT NULL DEFAULT '',
  department TEXT NOT NULL DEFAULT '',
  user TEXT NOT NULL DEFAULT '',
  location TEXT NOT NULL DEFAULT ''
);
```

#### company_check_sessions 表

```sql
CREATE TABLE company_check_sessions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  status INTEGER NOT NULL DEFAULT 0
);
```

#### company_check_items 表

```sql
CREATE TABLE company_check_items (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  asset_code TEXT NOT NULL,
  asset_snapshot TEXT NOT NULL,
  confirmed_at INTEGER,
  FOREIGN KEY (session_id) REFERENCES company_check_sessions(id) ON DELETE CASCADE
);
```

### 特调检查 — WebDAV 数据架构

云端文件结构：

```
/webdav/
  assets.json                  # 总资产主文件
  sessions/
    {shareCode}.json           # 分享的检查会话
```

总资产文件格式（通过 App 内"管理本地资产库"录入后上传）：

```json
[
  {"资产编码":"EQ-001","资产名称":"联想笔记本","规格型号":"ThinkPad X1","使用部门":"技术部","使用人":"张三","存放位置":"A栋301室"}
]
```

会话分享文件格式：

```json
{
  "name": "2024春季展会盘点",
  "createdAt": 1710000000000,
  "assetCodes": ["EQ-001", "EQ-005"],
  "confirmedCodes": ["EQ-001"]
}
```

扫码流程：扫码得到资产编码 → 本地总资产库查找 → 填充详情到检查项。确认时仅比对资产编码，不走网络。

### assets 表

```sql
CREATE TABLE assets(
  id TEXT PRIMARY KEY,
  asset_name TEXT NOT NULL,
  purchase_price REAL,
  purchase_date INTEGER NOT NULL,
  is_pinned INTEGER DEFAULT 0,
  category TEXT DEFAULT 'physical',
  tags TEXT DEFAULT '[]',
  created_at INTEGER NOT NULL,
  status INTEGER DEFAULT 0,
  expected_lifespan_days INTEGER,
  expire_date INTEGER,
  sold_price REAL,
  sold_date INTEGER,
  avatar_path TEXT,
  avatar_bg_color INTEGER,
  avatar_text TEXT,
  avatar_icon_code_point INTEGER,
  exclude_from_total INTEGER DEFAULT 0,
  exclude_from_daily INTEGER DEFAULT 0,
  ownership_type TEXT DEFAULT 'buyout',
  renewals TEXT DEFAULT '[]'
);
```

### check_sessions 表

```sql
CREATE TABLE check_sessions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  status INTEGER DEFAULT 0
);
```

### check_items 表

```sql
CREATE TABLE check_items (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  asset_id TEXT NOT NULL,
  asset_snapshot TEXT NOT NULL,
  confirmed_at INTEGER,
  FOREIGN KEY (session_id) REFERENCES check_sessions(id) ON DELETE CASCADE
);
```

### 字段配合逻辑

| 字段组合 | 用途 |
|----------|------|
| `status` + `soldDate` | 退役/卖出时冻结时间，计算实际使用天数 |
| `status` + `soldPrice` | 卖出时回血抵扣成本 |
| `expectedLifespanDays` + `purchaseDate` | 计算剩余天数与寿命进度 |
| `avatarPath` / `avatarIconCodePoint` / `avatarText` | 头像三级渲染优先级 |
| `excludeFromTotal` / `excludeFromDaily` | 统计过滤标记 |

### importAssetsWithUpsert 性能优化

批量查询 + 内存判断 + batch commit，避免逐条 SELECT：

```dart
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

## 核心功能实现

### 智能日均算法

```dart
double get dailyCost {
  double cost = purchasePrice ?? 0;
  if (status == 2 && soldPrice != null) {
    cost = (purchasePrice ?? 0) - soldPrice!;
  }

  final daysUsed = calculatedDays;

  // 服役中按预期寿命计算固定日均
  if (status == 0 && expectedLifespanDays != null && expectedLifespanDays! > 0) {
    if (daysUsed < expectedLifespanDays!) {
      return cost / expectedLifespanDays!;
    }
  }

  return cost / daysUsed;
}
```

### 订阅续费

| 所有权类型 | 计算公式 |
|------------|----------|
| `buyout` | 总成本 / 使用天数 |
| `subscription` | 总续费金额 / 总订阅天数 |

续费顺沿：当续费日期仍在上一次订阅期限内，新期限从原到期日开始。

```dart
DateTime newExpireDate = renewalDate.isBefore(lastExpireDate)
    ? lastExpireDate.add(Duration(days: renewalDays))
    : renewalDate.add(Duration(days: renewalDays));
```

### 时长显示格式

五种模式，通过 `TimeFormatter` 实现：

| 模式 | 格式 | 示例 |
|------|------|------|
| 自动计算 | 年月日拆分 | `1年3月15天` |
| 自动合并 | 统一换算为年 | `1.3年` |
| 年 | 强制年 | `1.5年` |
| 月 | 强制月 | `15.5月` |
| 日 | 强制天 | `450天` |

```dart
class TimeFormatter {
  static String formatDuration(int days, TimeDisplayMode mode) {
    switch (mode) {
      case TimeDisplayMode.auto:
        return _formatAuto(days);
      case TimeDisplayMode.autoMerge:
        return '${(days / 365.25).toStringAsFixed(1)}年';
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
}
```

用户偏好通过 `shared_preferences` 持久化：

```dart
await prefs.setString('time_display_mode', mode.name);
```

### 复合头像引擎 (SmartAssetAvatar)

四级渲染优先级，逐级降级：

| 优先级 | 条件 | 渲染 |
|--------|------|------|
| 1 | `avatarPath != null` 且文件存在 | 本地图片 |
| 2 | `avatarIconCodePoint != null` | Material 图标 |
| 3 | `avatarText != null` | 自定义文字 |
| 4 | 以上皆无 | 资产名称首字 |

```dart
class SmartAssetAvatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (asset.avatarPath != null && asset.avatarPath!.isNotEmpty) {
      final file = File(asset.avatarPath!);
      if (file.existsSync()) {
        return ClipOval(child: Image.file(file, fit: BoxFit.cover));
      }
    }

    if (asset.avatarIconCodePoint != null) {
      return CircleAvatar(
        backgroundColor: Color(asset.avatarBgColor ?? 0xFF6C5CE7),
        child: Icon(IconData(asset.avatarIconCodePoint!, fontFamily: 'MaterialIcons')),
      );
    }

    final displayText = asset.avatarText?.isNotEmpty == true
        ? asset.avatarText![0]
        : asset.assetName[0];

    return CircleAvatar(
      backgroundColor: Color(asset.avatarBgColor ?? 0xFF6C5CE7),
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(displayText)),
    );
  }
}
```

### 调色板定制

`flutter_colorpicker` 配置：屏蔽 Alpha、强制 HEX 输入、12 色预设矩阵。

```dart
ColorPicker(
  pickerColor: currentColor,
  onColorChanged: (color) => setState(() => currentColor = color),
  enableAlpha: false,
  hexInputBar: true,
  colorPickerType: ColorPickerType.custom,
  labelTypes: const [ColorLabelType.hex],
)
```

12 色预设：

```dart
const presetColors = [
  Color(0xFF6C5CE7), Color(0xFF00B894), Color(0xFF0984E3),
  Color(0xFFE17055), Color(0xFFFD79A8), Color(0xFFFDCB6E),
  Color(0xFF2D3436), Color(0xFFB2BEC3), Color(0xFF00CEC9),
  Color(0xFFE84393), Color(0xFFFF7675), Color(0xFF74B9FF),
];
```

### 悬浮岛导航

iOS 风格毛玻璃底部导航栏：

```dart
Scaffold(
  extendBody: true,
  body: IndexedStack(index: _selectedIndex, children: [...]),
  bottomNavigationBar: ClipRRect(
    borderRadius: BorderRadius.circular(30),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.65),
          border: Border.all(color: Colors.white.withOpacity(0.4), width: 1),
        ),
      ),
    ),
  ),
)
```

### 扫码引擎

`mobile_scanner` + 防抖 + 相册解析：

```dart
MobileScanner(
  onDetect: _debounce((barcode) {
    _handleBarcode(barcode);
  }, duration: Duration(milliseconds: 1500)),
)
```

### 云端同步

- Provider: Supabase
- 数据备份与恢复（手动触发双向同步）
- 密码重置：Edge Function + Resend 邮件服务（6 位验证码）
- 不做登录拦截，同步功能在设置 → 数据管理中

---

## 踩坑清单

### Release 打包 — ProGuard

`image_cropper`（UCrop）依赖了未使用的 `okhttp3`，R8 混淆报错。

`android/app/proguard-rules.pro`：

```proguard
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn java.nio.file.**
-keep class com.yalantis.ucrop** { *; }
```

打包命令：

```bash
flutter build apk --release --no-tree-shake-icons
```

> ⚠️ `--no-tree-shake-icons` 必须加，防止 Material 图标被摇树优化移除。

### CSV 插件版本锁定

`csv` 严格锁定为 `5.0.2`，使用时必须保留 `const`：

```dart
const ListToCsvConverter().convert(rows);
const CsvToListConverter().convert(csvString);
```

### 图片处理流程

选择 → 1:1 裁剪 → 保存到应用文档目录 → 数据库存路径：

```dart
final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
final CroppedFile? cropped = await _cropper.cropImage(
  sourcePath: picked.path,
  aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
);
final Directory appDir = await getApplicationDocumentsDirectory();
final String filePath = '${appDir.path}/assets/avatars/${Uuid().v4()}.jpg';
await File(cropped.path).copy(filePath);
```

### 自定义 APK 文件名

使用 `build_and_rename.sh`：

```bash
./build_and_rename.sh
```

输出：`cecilenn.dailyprice_v8a.apk`、`cecilenn.dailyprice_v7a.apk`、`cecilenn.dailyprice_x64.apk`

---

## 构建与发布

```bash
# Android
flutter build apk --release --no-tree-shake-icons

# iOS（需要 macOS + Xcode）
flutter build ios --release

# 使用自定义脚本（推荐）
./build_and_rename.sh
```

---

## 测试

```bash
flutter test
```

---

## 核心依赖

```yaml
dependencies:
  sqflite: ^2.3.0
  provider: ^6.1.2
  shared_preferences: ^2.3.3
  image_picker: ^1.0.0
  image_cropper: ^8.0.0
  mobile_scanner: ^3.5.0
  flutter_colorpicker: ^1.0.3
  csv: 5.0.2            # 版本锁定
  http: ^1.0.0
  supabase_flutter: ^2.0.0
  file_picker: ^10.3.10
  share_plus: ^12.0.1
  fl_chart: ^0.69.0
  universal_html: ^2.2.4
```
