import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { TitleBar } from '../components/TitleBar';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { AuditAcademyEntry, AuditControlParams } from '../model/CourseModel';
import { PreferencesUtil } from '../data/PreferencesUtil';

/**
 * 蹭课学院选择页 — 1:1 复刻 timetable/view/ChooseAcademyActivity.java（页名 course_audit，
 * TimetableActivity 审核按钮 course_click_addclass 入口 → HAP SchedulePage FAB audit）
 *
 * 源码还原的 UI 与数据链：
 *   1. 布局 mobile_campus_timetable_activity_chooseacademy.xml：toolbar_normal（标题 audit_course
 *      "蹭课"）+ 搜索框 FrameLayout(ybg_white，padding T/B 10vp；search_box marginH 10vp，
 *      圆角 6vp #E7E7E7、search_grey 前置图标、hint audit_course_search_course_tips、16fp)
 *      + divider_horizontal_grey_normal(8vp #F2F2F2) + 内层 MultiStateView(VaryingBubbles)
 *   2. VaryingBubbles 气泡（smali 校正公式）：气泡尺寸=容器高 H 的比例——large=0.35H medium=0.28H
 *      small=0.25H mini=small/1.3 superMini=mini/1.8 partWidth=2.8*large；每 part 9 个学院气泡
 *      （首个 part case=4,5,3,6,2,7,1,8,0；奇数 part case=8-j；其余偶数 part case=j）+ 5 个装饰
 *      小泡（mini*3+superMini*2，固定偏移）；气泡=blue_circle_with_shadow 底白字 2 行省略居中；
 *      超出学院数的气泡只显示底图；水平滚动，初滚 x=(partCount*PW)/2-(partCount%2==0?PW:PW/2)
 *   3. 数据：l.b() getCkColleges → 气泡（实测 9 学院）；l.c() ckControl → isSupport* 持久化
 *      （TimetableAuditCourseSharePreferencesUtil 键 isSupportAuditCourseSearchFilter/TimeFilter）；
 *      l.d() searchSchedule → data=纯文本 hint → "请输入"+hint（实测 '课程名称,老师,教室'）+
 *      持久化 supportSearchCourseKeyType
 *   4. 搜索：afterTextChanged 空 → U2() 重置全量；IME actionSearch → setSearchKey(true) →
 *      T2()：跳 timetable AddCourseActivity（审核课程列表，映射表标注范围外未翻译）——HAP 保留
 *      源码状态语义，路由待该页落地补全
 *   5. 气泡点击 → ChooseCourseActivity{academy}（HAP ChooseCoursePage 带 xydm/xymc）
 *   6. 空态 Page.EMPTY（no_report 图 + R.string.empty 空文案）；错误 Page.ERROR（empty_error 图）
 */
const BUBBLE_AREA_PAD: number = 38;
const PART_VALID_BUBBLES: number = 9;
const PART_DECOR_BUBBLES: number = 5;
const BUBBLE_GAP: number = 4;
const BUBBLE_TEXT_PAD: number = 6;
const BUBBLE_FONT: number = 14;
const PREF_AUDIT_SUPPORT_SEARCH: string = 'audit_is_support_search_filter';
const PREF_AUDIT_SEARCH_KEY_TYPE: string = 'audit_search_course_key_type';

/** 气泡渲染单元（位置/尺寸/文案/索引；label='' 表示装饰泡仅底图） */
class BubbleCell {
  x: number;
  y: number;
  size: number;
  label: string;
  index: number;

  constructor(x: number, y: number, size: number, label: string, index: number) {
    this.x = x;
    this.y = y;
    this.size = size;
    this.label = label;
    this.index = index;
  }
}

@Entry
@Component
struct ChooseAcademyPage {
  @State academies: AuditAcademyEntry[] = [];
  @State filtered: AuditAcademyEntry[] = [];
  @State bubbles: BubbleCell[] = [];
  @State hint: string = '请输入课程名称';
  @State searchKey: string = '';
  @State loadState: number = 0; // 0=content 1=loading 2=empty 3=error
  @State errorTips: string = '';
  private bubbleAreaHeight: number = 0;
  private containerWidth: number = 0;
  private bubbleScroller: Scroller = new Scroller();

  aboutToAppear(): void {
    this.loadAcademies();
  }

