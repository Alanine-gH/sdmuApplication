interface CompactWidgetCourse {
  n: string;
  p: string;
  d: number;
  s: number;
  e: number;
  w: number;
  wk: string;
}

interface GridCellItem {
  name: string;
  place: string;
  colorIdx: number;
  isToday: boolean;
}

interface DayColumnBlock {
  name: string;
  place: string;
  colorIdx: number;
  isToday: boolean;
  span: number;
  slotStart: number;
}

interface DayCourseItem {
  name: string;
  time: string;
  place: string;
}

const CELL_BG_COLORS: string[] = [
  '#FDECEE', '#EAF3FF', '#E9F8F0', '#FFF4E5', '#F3EEFF', '#E6F7FA'
];
const CELL_TEXT_COLORS: string[] = [
  '#97000C', '#1B68B7', '#1E7E4A', '#B85D00', '#6333B5', '#0D7A8F'
];
const WEEKDAY_LABELS: string[] = ['一', '二', '三', '四', '五', '六', '日'];
const SECTION_LABELS: string[] = ['1-2', '3-4', '5-6', '7-8', '9+'];
const SECTION_CLOCKS: string[][] = [
  ['08:00', '08:45'], ['08:55', '09:40'], ['10:00', '10:45'], ['10:55', '11:40'],
  ['14:00', '14:45'], ['14:55', '15:40'], ['16:00', '16:45'], ['16:55', '17:40'],
  ['19:00', '19:45'], ['19:55', '20:40'], ['20:50', '21:35'], ['21:45', '22:30']
];
const SECTION_END_MINUTES: number[] = [
  8 * 60 + 45, 9 * 60 + 40, 10 * 60 + 45, 11 * 60 + 40,
  14 * 60 + 45, 15 * 60 + 40, 16 * 60 + 45, 17 * 60 + 40,
  19 * 60 + 45, 20 * 60 + 40, 21 * 60 + 35, 22 * 60 + 30
];
const SECTION_START_MINUTES: number[] = [
  8 * 60, 8 * 60 + 55, 10 * 60, 10 * 60 + 55,
  14 * 60, 14 * 60 + 55, 16 * 60, 16 * 60 + 55,
  19 * 60, 19 * 60 + 55, 20 * 60 + 50, 21 * 60 + 45
];

const localStorage: LocalStorage = new LocalStorage();

@Entry(localStorage)
@Component
struct ScheduleWidgetCard {
  @LocalStorageProp('formDimension') formDimension: number = 4;
  @LocalStorageProp('viewMode') @Watch('onFormPropsChange') propViewMode: string = 'week';
  @LocalStorageProp('weekNum') @Watch('onFormPropsChange') propWeekNum: number = 1;
  @LocalStorageProp('maxWeek') maxWeek: number = 20;
  @LocalStorageProp('todayWeekday') todayWeekday: number = 1;
  @LocalStorageProp('selectedDay') @Watch('onFormPropsChange') propSelectedDay: number = 1;
  @LocalStorageProp('gridCols') propGridCols: number = 5;
  @LocalStorageProp('gridCells') propGridCells: GridCellItem[] = [];
  @LocalStorageProp('dayCourses') propDayCourses: DayCourseItem[] = [];
  @LocalStorageProp('allCourses') propAllCourses: CompactWidgetCourse[] = [];
  @LocalStorageProp('weekCourseCount') propWeekCourseCount: number = 0;
  @LocalStorageProp('subtitle') subtitle: string = '打开课表后自动同步本周课程';

  @State localViewMode: string = 'week';
  @State localWeekNum: number = 1;
  @State localSelectedDay: number = 1;

  aboutToAppear(): void {
    this.syncFromProps();
  }

  onFormPropsChange(): void {
    this.syncFromProps();
  }

