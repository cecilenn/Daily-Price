# 🛠️ DEVELOPMENT.md - Daily Price 开发者指南

> 本文档旨在帮助后续协同开发者快速理解项目架构、上手开发。

---

## 📁 目录结构

```
lib/
├── main.dart                 # 应用入口
├── models/
│   └── asset.dart            # 核心资产模型
├── providers/
│   └── app_provider.dart     # 全局状态管理
├── screens/
│   ├── main_tab_screen.dart  # 主容器（悬浮导航栏）
│   ├── home_screen.dart      # 首页（资产网格列表）
│   ├── add_edit_asset_screen.dart  # 添加/编辑资产
│   ├── asset_detail_screen.dart    # 资产详情页
│   ├── analysis_screen.dart  # 分析统计页
│   └── settings_screen.dart  # 设置页
├── services/
│   └── local_db_service.dart # SQLite 数据库服务
├── utils/
│   └── image_utils.dart      # 图片选择/裁剪工具
└── widgets/
    └── asset_form_dialog.dart # 资产表单弹窗组件
```

### 职责说明

| 目录 | 职责 |
|------|------|
| `models/` | 纯数据模型，包含字段定义、计算属性、序列化方法 |
| `screens/` | 页面级 Widget，处理业务逻辑和 UI 布局 |
| `services/` | 数据层服务，封装数据库操作、文件 I/O 等 |
| `providers/` | 全局状态管理（Provider 模式） |
| `utils/` | 工具类，如图片处理、日期格式化等 |
| `widgets/` | 可复用的 UI 组件 |

---

## 🗄️ 数据库演进：V1 → V2

### 为什么从 Isar 迁移到 SQLite

**历史背景**：
- **V1 时代**：使用 Isar 作为本地数据库，享受其链式查询和类型安全的优点
- **V2 决策**：迁移至 `sqflite`（SQLite）

**迁移原因**：
1. **兼容性更广**：SQLite 是 Flutter 生态中支持最广泛、最稳定的本地数据库方案
2. **稳定性更高**：Isar 在大型数据量下偶发性能问题，SQLite 经过数十年生产验证
3. **多表联查潜力**：SQLite 原生支持复杂 SQL 查询，为未来功能扩展预留空间
4. **依赖精简**：移除 Isar 的复杂编译依赖，简化构建流程

### 当前 assets 表结构

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `id` | TEXT PRIMARY KEY | UUID v4 主键 |
| `asset_name` | TEXT NOT NULL | 资产名称 |
| `purchase_price` | REAL | 购入价格（可为空） |
| `purchase_date` | INTEGER NOT NULL | 购买日期（毫秒时间戳） |
| `is_pinned` | INTEGER DEFAULT 0 | 是否置顶（0/1） |
| `category` | TEXT DEFAULT 'physical' | 资产分类 |
| `tags` | TEXT DEFAULT '[]' | 标签 JSON 数组 |
| `created_at` | INTEGER NOT NULL | 创建时间（毫秒时间戳） |
| `status` | INTEGER DEFAULT 0 | 状态（0服役中/1已退役/2已卖出） |
| `expected_lifespan_days` | INTEGER | 预计使用天数 |
| `expire_date` | INTEGER | 到期日（毫秒时间戳） |
| `sold_price` | REAL | 卖出价格 |
| `sold_date` | INTEGER | 卖出日期（毫秒时间戳） |
| `avatar_path` | TEXT | 头像本地路径 |
| `exclude_from_total` | INTEGER DEFAULT 0 | 不计入总资产 |
| `exclude_from_daily` | INTEGER DEFAULT 0 | 不计入日均 |

### 核心字段计算逻辑

#### `status` 状态机

```dart
// 0 = 服役中（Active）
// 1 = 已退役（Retired）
// 2 = 已卖出（Sold）

bool get isActive => status == 0;
bool get isSoldOrRetired => status == 1 || status == 2;
```

#### `calculatedDays` 实际/冻结天数

