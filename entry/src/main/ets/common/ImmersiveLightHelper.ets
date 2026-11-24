import { uiMaterial } from '@kit.ArkUI';

/**
 * 鸿蒙 API 26 原生沉浸光感材质助手（基于 @kit.ArkUI uiMaterial.ImmersiveMaterial）
 * 配合 module.json5 中 ohos.arkui.UIMaterial.state=enable 使用；
 * 挂载 systemMaterial 的组件需避免同时设置不透明 backgroundColor，使用 fallbackBg() 透出液态玻璃折射与光感。
 */
export class ImmersiveLightHelper {
  /**
   * 检测当前设备是否支持完整着色与折射的沉浸光感材质（EXQUISITE / GENTLE 算力档位）。
   * 注：依据 @ohos.arkui.uiMaterial.d.ts 规范，MaterialLevel.SMOOTH（如模拟器或低算力设备）
   * 不生效 materialColor 与 style，且会强制覆盖组件的 backgroundColor 与 border 为白底，
   * 会导致白字主按钮（如"登录"、"获取验证码"）在白底页面上变成白底白字不可见。
   */
  public static isSupported(): boolean {
    try {
      if (!uiMaterial.isImmersiveMaterialSupported()) {
        return false;
      }
      const level: uiMaterial.MaterialLevel = uiMaterial.getGlobalMaterialLevel();
      return level === uiMaterial.MaterialLevel.EXQUISITE || level === uiMaterial.MaterialLevel.GENTLE;
    } catch {
      return false;
    }
  }

  /** 返回组件底色：保留原始语义背景色作为衬底，防止白底页面上出现透明/白底白字 */
  public static fallbackBg(color: ResourceColor): ResourceColor {
    return color;
  }

  /** 主按钮沉浸光感材质（山管主题红半透玻璃 + 白色按压光感） */
  public static primaryButtonMaterial(): uiMaterial.ImmersiveMaterial | undefined {
    if (!ImmersiveLightHelper.isSupported()) {
      return undefined;
    }
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.REGULAR,
      materialColor: '#CC97000C',
      applyShadow: true,
      interactive: true,
      lightEffect: { color: Color.White }
    });
  }

  /** 次按钮沉浸光感材质（浅透白玻璃 + 主题红微光反馈） */
  public static secondaryButtonMaterial(): uiMaterial.ImmersiveMaterial | undefined {
    if (!ImmersiveLightHelper.isSupported()) {
      return undefined;
    }
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.THIN,
      materialColor: '#B8FFFFFF',
      applyShadow: true,
      interactive: true,
      lightEffect: { color: '#6697000C' }
    });
  }

  /** 卡片沉浸光感材质 */
  public static cardMaterial(): uiMaterial.ImmersiveMaterial | undefined {
    if (!ImmersiveLightHelper.isSupported()) {
      return undefined;
    }
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.THIN,
      materialColor: '#CCFFFFFF',
      applyShadow: true,
      interactive: true,
      lightEffect: { color: '#5597000C' }
    });
  }

  /** 标题栏/侧栏胶囊按钮沉浸光感材质 */
  public static pillMaterial(): uiMaterial.ImmersiveMaterial | undefined {
    if (!ImmersiveLightHelper.isSupported()) {
      return undefined;
    }
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
      materialColor: '#99FFFFFF',
      applyShadow: true,
      interactive: true,
      lightEffect: { color: '#6697000C' }
    });
  }

  /** 悬浮底栏 TabBar 专用沉浸光感材质 */
  public static tabBarMaterial(): uiMaterial.ImmersiveMaterial {
    return new uiMaterial.ImmersiveMaterial({
      style: uiMaterial.ImmersiveStyle.THIN,
      materialColor: '#B8FFFFFF',
      applyShadow: true,
      interactive: true,
      lightEffect: { color: '#5597000C' }
    });
  }
}
