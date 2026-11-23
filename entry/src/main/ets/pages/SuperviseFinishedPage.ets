import { router } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { SuperviseListenDetail } from '../model/SuperviseModel';
import { TitleBar } from '../components/TitleBar';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';

/**
 * 已完成督导详情页 — 源码级翻译 [P-C placeholder]（SuperviseLectureFinishActivity.java 逐行 → ArkTS）：
 *
 * 【考证】manifest L404 SuperviseLectureFinishActivity；入口 SuperviseMinePage:435
 *   "我的督导"-已过期行 {xlh} → H0 /supervise/finished。标题源码 T1=gVar.n("听课详情")
 *   + 右上 gVar.m("编辑")（toolBar_text_but 点击 d(gVar) 切换 编辑/保存）。
 * 【布局】mobile_campus_supervise_activity_supervise_finished.xml：toolbar + NestedScrollView
 *   （LectureDetailView supervise_detail_finished + LectureEvaluateEditView supervise_evaluate_finished mt24px→12vp）。
 * 【LectureDetailView】setLectureData(KCMC, SKLSXM, SKLS, BMMC, QSJSZ, "周"+XQJ+" "+DJJ, SKDD)
 *   + setSuperviseData(LISTENTIME) → divider/听课时间行 visible（本页显示，颜色 primary）；
 *   七行同 lecture_detail.xml（标签 14sp #999 / 值 14sp #333，课程名 16sp #1B68B7）。
 * 【LectureEvaluateEditView】mobile_campus_supervise_layout_evaluate_editable.xml：
 *   "教学评价"13sp 居中 + divider + 应到/实到人数两列（TextStyle5 宽136px→68vp maxLength3 number，
 *   实到值色 #E60012）+ divider + BaseRatingBar(5星 starSize20px→10vp starPadding8px→4vp
 *   touchable 初始 false) + 评价框 hint"本次课程整体效果如何呢？"(lines5) +
 *   "删除听课"钮（#E60012，setEditeable(false) 初始 visibility=gone）。
 * 【交互】d.onClick：p!=null 时 q 翻转；q=true→"保存"+setEditeable(true)；q=false→"编辑"+
 *   U2(p.XLH, rating, expect, actual, content, p.LISTENTIME, p.REMIND, p.REMINDTIME) → updateListenCourse
 *   （e.g data=="true"→toast"保存成功"）。删除钮 b→S2→deleteListen{xlh}（c.g data=="true"
 *   →toast"删除成功"+setResult(-1)+finish）。源码 U2 保存无 getWarnMsg 校验（方法未被调用）。
 * 【数据】T2→X0 detailsListen{xlh}→DetailsListen（a.g 填 7 字段 + setData(YDRS,SDRS,DJ,NR)）。
 * 【探针】probe_p_c_placeholder.py：detailsListen 假 xlh code=0001、deleteListen/updateListenCourse
 *   假参 code=0 data=false（端点存活，服务端业务校验）；测试账号无真实督导记录 → 真实空态。
 */

class FStar {
  index: number;
  lit: boolean;

  constructor(index: number, lit: boolean) {
    this.index = index;
    this.lit = lit;
  }
}

