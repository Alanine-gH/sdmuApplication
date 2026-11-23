import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { BusinessError } from '@kit.BasicServicesKit';
import { LoadingView } from '../components/LoadingView';
import { BreakpointSystem } from '../common/BreakpointSystem';

/**
 * 常用意见页 — 1:1 翻译原 APK TodoFastreplyActivity.java(503行)：
 *
 * 【页面结构】mobile_campus_oa_activity_todo_fastreply.xml（bg #fff2f2f2）：
 *   toolbar_normal：标题"常用意见"(T1 gVar.n) + 右"管理"(gVar.m，点击 Z2 切换)
 *   + common_lv 列表 + 底部 tvSubmit(49vp 白底 17fp #1B68B7 "确定"/"删除" alignParentBottom)；
 *   空态 llEmptyLayout（empty_fast_reply 图）替代内容区。
 *   列表项 mobile_campus_oa_view_todo_fast_reply2.xml：padL/R15 + ivCheck(chose/choose)
 *   + tvName 17fp #333(padL/R12 padT/B5) + ivEdit(icon_fast_reply_edit 仅管理模式可见) + 0.5 分隔线。
 *
 * 【数据流源码还原】（TodoPImpl.d1/Y0 → GET remark / POST updateOpinion）
 *   1. X2()（f1+f2 onResume）：o.O(...).x() → GET remark → String[] → TodoFastReplyBean{name,check:false}
 *   2. 项点击 a.a：u!=0(管理) 多选 toggle；u==0 单选（已选则保持，否则全清再选本条）
 *   3. 项编辑 a.b：弹窗"修改常用意见"预填 → 空 toast"内容不能为空"；否则 POST updateOpinion
 *      {remark: V2(i,newText)="[!_!]".join(替换后列表)} → "修改成功" + EventBus 17
 *   4. 长按 a.c（仅 u==1）：确认框"确定要删除吗？" → updateOpinion {remark: U2(i)=去 i 拼接} → "删除成功"
 *   5. 管理 Z2：u=0→1 右钮"完成"(#18B4ED) 底钮"删除"；u=1→0 右钮"管理"(#333) 底钮"确定"；清空勾选
 *   6. tvSubmit c.onClick：管理态收集勾选（无 → "请选择删除项"）→ 确认 → updateOpinion{T2()=未勾选拼接}
 *      → "删除成功"；选择态取勾选（无 → "请选择常用意见"）→ setResult("fastReply") finish
 *      （[W14] HAP 等价 router.back 携参，消费方=处理页 TodoProcedurePage 待翻译）
 *   7. Y2()：清空后列表空 → 右钮文案清空 + 切空态布局
 */
const SEP: string = '[!_!]';

class FastReplyItem {
  name: string = '';
  check: boolean = false;
}

@Entry
@Component
struct TodoFastReplyPage {
  @State items: FastReplyItem[] = [];
  @State loading: boolean = true;
  @State manageMode: boolean = false;
  /** 编辑弹窗状态 */
  @State showEditDialog: boolean = false;
  @State editIdx: number = -1;
  @State editText: string = '';
  @StorageProp('currentBreakpoint') currentBreakpoint: string = 'sm';
  @StorageProp('windowWidthVp') windowWidthVp: number = 360;
  @StorageProp('windowHeightVp') windowHeightVp: number = 780;
  @StorageProp('keyboardHeightVp') keyboardHeightVp: number = 0;
  /** 请求防抖（C0202a/C0203a 无 loading 锁，HAP 侧防重复提交） */
  private saving: boolean = false;

  onPageShow(): void {
    // 源码 f2 → X2()
    this.loadReplies();
  }

