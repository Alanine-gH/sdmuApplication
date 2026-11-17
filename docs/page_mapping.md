# HAP 页面 ↔ APK 源码 映射表

> 生成时间：2026-11-17 17:35。翻译方法：读 APK Activity 源码 + layout XML → 逐行翻译为 ArkTS。
> 状态：done=源码级翻译完成；partial=部分对齐；todo=待翻译；no-source=APK 无对应类（HAP 自建）。

| HAP 页面 | APK 源码类 | 状态 | 备注 |
|---|---|---|---|
| AboutPage.ets | AboutUsActivity | done | 版本行="当前版本号：V"+s.d()(_后子串)+"_"+versionCode（bundleManager 取真实值）；logo/应用名同 XML |
| AchievementDetailPage.ets | ? | no-source |  |
| AddCoursePage.ets | AddCourseActivity | todo |  |
| AppSearchPage.ets | AppSearchActivity | todo |  |
| AppUpdatePage.ets | AppUpdateActivity | todo |  |
| AppWidgetGuidePage.ets | AppWidgetGuideActivity | todo |  |
| AppsSettingPage.ets | AppsSettingActivity | todo |  |
| AttendancePage.ets | AttendanceLeaderFragment 等5个 | done | AttendanceMainActivity+Personal/List/Leader Fragment+widgets 源码级；isBoss=="1"→两页签（实测本校学生 0001→源码失败回调仅个人页）；index/bossIndex 为 POST 加密 body 实测通（index 返回 days/dayOfAttendance 为数字）；日历 scheme 点/统计卡/时间轴/ExpandableListView 全对齐；源码月拼接单月不补零（实测 0001）→HAP 补零为 yyyyMM |
| AttendancePersonalPage.ets | AttendancePersonalActivity 等2个 | todo |  |
| BannerDialogPage.ets | ? | no-source |  |
| BindEmailPage.ets | ? | no-source |  |
| BindPhonePage.ets | MobileCampusBindPhoneActivity | todo |  |
| BookBorrowReportPage.ets | ? | no-source |  |
| BreakfastPersonalPage.ets | ? | no-source |  |
| BreakfastRankPage.ets | ? | no-source |  |
| BrowsePhotosPage.ets | BrowsePhotosActivity | todo |  |
| CampusAppFragmentPage.ets | ? | no-source |  |
| CampusDateFragmentPage.ets | ? | no-source |  |
| CampusFirstPage.ets | CampusFirstActivity | todo |  |
| CarbonCopyListPage.ets | CarbonCopyListActivity | todo |  |
| CardConsumeReportPage.ets | ? | no-source |  |
| CenterDetailPage.ets | CenterDetailActivity | todo |  |
| ChangeNickNamePage.ets | ChangeNickNameActivity | todo |  |
| ChangeQqWechatPage.ets | ? | no-source |  |
| ChooseAcademyPage.ets | ChooseAcademyActivity | todo |  |
| ChooseCoursePage.ets | ChooseCourseActivity | todo |  |
| ChooseSchoolPage.ets | ChooseSchoolActivity | todo |  |
| CirculateReadPage.ets | CirculateReadActivity | todo |  |
| ClassmatesListPage.ets | ClassmatesListActivity | todo |  |
| CommonLaunchPage.ets | CommonLaunchActivity | todo |  |
| ContactClassAddressBookPage.ets | ContactClassAddressBookActivity | todo |  |
| ContactPage.ets | ContactFragment+ContactSubFragment+ContactExpanAdapter | done | getInitData/getStudentInitData/delTopContact/addTopContact 已接；端点=/mobileapi_ydxy/api/addressbook/*（ContactFactory 实证）；黄页分支降级为入口行 |
| ContactPersonalDetailPage.ets | ContactPersonalDetailActivity | todo |  |
| ContactSearchPage.ets | ContactSearchActivity | todo |  |
| ContactYellowListPage.ets | ? | no-source |  |
| ContactYellowPage.ets | ContactYellowActivity | todo |  |
| ContactYellowTypePage.ets | ContactYellowTypeActivity | todo |  |
| CourseDetailPage.ets | CourseDetailActivity | todo |  |
| CustomTimetablePage.ets | CustomTimetableActivity | todo |  |
| DemoPage.ets | ? | no-source |  |
| DepartmentListPage.ets | DepartmentListActivity | todo |  |
| DocNumberPage.ets | DocNumberActivity | todo |  |
| DownloadAddressPage.ets | ? | no-source |  |
| DownloadDialogPage.ets | ? | no-source |  |
| EditCommonAppPage.ets | EditCommonAppActivity | todo |  |
| EditCommonAppSearchPage.ets | EditCommonAppSearchActivity | todo |  |
| EditCoursePage.ets | EditCourseActivity | todo |  |
| EditTodoDetailPage.ets | EditTodoDetailActivity | todo |  |
| EmcMessageDetailPage.ets | EmcMessageDetailActivity | todo |  |
| EndisableServicePage.ets | ? | no-source |  |
| ExamAddListPage.ets | ? | no-source |  |
| ExamPage.ets | AddExamListActivity 等6个 | todo |  |
| FeedbackPage.ets | FeedbackActivity(lyyd/feedback) | done | 原生页非H5；types/announcement 接口照调（tvQuestion 源码恒 gone）；提交 POST_MULTIPART submit/ciphertext（data=固定key AES 密文原样，j=false 无外层加密+imgs 文件，key VmxNbUkzTkRBdE5UWmpNaQ==）；成功 toast+back；右上"反馈记录"→FeedbackRecordPage |
| FeedbackRecordPage.ets | FeedbackRecordActivity | done | records/ciphertext data=固定key AES {userId,xxdm}（j=false 普通 query 对，无外层加密）；状态文案 getStateString(0-4)；时间 e.f13232a "yyyy-MM-dd HH:mm"；空态 MultiStateView；item 点击→FeedbackDetailActivity 详情页未实现（范围外） |
| FileManagerPage.ets | FileManagerActivity | partial | 空态对齐 |
| FingerBindDevicePage.ets | FingerBindDeviceActivity | todo |  |
| FingerLoginPage.ets | FingerLoginActivity | todo |  |
| FontSizePage.ets | FontSizeSettingActivity | todo |  |
| FriendUserListPage.ets | ? | no-source |  |
| GesturePwdSettingPage.ets | GesturePwdSettingActivity | todo |  |
| GesturePwdVerifyPage.ets | GesturePwdVerifyActivity | todo |  |
| GradeRankPage.ets | ? | no-source |  |
| HandleExamCoursePage.ets | HandleExamCourseActivity | todo |  |
| HomeFunctionDialogPage.ets | ? | no-source |  |
| Index.ets | MainActivity + MainFragment | partial | 底栏3Tab已修复；主页Fragment内容见WMH/ICampus/IOffice |
| InputEmailPage.ets | MobileCampusInputEmailActivity | todo |  |
| InputIdentifyCodeChangePage.ets | ? | no-source |  |
| InputIdentifyCodePage.ets | InputIdentifyCodeActivity | todo |  |
| InputPhonePage.ets | MobileCampusInputPhoneActivity | todo |  |
| InspectionNewPage.ets | ? | no-source |  |
| InspectionPage.ets | InspectionActivity | todo |  |
| InspectionRankPage.ets | InspectionRankListActivity 等2个 | todo |  |
| InspectionRecordPage.ets | InspectionRecordActivity | todo |  |
| IssueReviewPage.ets | ? | no-source |  |
| KeywordSearchPage.ets | KeywordSearchActivity | todo |  |
| LightAppPage.ets | LightActivity(1080行)+AppsFactory | done | WebView+认证头注入+yyid参数，源码加载公式1:1 |
| LoginPage.ets | MobileCampusLoginNewActivity | done | 登录页实拍+源码混合，可用 |
| LoginedLaunchPage.ets | LoginedLaunchActivity | todo |  |
| MainNotificationPage.ets | MainNotificationActivity | todo |  |
| MainSettingPage.ets | MainSettingActivity | todo |  |
| MarkDetailPage.ets | MarkDetailActivity | todo |  |
| MarketPage.ets | MarketActivity 等2个 | todo |  |
| MarketPostPage.ets | MarketPostActivity | todo |  |
| MeetingAddPage.ets | ? | no-source |  |
| MeetingAnnouncementPage.ets | MeetingAnnouncementActivity | todo |  |
| MeetingAttendPage.ets | MeetingAttendActivity | todo |  |
| MeetingDetailPage.ets | MeetingDetailActivity | todo |  |
| MeetingMainActivity.ets | MeetingMainActivity | todo |  |
| MeetingPage.ets | MeetingActivity | done | MeetingActivity(转发MeetingMainActivity)+MeetingMainActivity+MeetingArrangementFragment+MeetingWeekPlanFragment 源码级翻译：getMeetTab 建"我的会议/周程会议"页签；我的会议=getJoinList 分组（past组可收起）+getPastList 20/页上拉+子项状态角标/报告/必须参加；周程=getCurrentOrWeek+termInfoForTeacher 算当前周+getWeekPlan{week偏移}+44dip 周翻页7日期格（SDGY 周一开头）；失败空态 |
| MeetingPersonDetailPage.ets | ? | no-source |  |
| MeetingReportEditPage.ets | MeetingReportEditActivity | todo |  |
| MeetingReportPage.ets | MeetingReportEditActivity 等2个 | todo |  |
| MeetingSelectorPage.ets | MeetingSelectorActivity | todo |  |
| MeetingSignPage.ets | MeetingSignActivity | todo |  |
| MeetingStaffSituationPage.ets | MeetingStaffSituationActivity | todo |  |
| MeetingWeekPlanPage.ets | MeetingWeekPlanFragment | todo |  |
| MessageListPage.ets | MessageListActivity 等2个 | done | MessageListActivity+MessageFragment 源码级翻译版：MToolBar/MagicIndicator/Swiper 多页签（messages_page_tabs=="2"→未读/已读，否则全部消息）；getDateMessage{stateCode,page} 15/页分页；点击标记已读 updateState{xlh,batchId}、EMC/无LX→EmcMessageDetailPage、EXT.LX 分流（16→详情 2/4/6/8/15→WebViewPage 5→请先安装应用 1/7→路由toast）；长按删单条 delete{xlh,isEmc}；SystemSwitch 三开关（all_messages_read/all_messages_delete/batch_messages_delete，HAP未持久化→null分支单页签）；编辑模式批量删除 batchdelete{xlhs} + 全部删除 alldelete{stateCode 3/1/2} + 全部已读 allUpdateState；MessagePopupDialog 菜单/错误/空态复刻 |
| MinePage.ets | MyPageFragment | done | MineTab=MyPageFragment 翻译版 |
| MipushPage.ets | MipushTestActivity | todo |  |
| MobileCampusLaunchPage.ets | ? | no-source |  |
| ModifyPasswordPage.ets | ModifyPwdActivity | done | 原生表单非H5：账号行+原密码+新密(6-12位)+确认；POST changePasswByOldPassw{passw,passwNew,passwNewAgain}；1020-1024→errorTips 其余 toast；成功弹窗2s后 logout；入口链路 MyPageFragment.c2 先查 getChangePasswUrlFromSchool 分派(type 0/1/2)，端点已备 GET_CHANGE_PASSW_URL |
| MyPostPage.ets | MyPostActivity | todo |  |
| NetTrafficReportPage.ets | ? | no-source |  |
| NewsDetailPage.ets | ? | no-source |  |
| NewsPage.ets | NewsFragment + NewsActivity | done | 源码级翻译（主体=NewsFragment）：K1():865 loadUrl(s.g("lapp/springboard")+"?yyid="+YYID, map)；yyid="bodaNews"（MainActivity.f1:1392 AppBean.setYYID，isH5=false）；headers=Access-Token(AES(HeadParamsEntity 4字段, 协商key)←e2()+BaseSecretUtil.i)+Unique-Code(会话UC)；WebViewClient 全链（amap/baidu 放行、tel 拨号、sms 短信、/seeyon/rest/attachment/file/ 拦截、lianyi/tmast 拦截、alipay/bankabc/weixin 外跳）；WebChromeClient 进度条(100隐藏)+geolocation invoke；onPageFinished canGoBack→ivBack；ybgLightApp JS 桥（clickOnAndroid/System→funFromjs 定位回调、openBrowser、closeWindow/signInSuccess 空实现、commitShare/JsUpdateBadgeNum 日志；文件/录音选择为 Android 特有未接）；MultiStateView loading/error；d2()/g2() 清缓存按源码 no-op。NewsActivity 的 ZhyBean 动态列表为 CenterDetail 二级页（入口未翻译，页面结构见旧复刻已废弃）。E1 验收修复：Unique-Code 改 onlyCode（源码 d.a.d()）、AT 四字段去 '1'/'sdmu' 兜底 |
| OaIssueApplyPage.ets | ? | no-source |  |
| OaIssueDetailPage.ets | ? | no-source |  |
| OaIssueNotificationPage.ets | ? | no-source |  |
| OaIssuePage.ets | ? | no-source |  |
| OaIssuePushPage.ets | ? | no-source |  |
| PersonalDetailNewPage.ets | PersonalDetailNewActivity | delete | 旧 XML 复刻版，被源码级 PersonalDetailPage 取代 |
| PersonalDetailPage.ets | PersonalDetailNewActivity | done | getUserInfo 接口+渲染全对齐 |
| PhotoPagerPage.ets | PhotoPagerActivity | todo |  |
| PhotoPickerPage.ets | PhotoPickerActivity 等2个 | todo |  |
| PolymerizationPage.ets | PolymerizationActivity | todo |  |
| PopupWindowPage.ets | ? | no-source |  |
| PostDetailPage.ets | PostDetailActivity | todo |  |
| PostPublishPage.ets | PostPublishActivity | todo |  |
| PrivacySettingsPage.ets | ? | no-source |  |
| PrivacyTextPage.ets | ? | no-source |  |
| ProgramDetailPage.ets | ? | no-source |  |
| ProgramListPage.ets | ProgramListActivity | todo |  |
| QrCodeScanPage.ets | ScanLoginActivity | partial | 扫码页 |
| QrCodeScanResultPage.ets | QrCodeScanResultActivity | todo |  |
| ReadingDetailPage.ets | MobileCampusReadingDetailActivity | todo |  |
| ReadingPage.ets | MobileCampusReadingActivity 等2个 | todo |  |
| ReadingSearchPage.ets | MobileCampusReadingSearchActivity | todo |  |
| ReadonlyTextPage.ets | ? | no-source |  |
| ReceiptAssistPage.ets | ReceiptAssistActivity 等2个 | todo |  |
| ReceiptDetailPage.ets | ? | no-source |  |
| ReceiptImagePage.ets | ? | no-source |  |
| ReceiptListPage.ets | ReceiptListActivity | todo |  |
| ReimburseLaunchPage.ets | ReimburseLaunchActivity | todo |  |
| ScanLoginPage.ets | ScanLoginActivity | todo |  |
| ScheduleAddPage.ets | ? | no-source |  |
| ScheduleDetailPage.ets | ScheduleDetailActivity | todo |  |
| ScheduleLaunchPage.ets | ScheduleLaunchActivity | todo |  |
| ScheduleMainActivity.ets | ScheduleMainActivity | todo |  |
| SchedulePage.ets | TimetableActivity+WeekCourseFragment+CourseBox+ChooseWeeksPopup/ChooseTermDialog | done | 源码级UI对齐：周次弹窗(1-25周/“(本周)”标记/当前周高亮common_color_7/scrollTo(cur-3))；上下周切换按钮；日期条“dd\n周X”+每月1日显“MM月”+今日列17fp#18B4ED+底线；周次zcd过滤(“1-16/1,3/单双”)；格子55vp节次轴50vp+showcolor1..14按课名分配+重叠折叠multi_tag角标+点击详情/多课3列弹窗；FAB组45°旋转展开custom→AddCoursePage/audit→ChooseAcademyPage；ChooseTermDialog学年学期；脚注*课表数据以教务单位提供为准；源码无月/周视图切换(timetable_tv_month为静态月份) |
| ScheduleWeekDetailPage.ets | ? | no-source |  |
| SchoolCircleEntryPage.ets | ? | no-source |  |
| SchoolMapPage.ets | ? | no-source |  |
| SchoolSceneryPage.ets | SchoolSceneryActivity 等2个 | todo |  |
| SchoolSituationPage.ets | SchoolSituationActivity | todo |  |
| ScoreChartPage.ets | ? | no-source |  |
| ScoreCommentDialogPage.ets | ? | no-source |  |
| ScoreCommentPage.ets | ScoreCommentListActivity 等3个 | todo |  |
| ScoreCommentPostPage.ets | ScoreCommentPostActivity | todo |  |
| ScoreHistoryPage.ets | ? | no-source |  |
| ScorePage.ets | ScoreMainActivity+ScoreMainFragment+ScoreModel | done | getSemester/hasSubject实测通；三段ECharts WebView按code分流 |
| SettingPage.ets | SettingActivity | todo |  |
| SocialHomePage.ets | ? | no-source |  |
| SocialLaunchPage.ets | ? | no-source |  |
| SocialMessagePage.ets | SocialMessageActivity | todo |  |
| SocialNewNewsPage.ets | ? | no-source |  |
| SocialNewsPage.ets | ? | no-source |  |
| SocialReportPage.ets | ? | no-source |  |
| SortDialogPage.ets | ? | no-source |  |
| SportStepsHistoryPage.ets | SportStepsHistoryActivity | todo |  |
| SportStepsRankPage.ets | SportStepsRankingsActivity 等2个 | todo |  |
| SportStepsSettingPage.ets | SportStepsSettingActivity | todo |  |
| SsoLoginPage.ets | ? | no-source |  |
| StudentListPage.ets | StudentListActivity 等2个 | todo |  |
| StudentReportHomePage.ets | ? | no-source |  |
| StudentScoreDetailPage.ets | ? | no-source |  |
| StudentScorePage.ets | StudentScoreActivity | todo |  |
| StudyReportDetailPage.ets | ? | no-source |  |
| SuperviseAddPage.ets | ? | no-source |  |
| SuperviseComingPage.ets | ? | no-source |  |
| SuperviseEvaluatePage.ets | SuperviseEvaluateActivity | todo |  |
| SuperviseFilterPage.ets | SuperviseFilterActivity | todo |  |
| SuperviseFinishedPage.ets | ? | no-source |  |
| SuperviseLaunchPage.ets | SuperviseLaunchActivity | todo |  |
| SuperviseLectureDetailPage.ets | ? | no-source |  |
| SuperviseMinePage.ets | SuperviseMineActivity | todo |  |
| SupervisePage.ets | SuperviseEditActivity 等12个 | todo |  |
| SuperviseSearchPage.ets | SuperviseSearchActivity | todo |  |
| TestWebViewPage.ets | TestWebviewActivity | todo |  |
| TimeTableLoginPage.ets | TimeTableLoginActivity | todo |  |
| TimetableLeaveDetailPage.ets | ? | no-source |  |
| TodoDepartmentPage.ets | ? | no-source |  |
| TodoFastReplyPage.ets | TodoFastreplyActivity | todo |  |
| TodoPage.ets | TodoMainActivity + TodoFragment + TodoModel/TodoPImpl | done | 源码级翻译。list 数据流还原：GET java/todoitem/list，参数放加密 data={pageSize:"10",pageNum,rule:<TodoTab.BPM_GZ>}（rule←com.heytap.mcssdk.constant.b.p，明文query会0001）；tab 实测五分类 R_S017_B002/003/004/067/034；MessageChannelBean 仅用于关注弹窗非列表数据源；rows 全字段 unescapeHtml3（TodoUtils.o）；点击 appid!=ydbg toast，ydbg→TodoReadPage 带 type+bean |
| TodoPersonSelectedPage.ets | ? | no-source |  |
| TodoProcedureOtherPage.ets | TodoProcedureOtherActivity | todo |  |
| TodoReadPage.ets | TodoReadActivity | todo |  |
| TodoSearchDepartmentPage.ets | TodoSearchDepartmentActivity | todo |  |
| TodoSearchPage.ets | TodoSearchActivity | todo |  |
| TodoSupervisePage.ets | ? | no-source |  |
| TouristModePage.ets | ? | no-source |  |
| UnifyNotificationPage.ets | ? | no-source |  |
| UpdateBackgroundPage.ets | UpdateBackgroundActivity | todo |  |
| UserDetailPage.ets | UserDetailActivity | todo |  |
| WebViewPage.ets | WebViewActivity 等2个 | todo |  |
| WorkApplyDetailPage.ets | WorkApplyDetailActivity | todo |  |
| WorkApplyEditPage.ets | WorkApplyEditActivity | todo |  |
| WorkApplyFormConfigPage.ets | WorkApplyFormConfigActivity | todo |  |
| WorkApplyMorePage.ets | WorkApplyMoreActivity | todo |  |
| WorkApplyPage.ets | WorkApplyActivity | todo |  |
| WorkApplyScreenPage.ets | WorkApplyScreenActivity | todo |  |
| YiBanPage.ets | YiBanFragment | todo |  |
| YiMiaoMiaoDetailPage.ets | YiMiaoMiaoDetailActivity | todo |  |
| ZhyCenterPage.ets | ? | no-source |  |
| ZhyFourPage.ets | ? | no-source |  |

统计：done=15 todo=117 partial=3 no-source=68 共=203