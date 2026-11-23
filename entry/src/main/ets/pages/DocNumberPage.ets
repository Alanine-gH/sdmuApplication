import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { OaDocNumEntity } from '../model/OaTodoModel';
import { TitleBar } from '../components/TitleBar';
import { LoadingView } from '../components/LoadingView';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 文号选择页 — 源码级翻译（W23，原空占位重写）：
 * APK DocNumberActivity（oa/selector/view，路由 /selector/doc = base.e.a.U，
 * EditTodoDetailActivity/WorkApplyFormConfig docNumberPicker 入口 rc 1569）。
 *
 * 【布局】mobile_campus_oa_activity_docnumber.xml：
 *   toolbar_normal（标题"选择"，T1 gVar.n("选择")）+ thin 分隔线 + content_container：
 *   左列分类 ListView 100dip（doc_number_items singleChoice，mt30）+ 2dip 竖线 + 右侧三段
 *   （tag_zihao"字号" 12fp common_color_1 bg common_color_5 + doc_number_zihao ListView；
 *   tag_niandu"年度" + doc_number_niandu；tag_bianhao"编号" + doc_number_bianhao）+
 *   1dip 线 + 底部 100dip（doc_number_text 14fp pl32 + doc_number_sure 17sp 白字 primary
 *   weight 3）。
 * 【数据流源码还原（SelectPImpl/SelectModel oa/b）】
 *   f1：b3() → getDocNumCategory（GET 无参；2026-11-18 实测 code=0 data={content:"[{id,text}]"}
 *   部门函件/处室函件/会议纪要/上行文…）+ e3() → getYear（GET 无参；实测 [{year:2024..2028}]）。
 *   分类点击（e 类）→ d3(category.id) → getDocNumWord {categoryId}（实测鲁管院发/鲁管院纪发…）；
 *   字号点击（f 类）→ c3(word.id) → getDocNumSerialNo {wordId}（实测空 wordId content='{"msg":""}'）
 *   + z=entity.text；年度点击（g 类）→ A=String(year)；编号点击（h 类）→ B=entity.text；
 *   每次点击 f3() → q 文本 "文号：%s %s %s"（String.format 半角空格）。
 * 【确定】i 类：z/A/B 任一空 → YBGToastUtil "请选择完整的文号"；否则 new Intent().putExtra
 *   ("docNumber", q.getText()) 后 setResult(-1)（**源码 bug 实锤：smali setResult(I) 单参无
 *   Intent**）→ finish。调用方 EditTodoDetail 1569 y.y(getStringExtra("docNumber")) 拿 null →
 *   j.y(str) TextUtils.isEmpty 直接 return（no-op）。
 *   HAP 保真：确定 → AppStorage 'doc_number_result'=''（空）+ back；消费方读到空 → no-op
 *   （与 APK y(null) 完全等价，选文号实际不回填——源码级 bug 保真）。
 * 【禁 mock】四列全真实接口；编号空列表真实空态。
 */
@Entry
@Component
struct DocNumberPage {
  @State categories: OaDocNumEntity[] = [];
  @State words: OaDocNumEntity[] = [];
  @State years: number[] = [];
  @State serials: OaDocNumEntity[] = [];
  @State catPicked: number = -1;
  @State wordPicked: number = -1;
  @State yearPicked: number = -1;
  @State serialPicked: number = -1;
  @State docNumberText: string = '文号：';
  @State isLoading: boolean = true;
  /** 源码 z（字号 text）/ A（年度 String.valueOf(year)）/ B（编号 text） */
  private zWord: string = '';
  private aYear: string = '';
  private bSerial: string = '';

  aboutToAppear(): void {
    this.loadCategories();
    this.loadYears();
  }

