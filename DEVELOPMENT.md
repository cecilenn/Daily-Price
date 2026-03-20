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

### 第三步：生成 Isar 数据库代码（重要！）

本项目使用 Isar 作为本地数据库，需要先生成代码：

```bash
# 运行代码生成器
flutter pub run build_runner build --delete-conflicting-outputs
```

> ⚠️ **注意**：
> - 这个命令会生成 `lib/models/asset.g.dart` 文件，**每次修改 `asset.dart` 后都需要重新运行**
> - 如果出现错误，可以尝试先清理再重新生成：
>   ```bash
>   flutter pub run build_runner clean
>   flutter pub run build_runner build --delete-conflicting-outputs
>   ```

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
   - 进入手机设置 → 关于手机 → 连续点击"版本号"7次
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
      expect(Asset.parseExpectedDays('1年'), 365);
      expect(Asset.parseExpectedDays('6个月'), 180);
      expect(Asset.parseExpectedDays('1年6个月'), 365 + 180);
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
| **资产计算** | 添加一个价格为 3650 元、100 天的资产 | 日均成本显示为 36.5 元 |
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
   - 预计使用天数：1460（或输入"4年"）
   - 点击保存

3. **验证计算结果**：
   - 日均成本应显示：约 10.27 元/天
   - 剩余价值应根据使用天数动态计算

### 调试指南

#### 使用 VS Code 调试（推荐）

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

#### 使用 Dart DevTools

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

#### 常用调试技巧

**1. 打印日志调试**

```dart
// 在代码中使用 print 输出调试信息
print('资产名称: ${asset.assetName}');
print('日均成本: ${asset.dailyCost}');
```

在 VS Code 的 DEBUG CONSOLE 中查看输出。

**2. 热重载调试**

```bash
# 在运行应用时，按以下键触发
r  # 热重载（保留状态，快速刷新）
R  # 热重启（重新启动应用）
q  # 退出应用
```

**3. 检查 Isar 数据库内容**

项目在开发模式已启用 Isar Inspector：

```dart
// lib/services/local_db_service.dart 中
_isar = await Isar.open(
  [AssetSchema],
  directory: dir.path,
  inspector: true,  // ← 开发环境启用检查器
);
```

启动应用后，打开浏览器访问 `http://localhost:22191` 可以查看数据库内容。

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

### 问题 2：`build_runner` 生成失败

**症状**：报错找不到 `asset.g.dart` 或生成失败

**解决方案**：

```bash
# 清理缓存后重新生成
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### 问题 3：找不到设备

**症状**：`flutter run` 提示 "No devices found"

**解决方案**：

```bash
# 检查已连接设备
flutter devices

# 如果列表为空：
# 1. Android: 确保模拟器已启动或真机已连接并开启 USB 调试
# 2. iOS: 确保已打开 iOS 模拟器（Mac  only）
```

### 问题 4：应用启动崩溃

**症状**：应用启动后立即闪退

**排查步骤**：

```bash
# 查看详细错误日志
flutter run --verbose

# 清理构建缓存
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

### 问题 5：测试运行失败

**症状**：`flutter test` 报错

**解决方案**：

```bash
# 确保项目已正确初始化
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs

# 运行测试（单文件）
flutter test test/widget_test.dart
```

---

## 📚 进阶资源

### 官方文档

