# Agent Handoff - daily price

日期：2026-06-22
工作目录：`/Users/liuzongpei/Projects/daily price`
当前目标：修复所有 bug，统一分类模型，拆分大页面

## 交接结论

当前代码已经做过一轮大规模清理：主资产分类模型基本统一，大页面已经拆分到没有 Dart 文件超过 500 行，多个外部数据入口的解析/兼容 bug 已修复，忘记密码验证码链路已修通，SQLite 旧 schema 升级路径已有 FFI 测试覆盖，`flutter analyze` 和 `flutter test` 通过。

但不要把任务标记完成。原因很明确：`所有 bug` 这个目标无法仅靠当前单元测试证明，真实设备扫码、真实老用户数据库文件升级、WebDAV 真实服务器同步、图库保存权限这些运行时路径还没有完整验收。

## 当前验证证据

最后一次验证命令：

```bash
flutter analyze
flutter test
find lib -name '*.dart' -maxdepth 5 -print0 | xargs -0 wc -l | sort -nr | head -30
rg -n "AssetFormDialog|asset_form_dialog|PrefKeys|pref_keys|category\s*==\s*['\"](physical|virtual|subscription)['\"]|category\s*=\s*['\"](physical|virtual|subscription)['\"]|DropdownMenuItem\(value: ['\"](physical|virtual)['\"]" lib test
```

结果：

- `flutter analyze`: 通过，`No issues found`
- `flutter test`: 通过，25 个测试全过
- 最大 Dart 文件：`lib/screens/check_list_screen.dart` 493 行，没有超过 500 行的 Dart 文件
- 旧分类残留只剩：
  - `lib/models/asset_category.dart` 的兼容逻辑
  - `lib/services/local_db_schema.dart` 的迁移 SQL

Flutter 当前仍有警告：

```text
permission_handler_apple 和 mobile_scanner 不支持 iOS Swift Package Manager。
Flutter 提示未来版本可能变成错误。
```

这是依赖风险，不是当前代码错误。

## 已完成的主要工作

### 分类模型统一

新增并使用：

- `lib/models/asset_category.dart`

规则：

- 旧分类 `physical / virtual / subscription` 不再作为资产分类保留
- 旧分类统一归到 `AssetCategory.uncategorized`，即 `未分类`
- `subscription` 只作为 `ownershipType` 使用
- `Asset` 构造、`fromMap`、`copyWith`、CSV、QR、检查快照、偏好设置都做了归一化

已删除遗留重复定义：

- `lib/utils/pref_keys.dart`

### 模型和服务拆分

新增/拆分的关键文件：

- `lib/models/asset_records.dart`
- `lib/models/asset_metrics.dart`
- `lib/utils/asset_input_parser.dart`
- `lib/services/local_db_schema.dart`
- `lib/services/asset_preferences_service.dart`
- `lib/services/asset_form_submission_service.dart`
- `lib/services/asset_analysis_service.dart`
- `lib/services/asset_csv_service.dart`
- `lib/services/asset_qr_service.dart`
- `lib/services/asset_share_service.dart`
- `lib/services/asset_scan_import_service.dart`
- `lib/services/asset_batch_service.dart`
- `lib/services/asset_export_service.dart`
- `lib/services/check_asset_snapshot_service.dart`
- `lib/services/check_session_archive_service.dart`
- `lib/services/home_scan_flow.dart`
- `lib/features/inspection/services/inspection_asset_code_parser.dart`

### 大页面拆分

现在没有超过 500 行的 Dart 文件。主要拆分包括：

- `home_screen.dart` 拆出 home app bar、列表、卡片、筛选、批量操作、扫码 flow
- `analysis_screen.dart` 拆出分析服务和卡片组件
- `asset_detail_screen.dart` 拆出详情卡片、耗材组件、二维码分享
- `add_edit_asset_screen.dart` 拆出表单、续费/耗材/记录 dialogs、提交服务
- `check_list_screen.dart` / `check_detail_screen.dart` / `check_scan_screen.dart` 拆出检查相关服务和 widget
- `inspection_detail_screen.dart` / `inspection_list_screen.dart` 拆出巡检 widgets 和 dialogs

已删除未引用的大型遗留入口：

- `lib/widgets/asset_form_dialog.dart`

### 已修复的明确 bug