  /** f1：l.b() 学院气泡 + l.c() ckControl 持久化 + l.d() searchSchedule hint 持久化 */
  private async loadAcademies(): Promise<void> {
    this.loadState = 1;
    // k(str)（d 失败分支）：缓存 hint 优先，网络成功后覆盖（f.c.e 同键回读）
    try {
      const cachedHint: string = await PreferencesUtil.getString(PREF_AUDIT_SEARCH_KEY_TYPE, '');
      if (cachedHint !== '') {
        this.hint = '请输入' + cachedHint;
      }
    } catch (error) {
      const be = error as BusinessError;
      ApiService.logError('CA readHint fail: ' + be.message);
    }
    const academyResp: ApiResponse<AuditAcademyEntry[]> = await ApiService.getCkColleges();
    if (academyResp.code === 0 && academyResp.data.length > 0) {
      this.applyAcademies(academyResp.data);
    } else if (academyResp.code === 0) {
      // g 回调 arrayList==null 分支：f0("没有其它院校信息")；空数组按 Page.EMPTY 空态
      this.loadState = 2;
    } else {
      this.errorTips = academyResp.message === '' ? '服务器正和程序猿闹脾气小奕正在调解中' : academyResp.message;
      this.loadState = 3;
    }
    const ctrlResp: ApiResponse<AuditControlParams> = await ApiService.getCkControl();
    if (ctrlResp.code === 0) {
      // I0 → f.c.f：isSupport* 派生（"1".equals）持久化，ChooseCoursePage 筛选按钮读同键
      try {
        await PreferencesUtil.putBoolean(PREF_AUDIT_SUPPORT_SEARCH, ctrlResp.data.supportSearchFilter());
        await PreferencesUtil.putBoolean('audit_is_support_time_filter', ctrlResp.data.supportTimeFilter());
      } catch (error) {
        const be = error as BusinessError;
        ApiService.logError('CA saveCtrl fail: ' + be.message);
      }
    }
    const hintResp: ApiResponse<string> = await ApiService.getAuditSearchHint();
    if (hintResp.code === 0 && hintResp.data !== '') {
      // h(str) → hint=please_input+str，f.c.g 持久化 supportSearchCourseKeyType
      this.hint = '请输入' + hintResp.data;
      try {
        await PreferencesUtil.putString(PREF_AUDIT_SEARCH_KEY_TYPE, hintResp.data);
      } catch (error) {
        const be = error as BusinessError;
        ApiService.logError('CA saveHint fail: ' + be.message);
      }
    }
  }

  /** h0：m=全量、o=过滤集（默认全量）→ setAdapter 气泡布局 */
  private applyAcademies(list: AuditAcademyEntry[]): void {
    this.academies = list;
    this.filtered = list;
    this.loadState = 0;
    this.buildBubbles();
  }

  /** U2()：搜索框过滤（xymc contains），空关键词重置全量；空结果 → Page.EMPTY */
  private applyFilter(): void {
    const key: string = this.searchKey;
    const out: AuditAcademyEntry[] = [];
    if (key === '') {
      for (const one of this.academies) {
        out.push(one);
      }
    } else {
      for (const one of this.academies) {
        if (one.xymc.indexOf(key) >= 0) {
          out.push(one);
        }
      }
    }
    this.filtered = out;
    if (out.length > 0) {
      this.loadState = 0;
      this.buildBubbles();
    } else {
      this.loadState = 2;
    }
  }

  /** IME actionSearch（c 类）：setSearchKey(true) → T2() 跳审核课程列表（范围外页，路由待补） */
  private submitSearch(): void {
    // 源码 T2(true)：new Intent(AddCourseActivity) + putExtra academy=new AcademyEntity()/
    // courseFilter/from_search=true —— timetable AddCourseActivity（searchCollegeCourses 列表）
    // 未翻译（映射表范围外），HAP 此处保留源码状态语义，不产生编造跳转。
  }

  /**
   * VaryingBubbles.setAdapter 布局 1:1（smali 校正：气泡直径=容器高 H 的比例）。
   * 每 part：9 个学院泡（首个 part case=4,5,3,6,2,7,1,8,0；奇数 part case=8-j；偶数 part case=j）
   * + 5 个装饰泡；index>=学院数 → 仅底图。
   */
  private buildBubbles(): void {
    const h: number = this.bubbleAreaHeight;
    if (h <= 0) {
      this.bubbles = [];
      this.containerWidth = 0;
      return;
    }
    const large: number = 0.35 * h;
    const medium: number = 0.28 * h;
    const small: number = 0.25 * h;
    const mini: number = small / 1.3;
    const superMini: number = mini / 1.8;
    const pw: number = 2.8 * large;
    const count: number = this.filtered.length;
    const partCount: number = Math.floor(count / PART_VALID_BUBBLES) +
      (count % PART_VALID_BUBBLES === 0 ? 0 : 1);
    this.containerWidth = partCount * pw;
    const centerPos: number = partCount % 2 === 0 ? partCount / 2 - 1 : Math.floor(partCount / 2);
    const cells: BubbleCell[] = [];
    for (let part = 0; part < partCount; part++) {
      const pos: number = part % 2 === 0 ? centerPos - Math.floor(part / 2)
        : centerPos + Math.floor(part / 2) + 1;
      const right: number = (pos + 1) * pw;
      this.appendValidBubbles(cells, part, count, right, large, medium, small, superMini);
      this.appendDecorBubbles(cells, right, large, medium, small, mini, superMini);
    }
    this.bubbles = cells;
    // showBubblesRunnable：初始滚动至中缝
    const initX: number = (partCount * pw) / 2 -
      (partCount % 2 === 0 ? pw : pw / 2);
    setTimeout(() => {
      this.bubbleScroller.scrollTo({ xOffset: initX, yOffset: 0 });
    }, 60);
  }

