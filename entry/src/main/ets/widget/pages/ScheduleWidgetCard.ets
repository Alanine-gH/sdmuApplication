interface GridCellItem {
  name: string;
  place: string;
  colorIdx: number;
  isToday: boolean;
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

@Entry
@Component
struct ScheduleWidgetCard {
  @LocalStorageProp('viewMode') viewMode: string = 'week';
  @LocalStorageProp('weekNum') weekNum: number = 1;
  @LocalStorageProp('maxWeek') maxWeek: number = 20;
  @LocalStorageProp('weekTitle') weekTitle: string = '第1周';
  @LocalStorageProp('todayWeekday') todayWeekday: number = 1;
  @LocalStorageProp('selectedDay') selectedDay: number = 1;
  @LocalStorageProp('gridCols') gridCols: number = 5;
  @LocalStorageProp('gridCells') gridCells: GridCellItem[] = [];
  @LocalStorageProp('dayCourses') dayCourses: DayCourseItem[] = [];
  @LocalStorageProp('weekCourseCount') weekCourseCount: number = 0;
  @LocalStorageProp('subtitle') subtitle: string = '打开课表后自动同步本周课程';

  private openScheduleApp(): void {
    postCardAction(this, {
      action: 'router',
      abilityName: 'EntryAbility',
      params: { targetPage: 'pages/SchedulePage' }
    });
  }

  private cellBg(cell: GridCellItem): string {
    if (cell.name === '') {
      return cell.isToday ? '#FFF7F7' : '#F7F8FA';
    }
    const idx = cell.colorIdx >= 0 && cell.colorIdx < CELL_BG_COLORS.length ? cell.colorIdx : 0;
    return CELL_BG_COLORS[idx];
  }

  private cellTextColor(cell: GridCellItem): string {
    const idx = cell.colorIdx >= 0 && cell.colorIdx < CELL_TEXT_COLORS.length ? cell.colorIdx : 0;
    return CELL_TEXT_COLORS[idx];
  }

  private getCell(slot: number, dayIdx: number): GridCellItem {
    const idx: number = slot * this.gridCols + dayIdx;
    if (idx >= 0 && idx < this.gridCells.length) {
      return this.gridCells[idx];
    }
    return { name: '', place: '', colorIdx: -1, isToday: false };
  }

  private dayIndices(): number[] {
    return this.gridCols === 7 ? [0, 1, 2, 3, 4, 5, 6] : [0, 1, 2, 3, 4];
  }

  @Builder
  weekCellBox(cell: GridCellItem) {
    Column() {
      if (cell.name !== '') {
        Text(cell.name)
          .fontSize(9)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.cellTextColor(cell))
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Center)
        if (cell.place !== '') {
          Text(cell.place)
            .fontSize(8)
            .fontColor('#666666')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 1 })
        }
      }
    }
    .layoutWeight(1)
    .height('100%')
    .padding(2)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(this.cellBg(cell))
    .borderRadius(5)
  }

  build() {
    Column() {
      // 顶部栏：< 第N周 > + [本周 | 今日] 切换开关
      Row() {
        Text('‹')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#555555')
          .width(24)
          .height(26)
          .textAlign(TextAlign.Center)
          .backgroundColor('#F3F4F6')
          .borderRadius(6)
          .onClick(() => {
            postCardAction(this, {
              action: 'message',
              params: { action: 'prevWeek' }
            });
          })

        Text('📅 ' + this.weekTitle)
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
          .width(24)
          .height(26)
          .textAlign(TextAlign.Center)
          .backgroundColor('#F3F4F6')
          .borderRadius(6)
          .onClick(() => {
            postCardAction(this, {
              action: 'message',
              params: { action: 'nextWeek' }
            });
          })

        Blank()

        Row() {
          Text('本周')
            .fontSize(11)
            .fontColor(this.viewMode === 'week' ? '#FFFFFF' : '#555555')
            .backgroundColor(this.viewMode === 'week' ? '#97000C' : Color.Transparent)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(6)
            .onClick(() => {
              postCardAction(this, {
                action: 'message',
                params: { action: 'setMode', mode: 'week' }
              });
            })
          Text('今日')
            .fontSize(11)
            .fontColor(this.viewMode === 'day' ? '#FFFFFF' : '#555555')
            .backgroundColor(this.viewMode === 'day' ? '#97000C' : Color.Transparent)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(6)
            .onClick(() => {
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

      if (this.viewMode === 'week') {
        // 星期头（点击任意天可切到单日视图）
        Row() {
          Blank().width(22)
          Row({ space: 3 }) {
            ForEach(this.gridCols === 7 ? WEEKDAY_LABELS : WEEKDAY_LABELS.slice(0, 5),
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
                    postCardAction(this, {
                      action: 'message',
                      params: { action: 'selectDay', day: idx + 1 }
                    });
                  })
              }, (label: string) => 'wd_' + label)
          }
          .layoutWeight(1)
        }
        .width('100%')
        .margin({ bottom: 4 })

        if (this.weekCourseCount > 0 && this.gridCells.length > 0) {
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

            // 本周 5×5 或 7×5 课程网格（Form 卡片使用 Column+Row 实现，兼容 ArkTS 卡片规范）
            Column({ space: 3 }) {
              ForEach([0, 1, 2, 3, 4], (slot: number) => {
                Row({ space: 3 }) {
                  ForEach(this.dayIndices(), (dayIdx: number) => {
                    this.weekCellBox(this.getCell(slot, dayIdx))
                  }, (dayIdx: number) => 'd_' + slot + '_' + dayIdx + '_' + this.weekNum + '_' + this.gridCols)
                }
                .width('100%')
                .layoutWeight(1)
              }, (slot: number) => 'slot_' + slot + '_' + this.weekNum + '_' + this.gridCols)
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
              .fontWeight(idx + 1 === this.selectedDay ? FontWeight.Bold : FontWeight.Normal)
              .fontColor(idx + 1 === this.selectedDay ? '#FFFFFF' : '#555555')
              .backgroundColor(idx + 1 === this.selectedDay ? '#97000C' : '#F3F4F6')
              .layoutWeight(1)
              .textAlign(TextAlign.Center)
              .padding({ top: 4, bottom: 4 })
              .borderRadius(6)
              .onClick(() => {
                postCardAction(this, {
                  action: 'message',
                  params: { action: 'selectDay', day: idx + 1 }
                });
              })
          }, (label: string) => 'dsel_' + label)
        }
        .width('100%')
        .margin({ bottom: 6 })

        if (this.dayCourses.length > 0) {
          Column({ space: 6 }) {
            ForEach(this.dayCourses.slice(0, 5), (item: DayCourseItem, idx: number) => {
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
            }, (item: DayCourseItem, idx: number) => 'dc_' + idx + '_' + item.name)
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