- [Flutter 官方文档](https://docs.flutter.dev/)
- [Flutter 中文文档](https://flutter.cn/)
- [Isar 数据库文档](https://isar.dev/)
- [Dart 语言指南](https://dart.dev/guides)

### 推荐 VS Code 扩展

- **Flutter** - Flutter 官方扩展
- **Dart** - Dart 语言支持
- **Awesome Flutter Snippets** - 代码片段
- **Flutter Tree** - 查看 Widget 树
- **Error Lens** - 实时错误提示

---

<div align="center">

**祝开发愉快！如有问题，欢迎在项目中提交 Issue 讨论 🎉**

</div>

---

## V2.0 架构重构与踩坑记录

> 本文档记录 Daily Price V2.0 的重大架构演进，涵盖数据库迁移、UI 架构升级和打包防坑指南。

---

### 📦 数据库层（SQLite）重构

#### Asset 数据模型升级

V2.0 将数据库从 Isar 迁移至 SQLite（`sqflite`），实现更轻量、可控的本地数据管理。

**核心字段扩展：**

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | String | UUID 主键 |
| `status` | int | **状态机核心**：0=服役中，1=已退役，2=已卖出 |
| `expectedLifespanDays` | int? | 预计寿命天数（可选） |
| `expireDate` | int? | 到期日时间戳（可选） |
| `soldPrice` | double? | 卖出价格（回血价） |
| `soldDate` | int? | 卖出/退役冻结日时间戳 |
| `avatarPath` | String? | 头像本地路径（见图片引擎章节） |
| `excludeFromTotal` | int | 不计入总资产标记（0/1） |
| `excludeFromDaily` | int | 不计入日均计算标记（0/1） |

#### 状态机设计（status）

```dart
/// 状态枚举映射
0: 服役中（Active）- 资产正在使用中，时间持续流逝
1: 已退役（Retired）- 资产退役但保留，时间冻结在 soldDate
2: 已卖出（Sold）- 资产已出售回血，成本按买入价-卖出价计算
```

**状态转换规则：**
- `0 → 1`：资产退役（手动标记或到期自动触发）
- `0 → 2`：资产出售（需填写 soldPrice 和 soldDate）
- `1/2 → 0`：重新服役（恢复资产活跃状态）

#### calculatedDays 与 dailyCost 动态计算

**calculatedDays - 实际/冻结天数计算：**

```dart
int get calculatedDays {
  final start = DateTime.fromMillisecondsSinceEpoch(purchaseDate);
  DateTime end;

  // 状态 1(退役) 或 2(卖出) 时，时间永久冻结在 soldDate
  if ((status == 1 || status == 2) && soldDate != null) {
    end = DateTime.fromMillisecondsSinceEpoch(soldDate!);
  } else {
    // 状态 0(服役中)，时间持续流逝到今天
    end = DateTime.now();
  }

  final days = end.difference(start).inDays;
  return days > 0 ? days : 1; // 兜底：最小使用天数为 1
}
```

**dailyCost - 日均成本核心业务逻辑：**

```dart
double get dailyCost {
  // 基础成本：如果已卖出且有回血价，则成本 = 买入价 - 卖出价
  double cost = purchasePrice ?? 0;
  if (status == 2 && soldPrice != null) {
    cost = (purchasePrice ?? 0) - soldPrice!;
  }

  final daysUsed = calculatedDays;

  // 核心逻辑：如果是服役中 (status == 0)，且设定了预计使用天数
  if (status == 0 && expectedLifespanDays != null && expectedLifespanDays! > 0) {
    if (daysUsed < expectedLifespanDays!) {
      // 未超出预期寿命：按预期寿命计算固定日均
      return cost / expectedLifespanDays!;
    }
  }

  // 其他情况：已退役、已卖出、未设预期寿命、或服役已超期，均按实际/冻结天数计算
  return cost / daysUsed;
}
```

**设计要点：**
- 服役中资产支持「固定日均」模式（按预期寿命均摊）
- 已卖出资产支持「回血抵扣」模式（买入价-卖出价）
- 退役/卖出资产的时间冻结，确保历史数据稳定

---

### 🎨 UI 路由架构升级

#### MainTabScreen - 全局根路由

V2.0 引入 `MainTabScreen` 作为应用全局根路由，替代原单页面设计。

**架构层级：**

```
MaterialApp
└── MainTabScreen (StatefulWidget)
    ├── IndexedStack
    │   ├── HomeScreen (首页/资产列表)
    │   ├── AnalysisScreen (统计分析)
    │   └── SettingsScreen (设置)
    └── FloatingDock (悬浮岛底部导航)
```

**核心代码：**

```dart
class MainTabScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // 关键：内容滚到底部栏下方形成悬浮穿透
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _buildFloatingDock(),
    );
  }
}
```

#### 悬浮岛（Floating Dock）设计

V2.0 采用 iOS 风格悬浮岛导航，实现毛玻璃穿透效果。

**技术实现：**

```dart
Scaffold(
  extendBody: true, // 让 body 延伸到 bottomNavigationBar 下方
  ...
)
```

**毛玻璃效果核心代码：**

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(30),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0), // 高斯模糊
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.65), // 半透明底色
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.4), // 边框高光
          width: 1,
        ),
      ),
      ...
    ),
  ),
)
```

**视觉特性：**
- `extendBody: true`：页面内容可滚动至底部导航栏下方
- `BackdropFilter`：实现 iOS 风格毛玻璃模糊
- 胶囊形状 + 阴影：悬浮于内容之上的视觉层级

---

### 🖼️ 本地图片引擎

V2.0 引入 `image_cropper` + `path_provider` 实现本地离线图片存储。

#### 依赖配置

```yaml
# pubspec.yaml
dependencies:
  image_picker: ^1.0.0
  image_cropper: ^5.0.0
  path_provider: ^2.1.0
  uuid: ^4.0.0
