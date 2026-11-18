import { router } from '@kit.ArkUI';
import { ApiService } from '../network/ApiService';
import { ApiResponse } from '../model/ResponseModel';
import { OaSubDeptResult, OaSubDeptUser } from '../model/OaTodoModel';
import { EmptyView } from '../components/EmptyView';
import { LoadingView } from '../components/LoadingView';
import { BusinessError } from '@kit.BasicServicesKit';

/**
 * 待办部门搜索选择页 — 源码级翻译（W23，原 1:1 XML 复刻版+mock 清除重写）：
 * APK TodoSearchDepartmentActivity（oa/selector/view，/selector/department 搜索入口）：
 *
 * 【布局】mobile_campus_oa_activity_todo_search_department.xml：
 *   mobile_campus_toolbar_base_search（搜索框 hint"输入关键字搜索..."（f1 setHint 覆盖）
 *   + 取消）+ MultiStateView（ListView + layoutBottom）。
 * 【数据流源码还原】
 *   c 类 IME action（3=SEARCH/6=DONE）→ S2(trim keyword) → SelectPImpl.t → SelectModel.c1：
 *   GET searchDepartment {keyword} → Department{title, departmentList:[{BMDM,BMMC,count,isChildren}]}
 *   （2026-11-18 实测"学院"→国际交流学院/继续教育学院/工会干部教育培训学院…多条 code=0）
 *   g 回调：r.setData(departmentList)；count>0 → v(content)；空 → t(EMPTY_SEARCH)；
 *   -3010 → ERROR_NETWORK；失败 toast=m(str2)。
 * 【列表】TodoSearchDepartmentAdapter（mobile_campus_oa_view_todo_search_department.xml：
 *   SingleItemCheckLayout 白底 padL12 行96(px_to_dip_96=48dip×2)+cb 40(px_to_dip_40=20dip
 *   mobile_campus_oa_todo_cb)+tvTitle 34(px_to_sp_34=17fp) ml24(12dip)+tvNext"下级"恒 gone
 *   （adapter 只绑 BMMC，无点击回调设置）+ thin 分隔线）。
 *   ListView choiceMode=2 多选；条目点击（b 类）→ o.setText("已选择："+R2()+"人")
 *   （R2=勾选行 count 求和）。
 * 【提交】d 类 tvSubmit → setResult(list)=Q2()（勾选行 Parcelable）+ finish，无 200 上限校验。
 * 【返回消费】HAP 等价 AppStorage 'oa_search_dept_result'（JSON [{BMDM,BMMC,count}]）+ back；
 *   消费方=EditTodoDetailPage/WorkApplyFormConfigPage（single/multiDeptPicker 回填，onPageShow）。
 * 【禁 mock】原占位 10 条假部门全清；空态 EMPTY_SEARCH=真实空态。
 */
interface SearchDeptNavParams {
  mode: string;
}

@Entry
@Component
struct TodoSearchDepartmentPage {
  @State keyword: string = '';
  @State departments: OaSubDeptUser[] = [];
  @State checkedKeys: string[] = [];
  @State selectedCount: number = 0;
  @State isLoading: boolean = true;
  @State searched: boolean = false;
  @State errorNetwork: boolean = false;
  /** 源码 ListView choiceMode：singleDeptPicker 单选 / multiDeptPicker 多选（入参 mode） */
  private mode: string = 'multiDeptPicker';

  aboutToAppear(): void {
    const params: Record<string, Object> | undefined = router.getParams() as Record<string, Object> | undefined;
    if (params !== undefined && params !== null) {
      const md: Object = params['mode'];
      if (typeof md === 'string' && (md as string) !== '') {
        this.mode = md as string;
      }
    }
  }

  onPageShow(): void {
    // 无结果冒泡场景（本页为叶子选择页）：返回即结束
  }

  /** 源码 c 类：IME action（SEARCH/DONE）→ S2(trim) → searchDepartment */
  private submitSearch(): void {
    const keyword: string = this.keyword.trim();
    this.isLoading = true;
    this.searched = true;
    ApiService.searchOaDepartments(keyword)
      .then((response: ApiResponse<OaSubDeptResult>) => {
        if (response.code === 1000) {
          return;
        }
        if (response.code === 0) {
          this.departments = response.data.resultData;
          this.errorNetwork = false;
        } else if (response.code === -3010) {
          this.errorNetwork = true;
          this.departments = [];
        } else {
          this.departments = [];
          this.errorNetwork = false;
          this.toast(response.message);
        }
        this.isLoading = false;
        this.refreshCount();
      })
      .catch((error: BusinessError) => {
        ApiService.logError('searchDepartment fail: ' + error.message);
        this.errorNetwork = true;
        this.departments = [];
        this.isLoading = false;
      });
  }

  private isChecked(bmdm: string): boolean {
    return this.checkedKeys.indexOf(bmdm) >= 0;
  }

  /** 源码 e 类 onItemClicked：singleUserPicker 单选/多选 toggle（ListView choiceMode 等价） */
  private onRowClick(bean: OaSubDeptUser): void {
    if (this.mode === 'singleDeptPicker') {
      this.checkedKeys = [bean.BMDM];
    } else if (this.isChecked(bean.BMDM)) {
      const rest: string[] = [];
      for (const k of this.checkedKeys) {
        if (k !== bean.BMDM) {
          rest.push(k);
        }
      }
      this.checkedKeys = rest;
    } else {
      this.checkedKeys = this.checkedKeys.concat([bean.BMDM]);
    }
    this.refreshCount();
  }

