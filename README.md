# 🏷️ Daily Price - 资产折旧与日常价格追踪

> 一句话介绍：这是一个基于 **Flutter + Isar** 的轻量级本地资产与日常价格追踪应用，帮助您记录资产折旧、计算日均成本，轻松管理您的每一份投资。

---

## 🛠️ 开发与测试指南

如果您准备参与本项目的开发，或者想在本地运行和测试代码，我们为您准备了详细的环境配置和测试流程。

👉 **请查阅：[开发与测试指南 (DEVELOPMENT.md)](./DEVELOPMENT.md)**

---

## 🛠 技术栈

| 类别 | 技术/插件 | 版本 | 用途 |
|------|-----------|------|------|
| 框架 | Flutter | ^3.11.0 | 跨平台 UI 框架 |
| 数据库 | Isar Database | ^3.1.0+1 | 高性能本地 NoSQL 数据库 |
| 状态管理 | Provider | ^6.1.2 | 应用状态管理 |
| 本地存储 | shared_preferences | ^2.3.3 | 用户偏好设置持久化 |
| 日期处理 | intl | ^0.19.0 | 日期格式化与解析 |
| 文件操作 | path_provider | ^2.1.5 | 获取系统文件路径 |
| CSV 处理 | csv | 5.0.2 | 数据导入导出 |
| UUID 生成 | uuid | ^4.5.3 | 唯一标识符生成 |
| 文件选择 | file_picker | ^10.3.10 | 跨平台文件选择 |
| 分享功能 | share_plus | ^12.0.1 | 系统分享能力 |

---

## 📂 项目结构

```
lib/
├── main.dart                    # 应用入口
├── models/
│   ├── asset.dart               # 🏷️ 核心资产数据模型
│   └── asset.g.dart             # Isar 自动生成的代码
├── providers/
│   └── app_provider.dart        # 全局状态管理
├── screens/
│   ├── home_screen.dart         # 🏠 首页：资产列表展示
│   ├── login_screen.dart        # 🔐 登录页面（预留）
│   └── settings_screen.dart     # ⚙️ 设置页面
├── services/
│   └── local_db_service.dart    # 💾 本地数据库服务层
├── utils/                       # 工具类目录（预留扩展）
└── widgets/                     # 可复用 UI 组件目录

```

> **✨ 架构亮点**：UI 与业务逻辑已解耦！
> - `screens/` 层仅负责页面渲染和用户交互
> - `services/` 层封装所有数据库操作，对外暴露清晰的 API
> - `models/` 层定义数据结构和业务计算方法
> - `providers/` 层管理全局应用状态

---

## 📊 核心数据模型 (Asset)

`Asset` 是本应用的核心数据实体，用于记录个人资产的完整生命周期。

### 字段详解

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `isarId` | `Id` (int) | Isar 本地自增主键（64位整数），数据库内部使用 |
| `id` | `String?` | UUID v4 字符串，用于与远端服务器（如 PocketBase）进行映射同步 |
| `userId` | `String?` | 用户 ID，预留用于多用户数据隔离 |
| `assetName` | `String` | **资产名称**（必填） |
| `purchasePrice` | `double` | **购入价格**（必填） |
| `expectedLifespanDays` | `int` | **预计使用天数**（必填），支持自然语言解析如"1年6个月" |
| `purchaseDate` | `DateTime` | **购买日期**（必填），支持多种格式解析 |
| `isPinned` | `bool` | 是否置顶，默认为 `false` |
| `isSold` | `bool` | 是否已出售，默认为 `false` |
| `soldPrice` | `double?` | 出售价格（可选） |
| `soldDate` | `DateTime?` | 出售日期（可选） |
| `category` | `String` | 资产分类：`physical`(实体) / `virtual`(虚拟) / `subscription`(订阅)，默认为 `physical` |
| `expireDate` | `DateTime?` | 过期日期（主要用于订阅类资产） |
| `renewalHistory` | `List<dynamic>` | 续费历史记录（JSON 存储） |
| `tags` | `List<String>` | 自定义标签列表，支持多标签筛选 |
| `createdAt` | `DateTime` | 创建时间 |

### 计算属性

| 属性 | 返回值 | 说明 |
|------|--------|------|
| `dailyCost` | `double` | 日均成本 = 购入价 / 预计使用天数 |
| `remainingDays` | `int` | 剩余可用天数 |
| `usedDays` | `int` | 已使用天数 |
| `actualUsedDays` | `int` | 实际使用天数（若已出售则计算到出售日期） |
| `remainingValue` | `double` | 剩余价值 = 日均成本 × 剩余天数 |
| `depreciatedValue` | `double` | 已折旧金额 = 日均成本 × 实际使用天数 |
| `isExpired` | `bool` | 是否已过期（剩余天数为0） |
| `actualDailyCost` | `double` | 实际日均花费（考虑出售盈亏） |
| `soldProfitOrLoss` | `double` | 出售盈亏金额 |

### 便捷方法

- `Asset.create(...)` - 工厂方法，自动设置创建时间和 UUID
- `copyWith(...)` - 复制并修改字段
- `toJson() / fromJson()` - 序列化与反序列化
- `parseExpectedDays(String)` - 解析自然语言时长（如"1年6个月"）
- `parseCustomDate(String)` - 解析多种日期格式

---

## 🔌 核心内部接口 (LocalDbService)

`LocalDbService` 采用**单例模式**管理 Isar 数据库实例，为 UI 层提供简洁的数据操作 API。

### 初始化与生命周期

```dart
// 在应用启动时初始化
await LocalDbService().init();

// 获取 Isar 实例（需在 init 之后）
final isar = LocalDbService().isar;

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
| `deleteAsset` | `Future<void> deleteAsset(int isarId)` | `void` | 通过 Isar 主键删除资产 |
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
  expectedLifespanDays: 1460, // 4年
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
- 支持平台: iOS / Android / macOS / Windows / Linux / Web

### 快速开始

```bash
# 1. 克隆代码仓库
git clone https://github.com/cecilenn/Daily-Price.git
cd daily_price

# 2. 安装依赖
flutter pub get

# 3. 生成 Isar 代码（必需！）
flutter pub run build_runner build --delete-conflicting-outputs

# 4. 运行应用
flutter run
```

### 开发调试

```bash
# 启用 Isar Inspector（开发模式已默认启用）
# Inspector 可在浏览器中查看和调试数据库内容

# 清理并重新生成代码
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs

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

## 🗺 未来路线图 (Roadmap)

### ✅ 已实现功能

- [x] 资产 CRUD 操作
- [x] 本地数据持久化（Isar）
- [x] CSV 导入/导出
- [x] 资产折旧计算
- [x] 标签系统与筛选
- [x] 置顶功能

### 🚧 开发中

- [ ] 数据备份与恢复
- [ ] 图表可视化（折旧曲线、资产分布）

### 📅 计划接入

- [ ] **PocketBase 云端同步** - 部署在 NAS 上的 PocketBase 作为云端冷备份后端，实现多端数据同步
- [ ] 用户认证系统
- [ ] 多设备同步
- [ ] 数据加密存储

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

**Made with ❤️ using Flutter & Isar**

</div>