  /** 9 个学院气泡的 case 0..8 偏移公式（widget/VaryingBubbles.java setAdapter 主 switch） */
  private appendValidBubbles(cells: BubbleCell[], part: number, count: number, right: number,
    large: number, medium: number, small: number, superMini: number): void {
    for (let j = 0; j < PART_VALID_BUBBLES; j++) {
      let caseIdx: number;
      if (part === 0) {
        caseIdx = j % 2 === 0 ? 4 - Math.floor(j / 2) : 4 + Math.floor(j / 2) + 1;
      } else if (part % 2 === 1) {
        caseIdx = 8 - j;
      } else {
        caseIdx = j;
      }
      const cell: BubbleCell = this.bubbleCase(caseIdx, right, large, medium, small, superMini);
      const idx: number = part * PART_VALID_BUBBLES + j;
      if (idx < count) {
        cell.label = this.filtered[idx].xymc;
        cell.index = idx;
      }
      cells.push(cell);
    }
  }

  /** case 0..8 → (size,x,y)：X=part 右缘（(pos+1)*partWidth），y 自容器 padding 顶起 */
  private bubbleCase(caseIdx: number, right: number, large: number, medium: number,
    small: number, superMini: number): BubbleCell {
    const gap: number = BUBBLE_GAP;
    switch (caseIdx) {
      case 0:
        return new BubbleCell(right - large, gap, large, '', -1);
      case 1:
        return new BubbleCell(right - small - gap * 2.5, large, small, '', -1);
      case 2:
        return new BubbleCell(right - large - gap * 3, large + small, large, '', -1);
      case 3:
        return new BubbleCell(right - large - small + gap * 2, gap / 3, small, '', -1);
      case 4:
        return new BubbleCell(right - small * 2 - gap * 1.5, large + small * 0.3, small, '', -1);
      case 5:
        return new BubbleCell(right - small * 2 + gap * 2 - large, small + gap, large, '', -1);
      case 6:
        return new BubbleCell(right - small * 2 - medium * 0.75, small + gap + large, medium, '', -1);
      case 7:
        return new BubbleCell(right - small * 2 - medium * 1.75, large * 1.5, medium, '', -1);
      default:
        return new BubbleCell(right - large - small + gap * 2 - superMini - medium, gap * 2,
          medium, '', -1);
    }
  }

  /** 每 part 5 个装饰小泡（d0..d4 固定偏移，仅 blue_circle_with_shadow 底图） */
  private appendDecorBubbles(cells: BubbleCell[], right: number, large: number, medium: number,
    small: number, mini: number, superMini: number): void {
    const gap: number = BUBBLE_GAP;
    const pad: number = BUBBLE_TEXT_PAD;
    cells.push(new BubbleCell(right - large - mini + pad * 4, small, mini, '', -1));
    cells.push(new BubbleCell(right - small * 2 + gap * 2 - large - mini, gap * 2 + medium,
      mini, '', -1));
    cells.push(new BubbleCell(right - small * 2 - medium * 0.75 - mini + gap * 2,
      large * 1.5 + medium, mini, '', -1));
    cells.push(new BubbleCell(right - small * 2 - medium * 0.75 - mini - superMini,
      large * 1.5 + medium, superMini, '', -1));
    cells.push(new BubbleCell(right - large - small + gap * 2 - superMini,
      gap * 3 + mini * 0.5, superMini, '', -1));
  }

  /** VaryingBubbles.b 回调：气泡点击 → ChooseCourseActivity{academy}（HAP 路由带全参） */
  private openCourseList(index: number): void {
    if (index < 0 || index >= this.filtered.length) {
      return;
    }
    const academy: AuditAcademyEntry = this.filtered[index];
    router.pushUrl({
      url: 'pages/ChooseCoursePage',
      params: { 'xydm': academy.xydm, 'xymc': academy.xymc, 'tjcs': academy.tjcs }
    });
  }