  // ===== 源码 X2：GET remark → String[] → TodoFastReplyBean[] =====
  private loadReplies(): void {
    this.loading = true;
    ApiService.getOaFastReplies()
      .then((response: ApiResponse<string[]>) => {
        this.loading = false;
        if (response.code === 1000) {
          // 网络层统一拦截，页面仅 return
          return;
        }
        if (response.code === 0) {
          const list: FastReplyItem[] = [];
          for (const one of response.data) {
            const item: FastReplyItem = new FastReplyItem();
            item.name = one;
            list.push(item);
          }
          this.items = list;
        } else {
          this.items = [];
          this.toast(response.message === '' ? '获取常用意见失败' : response.message);
        }
      })
      .catch((error: BusinessError) => {
        this.loading = false;
        ApiService.logError('TodoFastReply load fail: ' + error.message);
        this.items = [];
        this.toast('网络异常，请稍后重试');
      });
  }

  // ===== 源码 T2/U2/V2："[!_!]" 拼接（keep 模式三变体） =====
  private buildJoined(keep: (idx: number) => boolean, replaceIdx: number, replaceText: string): string {
    let joined: string = '';
    for (let i = 0; i < this.items.length; i++) {
      let name: string = this.items[i].name;
      if (i === replaceIdx) {
        name = replaceText;
      }
      if (keep(i)) {
        joined = joined + name + (i === this.items.length - 1 ? '' : SEP);
      }
    }
    return joined;
  }

  /** 源码 a.a(int)：管理态多选 / 选择态单选 */
  private onItemClick(idx: number): void {
    const copy: FastReplyItem[] = this.items.slice();
    if (this.manageMode) {
      copy[idx].check = !copy[idx].check;
      this.items = copy;
      return;
    }
    if (copy[idx].check) {
      return;
    }
    for (let i = 0; i < copy.length; i++) {
      copy[i].check = false;
    }
    copy[idx].check = true;
    this.items = copy;
  }

  // ===== 源码 a.b：编辑弹窗 → updateOpinion{V2} → "修改成功" =====
  private onEditConfirm(): void {
    const text: string = this.editText.trim();
    if (text === '') {
      this.toast('内容不能为空');
      return;
    }
    if (this.saving) {
      return;
    }
    this.saving = true;
    const joined: string = this.buildJoined((idx: number) => true, this.editIdx, text);
    ApiService.updateOaFastReplies(joined)
      .then((response: ApiResponse<Object>) => {
        this.saving = false;
        if (response.code === 1000) {
          // 网络层统一拦截，页面仅 return
          return;
        }
        if (response.code === 0) {
          this.showEditDialog = false;
          this.toast('修改成功');
          // 源码 g 回调：item.setName + notifyDataSetChanged + f.a(17,null)
          const copy: FastReplyItem[] = this.items.slice();
          copy[this.editIdx].name = text;
          this.items = copy;
        } else {
          this.toast(response.message);
        }
      })
      .catch((error: BusinessError) => {
        this.saving = false;
        ApiService.logError('TodoFastReply update fail: ' + error.message);
      });
  }

  // ===== 源码 b.a(h)/C0204a.a(h)：updateOpinion{joined} → "删除成功" → 移除条目 =====
  private deleteByJoined(joined: string, remove: number[]): void {
    if (this.saving) {
      return;
    }
    this.saving = true;
    ApiService.updateOaFastReplies(joined)
      .then((response: ApiResponse<Object>) => {
        this.saving = false;
        if (response.code === 1000) {
          // 网络层统一拦截，页面仅 return
          return;
        }
        if (response.code === 0) {
          this.toast('删除成功');
          const rest: FastReplyItem[] = [];
          for (let i = 0; i < this.items.length; i++) {
            if (remove.indexOf(i) < 0) {
              rest.push(this.items[i]);
            }
          }
          this.items = rest;
        } else {
          this.toast(response.message);
        }
      })
      .catch((error: BusinessError) => {
        this.saving = false;
        ApiService.logError('TodoFastReply delete fail: ' + error.message);
      });
  }

  /** 源码 a.c：长按删除确认（仅管理模式） */
  private onItemLongPress(idx: number): void {
    if (!this.manageMode) {
      return;
    }
    this.confirmDialog('确定要删除吗？', (): void => {
      const joined: string = this.buildJoined((keepIdx: number) => keepIdx !== idx, -1, '');
      this.deleteByJoined(joined, [idx]);
    });
  }

