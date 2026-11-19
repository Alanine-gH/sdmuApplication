# HAP 正式上线交付说明（功能对接中根治版）

> 生成时间：2026-11-18
> 产物：`entry/build/default/outputs/default/entry-default-signed.hap`（20,024,172 B）
> 构建：`hvigorw assembleHap` clean 全量 BUILD SUCCESSFUL，WRITE_CONTACTS 权限已恢复正式声明

## 一、本轮修复（用户投诉"怎么都是功能对接中"）

### 根因
`dispatchApp`（Index.ets + AppSearchPage.ets）对未进 YYID 原生映射表的应用直接 `showToast('功能对接中')`。但 APK 中所有非原生应用都是 LightActivity，通过 springboard 跳板免登打开——不存在"功能对接中"死路。这是 HAP 分发逻辑的第三种错误分支。

### 修复
| 文件 | 改动 |
|---|---|
| `pages/Index.ets` | dispatchApp：YYID 映射命中→原生页；其余全部走 LightAppPage（有 yyid→springboard，有 url→直载），删除"功能对接中"分支 |
| `pages/AppSearchPage.ets` | 同口径：nativeMap + 兜底 LightAppPage，删除 openNative toast |
| `pages/StudentReportHomePage.ets` | 修复 `pages/pages/` 双重前缀 404 bug（pagePath 已含前缀，不再二次拼接） |
| `pages/PhoneLoginPage.ets` | 修复手机号登录页协议勾选行被挤出屏幕：表单 Column 原 `height('100%')` 撑满根容器，把"同意《隐私政策》和《服务协议》"radio 行挤出屏外，导致用户看到"请先同意"toast 却无勾选入口。改为 `layoutWeight(1)`，实测 radio 行正常显示可勾选（截图 `temp/q5_phonelogin_fixed.png`） |
| `pages/LightAppPage.ets` | 修复轻应用（一卡通付款码等）加载失败无限白屏卡死：新增错误态视图（`@State viewState` + `mobile_campus_page_error` + 重试按钮）。hilog 实证财务处 `zf.cwc.sdmu.edu.cn` `ERR_TIMED_OUT(-7)`——目标服务器对出口网络不可达（校园内网应用），APK 同环境同样打不开；HAP 补错误态兜底。[R59] 一卡通 5 个 yyid 错误文案改为"一卡通服务需在校园网内使用\n请连接校园网后重试"。[R60] **移除右下角 Aa 字号按钮**：APK X5LightActivity.java L2156-2160 实证该按钮仅 `schoolId=="XNZY"`（另一所定制学校）时 setVisibility(0)，山东管理学院（SDMU）下永远不显示——HAP 无条件渲染属翻译错误，已删除对齐源码 |

### 服务端全量核对（temp/probe_applist_all.py）
10 组 30 应用：LX=1 原生仅 7 个（timetable/score/myLibrary/schedule/studyReport/campusView/schoolIntro，全部已映射）；其余 LX=2/4 均为 H5，走 springboard。单点验证：督评系统、挂失解挂、通讯录等点击均进 LightAppPage，无 toast。

## 二、可达占位页补真实现（13 页原"页面开发中"）

审计（placeholder-audit）确认 40 个占位页中 13 个被已实现页入口引用（真实体验硬伤），全部有 APK 源码，本轮补齐：

| 组 | 页面 | 验收 |
|---|---|---|
| P-A | BookBorrowReport / CardConsumeReport / BreakfastPersonal / ChangeQqWechat / SchoolMap | 通过，修 QQ 提交守卫 |
| P-B | SocialNews / SocialNewNews / FriendUserList / SocialReport / GradeRank | 通过，补相对时间+九宫格+纠编造文案 |
| P-C | SuperviseAdd / SuperviseFinished / ReceiptDetail | 通过，修任课教师/工号并排布局 |

剩余 27 个占位页为仅 main_pages.json 注册、无任何跳转引用的死代码，不影响上线。

## 三、交付前状态确认

| 项 | 状态 |
|---|---|
| LoginPage | 发布态（账号/密码空、privacyAgreed=false，无预填） |
| Web 调试 | setWebDebuggingAccess(false) 生产关闭 |
| WRITE_CONTACTS | 已恢复正式声明（需正式签名+AGC ACL） |
| 构建 | clean 全量 BUILD SUCCESSFUL |
| 禁 mock | 全工程零编造，无数据走真实空/错误态 |

## 四、上线须知

1. **签名与权限**：WRITE_CONTACTS 是受限权限，用正式证书签名并在 AppGallery Connect 申请该权限 ACL 后可上架。debug 签名会因 ACL 校验报 9568289 装不上，属 HarmonyOS 权限机制，非代码缺陷。
2. **服务端依赖**：部分 H5 报表页（如借阅排名 `/rank/libraryReport`）服务端返回 404，为服务端未部署，HAP 已按源码如实呈现错误态，服务端部署后自动生效无需改包。
3. **push 域**：yibaogao.com 相关校圈功能在非校园网环境 SSL 不可达，页面走真实错误态——与 APK 同环境行为一致。

## 五、产物

- HAP：`entry/build/default/outputs/default/entry-default-signed.hap`
- 验收报告：`docs/review_P-A-review.md` / `docs/review_P-B-review.md` / `docs/review_P-C-review.md`
- 索引：`docs/agents_index.md`
- 全过程快照：`D:\projects\sdmu_decompile\temp\PORT_ROUND2_SNAPSHOT.md`