  private syncFromProps(): void {
    this.localViewMode = this.propViewMode === 'day' ? 'day' : 'week';
    this.localWeekNum = this.clampWeek(this.propWeekNum, this.maxWeek);
    this.localSelectedDay = this.propSelectedDay >= 1 && this.propSelectedDay <= 7
      ? this.propSelectedDay
      : (this.todayWeekday >= 1 && this.todayWeekday <= 7 ? this.todayWeekday : 1);
  }

  private clampWeek(week: number, maxW: number): number {
    const safeMax: number = maxW > 0 ? maxW : 20;
    if (week < 1) {
      return 1;
    }
    if (week > safeMax) {
      return safeMax;
    }
    return week;
  }

  private sectionToSlot(sectionStart: number): number {
    if (sectionStart <= 2) {
      return 0;
    }
    if (sectionStart <= 4) {
      return 1;
    }
    if (sectionStart <= 6) {
      return 2;
    }
    if (sectionStart <= 8) {
      return 3;
    }
    return 4;
  }

  private hashCourseColor(name: string): number {
    let h: number = 0;
    for (let i = 0; i < name.length; i++) {
      h = (h * 31 + name.charCodeAt(i)) % 997;
    }
    return Math.abs(h) % 6;
  }

  private parseIntSafe(text: string): number {
    let digits: string = '';
    for (let i = 0; i < text.length; i++) {
      const ch: string = text.charAt(i);
      if (ch >= '0' && ch <= '9') {
        digits += ch;
      }
    }
    return digits === '' ? 0 : Number(digits);
  }

  private isCourseInWeek(c: CompactWidgetCourse, targetWeek: number): boolean {
    if (c.w > 0) {
      return c.w === targetWeek;
    }
    const raw: string = c.wk || '';
    if (raw === '') {
      return true;
    }
    const odd: boolean = raw.indexOf('单') >= 0;
    const even: boolean = raw.indexOf('双') >= 0;
    let cleaned: string = '';
    for (let i = 0; i < raw.length; i++) {
      const ch: string = raw.charAt(i);
      if ((ch >= '0' && ch <= '9') || ch === '-' || ch === ',' || ch === '~') {
        cleaned += ch;
      } else if (ch === '，' || ch === '、' || ch === '/') {
        cleaned += ',';
      }
    }
    const out: number[] = [];
    const tokens: string[] = cleaned.split(',');
    for (const token of tokens) {
      const seg: string = token.trim();
      if (seg.length === 0) {
        continue;
      }
      const dash: number = seg.indexOf('-');
      if (dash > 0) {
        const from: number = this.parseIntSafe(seg.substring(0, dash));
        const to: number = this.parseIntSafe(seg.substring(dash + 1));
        for (let i = from; i <= to; i++) {
          if (i >= 1 && !(odd && i % 2 === 0) && !(even && i % 2 === 1) && out.indexOf(i) < 0) {
            out.push(i);
          }
        }
      } else {
        const n: number = this.parseIntSafe(seg);
        if (n >= 1 && !(odd && n % 2 === 0) && !(even && n % 2 === 1) && out.indexOf(n) < 0) {
          out.push(n);
        }
      }
    }
    return out.length === 0 || out.indexOf(targetWeek) >= 0;
  }

  private getWeekCourses(): CompactWidgetCourse[] {
    const list: CompactWidgetCourse[] = [];
    for (const c of this.propAllCourses) {
      if (this.isCourseInWeek(c, this.localWeekNum)) {
        list.push(c);
      }
    }
    return list;
  }

  private activeGridCols(weekList: CompactWidgetCourse[]): number {
    if (this.propAllCourses.length === 0) {
      return this.propGridCols === 7 ? 7 : 5;
    }
    for (const c of weekList) {
      if (c.d >= 6) {
        return 7;
      }
    }
    return 5;
  }

