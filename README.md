# 🏷️ Daily Price - 资产折旧与日常价格追踪

> 一句话介绍：这是一个基于 **Flutter + sqflite** 的轻量级本地资产与日常价格追踪应用，帮助您记录资产折旧、计算日均成本，轻松管理您的每一份投资。

---

## 📢 V2.0 重大更新

**Daily Price V2.0 已发布！** 这是一次里程碑式的重构，带来全新的 UI 设计和更强大的功能：

### ✨ V2.0 核心亮点

| 特性 | 说明 |
|------|------|
| 🏝️ **悬浮岛导航** | iOS 风格毛玻璃特效底部导航栏，精致胶囊设计 |
| 📊 **全局统计卡片** | 首页顶部新增资产总览，一目了然 |
| 🔄 **三态资产管理** | 服役中 / 已退役 / 已卖出，更精细的状态管理 |
| 🧮 **智能日均算法** | 服役中资产按预期寿命计算固定日均，退役/卖出资产按实际天数计算 |
| 🖼️ **资产头像** | 支持为每个资产设置图片头像 |
| 🏷️ **自定义分栏** | 支持创建自定义分栏标签，灵活组织资产 |
| 📱 **详情页面** | 全新资产详情页，完整展示所有信息 |
| 🎨 **主题切换** | 支持极简留白、暗黑模式、复古护眼三种主题 |
| 💾 **状态持久化** | 分栏、排序等用户习惯自动保存 |

> 📖 **历史版本说明**：V1.0 采用 Isar 数据库，V2.0 已全面迁移至 SQLite（sqflite），获得更好的跨平台兼容性和长期维护性。

------- REPLACE


---

## 🛠️ 开发与测试指南

如果您准备参与本项目的开发，或者想在本地运行和测试代码，我们为您准备了详细的环境配置和测试流程。

👉 **请查阅：[开发与测试指南 (DEVELOPMENT.md)](./DEVELOPMENT.md)**

---

## 🛠️ 技术栈

### 核心框架

| 类别 | 技术/插件 | 版本 | 用途 |
|------|-----------|------|------|
| 框架 | Flutter | ^3.11.0 | 跨平台 UI 框架 |
| 数据库 | **sqflite** | 最新版 | 标准 SQLite 本地关系型数据库 |
| 状态管理 | Provider | ^6.1.2 | 应用状态管理 |
| 本地存储 | shared_preferences | ^2.3.3 | 用户偏好设置持久化 |
| 日期处理 | intl | ^0.19.0 | 日期格式化与解析 |
| 文件操作 | path_provider | ^2.1.5 | 获取系统文件路径 |
| CSV 处理 | csv | 5.0.2 | 数据导入导出 |
| UUID 生成 | uuid | ^4.5.3 | 唯一标识符生成 |
| 文件选择 | file_picker | ^10.3.10 | 跨平台文件选择 |
| 分享功能 | share_plus | ^12.0.1 | 系统分享能力 |

### V2.0 新增依赖

| 类别 | 技术/插件 | 版本 | 用途 |
|------|-----------|------|------|
| 图片选择 | image_picker | ^1.0.0+ | 资产头像图片选择 |
| 图片裁剪 | image_cropper | ^8.0.0+ | 头像裁剪功能 |
| Web 支持 | universal_html | ^2.0.0+ | Web 端 CSV 导出支持 |

> ⚠️ **依赖版本锁定**：`csv` 插件版本严格锁定为 `5.0.2`，使用相关方法时必须保留 `const ListToCsvConverter()` 和 `const CsvToListConverter()`。


---

## 📂 项目结构 (V2.0)

