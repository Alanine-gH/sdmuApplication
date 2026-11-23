import { uiMaterial } from '@kit.ArkUI';

/**
 * 鸿蒙 API 26 原生沉浸光感材质助手（基于 @kit.ArkUI uiMaterial.ImmersiveMaterial）
 * 配合 module.json5 中 ohos.arkui.UIMaterial.state=enable 使用；
 * 挂载 systemMaterial 的组件需避免同时设置不透明 backgroundColor，使用 fallbackBg() 透出液态玻璃折射与光感。
 */
export class ImmersiveLightHelper {
  /** 检测当前设备是否支持沉浸光感材质 */
  public static isSupported(): boolean {
    try {
      return uiMaterial.isImmersiveMaterialSupported();
    } catch {
      return false;
    }
  }

  /** 支持沉浸光感时返回透明背景以防遮挡材质层；否则回退为原始纯色背景 */
  public static fallbackBg(color: ResourceColor): ResourceColor {
    return ImmersiveLightHelper.isSupported() ? Color.Transparent : color;
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