- 旧 `deleteCategoryAndCleanTags` 会删除分类下资产，现在改为归入 `未分类`
- CSV 导入支持毫秒时间戳日期，不再把时间戳解析成当前时间
- CSV 布尔字段支持 `1/true/yes/y`
- 资产二维码分享不再丢失 `ownershipType / expireDate / renewals`
- 资产二维码解析支持字符串数字和布尔值
- 巡检快照坏 JSON 不再炸 UI
- WebDAV 资产清单支持中文和英文字段名
- 巡检扫码 `{}` 不再生成 `"null"` 资产编码
- 巡检详情批量确认/删除提示不再显示 `0 项`
- 表单提交服务保留续费、耗材、更换记录和头像字段
- 忘记密码页面改为通过 Supabase SDK 调用 `send-reset-code` / `verify-reset-code`
- Resend 测试模式错误改为清晰中文提示；验证域名并配置 `RESEND_FROM` 后，真实邮箱验证码发送已验证成功
- SQLite V5 -> V9 迁移测试覆盖旧 `subscription / physical` 分类、`ownership_type` 恢复、续费/耗材字段和检查表创建

## 当前工作树状态

工作树是大量未提交改动，包含 tracked 修改、tracked 删除和新增未跟踪文件。不要随便 `git reset` 或丢弃文件。

重要删除：

- `lib/widgets/asset_form_dialog.dart`
- `lib/utils/pref_keys.dart`

重要新增目录/文件：

- `lib/features/inspection/widgets/`
- `lib/features/inspection/services/inspection_asset_code_parser.dart`
- `lib/models/asset_category.dart`
- `lib/models/asset_metrics.dart`
- `lib/models/asset_records.dart`
- `lib/services/*` 多个抽出的服务
- `lib/widgets/*` 多个抽出的 UI 组件
- `lib/services/password_reset_service.dart`
- `lib/widgets/avatar_edit_result.dart`
- `lib/widgets/avatar_editor_options.dart`
- `supabase/functions/send-reset-code/index.ts`
- `supabase/functions/verify-reset-code/index.ts`
- `supabase/migrations/20260622000000_create_password_reset_codes.sql`

当前 diff 规模约：

```text
28 files changed, 1918 insertions(+), 7352 deletions(-)
```

注意：`git diff --stat` 不显示所有 untracked 新文件的完整统计，所以实际新增文件更多。

## 测试现状

测试文件：

- `test/widget_test.dart`

目前 25 个测试，覆盖：

- schema identity
- SQLite 旧 schema 迁移到 V9
- 旧分类归一化
- 输入解析兼容
- 表单提交服务
- 附属记录和头像字段保留
- 偏好分类归一化
- CSV parse/export
- QR parse/share roundtrip
- 扫码导入 existing/preview 决策
- 批量分享 payload
- filter state
- analysis exclusion flags
- check session CSV import/export
- 巡检快照坏数据防御
- WebDAV 资产字段 alias
- 巡检扫码资产编码解析
- Home 基础渲染

## 下一步建议

优先级从高到低：

1. 真实运行路径验收
   - 启动 app，走新增资产、编辑资产、分类管理、CSV 导入导出、二维码分享/扫码
   - 重点看订阅资产分享后再导入是否仍是订阅资产
   - 重点看删除分类后资产是否归入 `未分类`，不是被删除

2. WebDAV 巡检流程验收
   - 配置 WebDAV
   - 同步资产库
   - 新建检查任务
   - 扫码录入/扫码确认
   - 上传会话/分享码导入
   - 检查坏数据或字段不一致是否能降级显示

3. SQLite 真实老库文件验收
   - FFI 自动化测试已覆盖旧 schema 升级逻辑
   - 如果手上有真实旧版本 App 数据库文件，再做一次文件级升级回归

4. 继续收缩剩余大组件
   - 虽然都低于 500 行，但这些文件仍偏大：
     - `lib/screens/check_list_screen.dart` 493
     - `lib/screens/home_screen.dart` 487
     - `lib/screens/add_edit_asset_screen.dart` 472
     - `lib/widgets/analysis_cards.dart` 457
     - `lib/screens/check_detail_screen.dart` 448
   - `lib/widgets/avatar_editor_sheet.dart` 已从 452 行降到 403 行，拆出了 `AvatarEditResult` 和头像预设选项
   - 下一步可优先拆 `check_list_screen.dart` 或 `analysis_cards.dart`

5. 做一次端到端手动回归清单
   - 资产新增/编辑/删除
   - 订阅资产续费
   - 耗材添加/更换
   - 分类添加/删除
   - 标签添加/批量标签
   - CSV 导入导出
   - QR 分享和扫码入库
   - 巡检任务创建/录入/确认/导入导出

## 接手注意事项

- 不要把当前目标标记完成，除非完成真实运行验收或有更强证据。
- 不要恢复 `asset_form_dialog.dart`，它是未引用的旧入口，而且绕过 Provider。
- 不要恢复 `pref_keys.dart`，偏好 key 已集中到 `AssetPreferencesService`。
- 不要把 `subscription` 再当资产分类使用，它现在只应作为 `ownershipType`。
- 修改后必须至少跑：

```bash
dart format <changed files>
flutter analyze
flutter test
```

- 如果继续拆文件，先查引用，再小步移动，避免把大页面问题转移成大 widget 文件。
