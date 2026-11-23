import { hdsEffect } from '@kit.UIDesignKit';

/**
 * 鸿蒙沉浸光感视效助手（基于 @kit.UIDesignKit hdsEffect）
 * 提供点光源（PointLight）边缘受光与按压流光阴影（PressShadow）
 */
export class ImmersiveLightHelper {
  /** 按钮交互沉浸光感：默认边缘受光 + 按压渐隐渐变；按下时点亮亮光源 */
  public static buttonGlow(pressed: boolean = false): VisualEffect | undefined {
    if (!canIUse('SystemCapability.UIDesign.HDSComponent.Core')) {
      return undefined;
    }
    return new hdsEffect.HdsEffectBuilder()
      .pointLight({
        sourceType: pressed ? hdsEffect.PointLightSourceType.BRIGHT : hdsEffect.PointLightSourceType.NONE,
        illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER_CONTENT,
        options: {
          color: Color.White,
          intensity: pressed ? 0.9 : 0.45,
          height: 80
        }
      })
      .pressShadow(hdsEffect.PressShadowType.BLEND_GRADIENT)
      .buildEffect();
  }

  /** 卡片/菜单项边缘受光 + 轻按压光影 */
  public static cardGlow(): VisualEffect | undefined {
    if (!canIUse('SystemCapability.UIDesign.HDSComponent.Core')) {
      return undefined;
    }
    return new hdsEffect.HdsEffectBuilder()
      .pointLight({
        illuminatedType: hdsEffect.PointLightIlluminatedType.BORDER
      })
      .pressShadow(hdsEffect.PressShadowType.BLEND_WHITE)
      .buildEffect();
  }
}
