# 移植规格：山东管理学院校园APP → HarmonyOS

## 应用信息
- 包名: com.lysoft.android.lyyd.report.mobile.sdgy
- 版本: SDGY_3.2.0 (versionCode 68)
- 应用名: 山东管理学院
- 360加固已脱壳，真实DEX已提取（dex2: 2921类, dex3: 1099类）

## 网络配置
- 域名: portal.ly-sky.com (SOCKET_HOST)
- API前缀: /ly-pd-mb/
- 协议: HTTPS
- 客户端: OkHttp (Android)
- 关键接口:
  - /ly-pd-mb/information/api/information/listFromPortal (新闻列表)
  - /ly-pd-mb/information/api/information/detailFromPortal (新闻详情)

## 权限映射
| Android权限 | HarmonyOS权限 |
|---|---|
| INTERNET | ohos.permission.INTERNET |
| ACCESS_NETWORK_STATE | ohos.permission.GET_NETWORK_INFO |
| ACCESS_WIFI_STATE | ohos.permission.GET_WIFI_INFO |
| CAMERA | ohos.permission.CAMERA |
| READ_PHONE_STATE | (无直接对应，用telephony) |
| RECORD_AUDIO | ohos.permission.MICROPHONE |
| READ/WRITE_EXTERNAL_STORAGE | file permissions |
| ACCESS_FINE_LOCATION | ohos.permission.LOCATION |
| VIBRATE | ohos.permission.VIBRATE |
| WAKE_LOCK | (无需) |
| FLASHLIGHT | (无需) |

## 功能模块与页面

### 1. 启动/登录模块
- DispatchActivity (启动分发) → 判断登录状态
- MobileCampusLoginActivity (登录页) — 账号密码登录
- MobileCampusLoginNewActivity (新登录页)
- ScanLoginActivity (扫码登录)
- MobileCampusSSOActivity (SSO登录)
- ChooseSchoolActivity (选择学校)
- InputIdentifyCodeActivity (输入验证码)
- PrivacyPolicyActivity (隐私政策)
- CampusFirstActivity (首次启动)

### 2. 主页模块
- MainActivity (主页) — 底部Tab导航
- MainSettingActivity (主设置)
- KeywordSearchActivity (关键词搜索)
- PolymerizationActivity (聚合页)

### 3. 新闻模块
- NewsActivity (新闻列表)
- NewNewsActivityEx (新闻列表Ex)
- CenterDetailActivity (中心详情)
- MessageListActivity (消息列表)
- MainNotificationActivity (通知)
- MainNotificationV2Activity (通知V2)
- EmcMessageDetailActivity (消息详情)

### 4. 课表/日程模块
- ScheduleActivity (日程)
- ScheduleMainActivity (日程主页)
- ScheduleDetailActivity (日程详情)
- AddCourseActivity (添加课程)
- AddScheduleActivity (添加日程)
- EditCourseActivity (编辑课程)
- CourseDetailActivity (课程详情)
- TimetableActivity (时间表)
- ChooseCourseActivity (选择课程)
- ClassmatesListActivity (同学列表)

### 5. OA办公模块
- TodoMainActivity (待办主页)
- TodoDetailActivity (待办详情)
- TodoReadActivity (待办阅读)
- TodoFastreplyActivity (快速回复)
- WorkApplyActivity (工作申请)
- WorkApplyDetailActivity (工作申请详情)
- IssueMainActivity (公文主页)
- IssueDetailActivity (公文详情)
- FeedbackActivity (反馈)
- ReimburseLaunchActivity (报销发起)
- ReceiptListActivity (票据列表)

### 6. 考勤/巡检模块
- AttendanceMainActivity (考勤主页)
- AttendancePersonalActivity (个人考勤)
- InspectionActivity (巡检)
- InspectionRecordActivity (巡检记录)
- NewAddRecordActivity (新增记录)