@Entry
@Component
struct SuperviseFinishedPage {
  @State detail: SuperviseListenDetail | null = null;
  @State isLoading: boolean = true;
  @State showError: boolean = false;
  @State xlh: string = '';
  /** 源码 LectureEvaluateEditView 四输入 + rating */
  @State expect: string = '';
  @State actual: string = '';
  @State content: string = '';
  @State rating: number = 0;
  @State stars: FStar[] = [
    new FStar(1, false), new FStar(2, false), new FStar(3, false),
    new FStar(4, false), new FStar(5, false)
  ];
  /** 源码 d(gVar) 的 q 标志：false=查看（"编辑"）/true=编辑（"保存"） */
  @State editable: boolean = false;
  @State rightText: string = '编辑';
  @State isSaving: boolean = false;

  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    if (params !== undefined && params !== null) {
      const rec: Record<string, Object> = params as Record<string, Object>;
      const v: Object = rec['xlh'];
      if (typeof v === 'string') { this.xlh = v as string; }
    }
    this.loadDetail();
  }

  /** 源码 f1()→T2()：n.u(a).m(xlh) → X0 detailsListen */
  private loadDetail(): void {
    this.isLoading = true;
    this.showError = false;
    ApiService.getSuperviseListenDetail(this.xlh)
      .then((response: ApiResponse<SuperviseListenDetail>) => {
        this.isLoading = false;
        if (response.code !== 0 || response.data.KCMC === '') {
          this.showError = true;
          return;
        }
        this.detail = response.data;
        // 源码 a.g：m.setData(YDRS, SDRS, DJ, NR)
        this.expect = response.data.YDRS;
        this.actual = response.data.SDRS;
        this.content = response.data.NR;
        this.rating = response.data.DJ === '' ? 0 : Number(response.data.DJ);
        this.refreshStars();
      })
      .catch((error: BusinessError) => {
        this.isLoading = false;
        this.showError = true;
        ApiService.logError('SuperviseFinishedPage detail fail: ' + error.message);
      });
  }

  private refreshStars(): void {
    this.stars = this.stars.map((star: FStar): FStar => {
      return new FStar(star.index, star.index <= this.rating);
    });
  }

  /** 源码 d.onClick：q 翻转；off→U2 保存（无 getWarnMsg 校验） */
  private toggleEdit(): void {
    if (this.detail === null) { return; }
    if (!this.editable) {
      this.editable = true;
      this.rightText = '保存';
      return;
    }
    this.editable = false;
    this.rightText = '编辑';
    this.save();
  }

  /** 源码 U2 → SuperviseModel.d1 → updateListenCourse 8 参 */
  private save(): void {
    if (this.detail === null || this.isSaving) { return; }
    this.isSaving = true;
    ApiService.updateSuperviseListen(String(this.rating), this.expect, this.actual, this.content,
      this.detail.LISTENTIME, this.detail.REMIND, this.detail.REMINDTIME, this.detail.XLH)
      .then((response: ApiResponse<string>) => {
        this.isSaving = false;
        if (response.code === 0 && response.data === 'true') {
          this.getUIContext().getPromptAction().showToast({ message: '保存成功' });
        } else {
          this.getUIContext().getPromptAction().showToast({
            message: response.message === '' ? '保存失败' : response.message
          });
        }
      })
      .catch((error: BusinessError) => {
        this.isSaving = false;
        ApiService.logError('SuperviseFinishedPage save fail: ' + error.message);
        this.getUIContext().getPromptAction().showToast({ message: '保存失败' });
      });
  }

  /** 源码 b.onClick → S2() → V0 deleteListen{xlh}；c.g data=="true" → 删除成功 + back */
  private remove(): void {
    if (this.detail === null) { return; }
    ApiService.deleteSuperviseListen(this.detail.XLH)
      .then((response: ApiResponse<string>) => {
        if (response.code === 0 && response.data === 'true') {
          this.getUIContext().getPromptAction().showToast({ message: '删除成功' });
          AppStorage.setOrCreate<string>('supervise_finished_deleted', '1');
          router.back();
        } else {
          this.getUIContext().getPromptAction().showToast({
            message: response.message === '' ? '删除失败' : response.message
          });
        }
      })
      .catch((error: BusinessError) => {
        ApiService.logError('SuperviseFinishedPage delete fail: ' + error.message);
        this.getUIContext().getPromptAction().showToast({ message: '删除失败' });
      });
  }

  /** 源码 LectureDetailView 七字段 + setSuperviseData(LISTENTIME) 听课时间行（本页显示） */
  @Builder
  detailCard(d: SuperviseListenDetail) {
    Column() {
      Text(d.KCMC)
        .fontSize(16).fontColor('#1B68B7').margin({ bottom: 22 }).maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
      // 源码 lecture_detail.xml 首行：任课教师/工号同一水平行各 weight=1
      Row() {
        Row() {
          Text('任课教师')
            .fontSize(14).fontColor($r('app.color.common_color_3'))
            .maxLines(1).margin({ right: 12 })
          Text(d.SKLSXM)
            .fontSize(14).fontColor($r('app.color.common_color_1'))
            .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1).alignItems(VerticalAlign.Center)

        Row() {
          Text('工号')
            .fontSize(14).fontColor($r('app.color.common_color_3'))
            .maxLines(1).margin({ right: 12 })
          Text(d.SKLS)
            .fontSize(14).fontColor($r('app.color.common_color_1'))
            .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .layoutWeight(1).alignItems(VerticalAlign.Center)
      }
      .width('100%')

      this.detailRow('开课院系', d.BMMC, 12)
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5).margin({ top: 17, bottom: 17 })
      this.detailRow('开课周数', d.QSJSZ)
      this.detailRow('上课节数', '周' + d.XQJ + ' ' + d.DJJ, 12)
      this.detailRow('上课地点', d.SKDD, 12)
      this.detailRow('听课时间', d.LISTENTIME, 12)
    }
    .width('100%')
    .padding({ left: 12, right: 12, top: 20, bottom: 20 })
    .backgroundColor($r('app.color.white'))
  }

  @Builder
  detailRow(label: string, value: string, top: number = 0) {
    Row() {
      Text(label)
        .fontSize(14).fontColor($r('app.color.common_color_3'))
        .maxLines(1).margin({ right: 12 })
      Text(value)
        .fontSize(14).fontColor(label === '听课时间' ?
          $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_1'))
        .layoutWeight(1).maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .margin({ top: top })
    .alignItems(VerticalAlign.Center)
  }

  /** 源码 LectureEvaluateEditView：教学评价 + 应到/实到 + 星级 + 评价框 + 删除听课 */
  @Builder
  evaluateCard() {
    Column() {
      Text('教学评价').fontSize(13).fontColor($r('app.color.common_color_3'))
        .textAlign(TextAlign.Center).width('100%').padding({ top: 12, bottom: 12 })
      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

      Row() {
        this.attendanceInput('应到人数', this.expect, false)
        this.attendanceInput('实到人数', this.actual, true)
      }
      .width('100%').margin({ top: 24, bottom: 21 }).alignItems(VerticalAlign.Center)

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

      Row({ space: 4 }) {
        ForEach(this.stars, (star: FStar) => {
          Image(star.lit ? $r('app.media.mobile_campus_supervise_star_light') :
            $r('app.media.mobile_campus_supervise_star_grey'))
            .width(10).height(10)
            .onClick(() => {
              if (this.editable) { this.rating = star.index; this.refreshStars(); }
            })
        }, (star: FStar) => star.index.toString())
      }
      .margin({ top: 15, bottom: 15 })

      TextArea({ text: this.content, placeholder: '本次课程整体效果如何呢？' })
        .fontSize(14).fontColor($r('app.color.common_color_1'))
        .placeholderColor($r('app.color.edit_hint_color'))
        .backgroundColor($r('app.color.mobile_campus_supervise_evaluate_edittext_solid'))
        .borderRadius(4)
        .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_evaluate_edittext_stroke') })
        .padding(7).height(120).width('100%')
        .enabled(this.editable)
        .onChange((value: string) => { this.content = value; })

      if (this.editable) {
        Column() {
          Text('删除听课').fontSize(14).fontColor($r('app.color.mobile_campus_supervise_edit_textcolor'))
            .textAlign(TextAlign.Center).width('100%').padding({ top: 10, bottom: 10 })
            .borderRadius(4)
            .backgroundColor($r('app.color.common_color_6'))
            .onClick(() => { this.remove(); })
        }
        .width('100%')
        .padding({ left: 9, right: 9, top: 21 })
      }
    }
    .width('100%')
    .padding({ left: 12, right: 12, bottom: 20 })
    .backgroundColor($r('app.color.white'))
  }

  @Builder
  attendanceInput(label: string, value: string, isActual: boolean) {
    Row() {
      Text(label).fontSize(14).fontColor($r('app.color.common_color_1')).margin({ right: 12 })
      TextInput({ text: value })
        .fontSize(14)
        .fontColor(isActual ? $r('app.color.mobile_campus_supervise_edit_textcolor') :
          $r('app.color.common_color_1'))
        .maxLength(3).type(InputType.Number).textAlign(TextAlign.Center)
        .width(68).height(36).padding({ top: 8, bottom: 8 })
        .backgroundColor($r('app.color.mobile_campus_supervise_evaluate_edittext_solid'))
        .borderRadius(4)
        .border({ width: 0.5, color: $r('app.color.mobile_campus_supervise_evaluate_edittext_stroke') })
        .enabled(this.editable)
        .onChange((text: string) => {
          if (isActual) { this.actual = text; } else { this.expect = text; }
        })
    }
    .layoutWeight(1)
  }

  build() {
    Column() {
      // T1：听课详情 + 右上"编辑"/"保存"
      TitleBar({
        title: '听课详情', showBack: true, rightText: this.rightText,
        rightTextColor: '#1B68B7',
        onRightClick: () => { this.toggleEdit(); }
      })

      if (this.isLoading) {
        LoadingView()
      } else if (this.showError || this.detail === null) {
        EmptyView({ tipText: '暂无督导详情' })
      } else {
        Scroll() {
          Column() {
            this.detailCard(this.detail as SuperviseListenDetail)
            Column() { this.evaluateCard() }
              .width('100%').padding({ left: 12, right: 12, top: 12 })
          }
          .width('100%')
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
      }
    }
    .width('100%').height('100%')
    .backgroundColor($r('app.color.common_color_6'))
  }
}