```dart
int get calculatedDays {
  final start = DateTime.fromMillisecondsSinceEpoch(purchaseDate);
  DateTime end;

  if ((status == 1 || status == 2) && soldDate != null) {
    // 已退役/卖出：时间冻结在 soldDate
    end = DateTime.fromMillisecondsSinceEpoch(soldDate!);
  } else {
    // 服役中：时间持续流逝到今天
    end = DateTime.now();
  }

  final days = end.difference(start).inDays;
  return days > 0 ? days : 1; // 兜底：最小为 1 天
}
```

#### `dailyCost` 日均成本（核心业务逻辑）

```dart
double get dailyCost {
  // 基础成本：如果已卖出且有回血价，则成本 = 买入价 - 卖出价
  double cost = purchasePrice ?? 0;
  if (status == 2 && soldPrice != null) {
    cost = (purchasePrice ?? 0) - soldPrice!;
  }

  final daysUsed = calculatedDays;

  // 服役中 + 设定了预期寿命 → 按预期寿命计算固定日均
  if (status == 0 &&
      expectedLifespanDays != null &&
      expectedLifespanDays! > 0) {
    if (daysUsed < expectedLifespanDays!) {
      return cost / expectedLifespanDays!;
    }
  }

  // 其他情况：按实际/冻结天数计算
  return cost / daysUsed;
}
```

---

## 📦 第三方依赖说明

### 核心依赖

| 包名 | 版本 | 用途 |
|------|------|------|
| `sqflite` | ^2.3.0 | SQLite 数据库引擎 |
| `path` | ^1.9.0 | 路径拼接工具 |
| `uuid` | ^4.5.3 | UUID v4 生成器 |
| `shared_preferences` | ^2.3.3 | 本地键值对存储 |
| `provider` | ^6.1.2 | 状态管理 |
| `intl` | ^0.19.0 | 日期格式化 |
| `csv` | 5.0.2 | CSV 导入导出（**版本锁定**） |
| `image_picker` | ^1.2.1 | 系统相册选择图片 |
| `image_cropper` | ^11.0.0 | 图片裁剪（UCrop） |
| `path_provider` | ^2.1.5 | 获取应用文档目录 |
| `file_picker` | ^10.3.10 | 文件选择器 |
| `share_plus` | ^12.0.1 | 系统分享功能 |

### 依赖锁定说明

**⚠️ csv 包版本必须锁定为 `5.0.2`**

原因：项目代码中使用了 `const ListToCsvConverter()` 和 `const CsvToListConverter()` 构造方式，这是该版本特有的 API 签名。升级可能导致编译错误。

```yaml
csv: 5.0.2  # 注意：没有 ^ 符号，锁定精确版本
```

---

## 🐛 打包与构建踩坑记录

### Android Release 打包：R8 混淆问题

**问题现象**：
构建 Release APK 时，UCrop（image_cropper 底层）的 okhttp 依赖触发 R8 混淆警告，导致构建失败。

**错误日志示例**：
```
ERROR: R8: Missing class: okhttp3.**
ERROR: R8: Missing class: okio.**
```

**解决方案**：

在 `android/app/proguard-rules.pro` 中添加以下规则：

```proguard
# 忽略 UCrop 依赖的 okhttp 缺失警告
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn java.nio.file.**

# 保护 UCrop 核心类不被过度混淆
-keep class com.yalantis.ucrop** { *; }
-keep class com.yalantis.ucrop.** { *; }
```

同时确保 `android/app/build.gradle.kts` 中引用了混淆规则文件：

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"  // 关键：引用自定义规则
        )
    }
}
```

### 图片裁剪 UCrop 主题配置

UCrop Activity 需要在 `AndroidManifest.xml` 中声明主题，避免白屏：

```xml
<activity
    android:name="com.yalantis.ucrop.UCropActivity"
    android:screenOrientation="portrait"
    android:theme="@style/Theme.AppCompat.Light.NoActionBar" />
