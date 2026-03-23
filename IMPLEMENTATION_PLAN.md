# Daily Price 数据库和模型层改造实施计划

## 任务清单
- [x] 1. 分析现有 Asset 模型代码
- [x] 2. 修改 Asset 模型，新增 ownershipType 字段
- [x] 3. 修改 Asset 模型的 category 字段语义
- [x] 4. 更新数据库服务，添加版本6升级逻辑
- [x] 5. 创建时长格式化工具 TimeFormatter
- [x] 6. 创建 SharedPreferences key 常量文件
- [x] 7. 验证所有改动符合约束条件

## 详细步骤

### 步骤1：分析现有 Asset 模型代码
- 读取 lib/models/asset.dart 文件
- 了解当前字段定义和方法结构

### 步骤2：修改 Asset 模型
- 新增 ownershipType 字段（String，默认 'buyout'）
- 更新构造函数、create 工厂方法、copyWith 方法
- 更新 toMap() 和 fromMap() 方法

### 步骤3：修改 category 字段语义
- 将 Asset.create 工厂方法中 category 默认值从 'physical' 改为 '未分类'

### 步骤4：更新数据库服务
- 读取 lib/services/local_db_service.dart 文件
- 在 _onUpgrade 方法中添加版本6升级逻辑
- 更新数据库版本号到6

### 步骤5：创建时长格式化工具
- 创建 lib/utils/time_formatter.dart 文件
- 实现 TimeFormatter 类和所有格式化方法

### 步骤6：创建 SharedPreferences key 常量文件
- 创建 lib/utils/pref_keys.dart 文件
- 定义所有 SharedPreferences key 常量

### 步骤7：验证所有改动
- 确保不修改 screens/ 和 widgets/ 目录
- 确保不修改 pubspec.yaml
- 确保数据库升级逻辑在已有升级判断之后
- 确保 ownershipType 默认值正确