```
lib/
├── main.dart                    # 应用入口
├── models/
│   └── asset.dart               # 🏷️ 核心资产数据模型 (V2.0 新增状态字段)
├── providers/
│   └── app_provider.dart        # 全局状态管理 (V2.0 新增主题支持)
├── screens/
│   ├── main_tab_screen.dart     # 🏝️ V2.0 新增：主标签页（悬浮岛导航）
│   ├── home_screen.dart         # 🏠 首页：双列网格卡片 + 全局统计
│   ├── asset_detail_screen.dart # 📱 V2.0 新增：资产详情页
│   ├── add_edit_asset_screen.dart # ➕ V2.0 新增：添加/编辑资产页
│   ├── analysis_screen.dart     # 📊 V2.0 新增：分析页（开发中）
│   ├── login_screen.dart        # 🔐 登录页面（预留）
│   └── settings_screen.dart     # ⚙️ 设置页面（V2.0 扩展主题/分栏/导入导出）
├── services/
│   └── local_db_service.dart    # 💾 本地数据库服务层
├── utils/
│   └── image_utils.dart         # 🖼️ V2.0 新增：图片处理工具
└── widgets/
    └── asset_form_dialog.dart   # 📝 V2.0 新增：资产表单对话框

```

> **✨ 架构亮点**：UI 与业务逻辑已解耦！
> - `screens/` 层仅负责页面渲染和用户交互
> - `services/` 层封装所有数据库操作，对外暴露清晰的 API
> - `models/` 层定义数据结构和业务计算方法
> - `providers/` 层管理全局应用状态

### V2.0 架构改进

| 层级 | 改进内容 |
|------|----------|
| **UI 层** | 新增悬浮岛导航栏（`MainTabScreen`），使用 `BackdropFilter` 实现 iOS 毛玻璃效果 |
| **数据层** | 资产模型新增 `status`、`avatarPath`、`excludeFromTotal`、`excludeFromDaily` 字段 |
| **持久化** | 用户习惯（分栏选择、排序方式）使用 `SharedPreferences` 自动保存 |
| **导航** | 采用 `IndexedStack` 保持各标签页状态，实现流畅切换 |


---

## 📊 核心数据模型 (Asset) - V2.0

`Asset` 是本应用的核心数据实体，用于记录个人资产的完整生命周期。

### 字段详解

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `id` | `String` | UUID v4 字符串，作为 SQLite 主键，用于与远端服务器（如 PocketBase）进行映射同步 |
| `assetName` | `String` | **资产名称**（必填） |
| `purchasePrice` | `double?` | **购入价格**（可选，V2.0 改为可空） |
| `expectedLifespanDays` | `int?` | **预计使用天数**（可选，V2.0 改为可空） |
| `purchaseDate` | `int` | **购买日期时间戳**（毫秒，V2.0 统一使用 int 存储） |
| `isPinned` | `int` | 是否置顶（0 或 1，V2.0 改为 int 类型） |
| `status` | `int` | **资产状态**（V2.0 新增：0=服役中, 1=已退役, 2=已卖出） |
| `soldPrice` | `double?` | 卖出价格（V2.0 支持卖出回血计算） |
| `soldDate` | `int?` | 卖出/退役日期时间戳（毫秒，V2.0 支持时间冻结） |
| `category` | `String` | 资产分类：`physical`(实体) / `virtual`(虚拟) / `subscription`(订阅)，默认为 `physical` |
| `expireDate` | `int?` | 过期日期时间戳（毫秒，主要用于订阅类资产） |
| `tags` | `List<String>` | 自定义标签列表（SQLite 中存储为 JSON 字符串） |
| `createdAt` | `int` | 创建时间时间戳（毫秒） |
| `avatarPath` | `String?` | **资产头像本地路径**（V2.0 新增） |
| `excludeFromTotal` | `int` | **不计入总资产**（0 或 1，V2.0 新增） |
| `excludeFromDaily` | `int` | **不计入日均消费**（0 或 1，V2.0 新增） |

> ⚠️ **V2.0 字段变更说明**：
> - 移除了 `isSold` 布尔字段，改用 `status` 三态枚举
> - 日期字段统一改为 `int` 类型存储 Unix 时间戳（毫秒）
> - `isPinned` 改为 `int` 类型（0 或 1）便于 SQLite 存储