  private buildDayColumnBlocks(day: number, weekList: CompactWidgetCourse[]): DayColumnBlock[] {
    const safeToday: number = this.todayWeekday >= 1 && this.todayWeekday <= 7 ? this.todayWeekday : 1;
    const isToday: boolean = day === safeToday;

    if (this.propAllCourses.length === 0) {
      const cols: number = this.propGridCols === 7 ? 7 : 5;
      const fallbackBlocks: DayColumnBlock[] = [];
      for (let slot = 0; slot < 5; slot++) {
        const idx: number = slot * cols + (day - 1);
        const cell: GridCellItem = idx >= 0 && idx < this.propGridCells.length
          ? this.propGridCells[idx]
          : { name: '', place: '', colorIdx: -1, isToday: isToday };
        fallbackBlocks.push({
          name: cell.name,
          place: cell.place,
          colorIdx: cell.colorIdx,
          isToday: cell.isToday,
          span: 1,
          slotStart: slot
        });
      }
      return fallbackBlocks;
    }

    const slotCourses: (CompactWidgetCourse | null)[] = [null, null, null, null, null];
    const courseGroupId: number[] = [-1, -1, -1, -1, -1];
    for (let ci = 0; ci < weekList.length; ci++) {
      const c: CompactWidgetCourse = weekList[ci];
      if (c.d !== day) {
        continue;
      }
      const startSlot: number = this.sectionToSlot(c.s);
      const endSection: number = c.e >= c.s ? c.e : c.s;
      const endSlot: number = this.sectionToSlot(endSection);
      for (let slot = startSlot; slot <= endSlot; slot++) {
        if (slot >= 0 && slot < 5 && slotCourses[slot] === null) {
          slotCourses[slot] = c;
          courseGroupId[slot] = ci;
        }
      }
    }

    const blocks: DayColumnBlock[] = [];
    let slot: number = 0;
    while (slot < 5) {
      const c: CompactWidgetCourse | null = slotCourses[slot];
      if (c === null) {
        blocks.push({
          name: '',
          place: '',
          colorIdx: -1,
          isToday: isToday,
          span: 1,
          slotStart: slot
        });
        slot++;
      } else {
        const gid: number = courseGroupId[slot];
        let span: number = 1;
        while (slot + span < 5 && courseGroupId[slot + span] === gid) {
          span++;
        }
        blocks.push({
          name: c.n,
          place: c.p,
          colorIdx: this.hashCourseColor(c.n),
          isToday: isToday,
          span: span,
          slotStart: slot
        });
        slot += span;
      }
    }
    return blocks;
  }

  private getActiveDayCourses(weekList: CompactWidgetCourse[]): DayCourseItem[] {
    if (this.propAllCourses.length === 0) {
      return this.propDayCourses;
    }
    const dayRaw: CompactWidgetCourse[] = weekList.filter((c: CompactWidgetCourse) => c.d === this.localSelectedDay);
    dayRaw.sort((a: CompactWidgetCourse, b: CompactWidgetCourse) => a.s - b.s);
    return dayRaw.slice(0, 6).map((c: CompactWidgetCourse): DayCourseItem => {
      return {
        name: c.n,
        time: `第${c.s}-${c.e}节`,
        place: c.p
      };
    });
  }

  private getNextTodayCourse(): DayCourseItem | null {
    const safeToday: number = this.todayWeekday >= 1 && this.todayWeekday <= 7 ? this.todayWeekday : 1;
    if (this.propAllCourses.length > 0) {
      const todayList: CompactWidgetCourse[] = [];
      for (const c of this.propAllCourses) {
        if (c.d === safeToday && this.isCourseInWeek(c, this.localWeekNum)) {
          todayList.push(c);
        }
      }
      todayList.sort((a: CompactWidgetCourse, b: CompactWidgetCourse) => a.s - b.s);
      const now: Date = new Date();
      const nowMin: number = now.getHours() * 60 + now.getMinutes();
      for (const c of todayList) {
        const sIdx: number = Math.max(0, Math.min(SECTION_CLOCKS.length - 1, c.s - 1));
        const eIdx: number = Math.max(sIdx, Math.min(SECTION_CLOCKS.length - 1, c.e - 1));
        if (SECTION_END_MINUTES[eIdx] >= nowMin) {
          const status: string = nowMin >= SECTION_START_MINUTES[sIdx] ? '上课中' : '下一节';
          const clock: string = SECTION_CLOCKS[sIdx][0] + '-' + SECTION_CLOCKS[eIdx][1];
          return {
            name: c.n,
            time: `${status} · 第${c.s}-${c.e}节 (${clock})`,
            place: c.p
          };
        }
      }
      return null;
    }
    return this.propDayCourses.length > 0 ? this.propDayCourses[0] : null;
  }

