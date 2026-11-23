import { formBindingData, formProvider, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { WidgetDataHelper } from '../common/WidgetDataHelper';

/**
 * 桌面服务卡片 FormExtensionAbility（4×4 本周/今日交互课表 + 一卡通/待办快捷入口）
 */
export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = want.parameters ? String(want.parameters['ohos.extra.param.key.form_identity'] || '') : '';
    if (formId !== '') {
      WidgetDataHelper.saveFormId(this.context, formId);
    }
    return formBindingData.createFormBindingData(WidgetDataHelper.loadFormData(this.context, formId));
  }

  onUpdateForm(formId: string): void {
    const data = formBindingData.createFormBindingData(WidgetDataHelper.loadFormData(this.context, formId));
    formProvider.updateForm(formId, data).catch(() => {
      // 卡片刷新异常忽略
    });
  }

  onFormEvent(formId: string, message: string): void {
    WidgetDataHelper.handleFormEvent(this.context, formId, message);
  }

  onRemoveForm(formId: string): void {
    WidgetDataHelper.removeFormId(this.context, formId);
  }

  onAcquireFormState(_want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}
