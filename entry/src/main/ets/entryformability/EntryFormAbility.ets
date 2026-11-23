import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { WidgetDataHelper } from '../common/WidgetDataHelper';

/**
 * 桌面服务卡片 FormExtensionAbility（今日课表 + 一卡通/待办快捷入口）
 */
export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = want.parameters ? String(want.parameters['ohos.extra.param.key.form_identity'] || '') : '';
    if (formId !== '') {
      WidgetDataHelper.saveFormId(this.context, formId);
    }
    return formBindingData.createFormBindingData(WidgetDataHelper.loadFormData(this.context));
  }

  onUpdateForm(formId: string): void {
    const data = formBindingData.createFormBindingData(WidgetDataHelper.loadFormData(this.context));
    // 更新卡片数据在下次宿主刷新或主动 updateForm 时生效
  }

  onFormEvent(_formId: string, _message: string): void {
    // 卡片内事件回调预留
  }

  onRemoveForm(formId: string): void {
    WidgetDataHelper.removeFormId(this.context, formId);
  }

  onAcquireFormState(_want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}
