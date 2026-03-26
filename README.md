# 🏷️ Daily Price - 资产折旧与日常价格追踪

> 一句话介绍：基于 Flutter + SQLite 的轻量级本地资产追踪应用，帮助您记录资产折旧、计算日均成本，轻松管理每一份投资。

---

## 核心特性 (Core Features)

| 特性 | 说明 |
|------|------|
| 📱 **扫码分享与实体资产录入** | 支持扫码快速录入实体资产信息，一键分享资产详情 |
| 🎨 **复合型智能头像引擎** | `SmartAssetAvatar` 组件实现「照片 → 矢量图标 → 智能缩放文字」的绝对渲染优先级；支持相机拍照/相册选图（1:1 裁剪）、12 色 HEX 专业调色板、Material 图标自定义 |
| 🧮 **动态日均成本计算** | 智能算法根据资产状态自动切换计算方式：服役中按预期寿命计算固定日均，退役/卖出按实际冻结天数计算，支持卖出回血抵扣 |
| 🔄 **三态资产管理** | 服役中 / 已退役 / 已卖出，支持时间冻结与状态转换 |
| 🏝️ **悬浮岛导航** | iOS 风格毛玻璃特效底部导航栏，精致胶囊设计 |
| 📊 **全局统计卡片** | 首页顶部实时展示总资产、日均消费、资产状态分布 |
| 🔍 **资产检查功能** | 支持创建检查任务，扫码盘点资产，确认资产状态，导出检查报告 |
| 🏷️ **自定义分栏** | 创建自定义分栏标签，灵活组织资产，支持级联删除 |
| 📁 **自定义分类** | 替代硬编码分类，用户可自由创建分类（家庭/公司/...） |
| 🔄 **订阅续费追踪** | 订阅资产支持多次续费记录，自动计算到期日和日均成本 |
| 💾 **状态持久化** | 分栏选择、排序方式等用户习惯自动保存至 `shared_preferences` |
| � **CSV 导入/导出** | 跨平台数据备份与恢复，支持 `upsert` 智能合并 |
| 🎨 **主题切换** | 极简留白、暗黑模式、复古护眼三种主题 |
| �📊 **共享状态架构** | AssetProvider 统一管理资产数据，所有页面实时同步 |
| ☁️ **云端同步** | 支持 Supabase 云端备份与恢复，显示云端存档日期时间 |
| 🔐 **密码重置** | App 内置密码重置功能，支持验证码验证和新密码设置 |


---

## 技术栈

| 类别 | 技术/插件 | 版本 | 用途 |
|------|-----------|------|------|
| 项目版本 | Daily Price | 1.4.0 | 应用版本号 |
| 框架 | Flutter | ^3.11.0 | 跨平台 UI 框架 |
| 数据库 | sqflite | 最新版 | SQLite 本地关系型数据库 |
| 状态管理 | Provider | ^6.1.2 | 全局状态管理（AppProvider 管主题偏好，AssetProvider 管资产数据） |
| 本地存储 | shared_preferences | ^2.3.3 | 用户偏好设置持久化 |
| 日期处理 | intl | ^0.19.0 | 日期格式化与解析 |
| 文件操作 | path_provider | ^2.1.5 | 获取系统文件路径 |
| CSV 处理 | csv | **5.0.2** | 数据导入导出（版本锁定） |
| UUID 生成 | uuid | ^4.5.3 | 唯一标识符生成 |
| 文件选择 | file_picker | ^10.3.10 | 跨平台文件选择 |
| 分享功能 | share_plus | ^12.0.1 | 系统分享能力 |
| 图片选择 | image_picker | ^1.0.0+ | 资产头像图片选择 |
| 图片裁剪 | image_cropper | ^8.0.0+ | 头像裁剪功能 |
| 扫码 | mobile_scanner | ^3.5.0+ | 扫码识别与相册解析 |
| 颜色选择 | flutter_colorpicker | ^1.0.3 | 专业级 HEX 调色板 |
| 分析图表 | fl_chart | ^0.69.0 | 数据可视化图表 |

> ⚠️ **依赖版本锁定**：`csv` 插件版本严格锁定为 `5.0.2`，使用相关方法时必须保留 `const ListToCsvConverter()` 和 `const CsvToListConverter()`。

---

