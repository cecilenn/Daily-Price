# Daily Price

记录资产价值，追踪每日折旧，看清每一分钱花在哪了。

<!-- 截图占位：以后添加 -->
<!-- ![主界面](screenshots/home.png) ![检查功能](screenshots/check.png) -->

## 功能亮点

- **智能日均成本** — 服役中按预期寿命算，退役按实际天数算，卖出自动回血抵扣
- **扫码盘点** — 创建检查任务，扫码录入资产，扫码确认状态，导出 CSV 报告
- **复合头像** — 照片优先，降级到图标，再降级到文字，永不空白
- **云端同步** — Supabase 备份恢复，App 内密码重置
- **CSV 导入导出** — 跨平台数据迁移，支持智能去重合并
- **三种主题** — 极简留白、暗黑模式、复古护眼

## 快速开始

```bash
git clone https://github.com/cecilenn/Daily-Price.git
cd Daily-Price
flutter pub get
flutter run
```

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.11+ |
| 数据库 | sqflite (SQLite) |
| 状态管理 | Provider |
| 云端 | Supabase |
| 扫码 | mobile_scanner |
| 图表 | fl_chart |

## 更多

详细的架构设计、踩坑记录、部署流程：👉 [DEVELOPMENT.md](./DEVELOPMENT.md)

## 开源协议

MIT