### V2.0 三态资产管理

V2.0 引入更精细的状态管理，替代原有的 `isSold` 布尔字段：

| 状态值 | 状态名 | 说明 | 日均计算方式 |
|--------|--------|------|--------------|
| `0` | 服役中 | 资产正在使用中 | 按预期寿命计算固定日均 |
| `1` | 已退役 | 资产停止使用但未卖出 | 时间冻结在退役日期，按实际使用天数计算 |
| `2` | 已卖出 | 资产已出售 | 成本 = 购入价 - 卖出价，时间冻结在卖出日期 |

### 计算属性

| 属性 | 返回值 | 说明 |
|------|--------|------|
| `dailyCost` | `double` | **日均成本**（V2.0 智能算法，见下方详细说明） |
| `calculatedDays` | `int` | 实际/冻结天数（服役中计算到今天，退役/卖出冻结在 soldDate） |
| `remainingDays` | `int?` | 剩余可用天数（需设置 expectedLifespanDays） |
| `usedDays` | `int` | 已使用天数（从购买日期到今天） |
| `actualUsedDays` | `int` | 实际使用天数（若已卖出/退役则计算到 soldDate） |
| `isExpired` | `bool` | 是否已过期（剩余天数为 0） |
| `isActive` | `bool` | 是否服役中（status == 0） |
| `isSoldOrRetired` | `bool` | 是否已卖出或退役（status == 1 或 2） |

### 🧮 V2.0 智能日均算法

V2.0 的日均成本计算采用智能算法，根据资产状态动态调整：

```dart
/// 计算日均价格（核心业务逻辑）
/// - 如果已卖出且有回血价，成本 = 买入价 - 卖出价
/// - 服役中且未超期：按预期寿命计算固定日均
/// - 其他情况：按实际/冻结天数计算
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

**算法说明**：
1. **服役中资产**：在预期寿命内，按 `购入价 / 预计使用天数` 计算固定日均
2. **超期服役资产**：超出预期寿命后，自动切换为按实际天数计算
3. **已卖出资产**：成本 = `购入价 - 卖出价`，时间冻结在卖出日期
4. **已退役资产**：成本 = `购入价`，时间冻结在退役日期

### 便捷方法

- `Asset.create(...)` - 工厂方法，自动设置创建时间和 UUID
- `Asset.fromMap(Map)` - 从 Map 创建对象（用于 SQLite 查询结果）
- `toMap()` - 转换为 Map（用于 SQLite 插入/更新）
- `copyWith(...)` - 复制并修改字段
- `parseExpectedDays(String)` - 解析自然语言时长（支持 "1 年 6 个月"、"100 天" 等）
- `parseCustomDate(String)` - 解析多种日期格式（支持 "2026 年 2 月 2 日"、"2026-01-01" 等）
- `formatDays(int)` - 格式化天数显示（自动转换为 "X 年 X 月 X 天"）


---

## 🔌 核心内部接口 (LocalDbService)

`LocalDbService` 采用**单例模式**管理 SQLite 数据库实例，为 UI 层提供简洁的数据操作 API。

### 数据库架构

数据库文件名：`daily_price.db`

**assets 表结构（V2.0）**：

```sql
CREATE TABLE assets(
  id TEXT PRIMARY KEY,                    -- UUID v4 字符串
  asset_name TEXT NOT NULL,               -- 资产名称
  purchase_price REAL,                    -- 购入价格（V2.0 改为可空）
  expected_lifespan_days INTEGER,         -- 预计使用天数（V2.0 改为可空）
  purchase_date INTEGER NOT NULL,         -- 购买日期时间戳（毫秒）
  is_pinned INTEGER DEFAULT 0,            -- 是否置顶（0 或 1）
  status INTEGER DEFAULT 0,               -- V2.0 新增：状态（0=服役中, 1=已退役, 2=已卖出）
  sold_price REAL,                        -- 卖出价格
  sold_date INTEGER,                      -- 卖出/退役日期时间戳（毫秒）
  category TEXT DEFAULT 'physical',       -- 资产分类
  expire_date INTEGER,                    -- 过期日期时间戳（毫秒）
  tags TEXT DEFAULT '[]',                 -- 标签列表（JSON 字符串）
  created_at INTEGER NOT NULL,            -- 创建时间时间戳（毫秒）
  avatar_path TEXT,                       -- V2.0 新增：头像本地路径
  exclude_from_total INTEGER DEFAULT 0,   -- V2.0 新增：不计入总资产（0 或 1）
  exclude_from_daily INTEGER DEFAULT 0    -- V2.0 新增：不计入日均消费（0 或 1）
)
```

> ⚠️ **V2.0 数据库变更**：
> - 移除了 `isSold` 字段，改用 `status` 字段
> - 所有字段名改为下划线命名（`asset_name` 而非 `assetName`）
> - 日期字段统一使用 Unix 时间戳（毫秒）存储
> - 新增 `status`、`avatar_path`、`exclude_from_total`、`exclude_from_daily` 字段


### 初始化与生命周期

```dart
// 在应用启动时初始化
await LocalDbService().init();