### 7. 通讯录模块
- ContactSearchActivity (搜索)
- ContactDepartmentActivity (部门)
- ContactPersonalDetailActivity (个人详情)
- ContactClassAddressBook (班级通讯录)

### 8. 成绩模块
- ScoreMainActivity (成绩主页)
- StudentScoreActivity (学生成绩)
- ScoreListActivity (成绩列表)
- ExamListActivity (考试列表)

### 9. 会议模块
- MeetingActivity (会议)
- MeetingMainActivity (会议主页)
- AddMeetingActivity (添加会议)
- MeetingSignActivity (签到)

### 10. 社交模块
- SocialMainActivity (社交主页)
- NewNewsActivity (社交新闻)
- PostPublishActivity (发布)
- MarketActivity (市场)

### 11. 个人中心模块
- SettingActivity (设置)
- PersonalDetailActivity (个人详情)
- ModifyPwdActivity (修改密码)
- GesturePwdSettingActivity (手势密码)
- FingerLoginActivity (指纹登录)
- AboutUsActivity (关于)
- FileManagerActivity (文件管理)
- FontSizeSettingActivity (字体大小)

### 12. 运动步数模块
- SportStepsRankingsActivity (步数排名)
- SportStepsSettingActivity (步数设置)
- SportStepsHistoryActivity (步数历史)

### 13. 校园服务模块
- SchoolSceneryActivity (校园风景)
- SchoolFunctionMapActivity (功能地图)
- SchoolLocationActivity (位置)
- MobileCampusReadingActivity (阅读)

## 数据模型 (关键)
- UserInfo (用户信息: 学号/姓名/班级/学院)
- NewsItem (新闻: id/title/summary/time/url)
- CourseItem (课程: name/teacher/location/week/day/section)
- ScheduleItem (日程: title/time/location/type)
- TodoItem (待办: title/status/type/deadline)
- ContactItem (联系人: name/department/phone/email)
- ScoreItem (成绩: course/score/credit/gpa)
- ExamItem (考试: course/time/location/type)
- MeetingItem (会议: title/time/location/status)
- AttendanceItem (考勤: course/status/time/type)

## 第三方SDK映射
| Android SDK | HarmonyOS替代 |
|---|---|
| 极光推送 JPush | HarmonyOS Push Kit |
| 友盟 UMeng | 自定义统计/无 |
| 小米/魅族/OPPO推送 | HarmonyOS Push Kit |
| 高德地图 AMap | HarmonyOS Map Kit / Petal Maps |
| 腾讯X5 WebView | 系统Web组件 |
| 华为HMS | HarmonyOS原生API |
| Sharesdk分享 | 系统分享 |
| UCrop | 系统图片编辑 |
| PictureSelector | 系统图片选择器 |
| OkHttp | @ohos.net.http |

## 项目结构
```
entry/src/main/ets/
├── entryability/EntryAbility.ets
├── pages/
│   ├── Index.ets (主页Tab容器)
│   ├── LoginPage.ets (登录)
│   ├── NewsPage.ets (新闻列表)
│   ├── NewsDetailPage.ets (新闻详情)
│   ├── SchedulePage.ets (课表)
│   ├── TodoPage.ets (待办)
│   ├── ContactPage.ets (通讯录)
│   ├── ScorePage.ets (成绩)
│   ├── MeetingPage.ets (会议)
│   ├── MinePage.ets (个人中心)
│   └── ... (其他页面)
├── components/ (复用组件)
├── model/ (数据模型)
├── network/ (网络层)
├── data/ (持久化)
├── common/ (工具/常量)
└── constants/ (常量)
```

## 设计要点
- 主页用底部Tab导航 (Tabs组件)，5个Tab: 首页/消息/课表/我的
- 登录页: 账号密码输入 + 登录按钮
- 新闻页: 列表 + 详情页
- 课表页: 周视图课表
- 个人中心: 设置列表
- 网络层: @ohos.net.http 封装
- 持久化: @ohos.data.preferences