  private openScheduleApp(): void {
    postCardAction(this, {
      action: 'router',
      abilityName: 'EntryAbility',
      params: { targetPage: 'pages/SchedulePage' }
    });
  }

  private cellBg(block: DayColumnBlock): string {
    if (block.name === '') {
      return block.isToday ? '#FFF7F7' : '#F7F8FA';
    }
    const idx = block.colorIdx >= 0 && block.colorIdx < CELL_BG_COLORS.length ? block.colorIdx : 0;
    return CELL_BG_COLORS[idx];
  }

  private cellTextColor(block: DayColumnBlock): string {
    const idx = block.colorIdx >= 0 && block.colorIdx < CELL_TEXT_COLORS.length ? block.colorIdx : 0;
    return CELL_TEXT_COLORS[idx];
  }

  private dayIndices(cols: number): number[] {
    return cols === 7 ? [0, 1, 2, 3, 4, 5, 6] : [0, 1, 2, 3, 4];
  }

  @Builder
  weekBlockBox(block: DayColumnBlock) {
    Column() {
      if (block.name !== '') {
        Text(block.name)
          .fontSize(9)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.cellTextColor(block))
          .maxLines(block.span >= 2 ? 4 : 2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
        if (block.place !== '') {
          Text(block.place)
            .fontSize(8)
            .fontColor('#666666')
            .maxLines(block.span >= 2 ? 2 : 1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 1 })
        }
      }
    }
    .width('100%')
    .layoutWeight(block.span)
    .padding(2)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.cellBg(block))
    .borderRadius(5)
  }

  build() {
    if (this.formDimension === 2) {
      this.buildCompactCard();
    } else {
      this.buildFullCard();
    }
  }

  @Builder
  buildCompactCard() {
    Column() {
      Row() {
        Text('第' + this.localWeekNum + '周')
          .fontSize(11)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .backgroundColor('#97000C')
          .padding({ left: 7, right: 7, top: 2, bottom: 2 })
          .borderRadius(6)
        Blank()
        Text('周' + WEEKDAY_LABELS[(this.todayWeekday >= 1 && this.todayWeekday <= 7 ? this.todayWeekday : 1) - 1])
          .fontSize(11)
          .fontWeight(FontWeight.Medium)
          .fontColor('#97000C')
      }
      .width('100%')

      if (this.getNextTodayCourse() !== null) {
        Column({ space: 4 }) {
          Text(this.getNextTodayCourse()!.name)
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#222222')
            .maxLines(2)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          Text(this.getNextTodayCourse()!.time)
            .fontSize(11)
            .fontWeight(FontWeight.Medium)
            .fontColor('#97000C')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
          if (this.getNextTodayCourse()!.place !== '') {
            Text(this.getNextTodayCourse()!.place)
              .fontSize(11)
              .fontColor('#666666')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
      } else {
        Column({ space: 4 }) {
          Text(this.propAllCourses.length > 0 ? '今日课程已结束' : '暂无同步课表')
            .fontSize(13)
            .fontWeight(FontWeight.Medium)
            .fontColor('#333333')
          Text('点击查看完整课表')
            .fontSize(11)
            .fontColor('#888888')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Start)
      }
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .onClick(() => {
      this.openScheduleApp();
    })
  }

  @Builder
  buildFullCard() {
    Column() {
      // 顶部栏：< 第N周 > + [本周 | 今日] 切换开关
      Row() {
        Text('‹')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#555555')
          .width(26)
          .height(26)
          .textAlign(TextAlign.Center)
          .backgroundColor('#F3F4F6')
          .borderRadius(6)
          .onClick(() => {
            this.localWeekNum = this.clampWeek(this.localWeekNum - 1, this.maxWeek);
            postCardAction(this, {
              action: 'message',
              params: { action: 'prevWeek' }
            });
          })

        Text('📅 第' + this.localWeekNum + '周')
          .fontSize(14)
          .fontWeight(FontWeight.Bold)
          .fontColor('#97000C')
          .margin({ left: 6, right: 6 })
          .onClick(() => {
            this.openScheduleApp();
          })

        Text('›')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#555555')
          .width(26)
          .height(26)
          .textAlign(TextAlign.Center)
          .backgroundColor('#F3F4F6')
          .borderRadius(6)
          .onClick(() => {
            this.localWeekNum = this.clampWeek(this.localWeekNum + 1, this.maxWeek);
            postCardAction(this, {
              action: 'message',
              params: { action: 'nextWeek' }
            });
          })

        Blank()

        Row() {
          Text('本周')
            .fontSize(11)
            .fontColor(this.localViewMode === 'week' ? '#FFFFFF' : '#555555')
            .backgroundColor(this.localViewMode === 'week' ? '#97000C' : Color.Transparent)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(6)
            .onClick(() => {
              this.localViewMode = 'week';
              postCardAction(this, {
                action: 'message',
                params: { action: 'setMode', mode: 'week' }
              });
            })
          Text('今日')
            .fontSize(11)
            .fontColor(this.localViewMode === 'day' ? '#FFFFFF' : '#555555')
            .backgroundColor(this.localViewMode === 'day' ? '#97000C' : Color.Transparent)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(6)
            .onClick(() => {
              this.localViewMode = 'day';
              this.localSelectedDay = this.todayWeekday >= 1 && this.todayWeekday <= 7 ? this.todayWeekday : 1;
              postCardAction(this, {
                action: 'message',
                params: { action: 'setMode', mode: 'day' }
              });
            })
        }
        .padding(2)
        .backgroundColor('#F2F3F5')
        .borderRadius(8)
      }
      .width('100%')
      .height(30)
      .alignItems(VerticalAlign.Center)

      Divider().color('#EEEEEE').strokeWidth(0.5).margin({ top: 5, bottom: 5 })

      if (this.localViewMode === 'week') {
        // 星期头（点击任意天可切到单日视图）
        Row() {
          Blank().width(22)
          Row({ space: 3 }) {
            ForEach(
              this.activeGridCols(this.getWeekCourses()) === 7 ? WEEKDAY_LABELS : WEEKDAY_LABELS.slice(0, 5),
              (label: string, idx: number) => {
                Text('周' + label)
                  .fontSize(10)
                  .fontWeight(idx + 1 === this.todayWeekday ? FontWeight.Bold : FontWeight.Normal)
                  .fontColor(idx + 1 === this.todayWeekday ? '#97000C' : '#666666')
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
                  .padding({ top: 2, bottom: 2 })
                  .backgroundColor(idx + 1 === this.todayWeekday ? '#FFF0F0' : Color.Transparent)
                  .borderRadius(4)
                  .onClick(() => {
                    this.localSelectedDay = idx + 1;
                    this.localViewMode = 'day';
                    postCardAction(this, {
                      action: 'message',
                      params: { action: 'selectDay', day: idx + 1 }
                    });
                  })
              },
              (label: string) => 'wd_' + label + '_' + this.localWeekNum
            )
          }
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 4 })

        if (this.propAllCourses.length > 0 || (this.propWeekCourseCount > 0 && this.propGridCells.length > 0)) {
          Row() {
            // 左侧节次轴
            Column() {
              ForEach(SECTION_LABELS, (sec: string) => {
                Text(sec)
                  .fontSize(9)
                  .fontColor('#999999')
                  .layoutWeight(1)
                  .textAlign(TextAlign.Center)
              }, (sec: string) => 'sec_' + sec)
            }
            .width(22)
            .height('100%')

            // 按天纵列渲染（支持连上多节合并为整块）
            Row({ space: 3 }) {
              ForEach(this.dayIndices(this.activeGridCols(this.getWeekCourses())), (dayIdx: number) => {
                Column({ space: 3 }) {
                  ForEach(
                    this.buildDayColumnBlocks(dayIdx + 1, this.getWeekCourses()),
                    (block: DayColumnBlock) => {
                      this.weekBlockBox(block)
                    },
                    (block: DayColumnBlock) => 'blk_' + this.localWeekNum + '_' + dayIdx + '_' +
                      block.slotStart + '_' + block.span + '_' + block.name + '_' + this.propAllCourses.length
                  )
                }
                .layoutWeight(1)
                .height('100%')
              }, (dayIdx: number) => 'col_' + this.localWeekNum + '_' + dayIdx + '_' +
                this.activeGridCols(this.getWeekCourses()) + '_' + this.propAllCourses.length)
            }
            .layoutWeight(1)
            .height('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .onClick(() => {
            this.openScheduleApp();
          })
        } else {
          Column() {
            Text(this.subtitle)
              .fontSize(13)
              .fontColor('#333333')
              .textAlign(TextAlign.Center)
            Text('点击打开课表同步本周全部课程')
              .fontSize(11)
              .fontColor('#888888')
              .margin({ top: 6 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.openScheduleApp();
          })
        }
      } else {
        // 今日/单日详情模式：7 天快选条 + 单日课程列表
        Row({ space: 4 }) {
          ForEach(WEEKDAY_LABELS, (label: string, idx: number) => {
            Text('周' + label)
              .fontSize(10)
              .fontWeight(idx + 1 === this.localSelectedDay ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(idx + 1 === this.localSelectedDay ? '#FFFFFF' : '#555555')
              .backgroundColor(idx + 1 === this.localSelectedDay ? '#97000C' : '#F3F4F6')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .padding({ top: 4, bottom: 4 })
              .borderRadius(6)
              .onClick(() => {
                this.localSelectedDay = idx + 1;
                this.localViewMode = 'day';
                postCardAction(this, {
                  action: 'message',
                  params: { action: 'selectDay', day: idx + 1 }
                });
              })
          }, (label: string) => 'dsel_' + label)
        }
        .width('100%')
        .margin({ bottom: 6 })

        if (this.getActiveDayCourses(this.getWeekCourses()).length > 0) {
          Column({ space: 6 }) {
            ForEach(
              this.getActiveDayCourses(this.getWeekCourses()).slice(0, 5),
              (item: DayCourseItem, idx: number) => {
                Row() {
                  Column()
                    .width(4)
                    .height(30)
                    .borderRadius(2)
                    .backgroundColor('#97000C')
                    .margin({ right: 8 })
                  Column() {
                    Text(item.name)
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .fontColor('#222222')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text((item.time + ' ' + item.place).trim())
                      .fontSize(11)
                      .fontColor('#666666')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .margin({ top: 2 })
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)
                }
                .width('100%')
                .padding({ left: 8, right: 8, top: 6, bottom: 6 })
                .backgroundColor('#F7F8FA')
                .borderRadius(8)
              },
              (item: DayCourseItem, idx: number) => 'dc_' + this.localWeekNum + '_' + this.localSelectedDay + '_' +
                idx + '_' + item.name + '_' + item.time + '_' + item.place
            )
          }
          .width('100%')
          .layoutWeight(1)
          .onClick(() => {
            this.openScheduleApp();
          })
        } else {
          Column() {
            Text('当日暂无课程')
              .fontSize(14)
              .fontColor('#333333')
            Text('可点击上方周次或“本周”查看全周排课')
              .fontSize(11)
              .fontColor('#888888')
              .margin({ top: 6 })
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .onClick(() => {
            this.openScheduleApp();
          })
        }
      }
    }
    .width('100%')
    .height('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
  }
}
