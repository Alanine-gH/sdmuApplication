import { ApiResponse } from '../model/ResponseModel';
import { UserInfo } from '../model/UserModel';
import { NewsItem } from '../model/NewsModel';
import { CourseItem } from '../model/CourseModel';
import { TodoItem } from '../model/TodoModel';
import { ContactItem } from '../model/ContactModel';
import { ScoreItem, ExamItem } from '../model/ScoreModel';
import { MeetingItem } from '../model/MeetingModel';
import { AttendanceItem } from '../model/AttendanceModel';

/**
 * API 服务层：当前服务器不可达，所有方法直接返回本地模拟数据（成功状态）。
 * 保留 HttpClient 引用供后续真实接入时替换。
 */
export class ApiService {
  static async login(account: string, password: string): Promise<ApiResponse<UserInfo>> {
    const user: UserInfo = new UserInfo(
      'U20230001', '张明理', '20230001', '计算机2301班', '信息工程学院', '计算机科学与技术', '2023级',
      '13800001234', 'zhangml@sdmu.edu.cn', '', 'mock-token-' + account);
    return new ApiResponse<UserInfo>(0, 'success', user);
  }

  static async getUserInfo(userId: string): Promise<ApiResponse<UserInfo>> {
    const user: UserInfo = new UserInfo(
      userId, '张明理', '20230001', '计算机2301班', '信息工程学院', '计算机科学与技术', '2023级',
      '13800001234', 'zhangml@sdmu.edu.cn', '', 'mock-token');
    return new ApiResponse<UserInfo>(0, 'success', user);
  }

  static async getNewsList(): Promise<ApiResponse<NewsItem[]>> {
    const list: NewsItem[] = [
      new NewsItem('N1', '学校召开2026年秋季学期教学工作部署会',
        '11月10日上午，学校在明德楼会议室召开2026年秋季学期教学工作部署会，校领导及各学院负责人参加会议。',
        '11月10日上午，学校在明德楼会议室召开2026年秋季学期教学工作部署会。会议全面总结了上一阶段教学工作取得的成果，深入分析了当前教学中存在的问题，并对下一阶段重点任务作出部署。校党委书记强调，要坚持以人才培养为中心，深化教学改革，提升课堂教学质量。各学院要结合自身实际，制定具体实施方案，确保各项任务落地见效。教务处负责人通报了期中教学检查情况，并就课程建设、专业认证、实践教学等工作提出具体要求。',
        '教务处', '2026-11-10 14:30', '', '', '通知公告'),
      new NewsItem('N2', '我校学子在全国大学生数学建模竞赛中获佳绩',
        '近日，2026年全国大学生数学建模竞赛成绩揭晓，我校代表队获得全国一等奖1项、二等奖2项的优异成绩。',
        '近日，2026年全国大学生数学建模竞赛成绩揭晓，我校代表队获得全国一等奖1项、二等奖2项的优异成绩。本次竞赛吸引了全国1600余所高校参赛。我校高度重视学科竞赛工作，自4月份启动培训以来，指导教师团队利用周末和暑期开展系统训练。参赛同学刻苦钻研、团结协作，充分展现了我校学生扎实的专业基础和良好的创新实践能力。',
        '学生工作处', '2026-11-08 09:00', '', '', '校园动态'),
      new NewsItem('N3', '图书馆关于延长开放时间的通知',
        '为满足广大师生期末复习备考需求，图书馆自11月15日起延长自习区开放时间至每晚23:00。',
        '为满足广大师生期末复习备考需求，图书馆经研究决定，自11月15日起至本学期末，图书馆自习区开放时间延长至每晚23:00，其中一层自习室实行24小时开放。请同学们自觉遵守图书馆各项管理规定，保持安静，爱护公物，共同维护良好的学习环境。如有疑问请联系图书馆办公室，电话0531-88951234。',
        '图书馆', '2026-11-06 16:20', '', '', '通知公告'),
      new NewsItem('N4', '我校举办第十八届校园文化艺术节',
        '11月5日晚，学校第十八届校园文化艺术节开幕式在大学生活动中心隆重举行，全校师生代表千余人参加。',
        '11月5日晚，学校第十八届校园文化艺术节开幕式在大学生活动中心隆重举行。本届艺术节以"青春绽放，梦想启航"为主题，为期一个月，将陆续举办合唱比赛、舞蹈大赛、书画展、话剧专场等十余项活动。开幕式上，各学院带来了精彩纷呈的文艺表演，现场气氛热烈。校园文化艺术节是我校校园文化建设的品牌活动，已连续举办十八届，深受广大师生喜爱。',
        '校团委', '2026-11-05 21:10', '', '', '校园动态'),
      new NewsItem('N5', '关于2026年下半年全国大学英语四六级考试报名的通知',
        '2026年下半年全国大学英语四、六级考试将于12月19日举行，请符合条件的同学于11月20日前完成报名。',
        '2026年下半年全国大学英语四、六级考试（笔试）将于12月19日举行。报名工作采取网上报名方式，请符合条件的同学在11月20日前登录全国大学英语四六级考试报名网站完成报名和缴费。逾期不予补报。请报名同学合理安排复习时间，按时参加考试。考试具体安排请关注教务处后续通知。',
        '教务处', '2026-11-04 10:00', '', '', '考试安排'),
      new NewsItem('N6', '我校与多家企业签署产学研合作协议',
        '11月3日，学校举行产学研合作签约仪式，与12家企业签署合作协议，进一步深化校企合作。',
        '11月3日，学校产学研合作签约仪式在行政楼会议室举行。校长代表学校与12家企业代表签署合作协议，内容涵盖共建实习实训基地、联合培养应用型人才、协同开展技术攻关等多个方面。校长指出，深化产教融合、校企合作是应用型本科高校建设的必由之路。学校将以此次签约为契机，进一步创新合作机制，提升服务地方经济社会发展的能力。',
        '合作发展处', '2026-11-03 18:45', '', '', '校园动态')
    ];
    return new ApiResponse<NewsItem[]>(0, 'success', list);
  }

