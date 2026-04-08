# Daily Price

记录资产价值，追踪每日折旧，看清每一分钱花在哪了。

<!-- 截图占位：以后添加 -->
<!-- ![主界面](screenshots/home.png) ![检查功能](screenshots/check.png) -->

## 功能亮点

- **智能日均成本** — 服役中按预期寿命算，退役按实际天数算，卖出自动回血抵扣
- **扫码盘点** — 创建检查任务，扫码录入资产，扫码确认状态，导出 CSV 报告
- **特调检查** — WebDAV 云端资产库同步，扫码/手动录入，分享码分享检查列表（见下方详细说明）
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

## 特调检查功能

独立模块，用于展会/出差时盘点公司设备资产。需要配合 WebDAV 服务使用。

### 数据架构

```
云端 WebDAV
├── assets.json                    # 总资产主文件（公司全量设备）
└── sessions/
    └── {shareCode}.json           # 分享的检查会话（仅含资产编码列表）
```

总资产文件格式：

```json
[
  {
    "资产编码": "EQ-001",
    "资产名称": "联想笔记本",
    "规格型号": "ThinkPad X1",
    "使用部门": "技术部",
    "使用人": "张三",
    "存放位置": "A栋301室"
  }
]
```

会话分享文件格式：

```json
{
  "name": "2024春季展会盘点",
  "createdAt": 1710000000000,
  "assetCodes": ["EQ-001", "EQ-005"],
  "confirmedCodes": ["EQ-001"]
}
```

### 搭建 WebDAV 服务

推荐用 Python 起一个本地测试服务，正式环境可部署到公司服务器。

#### 方式一：Python（本地测试）

```bash
pip3 install wsgidav cheroot

# 创建目录结构和测试资产文件
mkdir -p /tmp/webdav/inspection/sessions
echo '[{"资产编码":"EQ-001","资产名称":"联想笔记本","规格型号":"ThinkPad X1","使用部门":"技术部","使用人":"张三","存放位置":"A栋301室"}]' > /tmp/webdav/inspection/assets.json

# 启动服务（匿名模式，无需认证）
wsgidav --host 0.0.0.0 --port 8080 --root /tmp/webdav --auth=anonymous
```

验证服务是否正常：

```bash
curl http://localhost:8080/inspection/assets.json
```

#### 方式二：Docker

```bash
docker run -d -p 8080:8080 \
  -e AUTH_TYPE=Basic \
  -e USERNAME=admin \
  -e PASSWORD=admin \
  -v /tmp/webdav:/var/lib/dav \
  bytemark/webdav
```

#### 方式三：Nginx + nginx-dav-ext-module

适合正式部署，需要自行编译 Nginx 并启用 WebDAV 模块。配置示例：

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location /dav/ {
        dav_methods PUT DELETE MKCOL COPY MOVE;
        dav_ext_methods PROPFIND OPTIONS;
        dav_access user:rw group:rw all:r;
        create_full_put_path on;
        client_max_body_size 100M;
        auth_basic "WebDAV";
        auth_basic_user_file /etc/nginx/.htpasswd;
        root /data/webdav;
    }
}
```

### App 内配置

1. **功能 → 特调检查 → 右上角齿轮图标**
2. 填写配置：
   - 服务器地址：`http://<IP>:<端口>`（如 `http://192.168.1.100:8080`）
   - 用户名/密码：匿名模式留空
   - 资产文件路径：`/inspection/assets.json`
   - 会话目录路径：`/inspection/sessions/`
3. 点击 **测试连接**，成功后点 **保存配置**

### 使用流程

1. **同步资产库** — 点击云同步图标，从 WebDAV 下载总资产到本地
2. **管理本地资产库** — WebDAV 配置页底部按钮，支持新增/编辑/删除资产，可一键上传到 WebDAV
3. **新建检查任务** — 点击 "+" 命名创建
4. **扫码录入** — 扫描设备二维码（内容为资产编码），从本地资产库查找对应详情
5. **扫码确认** — 扫描二维码，匹配检查列表中的资产编码并标记已确认
6. **手动输入** — 无二维码时可手动输入资产编码
7. **上传到云端** — 详情页右上角按钮，生成 6 位分享码 + QR 码
8. **导入检查任务** — 输入同事的分享码，从云端下载检查列表

> 扫码和确认均在本地完成，不依赖网络。仅同步资产库和分享检查列表时需要网络。

### 代码结构

所有代码在 `lib/features/inspection/` 下，与主应用完全独立。如需拆分为单独项目，删除该目录并在 `function_hub_screen.dart` 移除对应卡片即可。

```
lib/features/inspection/
├── models/          # 数据模型（CompanyAsset, CompanyCheckSession, CompanyCheckItem）
├── data/            # 独立数据库 inspection.db（sqflite）
├── services/        # WebDAV 配置与客户端
├── providers/       # InspectionProvider（状态管理）
└── screens/         # 6 个页面（列表、详情、扫码、导入、配置、资产管理）
```

## 技术栈

| 类别 | 技术 |
|------|------|
| 框架 | Flutter 3.11+ |
| 数据库 | sqflite (SQLite) |
| 状态管理 | Provider |
| 云端 | Supabase（主应用同步） + WebDAV（特调检查同步） |
| 扫码 | mobile_scanner |
| 图表 | fl_chart |
| QR 码生成 | qr_flutter |

## 更多

详细的架构设计、踩坑记录、部署流程：👉 [DEVELOPMENT.md](./DEVELOPMENT.md)

## 开源协议

MIT