  /** 源码 Q2()/R2()：勾选行 + count 求和 */
  private refreshCount(): void {
    let total: number = 0;
    for (const bean of this.departments) {
      if (this.isChecked(bean.BMDM)) {
        total += bean.count;
      }
    }
    this.selectedCount = total;
  }

  /** 源码 d 类 tvSubmit：setResult(Q2) finish → AppStorage 管道 + back */
  private submit(): void {
    const rows: Record<string, Object>[] = [];
    for (const bean of this.departments) {
      if (this.isChecked(bean.BMDM)) {
        rows.push({
          'BMDM': bean.BMDM,
          'BMMC': bean.BMMC,
          'count': bean.count,
          'isChildren': '0'
        });
      }
    }
    AppStorage.setOrCreate<string>('oa_search_dept_result', JSON.stringify(rows));
    this.getUIContext().getRouter().back();
  }

  private toast(message: string): void {
    this.getUIContext().getPromptAction().showToast({ message: message });
  }

  build() {
    Column() {
      // mobile_campus_toolbar_base_search.xml：搜索框 32 圆角灰 + 取消
      Row() {
        Row() {
          Image($r('app.media.search_b'))
            .width(16)
            .height(16)
            .margin({ left: 8, right: 9 })
          TextInput({ placeholder: '输入关键字搜索...', text: this.keyword })
            .fontSize(14)
            .fontColor($r('app.color.common_color_1'))
            .placeholderColor('#B5B5B5')
            .placeholderFont({ size: 14 })
            .backgroundColor(Color.Transparent)
            .padding({ left: 0, right: 8 })
            .height('100%')
            .layoutWeight(1)
            .onChange((value: string) => {
              this.keyword = value;
            })
            .onSubmit((enterKey: EnterKeyType) => {
              // 源码 c 类：IME_ACTION_SEARCH(3)/IME_ACTION_DONE(6) 触发搜索
              if (enterKey === EnterKeyType.Search || enterKey === EnterKeyType.Done) {
                this.submitSearch();
              }
            })
        }
        .width('100%')
        .height(32)
        .margin({ right: 4 })
        .borderRadius(8)
        .backgroundColor($r('app.color.common_color_6'))
        .alignItems(VerticalAlign.Center)

        Text('取消')
          .fontSize(14)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 8 })
          .height(44)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.getUIContext().getRouter().back();
          })
      }
      .width('100%')
      .height(44)
      .padding({ right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.main_bg'))

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)

      if (this.isLoading) {
        Column() {
          LoadingView()
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.errorNetwork) {
        Column() {
          EmptyView({ tipText: '网络异常，请稍后重试' })
        }
        .width('100%')
        .layoutWeight(1)
      } else if (this.departments.length === 0) {
        Column() {
          // 源码 s2/t(m, EMPTY_SEARCH)：空搜索结果真实空态
          EmptyView({ tipText: this.searched ? '暂无搜索结果' : '输入关键字搜索部门' })
        }
        .width('100%')
        .layoutWeight(1)
      } else {
        this.listContent()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** MultiStateView content：ListView + layoutBottom */
  @Builder
  listContent() {
    Column() {
      List() {
        ForEach(this.departments, (bean: OaSubDeptUser) => {
          ListItem() {
            this.deptRow(bean)
          }
        }, (bean: OaSubDeptUser) => bean.BMDM)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .backgroundColor(Color.Transparent)

      // layoutBottom：98(px_to_dip_98=49dip) 白底 padL12 已选择 + 确定(160=80dip)
      Row() {
        Text('已选择：' + this.selectedCount + '人')
          .fontSize(16)
          .fontColor($r('app.color.mobile_campus_primary_color_default'))
        Blank()
        Text('确定')
          .fontSize(17)
          .fontColor($r('app.color.white'))
          .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
          .width(80)
          .height('100%')
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.submit();
          })
      }
      .width('100%')
      .height(49)
      .padding({ left: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
    }
    .width('100%')
    .layoutWeight(1)
  }

  /** mobile_campus_oa_view_todo_search_department 行：cb20 + tvTitle 17fp ml12 + tvNext 恒 gone */
  @Builder
  deptRow(bean: OaSubDeptUser) {
    Column() {
      Row() {
        this.checkBox(this.isChecked(bean.BMDM))
        Text(bean.BMMC)
          .fontSize(17)
          .fontColor($r('app.color.common_color_1'))
          .margin({ left: 12 })
          .maxLines(1)
          .layoutWeight(1)
        // 源码 TodoSearchDepartmentAdapter：tvNext visibility=gone（保真不渲染）
      }
      .width('100%')
      .height(48)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.white'))
      .onClick(() => {
        this.onRowClick(bean);
      })

      Divider().color($r('app.color.common_color_5')).strokeWidth(0.5)
    }
    .width('100%')
    .backgroundColor($r('app.color.white'))
  }

  /** mobile_campus_oa_todo_cb 复选框20（selected 时 title 也随行底色，HAP 沿项目 Circle 等价） */
  @Builder
  checkBox(checked: boolean) {
    Stack() {
      Circle()
        .width(20)
        .height(20)
        .fill(Color.Transparent)
        .stroke(checked ? $r('app.color.mobile_campus_primary_color_default') : $r('app.color.common_color_3'))
        .strokeWidth(1)
      if (checked) {
        Text('✓')
          .fontSize(12)
          .fontColor($r('app.color.white'))
          .backgroundColor($r('app.color.mobile_campus_primary_color_default'))
          .width(20)
          .height(20)
          .textAlign(TextAlign.Center)
          .borderRadius(10)
      }
    }
    .width(20)
    .height(20)
  }
}
