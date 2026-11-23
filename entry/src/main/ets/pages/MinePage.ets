import { router } from '@kit.ArkUI';
import { PreferencesUtil } from '../data/PreferencesUtil';
import { Constants } from '../data/Constants';
import { MineTab } from '../components/MineTab';

/**
 * 个人中心独立页（复用 MineTab）。
 */
@Entry
@Component
struct MinePage {
  build() {
    Column() {
      MineTab()
    }
    .width('100%')
    .height('100%')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