  /** 源码 Z2：管理/完成切换 + 重置勾选 */
  private toggleManage(): void {
    this.manageMode = !this.manageMode;
    const copy: FastReplyItem[] = this.items.slice();
    for (let i = 0; i < copy.length; i++) {
      copy[i].check = false;
    }
    this.items = copy;
  }

  // ===== 源码 c.onClick：底钮（选择态返回 / 管理态批量删除） =====
  private onSubmitClick(): void {
    if (this.manageMode) {
      const checked: number[] = [];
      for (let i = 0; i < this.items.length; i++) {
        if (this.items[i].check) {
          checked.push(i);
        }
      }
      if (checked.length === 0) {
        this.toast('请选择删除项');
        return;
      }
      this.confirmDialog('确定要删除吗？', (): void => {
        const joined: string = this.buildJoined((keepIdx: number) => checked.indexOf(keepIdx) < 0, -1, '');
        this.deleteByJoined(joined, checked);
      });
      return;
    }
    // 源码 u==0：取最后一个勾选项（循环覆盖语义）
    let picked: number = -1;
    for (let i = 0; i < this.items.length; i++) {
      if (this.items[i].check) {
        picked = i;
      }
    }
    if (picked < 0) {
      this.toast('请选择常用意见');
      return;
    }
    // 源码 setResult(-1, intent{fastReply}) + finish：宿主=处理页 TodoProcedureActivity/TodoProcedureOtherActivity
    // （e.a.F，requestCode 120；处理页待翻译，届时消费 AppStorage）。按本批统一 AppStorage 管道（edited_todo_form 同款）
    AppStorage.setOrCreate('fast_reply_result', this.items[picked].name);
    router.back();
  }