```

#### 核心流程

**选择 → 裁剪 → 保存到本地：**

```dart
class ImageUtils {
  static Future<String?> pickAndCropImage() async {
    // 1. 从相册选择图片
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
    );

    // 2. 裁剪为 1:1 正方形
    final CroppedFile? croppedFile = await _cropper.cropImage(
      sourcePath: pickedFile.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(toolbarTitle: '裁剪头像', ...),
        IOSUiSettings(title: '裁剪头像', ...),
      ],
    );

    // 3. 保存到应用文档目录
    return await _saveImageToAppDirectory(croppedFile);
  }

  static Future<String> _saveImageToAppDirectory(CroppedFile croppedFile) async {
    final Directory appDir = await getApplicationDocumentsDirectory();
    final String imageDirPath = '${appDir.path}/assets/avatars';
    
    // 创建目录（如果不存在）
    await Directory(imageDirPath).create(recursive: true);
    
    // UUID 生成唯一文件名
    final String fileName = '${Uuid().v4()}.jpg';
    final String filePath = '$imageDirPath/$fileName';
    
    // 复制文件
    return await File(croppedFile.path).copy(filePath);
  }
}
```

**存储路径结构：**

```
应用文档目录/
└── assets/
    └── avatars/
        ├── a1b2c3d4-e5f6-7890-abcd-ef1234567890.jpg
        └── ... (其他头像文件)
```

**数据库记录：**
- 数据库仅存储 `avatarPath`（本地绝对路径）
- 图片文件离线存储，不占用数据库空间
- 支持图片删除时同步清理本地文件

---

### 🚨 Release 打包防坑指南（重要！）

#### 问题现象

在打 Release 包时，由于 `image_cropper`（UCrop）内部依赖了未使用的 `okhttp3`，导致 R8 混淆器报错：

```
ERROR: R8: Missing class okhttp3.OkHttpClient
ERROR: R8: Missing class okhttp3.Request
...
```

#### 原因分析

`image_cropper` 的 Android 底层实现 UCrop 库在源码中引用了 `okhttp3`，但实际并未真正使用。R8 混淆器在编译时发现这些未解析的依赖，导致构建失败。

#### 解决方案

**1. 添加 ProGuard 忽略规则**

在 `android/app/proguard-rules.pro` 中添加：

```proguard
# 忽略 UCrop 依赖的 okhttp 缺失警告
-dontwarn okhttp3.**
-dontwarn okio.**
-dontwarn java.nio.file.**

# 保护 UCrop 核心类不被过度混淆
-keep class com.yalantis.ucrop** { *; }
-keep class com.yalantis.ucrop.** { *; }
```

**2. 启用自定义 ProGuard 规则**

在 `android/app/build.gradle.kts` 中配置：

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
        
        // 启用自定义混淆规则（关键！）
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}
```

#### 验证步骤

```bash
# 清理构建缓存
flutter clean

# 重新安装依赖
flutter pub get

# 打 Release 包测试
flutter build apk --release

# 如果成功，会输出：
# ✓ Built build/app/outputs/flutter-apk/app-release.apk
```

#### 避坑总结

| 问题 | 原因 | 解决 |
|------|------|------|
| R8 报错找不到 okhttp3 | UCrop 源码引用未实际使用 | `-dontwarn okhttp3.**` |
| R8 报错找不到 okio | UCrop 依赖传递 | `-dontwarn okio.**` |
| UCrop 类被混淆导致崩溃 | ProGuard 过度优化 | `-keep class com.yalantis.ucrop**` |

> ⚠️ **重要提示**：每次修改 `proguard-rules.pro` 后，必须执行 `flutter clean` 并重新构建，否则缓存可能导致规则未生效。

---

### 🔄 数据库迁移指南（Isar → SQLite）

如需从 V1.0（Isar）迁移数据到 V2.0（SQLite）：

```dart
// 导出 V1.0 Isar 数据为 CSV
// 在 V2.0 中使用 CSV 导入功能恢复数据
// 路径：设置 → 导入/导出 → 选择 CSV 文件
```

**CSV 格式要求：**

```csv
asset_name,purchase_price,purchase_date,category,tags,expected_lifespan_days
MacBook Pro,14999,1704067200000,electronics,laptop;apple,1460
```

---

### 📚 V2.0 相关依赖版本

```yaml
# 数据库
dependencies:
  sqflite: ^2.3.0
  path: ^1.8.3

# 图片处理
  image_picker: ^1.0.0
  image_cropper: ^5.0.0
  path_provider: ^2.1.0

# 状态管理
  provider: ^6.0.5
```

---

<div align="center">

**V2.0 架构重构完成于 2025 年 Q1**

如有架构相关问题，欢迎提交 Issue 讨论 🔧

</div>
