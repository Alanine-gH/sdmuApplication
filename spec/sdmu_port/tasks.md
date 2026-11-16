# Implementation Tasks — 山东管理学院校园APP 移植

> 来源：PORT_SPEC.md + 父代理任务摘要。Verification 阶段不在本子代理范围内（由 spec-verify 阶段执行）。

## Phase 1: Setup
- [X] A1: 更新 AppScope/app.json5：label="山东管理学院", versionCode=68, versionName="3.2.0"
- [X] A2: 更新 entry/src/main/module.json5：添加 requestPermissions（INTERNET/GET_NETWORK_INFO/GET_WIFI_INFO/CAMERA/MICROPHONE/LOCATION/APPROXIMATELY_LOCATION/VIBRATE）
- [X] A3: 更新 entry/src/main/resources/base/element/string.json：app_name="山东管理学院", module_desc, EntryAbility_desc, EntryAbility_label
- [X] A4: 更新 entry/src/main/resources/base/element/color.json：添加主题色（主色 #1677FF 等）
- [X] A5: 更新 entry/src/main/resources/base/profile/main_pages.json：注册所有页面路径
- [X] A6: 创建目录骨架：pages/ components/ model/ network/ data/ common/ constants/

## Phase 2: Foundational
- [X] B1: model/UserModel.ets — UserInfo class
- [X] B2: model/NewsModel.ets — NewsItem class
- [X] B3: model/CourseModel.ets — CourseItem + ScheduleItem class
- [X] B4: model/TodoModel.ets — TodoItem class
- [X] B5: model/ContactModel.ets — ContactItem class
- [X] B6: model/ScoreModel.ets — ScoreItem + ExamItem class
- [X] B7: model/MeetingModel.ets — MeetingItem class
- [X] B8: model/AttendanceModel.ets — AttendanceItem class
- [X] B9: model/ResponseModel.ets — ApiResponse<T> class
- [X] C1: network/HttpClient.ets — @kit.NetworkKit http 封装
- [X] C2: network/Api.ets — API 常量
- [X] C3: network/ApiService.ets — 单例 ApiService
- [X] D1: data/PreferencesUtil.ets — @kit.ArkData preferences 封装
- [X] D2: data/Constants.ets — 常量
- [X] F1: components/TitleBar.ets — 通用标题栏
- [X] F2: components/ListItem.ets — 通用列表项（以 ListStateView 状态容器实现）
- [X] F3: components/EmptyView.ets — 空数据提示
- [X] F4: components/LoadingView.ets — 加载中
- [X] F0: common/BasicDataSource.ets — 未单独实现：页面数据量小，统一用 ForEach + key，无需 LazyForEach 数据源

## Phase 3: User Stories
- [X] E1: pages/Index.ets — 主页 Tab 容器（底部导航）
- [X] E2: pages/LoginPage.ets — 登录页
- [X] E3: pages/NewsPage.ets — 新闻列表
- [X] E4: pages/NewsDetailPage.ets — 新闻详情
- [X] E5: pages/SchedulePage.ets — 课表页
- [X] E6: pages/TodoPage.ets — 待办列表
- [X] E7: pages/ContactPage.ets — 通讯录
- [X] E8: pages/ScorePage.ets — 成绩页
- [X] E9: pages/MeetingPage.ets — 会议列表
- [X] E10: pages/MinePage.ets — 个人中心
- [X] E11: pages/SettingPage.ets — 设置页
- [X] E12: pages/PersonalDetailPage.ets — 个人详情
- [X] E13: pages/ExamPage.ets — 考试列表
- [X] E14: pages/AttendancePage.ets — 考勤页
- [X] E15: pages/MeetingDetailPage.ets — 会议详情
- [X] E16: pages/WebViewPage.ets — 通用 WebView 页

## Phase 4: Polish
- [X] G1: entryability/EntryAbility.ets — loadContent 为 'pages/Index'，保持现有生命周期（新增 PreferencesUtil.init）