// 关闭数据库（应用退出时）
await LocalDbService().close();
```

### 核心方法列表

#### 📥 查询类方法

| 方法 | 签名 | 返回值 | 说明 |
|------|------|--------|------|
| `getAllAssets` | `Future<List<Asset>> getAllAssets()` | `List<Asset>` | 获取所有资产 |
| `getAssetByUuid` | `Future<Asset?> getAssetByUuid(String uuid)` | `Asset?` | 通过 UUID 查找单个资产 |
| `getAssetByStringId` | `Future<Asset?> getAssetByStringId(String stringId)` | `Asset?` | 通过字符串 ID 查找资产（UI 层调用） |
| `getAssetsByUuids` | `Future<Map<String, Asset>> getAssetsByUuids(List<String> uuids)` | `Map<String, Asset>` | 批量查找，返回 UUID-Asset 映射 |
| `getAssetCount` | `Future<int> getAssetCount()` | `int` | 获取资产总数 |

#### 💾 保存/更新类方法

| 方法 | 签名 | 返回值 | 说明 |
|------|------|--------|------|
| `saveAsset` | `Future<void> saveAsset(Asset asset)` | `void` | 保存或更新单个资产。自动为缺少 UUID 的资产生成 UUID v4 |
| `saveAllAssets` | `Future<void> saveAllAssets(List<Asset> assets)` | `void` | 批量保存资产（直接插入，不查重） |
| `importAssetsWithUpsert` | `Future<(int inserted, int updated)> importAssetsWithUpsert(List<Asset> parsedAssets)` | `(int, int)` | **智能导入**：按 UUID 查重，存在则更新，不存在则插入。返回插入数和更新数 |

#### 🗑️ 删除类方法

| 方法 | 签名 | 返回值 | 说明 |
|------|------|--------|------|
| `deleteAsset` | `Future<void> deleteAsset(String id)` | `void` | 通过 UUID 主键删除资产 |
| `deleteAssetByUuid` | `Future<void> deleteAssetByUuid(String uuid)` | `void` | 通过 UUID 删除资产 |
| `deleteAllAssets` | `Future<void> deleteAllAssets()` | `void` | 清空所有资产（危险操作） |

### 使用示例

```dart
// 获取单例实例
final db = LocalDbService();

// 保存新资产
final newAsset = Asset.create(
  assetName: 'MacBook Pro',
  purchasePrice: 14999.0,
  expectedLifespanDays: 1460, // 4 年
  purchaseDate: DateTime.now(),
  category: 'physical',
  tags: ['电子产品', '生产力工具'],
);
await db.saveAsset(newAsset);

// 查询所有资产
final assets = await db.getAllAssets();