  static async getNewsDetail(id: string): Promise<ApiResponse<NewsItem>> {
    const response: ApiResponse<NewsItem[]> = await ApiService.getNewsList();
    let detail: NewsItem = new NewsItem(id, '新闻详情', '', '暂无详细内容', '', '', '', '', '');
    for (const item of response.data) {
      if (item.id === id) {
        detail = item;
      }
    }
    return new ApiResponse<NewsItem>(0, 'success', detail);
  }

  static async getScheduleList(): Promise<ApiResponse<CourseItem[]>> {
    const list: CourseItem[] = [
      new CourseItem('C1', '高等数学(下)', '王立华', '明德楼201', '1-16周', 1, 1, 2, 4.0, '必修'),
      new CourseItem('C2', '大学英语(三)', '李芳', '博文楼105', '1-16周', 2, 1, 2, 3.0, '必修'),
      new CourseItem('C3', '数据结构', '赵建国', '实训楼302', '1-16周', 3, 3, 4, 4.0, '必修'),
      new CourseItem('C4', '计算机网络', '陈晓燕', '明德楼315', '1-16周', 1, 3, 4, 3.5, '必修'),
      new CourseItem('C5', '操作系统', '刘志强', '博文楼210', '1-16周', 2, 5, 6, 3.5, '必修'),
      new CourseItem('C6', '体育(三)', '孙伟', '体育馆', '1-16周', 4, 3, 4, 1.0, '必修'),
      new CourseItem('C7', '马克思主义基本原理', '周文静', '明德楼101', '1-16周', 5, 1, 2, 3.0, '必修'),
      new CourseItem('C8', 'Java程序设计', '赵建国', '实训楼305', '1-16周', 4, 6, 7, 3.0, '选修'),
      new CourseItem('C9', '数据库原理', '陈晓燕', '明德楼408', '1-16周', 3, 8, 9, 3.5, '必修')
    ];
    return new ApiResponse<CourseItem[]>(0, 'success', list);
  }

