# 山东管理学院校园服务应用（HarmonyOS）

山东管理学院校园移动服务客户端的 HarmonyOS 原生复刻版。基于反编译的原 Android APK（X5 WebView 混合架构）源码，逐页面还原为 ArkTS 原生实现，覆盖原应用全部核心功能。

> 当前版本：**3.3.0** (VersionCode 69) ｜ 目标平台：HarmonyOS NEXT（API 12+，arm64）｜ 开发者：Alanine-孔硕

## 项目背景

原 Android 客户端为「原生壳 + X5 WebView 加载学校 H5 页面」的混合架构，页面本体多为 H5，原生部分仅做壳、路由与登录态。本项目将全部页面迁移至 ArkTS 原生实现：

- **原生页面**：门户首页、应用宫格、校园风光、学校概况、课表、通讯录、意见反馈等 146 个页面已完成 ArkTS 原生复刻
- **轻应用（H5）**：一卡通、智慧后勤等仍依赖学校 H5 服务的页面，通过原生 `Web` 组件承载，注入免登票据（加密 AT 头 + 路由参数），复刻原 X5LightActivity 的加载与错误处理逻辑
- **无源页面**：58 个页面在反编译产物中无对应源码，已在 `docs/page_mapping.md` 中登记并按需补齐

## 功能概览

| 模块 | 说明 |
|---|---|
| 门户首页 | 轮播图、通知公告、快捷入口、校园资讯 |
| 应用宫格 | 200+ 校内应用入口，支持搜索与分类，原生页面直达 / 轻应用跳板分发 |
| 课表 | 学期课表拉取与展示（对接学校教务接口，TT 协议逐字段还原） |
| 一卡通 | 扫码付款、余额查询、宿舍电量、校园卡挂失等 5 个入口（经学校 SSO 302 链路） |
| 通讯录 | 校内通讯录，支持保存联系人到本地（WRITE_CONTACTS ACL） |
| 消息/待办 | 校内消息中心、流程待办 |
| 我的 | 个人信息、意见反馈（对接第三方凌云反馈服务）、修改密码、隐私协议 |

## 技术架构

```
entry/src/main/ets/
├── entryability/     # EntryAbility（窗口生命周期、宽屏适配 AppStorage）
├── pages/            # 206 个 ArkTS 页面
├── components/       # 通用组件（TitleBar、MineTab 等）
├── network/          # Api / ApiService / HttpClient（接口逐字段还原自反编译源码）
├── common/ model/    # 工具与数据模型
```

- **网络层**：1:1 还原原 APK 的请求签名与加密协议（AT 免登票据、固定密钥反馈密文通道、multipart 上传），按 ServiceType 分通道复用 `HttpClient`
- **路由分发**：应用宫格点击 → YYID 路由表命中原生页 / 未命中走 `LightAppPage` 轻应用跳板，杜绝空路由死端
- **状态管理**：`@State` / AppStorage，宽屏（≥600vp）自适应三栏布局
- **Web 轻应用**：免登头注入、DoH 解析（`onControllerAttached` 时机调用，规避引擎未初始化崩溃）、`*.sdmu.edu.cn` SSL 白名单容忍、错误页状态机（区分超时/校园网限制/网络异常）

## 构建与运行

### 环境要求

- DevEco Studio（配套 HarmonyOS SDK）
- Node.js（DevEco 自带即可）
- 签名文件：调试签名走默认配置；发布签名需在 `build-profile.json5` 配置 signingConfigs（证书文件不入库）

### 命令行构建

```powershell
Set-Location D:\projects\sdmuApplication
$env:DEVECO_SDK_HOME="C:\soft\Huawei\DevEco Studio\sdk"
& "C:\soft\Huawei\DevEco Studio\tools\node\node.exe" "C:\soft\Huawei\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p product=default assembleHap --analyze=normal --parallel --incremental --daemon
```

产物位于 `entry/build/default/outputs/default/entry-default-signed.hap`。

### 上架包（.app）

AGC 上架需 `.app` 包：`hvigorw --mode project -p product=default assembleApp`，需发布证书与 Profile。

## 项目结构说明

| 目录 | 内容 |
|---|---|
| `entry/` | 主模块（全部 ArkTS 源码与资源） |
| `AppScope/` | 应用级配置（app.json5：bundleName、版本号） |
| `spec/sdmu_port/` | 反编译参考规格 |
| `发布/` | AGC 上架材料（指引文档、图标、截图、隐私政策、权限视频等；签名文件已 gitignore） |
| `docs/` | 开发文档（页面映射表、评审记录、平板适配） |
| `安卓apk/` | 原 APK 反编译参考产物（参考用，不参与构建） |

## 已知限制

- 一卡通等轻应用依赖学校服务端（`zf.cwc.sdmu.edu.cn`），校园网外或服务端故障时显示引导性错误页
- 部分功能（如门禁、水电缴费）依赖学校内网或未开放的接口
- 平板适配已完成布局层（≥600vp 三栏），未在真机平板上全量回归

## 许可与声明

- 本项目为学习研究性质的个人复刻，接口协议还原自原客户端，版权归原平台所有
- 项目不含任何签名证书、密钥与敏感凭据（`.gitignore` 已排除 `*.p12` / `*.cer` / `*.csr` / `*.p7b`）
