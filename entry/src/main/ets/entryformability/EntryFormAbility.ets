import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';

/**
 * 桌面服务卡片 FormExtensionAbility（今日课表 + 一卡通/待办快捷入口）
 */
export default class EntryFormAbility extends FormExtensionAbility {
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formData: Record<string, Object> = {
      'title': '今日课表',
      'subtitle': '点击查看完整课表',
      'cardTitle': '校园快捷入口'
    };
    return formBindingData.createFormBindingData(formData);
  }

  onUpdateForm(_formId: string): void {
    // 定时/主动刷新预留
  }

  onFormEvent(_formId: string, _message: string): void {
    // 卡片内事件回调预留
  }

  onRemoveForm(_formId: string): void {
    // 卡片移除清理预留
  }

  onAcquireFormState(_want: Want): formInfo.FormState {
    return formInfo.FormState.READY;
  }
}