  static async getTodoList(): Promise<ApiResponse<TodoItem[]>> {
    const list: TodoItem[] = [
      new TodoItem('T1', '关于填报2026年度教师工作量统计表的通知', '0', '待办', '2026-11-20 17:00', '高', '教务处',
        '各位老师请于11月20日17:00前登录OA系统完成本年度工作量填报，逾期系统将关闭。'),
      new TodoItem('T2', '2026年秋季学期期中教学检查意见反馈', '0', '待办', '2026-11-25 12:00', '中', '质量监控中心',
        '请各学院教学秘书汇总期中教学检查情况，形成书面报告后在线提交。'),
      new TodoItem('T3', '实验室安全知识在线学习任务', '0', '待办', '2026-11-30 23:59', '中', '实验室管理处',
        '全体师生须在规定时间内完成实验室安全知识在线课程学习并通过测试。'),
      new TodoItem('T4', '教职工体检通知确认', '1', '已办', '2026-11-05 18:00', '低', '校工会',
        '请确认体检时间安排，如需调整请在规定时间内联系校工会。'),
      new TodoItem('T5', '科研项目申报材料提交', '0', '待办', '2026-12-01 17:30', '高', '科研处',
        '2027年度校级科研项目申报截止时间为12月1日，请申报教师按时提交材料。'),
      new TodoItem('T6', '第十二周教学例会通知', '1', '已办', '2026-11-11 14:30', '中', '教务处',
        '请全体教学管理人员准时参加第十二周教学例会。')
    ];
    return new ApiResponse<TodoItem[]>(0, 'success', list);
  }

  static async getContactList(): Promise<ApiResponse<ContactItem[]>> {
    const list: ContactItem[] = [
      new ContactItem('CT1', '张明理', '信息工程学院', '0531-88951001', 'zhangml@sdmu.edu.cn', '院长', ''),
      new ContactItem('CT2', '王立华', '信息工程学院', '0531-88951002', 'wanglh@sdmu.edu.cn', '副院长', ''),
      new ContactItem('CT3', '赵建国', '信息工程学院', '0531-88951003', 'zhaojg@sdmu.edu.cn', '系主任', ''),
      new ContactItem('CT4', '李芳', '外国语学院', '0531-88952001', 'lifang@sdmu.edu.cn', '教学秘书', ''),
      new ContactItem('CT5', '陈晓燕', '外国语学院', '0531-88952002', 'chenxy@sdmu.edu.cn', '讲师', ''),
      new ContactItem('CT6', '刘志强', '会计学院', '0531-88953001', 'liuzq@sdmu.edu.cn', '党委副书记', ''),
      new ContactItem('CT7', '周文静', '会计学院', '0531-88953002', 'zhouwj@sdmu.edu.cn', '辅导员', ''),
      new ContactItem('CT8', '孙伟', '教务处', '0531-88954001', 'sunwei@sdmu.edu.cn', '处长', ''),
      new ContactItem('CT9', '吴秀兰', '教务处', '0531-88954002', 'wuxl@sdmu.edu.cn', '科员', ''),
      new ContactItem('CT10', '郑海涛', '学生工作处', '0531-88955001', 'zhenght@sdmu.edu.cn', '副处长', '')
    ];
    return new ApiResponse<ContactItem[]>(0, 'success', list);
  }

  static async getScoreList(): Promise<ApiResponse<ScoreItem[]>> {
    const list: ScoreItem[] = [
      new ScoreItem('S1', '高等数学(上)', 92, 4.0, 3.9, '2025-2026-1', '必修'),
      new ScoreItem('S2', '大学英语(二)', 85, 3.0, 3.5, '2025-2026-1', '必修'),
      new ScoreItem('S3', 'C语言程序设计', 95, 4.0, 4.0, '2025-2026-1', '必修'),
      new ScoreItem('S4', '大学物理', 78, 3.0, 2.8, '2025-2026-1', '必修'),
      new ScoreItem('S5', '高等数学(下)', 88, 4.0, 3.7, '2025-2026-2', '必修'),
      new ScoreItem('S6', '数据结构', 91, 4.0, 3.9, '2025-2026-2', '必修'),
      new ScoreItem('S7', '大学英语(三)', 82, 3.0, 3.2, '2025-2026-2', '必修'),
      new ScoreItem('S8', 'Web前端开发', 56, 3.0, 0.0, '2025-2026-2', '选修'),
      new ScoreItem('S9', '线性代数', 90, 3.0, 3.8, '2026-2027-1', '必修'),
      new ScoreItem('S10', '计算机网络', 87, 3.5, 3.5, '2026-2027-1', '必修')
    ];
    return new ApiResponse<ScoreItem[]>(0, 'success', list);
  }