## 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/
│   ├── asset.dart               # 核心资产数据模型
│   └── check_session.dart       # 检查任务与检查项模型
├── providers/
│   ├── app_provider.dart        # 全局状态管理（主题偏好）
│   ├── asset_provider.dart      # 资产数据共享状态管理
│   └── check_provider.dart      # 检查任务状态管理
├── screens/
│   ├── main_tab_screen.dart     # 主标签页（悬浮岛导航）
│   ├── home_screen.dart         # 首页：资产列表 + 全局统计
│   ├── asset_detail_screen.dart # 资产详情页
│   ├── add_edit_asset_screen.dart # 添加/编辑资产页
│   ├── analysis_screen.dart     # 统计分析页
│   ├── scanner_screen.dart      # 扫码页面
│   ├── login_screen.dart        # 登录页面（预留）
│   ├── settings_screen.dart     # 设置页面
│   ├── category_settings_screen.dart # 自定义分类设置
│   ├── tag_settings_screen.dart # 标签设置页面
│   ├── preference_settings_screen.dart # 偏好设置页面
│   ├── data_settings_screen.dart # 数据设置页面
│   ├── theme_settings_screen.dart # 主题设置页面
│   ├── function_hub_screen.dart # 功能入口页
│   ├── check_list_screen.dart   # 检查任务列表页
│   ├── check_detail_screen.dart # 检查详情页
│   └── check_scan_screen.dart   # 扫码检查页
├── services/
│   ├── local_db_service.dart    # SQLite 数据库服务层
│   └── asset_filter_sorter.dart # 过滤与排序工具类
├── utils/
│   ├── image_utils.dart         # 图片处理工具
│   ├── stats_calculator.dart    # 统计计算工具类
│   ├── time_formatter.dart      # 时长格式化工具
│   └── pref_keys.dart           # 偏好设置键名常量
└── widgets/
    ├── asset_form_dialog.dart   # 资产表单对话框
    ├── smart_asset_avatar.dart  # 智能头像组件
    └── avatar_editor_sheet.dart # 头像编辑器底部面板
```

---

## 核心数据模型 (Asset)

### 字段清单

| 字段 | 类型 | 说明 |
|------|------|------|
| `id` | `String` | UUID v4 主键，用于与远端服务器映射同步 |
| `assetName` | `String` | 资产名称（必填） |
| `purchasePrice` | `double?` | 购入价格（可选） |
| `purchaseDate` | `int` | 购买日期时间戳（毫秒） |
| `isPinned` | `int` | 是否置顶（0 或 1） |
| `category` | `String` | 资产分类：`physical` / `virtual` / `subscription` |
| `tags` | `List<String>` | 自定义标签列表（JSON 字符串存储） |
| `createdAt` | `int` | 创建时间时间戳（毫秒） |
| `status` | `int` | 资产状态：0=服役中, 1=已退役, 2=已卖出 |
| `expectedLifespanDays` | `int?` | 预计使用天数（可选） |
| `expireDate` | `int?` | 过期日期时间戳（毫秒，主要用于订阅类） |
| `soldPrice` | `double?` | 卖出价格 |
| `soldDate` | `int?` | 卖出/退役日期时间戳（毫秒） |
| `avatarPath` | `String?` | 头像本地图片路径 |
| `avatarBgColor` | `int?` | 头像背景色（ARGB 整数，如 `0xFF6C5CE7`） |
| `avatarText` | `String?` | 头像自定义文字（单字自动缩放防溢出） |
| `avatarIconCodePoint` | `int?` | Material 图标 Unicode 码点 |
| `excludeFromTotal` | `int` | 不计入总资产（0 或 1，默认 0） |
| `excludeFromDaily` | `int` | 不计入日均消费（0 或 1，默认 0） |
| `ownershipType` | `String` | 所有权类型：`buyout`（买断）/ `subscription`（订阅） |
| `renewals` | `List<RenewalRecord>` | 续费记录列表（JSON 字符串存储） |

### 智能日均算法

```dart
/// 计算日均价格
/// - 已卖出且有回血价：成本 = 买入价 - 卖出价
/// - 服役中且未超期：按预期寿命计算固定日均
/// - 其他情况：按实际/冻结天数计算
double get dailyCost {
  double cost = purchasePrice ?? 0;
  if (status == 2 && soldPrice != null) {
    cost = (purchasePrice ?? 0) - soldPrice!;
  }

  final daysUsed = calculatedDays;

  // 服役中资产按预期寿命计算固定日均
  if (status == 0 && expectedLifespanDays != null && expectedLifespanDays! > 0) {
    if (daysUsed < expectedLifespanDays!) {
      return cost / expectedLifespanDays!;
    }
  }

  return cost / daysUsed;
}
```

---

## 本地运行指南

### 环境要求

- Flutter SDK: ^3.11.0
- Dart SDK: ^3.11.0
- 支持平台：iOS / Android / macOS / Windows / Linux / Web

### 快速开始

```bash
# 克隆代码仓库
git clone https://github.com/cecilenn/Daily-Price.git
cd daily_price

# 安装依赖
flutter pub get

# 运行应用
flutter run
```

### 构建发布版本

```bash
# Android APK
flutter build apk --release

# iOS（需要 macOS + Xcode）
flutter build ios --release

# macOS
flutter build macos --release

# Windows
flutter build windows --release
```

---

## 开发与测试指南

详细的环境配置、架构文档与踩坑记录，请参阅：

👉 **[DEVELOPMENT.md](./DEVELOPMENT.md)**

---

## 开源协议

本项目采用 MIT 协议开源。

---

<div align="center">

**Made with ❤️ using Flutter & sqflite**

</div>