```

---

## 🧩 关键代码模式

### Upsert 操作（插入或更新）

```dart
Future<void> saveAsset(Asset asset) async {
  await db.insert(
    'assets',
    asset.toMap(),
    conflictAlgorithm: ConflictAlgorithm.replace, // 存在则替换
  );
}
```

### 批量导入（查重逻辑）

```dart
Future<(int inserted, int updated)> importAssetsWithUpsert(
  List<Asset> parsedAssets,
) async {
  int insertedCount = 0;
  int updatedCount = 0;

  for (var importedAsset in parsedAssets) {
    // 检查是否已存在
    final existing = await db.query(
      'assets',
      where: 'id = ?',
      whereArgs: [importedAsset.id],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      // 更新现有记录
      batch.update('assets', importedAsset.toMap(), ...);
      updatedCount++;
    } else {
      // 插入新记录
      batch.insert('assets', importedAsset.toMap());
      insertedCount++;
    }
  }
  await batch.commit(noResult: true);

  return (insertedCount, updatedCount);
}
```

### SharedPreferences 持久化用户习惯

```dart
// 保存
final prefs = await SharedPreferences.getInstance();
await prefs.setString('home_sort_by', 'purchase_date');
await prefs.setBool('home_sort_ascending', false);

// 读取
final sortBy = prefs.getString('home_sort_by') ?? 'created_at';
final ascending = prefs.getBool('home_sort_ascending') ?? false;
```

---

## 🎨 UI 架构约定

### 导航栏布局

V2.0 采用**底部悬浮岛导航**，约定如下：
- **左侧区域**：筛选按钮、刷新按钮
- **中间/右侧区域**：排序按钮、添加按钮、设置按钮
- **禁止使用 Drawer 侧边栏**

参考实现：`lib/screens/main_tab_screen.dart`

### 排序优先级

V2.0 排序规则（硬性约定）：
1. **第一优先级**：`isPinned`（置顶始终排第一）
2. **第二优先级**：用户选择的排序字段（名称/价格/日期等）
3. **第三优先级**：升序/降序方向

### 网格卡片设计

- 双列网格，固定比例 `childAspectRatio: 1.2`
- 卡片内信息层次：状态指示器 > 头像 > 名称 > 日均成本
- 已卖出资产显示「已卖出」印章（半透明覆盖）

---

## 🚀 开发工作流

```bash
# 1. 获取依赖
flutter pub get

# 2. 运行调试（热重载）
flutter run

# 3. 代码检查
flutter analyze

# 4. 格式化代码
flutter format lib/

# 5. 构建 Release APK
flutter build apk --release

# 6. 构建 AppBundle（Google Play）
flutter build appbundle --release
```

---

## 📋 代码规范

### 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 对人可见 | 中文 | 注释、文档、UI 文案 |
| 对机器可见 | 英文 | 变量、函数、类名 |

### Null Safety

```dart
// ✅ 正确：先判空再使用
if (soldDate != null) {
  return DateTime.fromMillisecondsSinceEpoch(soldDate!);
}

// ✅ 正确：使用 ?? 提供默认值
final price = purchasePrice ?? 0.0;

// ❌ 错误：直接解包可能为 null 的值
return DateTime.fromMillisecondsSinceEpoch(soldDate); // 可能崩溃
```

### 字符串判空

```dart
// ✅ 正确顺序：先判 null，再判 empty
if (value != null && value.isNotEmpty) { ... }

// ❌ 错误：可能 NullPointerException
if (value.isNotEmpty) { ... }
```

---

## 🔮 未来扩展建议

1. **数据同步**：接入云同步（Firebase / Supabase），支持多端同步
2. **分类管理**：支持自定义分类图标和颜色
3. **图表统计**：在 Analysis 页增加折线图、饼图
4. **标签云**：支持标签搜索和智能推荐
5. **数据导出增强**：支持 Excel、PDF 导出

---

> 📝 **文档维护**：本文档应与代码同步更新。任何涉及新增/删除文件、模块重组、数据库迁移的操作，完成后请更新本文档。