  static async getExamList(): Promise<ApiResponse<ExamItem[]>> {
    const list: ExamItem[] = [
      new ExamItem('E1', '高等数学(下)', '2026-12-20 09:00-11:00', '明德楼201考场', '闭卷笔试'),
      new ExamItem('E2', '数据结构', '2026-12-21 14:00-16:00', '实训楼302考场', '闭卷笔试'),
      new ExamItem('E3', '大学英语(三)', '2026-12-22 09:00-11:00', '博文楼105考场', '闭卷笔试'),
      new ExamItem('E4', '计算机网络', '2026-12-23 14:00-16:00', '明德楼315考场', '闭卷笔试'),
      new ExamItem('E5', '操作系统', '2026-12-24 09:00-11:00', '博文楼210考场', '闭卷笔试'),
      new ExamItem('E6', '数据库原理', '2026-12-25 14:00-16:00', '明德楼408考场', '闭卷笔试')
    ];
    return new ApiResponse<ExamItem[]>(0, 'success', list);
  }

  static async getMeetingList(): Promise<ApiResponse<MeetingItem[]>> {
    const list: MeetingItem[] = [
      new MeetingItem('M1', '2026年秋季学期期末教学工作部署会', '2026-11-18 14:30', '行政楼三楼会议室', '0',
        '教务处', '部署期末考试安排、成绩录入及下学期教学准备工作。请各学院教学负责人准时参加并做好会议记录。'),
      new MeetingItem('M2', '信息工程学院学科建设研讨会', '2026-11-16 10:00', '明德楼501会议室', '1',
        '信息工程学院', '研讨计算机科学与技术专业一流课程建设方案，审定2027版人才培养方案修订稿。'),
      new MeetingItem('M3', '校园安全工作联席会议', '2026-11-14 15:00', '行政楼一楼报告厅', '2',
        '保卫处', '通报近期校园安全检查情况，部署冬季消防安全专项工作。'),
      new MeetingItem('M4', '学生工作例会', '2026-11-20 16:00', '大学生活动中心202', '0',
        '学生工作处', '布置期中学生座谈、心理健康普查及资助育人等工作。'),
      new MeetingItem('M5', '图书馆管理委员会年度会议', '2026-11-08 09:30', '图书馆会议室', '2',
        '图书馆', '总结年度工作，审议文献资源采购计划及延长开放时间方案。')
    ];
    return new ApiResponse<MeetingItem[]>(0, 'success', list);
  }

  static async getMeetingDetail(id: string): Promise<ApiResponse<MeetingItem>> {
    const response: ApiResponse<MeetingItem[]> = await ApiService.getMeetingList();
    let detail: MeetingItem = new MeetingItem(id, '会议详情', '', '', '2', '', '暂无详细内容');
    for (const item of response.data) {
      if (item.id === id) {
        detail = item;
      }
    }
    return new ApiResponse<MeetingItem>(0, 'success', detail);
  }

  static async getAttendanceList(): Promise<ApiResponse<AttendanceItem[]>> {
    const list: AttendanceItem[] = [
      new AttendanceItem('A1', '数据结构', '正常', '2026-11-14 08:00', '课堂考勤', '实训楼302'),
      new AttendanceItem('A2', '高等数学(下)', '正常', '2026-11-13 08:00', '课堂考勤', '明德楼201'),
      new AttendanceItem('A3', '大学英语(三)', '迟到', '2026-11-12 10:10', '课堂考勤', '博文楼105'),
      new AttendanceItem('A4', '计算机网络', '正常', '2026-11-11 14:00', '课堂考勤', '明德楼315'),
      new AttendanceItem('A5', '操作系统', '缺勤', '2026-11-10 14:00', '课堂考勤', '博文楼210'),
      new AttendanceItem('A6', '体育(三)', '正常', '2026-11-10 10:00', '课堂考勤', '体育馆'),
      new AttendanceItem('A7', '数据库原理', '正常', '2026-11-07 16:00', '课堂考勤', '明德楼408'),
      new AttendanceItem('A8', 'Java程序设计', '迟到', '2026-11-06 19:00', '晚自习考勤', '实训楼305')
    ];
    return new ApiResponse<AttendanceItem[]>(0, 'success', list);
  }
}
