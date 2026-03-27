# Daily Price 修复任务清单

## 修复 1：耗材开关改为独立显示控制
- [x] 在 State 类中添加 _showConsumables 变量
- [x] 在 initState / _loadAsset 中初始化 _showConsumables
- [x] 修改 SwitchListTile 使用 _showConsumables
- [x] 将 if (_consumables.isNotEmpty) 改为 if (_showConsumables)

## 修复 2：耗材日期改为手动输入
- [x] 添加 _parseDateString 方法
- [x] 修改 _showAddConsumableDialog 使用 TextField 和手动日期解析
- [x] 修改 _showEditConsumableDialog 使用 TextField 和手动日期解析

## 修复 3：耗材单价允许为空
- [x] 修改 ConsumableRecord.dailyCost getter 处理 price 为 0
- [x] 修改 _showAddConsumableDialog 验证逻辑，允许 price 为空
- [x] 修改 _showEditConsumableDialog 验证逻辑，允许 price 为空
- [x] 修改耗材单价显示逻辑，处理 price 为 0 的情况

## 修复 4：首页显示所有耗材
- [x] 修改 home_screen.dart 显示所有耗材而非仅最紧急的一个

## 修复 5：QR 码包含耗材
- [x] 确认 asset_detail_screen.dart 的 _serializeAssetToJson 包含耗材（已存在）

## 修复 6：CSV 导出包含所有字段
- [x] 修改 _exportToCSV 表头，添加缺失字段
- [x] 修改数据行，添加对应的值

## 修复 7：CSV 导入解析新字段
- [x] 在构建 Asset 的代码块中添加新字段解析
- [x] 修改 Asset 构造函数，添加新字段

---

## 完成状态：✅ 全部完成

所有7个修复已成功应用到代码中。