  @Builder
  bubbleCellView(cell: BubbleCell) {
    // 气泡 = blue_circle_with_shadow 拉伸底图 + 白字（setLines(2)/ellipsize END/居中）
    Stack({ alignContent: Alignment.Center }) {
      Image($r('app.media.blue_circle_with_shadow'))
        .width(cell.size)
        .height(cell.size)
        .objectFit(ImageFit.Fill)
      if (cell.label !== '') {
        Text(cell.label)
          .fontSize(BUBBLE_FONT)
          .fontColor($r('app.color.white'))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width(cell.size)
          .height(cell.size)
          .padding(BUBBLE_TEXT_PAD)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.openCourseList(cell.index);
          })
      }
    }
    .width(cell.size)
    .height(cell.size)
    .position({ x: cell.x, y: cell.y })
  }

  @Builder
  bubbleArea() {
    Scroll(this.bubbleScroller) {
      Stack() {
        ForEach(this.bubbles, (cell: BubbleCell, index: number) => {
          this.bubbleCellView(cell)
        }, (cell: BubbleCell) => 'bub' + cell.x + '_' + cell.y + '_' + cell.index)
      }
      .width(this.containerWidth > 0 ? this.containerWidth : '100%')
      .height('100%')
      .alignContent(Alignment.TopStart)
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
    .height('100%')
    .onAreaChange((oldValue: Area, newValue: Area) => {
      // onMeasure：容器高 H 决定气泡直径比例；padding T/B 38 后仍以总高计（smali getMeasuredHeight）
      const nextH: number = newValue.height as number;
      if (Math.abs(nextH - this.bubbleAreaHeight) > 1) {
        this.bubbleAreaHeight = nextH;
        this.buildBubbles();
      }
    })
  }

  @Builder
  stateArea() {
    Stack() {
      if (this.loadState === 1) {
        // loading_view.xml：72dip GIF（HAP LoadingProgress 等尺寸替代）
        LoadingProgress()
          .width(72)
          .height(72)
          .color($r('app.color.ybg_blue'))
      } else if (this.loadState === 2) {
        // Page.EMPTY：no_report 图 + R.string.empty（空文案）
        Column() {
          Image($r('app.media.no_report'))
            .width(220)
            .height(150)
            .objectFit(ImageFit.Contain)
            .margin({ left: 25, right: 25 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.loadState === 3) {
        // Page.ERROR：empty_error 图 + error_page_tips_new
        Column() {
          Image($r('app.media.empty_error'))
            .width(220)
            .height(150)
            .objectFit(ImageFit.Contain)
            .margin({ left: 25, right: 25 })
          Text(this.errorTips)
            .fontSize(12)
            .fontColor('#CECECE')
            .textAlign(TextAlign.Center)
            .padding(15)
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        this.bubbleArea()
      }
    }
    .width('100%')
    .height('100%')
    .padding({ top: BUBBLE_AREA_PAD, bottom: BUBBLE_AREA_PAD })
  }

  /** search_box.xml：圆角 6vp #E7E7E7、search_grey 前置、drawablePadding 10、16fp hint common_color_3 */
  @Builder
  searchBox() {
    Row() {
      Image($r('app.media.search_grey'))
        .width(16)
        .height(16)
        .margin({ right: 10 })
      TextInput({ text: this.searchKey, placeholder: this.hint })
        .fontSize(16)
        .fontColor($r('app.color.common_color_2'))
        .placeholderColor($r('app.color.common_color_3'))
        .placeholderFont({ size: 16 })
        .backgroundColor(Color.Transparent)
        .padding(0)
        .layoutWeight(1)
        .height(36)
        .maxLines(1)
        .enterKeyType(EnterKeyType.Search)
        .onChange((value: string) => {
          this.searchKey = value;
          // a 类 TextWatcher.afterTextChanged：清空即 U2() 重置
          if (value.length <= 0) {
            this.applyFilter();
          }
        })
        .onSubmit(() => {
          // c 类 OnEditorAction：IME actionSearch → T2(true)
          this.submitSearch();
        })
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 6, bottom: 6 })
    .backgroundColor($r('app.color.common_color_5'))
    .borderRadius(6)
  }

  build() {
    Column() {
      TitleBar({ title: '蹭课', showBack: true })
      // FrameLayout(ybg_white, padding T/B 10) 包 search_box(marginH 10)
      Column() {
        Column() {
          this.searchBox()
        }
        .width('100%')
        .padding({ left: 10, right: 10 })
      }
      .width('100%')
      .padding({ top: 10, bottom: 10 })
      .backgroundColor($r('app.color.ybg_white'))
      // divider_horizontal_grey_normal：8vp common_color_6
      Row()
        .width('100%')
        .height(8)
        .backgroundColor($r('app.color.common_color_6'))
      this.stateArea()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.main_bg'))
  }
}
