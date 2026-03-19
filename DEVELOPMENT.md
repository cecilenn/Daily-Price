# 🛠️ 开发与测试指南

> 欢迎来到 Daily Price 项目！这份指南将手把手带你完成环境配置、项目运行和测试验证，即使你之前没有 Flutter 开发经验也能轻松上手 😊

---

## 📋 环境准备

### 必需软件清单

在开始前，请确保你的电脑已安装以下软件：

| 软件 | 推荐版本 | 用途 | 下载链接 |
|------|----------|------|----------|
| **Flutter SDK** | 3.11.0 或更高 | 跨平台开发框架 | [官网下载](https://docs.flutter.dev/get-started/install) |
| **Dart SDK** | 3.11.0 或更高 | Dart 语言运行环境 | 随 Flutter 一起安装 |
| **Android Studio** | 最新版 | Android 模拟器 + SDK | [官网下载](https://developer.android.com/studio) |
| **Xcode** | 最新版 | iOS/macOS 开发（仅限 Mac） | App Store 下载 |
| **Git** | 任意版本 | 代码版本管理 | [官网下载](https://git-scm.com/downloads) |
| **VS Code** | 最新版（推荐） | 代码编辑器 | [官网下载](https://code.visualstudio.com/) |

### 验证安装

打开终端，运行以下命令检查环境：

```bash
# 检查 Flutter 是否安装成功
flutter --version

# 检查 Flutter 环境是否完整（这个命令会列出所有环境配置）
flutter doctor
```

> 💡 **提示**：运行 `flutter doctor` 后，如果有红色 ❌ 标记的项目，请按照提示进行修复。
> 常见的需要修复项包括：Android SDK、Xcode command line tools、Android 模拟器等。

---

## 🚀 项目初始化

### 第一步：克隆代码仓库

```bash
# 进入你想要存放项目的文件夹（比如 Documents 或 Projects）
cd ~/Documents

# 克隆代码仓库
git clone https://github.com/cecilenn/Daily-Price.git

# 进入项目目录
cd Daily-Price
```

### 第二步：安装依赖包

```bash
# 安装 Flutter 项目依赖（这个过程可能需要几分钟，请耐心等待）
flutter pub get
```

> 💡 **小贴士**：如果你在中国大陆，可能会遇到网络问题。可以配置 Flutter 使用国内镜像：
> ```bash
> # 临时使用清华镜像
> export PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub"
> export FLUTTER_STORAGE_BASE_URL="https://mirrors.tuna.tsinghua.edu.cn/flutter"
> flutter pub get
> ```

### 第三步：验证项目结构

```bash
# 查看项目文件结构
ls -la

# 检查关键文件是否存在
ls lib/models/ lib/services/
```

> ⚠️ **注意**：迁移到 sqflite 后，**不再需要运行 `build_runner`**！项目启动更加简单。

---

## 💻 本地运行

### 方式一：在模拟器中运行（推荐新手）

#### 启动 Android 模拟器

**方法 A：通过 Android Studio 启动（推荐）**

1. 打开 Android Studio
2. 点击右上角 📱 设备管理器（Device Manager）
3. 点击 ➕ 创建新设备（如果没有现有设备）
4. 选择一个设备型号（推荐 Pixel 6 或 Pixel 7）
5. 下载并选择一个系统镜像（推荐 Android 13 或更高）
6. 点击 ▶️ 启动模拟器

**方法 B：通过命令行启动**

```bash
# 列出所有可用的模拟器
flutter emulators

# 启动指定模拟器（将 <emulator_id> 替换为实际的 ID）
flutter emulators --launch <emulator_id>

# 例如：
flutter emulators --launch Pixel_6_API_33
```

#### 启动 iOS 模拟器（仅限 Mac）

```bash
# 打开 iOS 模拟器
open -a Simulator
```

### 方式二：在真机上运行

#### Android 真机

1. **开启开发者模式**：
   - 进入手机设置 → 关于手机 → 连续点击"版本号"7 次
   - 返回设置 → 开发者选项 → 开启"USB 调试"

2. **连接电脑**：
   - 用 USB 线连接手机和电脑
   - 手机上允许 USB 调试授权

3. **验证连接**：
   ```bash
   flutter devices
   ```
   应该能看到你的设备出现在列表中

#### iOS 真机（仅限 Mac）

1. 用数据线连接 iPhone
2. 在 Xcode 中配置签名（首次需要）
3. 运行 `flutter devices` 查看设备

### 运行应用

确保模拟器已启动或真机已连接后，运行：

```bash
# 启动应用（自动检测可用设备）
flutter run
```

> 🎉 **成功标志**：你应该能看到应用界面出现在模拟器/手机上！

#### 常用运行选项

```bash
# 指定设备运行（将 <device_id> 替换为实际 ID）
flutter run -d <device_id>

# 热重载模式（开发时推荐，保存代码后自动刷新）
flutter run --hot

# 调试模式（启用 Dart DevTools）
flutter run --debug

# 发布模式（测试性能时使用）
flutter run --release
```

---

## 🧪 测试指南

### 自动化测试

本项目使用 Flutter 自带的测试框架。测试文件位于 `test/` 目录下。

#### 运行所有测试

```bash
# 运行所有测试
flutter test

# 运行测试并显示详细信息
flutter test --verbose

# 运行特定测试文件
flutter test test/widget_test.dart
```

#### 当前测试说明

目前项目包含以下测试：

| 测试文件 | 测试内容 | 验证点 |
|----------|----------|--------|
| `test/widget_test.dart` | 首页组件测试 | 验证"个人资产管理"标题、"添加资产"表单、"资产列表"是否正常显示 |

**测试结果解读**：
- ✅ **All tests passed!** - 所有测试通过
- ❌ **Test failed** - 有测试失败，请查看错误信息

#### 添加新测试（扩展）

如果你想为项目添加更多测试，可以在 `test/` 目录下创建新文件：

```dart
// test/asset_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:daily_price/models/asset.dart';

void main() {
  group('Asset Model Tests', () {
    test('should calculate daily cost correctly', () {
      final asset = Asset.create(
        assetName: '测试资产',
        purchasePrice: 1000,
        expectedLifespanDays: 100,
        purchaseDate: DateTime.now(),
      );
      
      expect(asset.dailyCost, 10.0);  // 1000 / 100 = 10
    });
    
    test('should parse expected days from natural language', () {
      expect(Asset.parseExpectedDays('1 年'), 365);
      expect(Asset.parseExpectedDays('6 个月'), 180);
      expect(Asset.parseExpectedDays('1 年 6 个月'), 365 + 180);
    });
  });
}
```

### 手动测试流程

如果没有自动化测试或想验证具体功能，可以按照以下流程进行手动测试：

#### 核心功能验证清单

| 功能模块 | 测试步骤 | 预期结果 |
|----------|----------|----------|
| **添加资产** | 点击"添加" → 填写名称、价格、天数 → 点击保存 | 资产出现在列表中 |
| **资产计算** | 添加一个价格为 3650 元、100 天的资产 | 日均成本显示为 36.5 元/天 |
| **标签筛选** | 为资产添加标签 → 点击标签进行筛选 | 只显示对应标签的资产 |
| **置顶功能** | 点击资产卡片上的置顶按钮 | 资产移动到列表顶部 |
| **编辑资产** | 点击资产卡片 → 修改信息 → 保存 | 信息更新成功 |
| **删除资产** | 长按资产卡片 → 确认删除 | 资产从列表消失 |
| **CSV 导入** | 设置 → 导入 → 选择 CSV 文件 | 数据成功导入 |
| **CSV 导出** | 设置 → 导出 → 保存文件 | CSV 文件生成成功 |

#### 手动测试操作路径

1. **启动应用后**，你应该看到主界面包含：
   - 顶部：筛选、刷新、排序、添加、设置按钮
   - 中间：资产列表（初始为空或显示示例数据）
   - 底部：添加资产的表单（或点击"添加"按钮弹出）

2. **添加测试数据**：
   - 资产名称："MacBook Pro"
   - 购入价格：14999
   - 预计使用天数：1460（或输入"4 年"）
   - 点击保存

3. **验证计算结果**：
   - 日均成本应显示：约 10.27 元/天
   - 剩余价值应根据使用天数动态计算

---

## 🔧 调试指南

### 使用 VS Code 调试（推荐）

**配置步骤：**

1. 打开 VS Code，确保安装了 **Flutter** 和 **Dart** 扩展
2. 按 `F5` 或点击左侧调试图标 → "运行和调试"
3. 选择 "Flutter" 配置
4. 在代码中点击行号左侧添加断点（红点）
5. 应用会在断点处暂停，你可以查看变量、单步执行

**常用调试快捷键：**

| 快捷键 | 功能 |
|--------|------|
| `F5` | 启动调试 |
| `Shift + F5` | 停止调试 |
| `F9` | 切换断点 |
| `F10` | 单步跳过 |
| `F11` | 单步进入 |
| `Shift + F11` | 单步跳出 |

### 使用 Dart DevTools

```bash
# 在运行应用时启动 DevTools
flutter run --debug

# 或者在应用运行时，在另一个终端打开 DevTools
flutter pub global activate devtools
dart devtools
```

DevTools 提供以下功能：
- 🔍 **Widget Inspector** - 查看 UI 组件树
- 🐛 **Debugger** - 断点调试
- 📊 **Performance** - 性能分析
- 🧠 **Memory** - 内存监控
- 🌐 **Network** - 网络请求监控

### 常用调试技巧

**1. 打印日志调试**

```dart
// 在代码中使用 print 输出调试信息
print('资产名称：${asset.assetName}');
print('日均成本：${asset.dailyCost}');
```

在 VS Code 的 DEBUG CONSOLE 中查看输出。

**2. 热重载调试**

```bash
# 在运行应用时，按以下键触发
r  # 热重载（保留状态，快速刷新）
R  # 热重启（重新启动应用）
q  # 退出应用
```

**3. 检查 SQLite 数据库内容**

可以使用以下工具查看 SQLite 数据库：

```bash
# macOS/Linux: 使用 sqlite3 命令行
sqlite3 ~/Library/Application\ Support/com.example.dailyPrice/daily_price.db

# 查看表结构
.schema assets

# 查询数据
SELECT * FROM assets;
```

或者使用 GUI 工具：
- [DB Browser for SQLite](https://sqlitebrowser.org/)（免费开源）
- [TablePlus](https://tableplus.com/)（付费，有免费版）

---

## 🗄️ 数据库架构说明

### 数据库文件位置

不同平台的数据库文件存储位置：

| 平台 | 路径 |
|------|------|
| **Android** | `/data/data/<package_name>/databases/daily_price.db` |
| **iOS** | `~/Library/Application Support/<bundle_id>/daily_price.db` |
| **macOS** | `~/Library/Application Support/<bundle_id>/daily_price.db` |
| **Windows** | `C:\Users\<username>\AppData\Roaming\<bundle_id>\daily_price.db` |
| **Linux** | `~/.local/share/<bundle_id>/daily_price.db` |

### assets 表结构

```sql
CREATE TABLE assets(
  id TEXT PRIMARY KEY,              -- UUID v4 字符串
  userId TEXT,                      -- 用户 ID（预留）
  assetName TEXT NOT NULL,          -- 资产名称
  purchasePrice REAL NOT NULL,      -- 购入价格
  expectedLifespanDays INTEGER NOT NULL,  -- 预计使用天数
  purchaseDate INTEGER NOT NULL,    -- 购买日期（Unix 时间戳，毫秒）
  isPinned INTEGER DEFAULT 0,       -- 是否置顶（0 或 1）
  isSold INTEGER DEFAULT 0,         -- 是否已出售（0 或 1）
  soldPrice REAL,                   -- 出售价格
  soldDate INTEGER,                 -- 出售日期（Unix 时间戳，毫秒）
  category TEXT DEFAULT 'physical', -- 资产分类
  expireDate INTEGER,               -- 过期日期（Unix 时间戳，毫秒）
  renewalHistoryJson TEXT DEFAULT '[]',  -- 续费历史（JSON 字符串）
  tags TEXT DEFAULT '[]',           -- 标签列表（JSON 字符串）
  createdAt INTEGER NOT NULL        -- 创建时间（Unix 时间戳，毫秒）
);
```

### 索引（可选扩展）

如果未来需要优化查询性能，可以考虑添加以下索引：

```sql
-- 按创建时间排序查询优化
CREATE INDEX idx_assets_createdAt ON assets(createdAt);

-- 按分类查询优化
CREATE INDEX idx_assets_category ON assets(category);

-- 按置顶状态查询优化
CREATE INDEX idx_assets_isPinned ON assets(isPinned);
```

### 数据迁移

如果需要修改数据库结构，需要在 `local_db_service.dart` 的 `init()` 方法中处理版本迁移：

```dart
_db = await openDatabase(
  path,
  version: 2,  // 每次修改结构时递增版本号
  onCreate: (Database db, int version) async {
    // 创建新表
    await db.execute('CREATE TABLE assets(...)');
  },
  onUpgrade: (Database db, int oldVersion, int newVersion) async {
    // 执行迁移逻辑
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE assets ADD COLUMN newColumn TEXT');
    }
  },
);
```

---

## 🆘 常见问题排查

### 问题 1：`flutter pub get` 失败

**症状**：依赖安装失败，网络超时

**解决方案**：

```bash
# 配置国内镜像后重试
export PUB_HOSTED_URL="https://mirrors.tuna.tsinghua.edu.cn/dart-pub"
export FLUTTER_STORAGE_BASE_URL="https://mirrors.tuna.tsinghua.edu.cn/flutter"
flutter pub get
```

### 问题 2：找不到设备

**症状**：`flutter run` 提示 "No devices found"

**解决方案**：

```bash
# 检查已连接设备
flutter devices

# 如果列表为空：
# 1. Android: 确保模拟器已启动或真机已连接并开启 USB 调试
# 2. iOS: 确保已打开 iOS 模拟器（Mac only）
```

### 问题 3：应用启动崩溃

**症状**：应用启动后立即闪退

**排查步骤**：

```bash
# 查看详细错误日志
flutter run --verbose

# 清理构建缓存
flutter clean
flutter pub get
flutter run
```

### 问题 4：测试运行失败

**症状**：`flutter test` 报错

**解决方案**：

```bash
# 确保项目已正确初始化
flutter pub get

# 运行测试（单文件）
flutter test test/widget_test.dart
```

### 问题 5：数据库访问错误

**症状**：运行时提示数据库无法打开或表不存在

**解决方案**：

```bash
# 清除应用数据后重新运行
flutter run --uninstall

# 或者手动删除数据库文件（以 macOS 为例）
rm ~/Library/Application\ Support/<bundle_id>/daily_price.db
```

---

## 📚 进阶资源

### 官方文档

- [Flutter 官方文档](https://docs.flutter.dev/)
- [Flutter 中文文档](https://flutter.cn/)
- [sqflite 插件文档](https://pub.dev/packages/sqflite)
- [SQLite 官方文档](https://www.sqlite.org/docs.html)
- [Dart 语言指南](https://dart.dev/guides)

### 推荐 VS Code 扩展

- **Flutter** - Flutter 官方扩展
- **Dart** - Dart 语言支持
- **Awesome Flutter Snippets** - 代码片段
- **Flutter Tree** - 查看 Widget 树
- **Error Lens** - 实时错误提示
- **SQLite Viewer** - 在 VS Code 中查看 SQLite 数据库

### 数据库管理工具

- [DB Browser for SQLite](https://sqlitebrowser.org/) - 免费开源的 SQLite 浏览器
- [TablePlus](https://tableplus.com/) - 现代化数据库管理工具
- [DBeaver](https://dbeaver.io/) - 免费的多数据库管理工具

---

<div align="center">

**祝开发愉快！如有问题，欢迎在项目中提交 Issue 讨论 🎉**

</div>