// 导入数据（智能合并）
final (inserted, updated) = await db.importAssetsWithUpsert(parsedAssets);
print('导入完成：插入 $inserted 条，更新 $updated 条');
```

---

## 🚀 本地运行指南

### 环境要求

- Flutter SDK: ^3.11.0
- Dart SDK: ^3.11.0
- 支持平台：iOS / Android / macOS / Windows / Linux / Web

### 快速开始

```bash
# 1. 克隆代码仓库
git clone https://github.com/cecilenn/Daily-Price.git
cd daily_price

# 2. 安装依赖
flutter pub get

# 3. 运行应用
flutter run
```

> ⚠️ **注意**：迁移到 sqflite 后，**不再需要运行 `build_runner`**！

### 开发调试

```bash
# 运行应用
flutter run

# 启用详细日志
flutter run --verbose

# 运行测试
flutter test
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

## 🗺️ 数据库迁移说明

### 从 Isar 迁移到 sqflite

本项目已从 Isar 数据库迁移到标准 SQLite（通过 sqflite 插件），主要变更如下：

| 项目 | 迁移前 (Isar) | 迁移后 (sqflite) |
|------|---------------|------------------|
| 数据库类型 | NoSQL 文档型 | 关系型 SQL |
| 主键类型 | `isarId` (int 自增) | `id` (UUID v4 String) |
| 代码生成 | 需要 `build_runner` | 不需要 |
| 存储格式 | 二进制 + 索引 | 标准 SQLite 表 |
| 查询方式 | Isar 查询 API | SQL 查询 |

**兼容性改进**：
- ✅ 更好的跨平台支持和长期维护性
- ✅ 标准 SQL 便于数据导出和分析
- ✅ 移除代码生成步骤，开发流程更简单
- ✅ 使用 UUID 作为主键，便于与云端同步

**数据结构变更**：
- `tags` 字段：从 `List<String>` 改为 JSON 字符串存储
- `renewalHistory` 字段：从 `List<dynamic>` 改为 JSON 字符串存储
- 所有日期字段：存储为 Unix 时间戳（毫秒）

---

## 🗺 版本演进与路线图 (Roadmap)

### V2.0 已实现功能 ✅

| 功能模块 | 特性说明 |
|----------|----------|
| 🏝️ **悬浮岛导航** | iOS 风格毛玻璃特效底部导航栏，胶囊设计 |
| 📊 **全局统计卡片** | 首页顶部实时展示总资产、日均消费、资产状态统计 |
| 🔄 **三态资产管理** | 服役中 / 已退役 / 已卖出，支持时间冻结和卖出回血计算 |
| 🧮 **智能日均算法** | 根据资产状态自动选择计算方式，服役中按预期寿命，退役/卖出按实际天数 |
| 🖼️ **资产头像** | 支持为每个资产设置图片头像，自动生成文字头像 |
| 🏷️ **自定义分栏** | 创建自定义分栏标签，灵活组织资产，支持级联删除 |
| 📱 **资产详情页** | 全新详情页面，完整展示资产生命周期信息 |
| ➕ **添加/编辑页面** | 全屏表单页面，支持自然语言输入 |
| 🎨 **主题系统** | 极简留白、暗黑模式、复古护眼三种主题 |
| 💾 **状态持久化** | 分栏选择、排序方式、默认启动分栏自动保存 |
| 📤 **CSV 导入/导出** | 支持跨平台 CSV 数据备份与恢复 |
| 📋 **置顶功能** | 资产置顶显示，排序优先级最高 |

### 🚧 V2.x 开发中

- [ ] 数据备份与恢复（云端）
- [ ] 图表可视化（折旧曲线、资产分布饼图）
- [ ] 批量编辑资产
- [ ] 资产搜索功能

### 📅 V3.0 计划接入