  /** 源码 b3：getDocNumCategory（content 内嵌 JSON 串解析在 ApiService） */
  private loadCategories(): void {
    ApiService.getOaDocNumCategory()
      .then((response: ApiResponse<OaDocNumEntity[]>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.categories = response.data;
        } else {
          ApiService.logError('getDocNumCategory fail code=' + response.code);
        }
        this.isLoading = false;
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getDocNumCategory error: ' + error.message);
        this.isLoading = false;
      });
  }

  /** 源码 e3：getYear */
  private loadYears(): void {
    ApiService.getOaDocNumYears()
      .then((response: ApiResponse<number[]>) => {
        if (response.code === 0) {
          this.years = response.data;
        } else {
          ApiService.logError('getYear fail code=' + response.code);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getYear error: ' + error.message);
      });
  }

  /** 源码 e 类（分类点击）→ d3：getDocNumWord {categoryId} */
  private onCategoryClick(index: number): void {
    const picked: number = this.catPicked;
    if (picked === -1) {
      return;
    }
    const entity: OaDocNumEntity | undefined = this.categories[picked];
    if (entity === undefined) {
      return;
    }
    ApiService.getOaDocNumWords(entity.id)
      .then((response: ApiResponse<OaDocNumEntity[]>) => {
        if (response.code === 0) {
          this.words = response.data;
          this.wordPicked = -1;
          this.zWord = '';
        } else {
          ApiService.logError('getDocNumWord fail code=' + response.code);
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getDocNumWord error: ' + error.message);
      });
  }

  /** 源码 f 类（字号点击）→ c3：getDocNumSerialNo {wordId} + z=text + f3() */
  private onWordClick(index: number): void {
    const picked: number = this.wordPicked;
    if (picked === -1) {
      return;
    }
    const entity: OaDocNumEntity | undefined = this.words[picked];
    if (entity === undefined) {
      return;
    }
    this.zWord = entity.text;
    ApiService.getOaDocNumSerialNos(entity.id)
      .then((response: ApiResponse<OaDocNumEntity[]>) => {
        if (response.code === 0) {
          this.serials = response.data;
          this.serialPicked = -1;
          this.bSerial = '';
        } else {
          ApiService.logError('getDocNumSerialNo fail code=' + response.code);
        }
        this.composeText();
      })
      .catch((error: BusinessError) => {
        ApiService.logError('getDocNumSerialNo error: ' + error.message);
        this.composeText();
      });
  }

  /** 源码 g 类（年度点击）：A=String.valueOf(year) + f3() */
  private onYearClick(index: number): void {
    const picked: number = this.yearPicked;
    if (picked === -1) {
      return;
    }
    this.aYear = String(this.years[picked]);
    this.composeText();
  }

  /** 源码 h 类（编号点击）：B=entity.text + f3() */
  private onSerialClick(index: number): void {
    const picked: number = this.serialPicked;
    if (picked === -1) {
      return;
    }
    const entity: OaDocNumEntity | undefined = this.serials[picked];
    if (entity === undefined) {
      return;
    }
    this.bSerial = entity.text;
    this.composeText();
  }

  /** 源码 f3()：String.format("文号：%s %s %s", z, A, B) */
  private composeText(): void {
    this.docNumberText = '文号：' + this.zWord + ' ' + this.aYear + ' ' + this.bSerial;
  }

  /** 源码 i 类：三段任一空 → "请选择完整的文号"；否则 setResult(-1)（源码 bug：无 Intent） */
  private submit(): void {
    if (this.zWord === '' || this.aYear === '' || this.bSerial === '') {
      this.toast('请选择完整的文号');
      return;
    }
    // 源码 bug 保真：smali DocNumberActivity$i new Intent+putExtra 后 setResult(I) 单参无 data
    // → 调用方 j.y(null) TextUtils.isEmpty return（no-op）。HAP 回传空串同语义。
    AppStorage.setOrCreate<string>('doc_number_result', '');
    this.getUIContext().getRouter().back();
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  build() {
    Column() {
      TitleBar({ title: '选择', showBack: true })
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)
      if (this.isLoading) {
        Column() {
          LoadingView()
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        this.content()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** content_container：左分类 100dip + 2dip 竖线 + 右三段（字号/年度/编号） */
  @Builder
  content() {
    Column() {
      Row() {
        this.leftColumn()
        Column()
          .width(1)
          .height('100%')
          .backgroundColor($r('app.color.common_color_4'))
        Column() {
          this.rightSection('字号', this.words, this.wordPicked, (index: number): void => {
            this.wordPicked = index;
            this.onWordClick(index);
          })
          this.yearSection()
          this.rightSection('编号', this.serials, this.serialPicked, (index: number): void => {
            this.serialPicked = index;
            this.onSerialClick(index);
          })
        }
        .padding({ left: 12 })
        .layoutWeight(1)
        .height('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .alignItems(VerticalAlign.Top)

      Column()
        .width('100%')
        .height(0.5)
        .backgroundColor($r('app.color.common_color_4'))

      Row() {
        Text(this.docNumberText)
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .padding({ left: 16 })
          .layoutWeight(8)
          .height('100%')
          .textAlign(TextAlign.Start)
        Text('确定')
          .fontSize(17)
          .fontColor($r('app.color.white'))
          .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
          .layoutWeight(3)
          .height('100%')
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
      .height(50)
    }
    .width('100%')
    .layoutWeight(1)
  }

  /** 左列分类 ListView（singleChoice，mt30） */
  @Builder
  leftColumn() {
    Column() {
      List() {
        ForEach(this.categories, (entity: OaDocNumEntity, index: number) => {
          ListItem() {
            Text(entity.text)
              .fontSize(14)
              .fontColor(this.catPicked === index ? $r('app.color.mobile_campus_primary_color_default')
                : $r('app.color.common_color_1'))
              .width('100%')
              .padding({ left: 8, right: 8, top: 10, bottom: 10 })
              .textAlign(TextAlign.Center)
              .maxLines(2)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
          .onClick(() => {
            this.catPicked = index;
            this.onCategoryClick(index);
          })
        }, (entity: OaDocNumEntity) => entity.id)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width(100)
    .margin({ top: 15 })
    .height('100%')
  }

  /** 右侧字号/编号段：tag 12fp bg common_color_5 + ListView（singleChoice） */
  @Builder
  rightSection(tag: string, list: OaDocNumEntity[], picked: number, onPick: (index: number) => void) {
    Column() {
      Text(tag)
        .fontSize(12)
        .fontColor($r('app.color.common_color_1'))
        .backgroundColor($r('app.color.common_color_5'))
        .width('100%')
        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
    }
    .width('100%')
    .padding({ top: 15, right: 12 })
    List() {
      ForEach(list, (entity: OaDocNumEntity, index: number) => {
        ListItem() {
          Text(entity.text)
            .fontSize(14)
            .fontColor(picked === index ? $r('app.color.mobile_campus_primary_color_default')
              : $r('app.color.common_color_1'))
            .width('100%')
            .padding({ top: 8, bottom: 8 })
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .onClick(() => {
          onPick(index);
        })
      }, (entity: OaDocNumEntity) => entity.id + '_' + String(picked === list.indexOf(entity)))
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  /** 年度段（DocNumYear {year:number}） */
  @Builder
  yearSection() {
    Column() {
      Text('年度')
        .fontSize(12)
        .fontColor($r('app.color.common_color_1'))
        .backgroundColor($r('app.color.common_color_5'))
        .width('100%')
        .padding({ left: 6, right: 6, top: 4, bottom: 4 })
    }
    .width('100%')
    .padding({ top: 15, right: 12 })
    List() {
      ForEach(this.years, (year: number, index: number) => {
        ListItem() {
          Text(String(year))
            .fontSize(14)
            .fontColor(this.yearPicked === index ? $r('app.color.mobile_campus_primary_color_default')
              : $r('app.color.common_color_1'))
            .width('100%')
            .padding({ top: 8, bottom: 8 })
        }
        .onClick(() => {
          this.yearPicked = index;
          this.onYearClick(index);
        })
      }, (year: number) => String(year))
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }
}