  private confirmDialog(message: string, onConfirm: () => void): void {
    AlertDialog.show({
      message: message,
      autoCancel: true,
      alignment: DialogAlignment.Center,
      primaryButton: {
        value: '取消',
        action: (): void => {
        }
      },
      secondaryButton: {
        value: '确定',
        action: (): void => {
          onConfirm();
        }
      }
    });
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  build() {
    Stack() {
      Column() {
        this.topBar()
        if (this.loading) {
          Column() {
            LoadingView()
          }
          .width('100%')
          .layoutWeight(1)
        } else if (this.items.length === 0) {
          // 源码 Y2：列表空 → llEmptyLayout（empty_fast_reply）
          Column() {
            Image($r('app.media.empty_fast_reply'))
              .width(140)
              .height(140)
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .backgroundColor($r('app.color.common_color_6'))
        } else {
          this.replyList()
        }
        if (this.items.length > 0) {
          Text(this.manageMode ? '删除' : '确定')
            .fontSize(17)
            .fontColor($r('app.color.mobile_campus_primary_color_default'))
            .textAlign(TextAlign.Center)
            .width('100%')
            .height(49)
            .backgroundColor($r('app.color.white'))
            .onClick(() => {
              this.onSubmitClick();
            })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.common_color_6'))
      if (this.showEditDialog) {
        this.editDialogOverlay()
      }
    }
    .width('100%')
    .height('100%')
  }

  /** toolbar_normal：标题"常用意见" + 右"管理/完成"（Z2 切色 #333 ↔ #18B4ED） */
  @Builder
  topBar() {
    Column() {
      Row() {
        Image($r('app.media.nav_back_btn'))
          .width(24)
          .height(24)
          .margin({ left: 10 })
          .onClick(() => {
            // 源码 v.setOnClickListener/onBackPressed → finish
            router.back();
          })
        Text('常用意见')
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .textAlign(TextAlign.Center)
          .maxLines(1)
          .layoutWeight(1)
        Text(this.manageMode ? '完成' : '管理')
          .fontSize(16)
          .fontColor(this.manageMode ? $r('app.color.ybg_blue') : $r('app.color.common_color_1'))
          .margin({ right: 12 })
          .onClick(() => {
            this.toggleManage();
          })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))
      Divider()
        .color($r('app.color.common_color_5'))
        .strokeWidth(0.5)
        .width('100%')
    }
    .width('100%')
    .backgroundColor($r('app.color.main_bg'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }

  /** mobile_campus_oa_view_todo_fast_reply2.xml：padL/R15 + 勾选图标 + 名称17fp + 编辑图标 */
  @Builder
  replyList() {
    List({ space: 0 }) {
      ForEach(this.items, (item: FastReplyItem, idx: number) => {
        ListItem() {
          Column() {
            Row() {
              Image(item.check ? $r('app.media.mobile_campus_oa_choose') :
                $r('app.media.mobile_campus_oa_chose'))
                .width(20)
                .height(20)
              Text(item.name)
                .fontSize(17)
                .fontColor($r('app.color.common_color_1'))
                .padding({ left: 12, right: 12, top: 5, bottom: 5 })
                .layoutWeight(1)
              if (this.manageMode) {
                Image($r('app.media.icon_fast_reply_edit'))
                  .width(22)
                  .height(22)
                  .padding(5)
                  .onClick(() => {
                    // 源码 a.b：修改常用意见弹窗预填
                    this.editIdx = idx;
                    this.editText = item.name;
                    this.showEditDialog = true;
                  })
              }
            }
            .width('100%')
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              this.onItemClick(idx);
            })
            .gesture(LongPressGesture().onAction(() => {
              this.onItemLongPress(idx);
            }))
            Divider()
              .color($r('app.color.common_color_5'))
              .strokeWidth(0.5)
              .width('100%')
          }
          .width('100%')
          .backgroundColor($r('app.color.white'))
        }
      }, (item: FastReplyItem, idx: number) => idx.toString() + '-' + item.name)
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Off)
  }

  /** 源码 dialog.a("修改常用意见")：输入预填 + 确定/取消 */
  @Builder
  editDialogOverlay() {
    Column() {
      Scroll() {
        Column({ space: 14 }) {
          Text('修改常用意见')
            .fontSize(16)
            .fontColor($r('app.color.common_color_1'))
            .fontWeight(FontWeight.Bold)
          TextInput({
            text: this.editText,
            placeholder: '请输入常用意见'
          })
            .fontSize(15)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor('#B5B5B5')
            .height(40)
            .backgroundColor($r('app.color.common_color_6'))
            .borderRadius(4)
            .padding({ left: 10, right: 10 })
            .enterKeyType(EnterKeyType.Done)
            .onChange((value: string) => {
              this.editText = value;
            })
            .onSubmit(() => {
              this.onEditConfirm();
            })
          Row({ space: 12 }) {
            Text('取消')
              .fontSize(15)
              .fontColor($r('app.color.common_color_3'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .padding({ top: 10, bottom: 10 })
              .borderRadius(4)
              .backgroundColor($r('app.color.common_color_6'))
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.showEditDialog = false;
              })
            Text('确定')
              .fontSize(15)
              .fontColor($r('app.color.white'))
              .textAlign(TextAlign.Center)
              .layoutWeight(1)
              .padding({ top: 10, bottom: 10 })
              .borderRadius(4)
              .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
              .hoverEffect(HoverEffect.Highlight)
              .onClick(() => {
                this.onEditConfirm();
              })
          }
          .width('100%')
        }
        .padding(16)
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .backgroundColor($r('app.color.white'))
      .borderRadius(8)
      .width(BreakpointSystem.getDialogMaxWidth(this.currentBreakpoint, this.windowWidthVp))
      .constraintSize({ maxHeight: BreakpointSystem.getDialogMaxHeight(this.windowHeightVp) })
      .onClick(() => {
        // 拦截弹窗内点击
      })
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16, bottom: this.keyboardHeightVp })
    .backgroundColor('#66000000')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => {
      this.showEditDialog = false;
    })
  }
}