- [ ] **PocketBase 云端同步** - 部署在 NAS 上的 PocketBase 作为云端冷备份后端，实现多端数据同步
- [ ] 用户认证系统
- [ ] 多设备同步
- [ ] 数据加密存储
- [ ] 资产提醒通知
- [ ] 数据导出 PDF 报告

### 📜 历史版本

| 版本 | 时间 | 主要特性 |
|------|------|----------|
| V1.0 | 2024 | 基于 Isar 数据库的基础资产追踪功能 |
| V2.0 | 2025 | 全面重构，迁移至 SQLite，新增悬浮岛 UI、三态管理、智能算法 |


---

## 📖 V2.0 用户指南

### 🏝️ 悬浮岛导航

V2.0 采用全新的悬浮岛风格底部导航栏：

- **资产页**：浏览和管理您的所有资产
- **分析页**（开发中）：查看资产统计和图表分析
- **设置页**：配置主题、分栏、导入导出数据
- **悬浮添加按钮**：点击右下角蓝色悬浮按钮快速添加资产

### 📊 全局统计卡片

首页顶部显示实时资产统计：

| 统计项 | 说明 |
|--------|------|
| 💰 总资产 | 所有未勾选"不计入总资产"的资产购入价总和 |
| 📈 日均消费 | 所有未勾选"不计入日均"的资产日均成本总和 |
| ✅ 服役中 | 状态为"服役中"的资产数量 |
| ⏸️ 已退役 | 状态为"已退役"的资产数量 |
| 💵 已卖出 | 状态为"已卖出"的资产数量 |

### 🔄 三态资产管理

V2.0 支持三种资产状态：

**1. 服役中（默认）**
- 资产正在使用中
- 日均成本按预期寿命计算固定值
- 时间持续流逝到今天

**2. 已退役**
- 资产停止使用但未卖出（如闲置、损坏）
- 时间冻结在退役日期
- 按实际使用天数计算日均

**3. 已卖出**
- 资产已出售
- 成本 = 购入价 - 卖出价（回血抵扣）
- 时间冻结在卖出日期

### 🏷️ 自定义分栏

V2.0 支持创建自定义分栏：

1. 进入**设置页** → **自定义分栏**
2. 点击"添加自定义分栏"
3. 输入分栏名称（如"工作"、"闲置"）
4. 在资产编辑页面为该资产添加分栏标签
5. 返回首页，点击左上角文件夹图标选择自定义分栏

> 💡 **提示**：删除自定义分栏时，该标签会从所有资产中自动移除（级联清洗）。

### 💾 状态持久化

V2.0 自动保存以下用户习惯：

- 当前分栏选择
- 排序方式（按添加日期/名称/购买日期/价格）
- 排序方向（升序/降序）
- 默认启动分栏

这些设置会保存在本地，下次打开应用时自动恢复。

### 📤 CSV 导入/导出

**导出数据**：
1. 进入**设置页** → **导出数据存档**
2. 选择保存位置
3. CSV 文件包含所有资产数据

**导入数据**：
1. 进入**设置页** → **导入本地存档**
2. 选择之前导出的 CSV 文件
3. 系统会自动合并数据（相同 UUID 的资产会更新而非重复添加）

> ⚠️ **注意**：V2.0 支持 `status` 字段（0/1/2），V1.0 导出的 `is_sold` 字段会被自动映射转换。

---

## 🤝 协作指南


### 分支管理

- `main`: 稳定版本分支
- `develop`: 开发分支
- `feature/*`: 功能分支
- `bugfix/*`: 修复分支

### 提交规范

```
feat: 添加新功能
fix: 修复 bug
docs: 文档更新
refactor: 代码重构
chore: 杂项更新
```

### 代码审查

1. 所有 PR 需经过至少 1 人 review
2. 确保 CI 检查通过
3. 保持代码风格一致性

---

## 📄 开源协议

本项目采用 MIT 协议开源，欢迎 Fork 和贡献代码！

---

<div align="center">

**Made with ❤️ using Flutter & sqflite**

</div>