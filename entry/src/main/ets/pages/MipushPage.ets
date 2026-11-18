import { router } from '@kit.ArkUI';

/**
 * 推送透传落地页 — 源码级复刻 MipushTestActivity（baselibrary/framework/sdk/umeng）。
 * 源码：extends UmengNotifyClickActivity，onCreate 为加固 native（无布局资源），
 * onMessage(intent)：getStringExtra("body") → log"友盟推送1" → bundle{umeng_push=body}
 * → w.g(this, mobile_campus_launch_main, bundle) 跳主页 → finish()。
 * HAP 等价：纯转发壳，aboutToAppear 即 replaceUrl 主页（launch_main=Index），
 * 无任何 UI 元素（源码 onCreate 无 setContentView，UmengNotifyClickActivity 默认透明主题）。
 * 推送 body 参数（umeng_push）随 params 透传至主页（MainFragment onMessage 等价消费点）。
 */
/** 推送透传 bundle（源码 bundle{umeng_push=body}） */
class PushBodyParams {
  umeng_push: string = '';
}

@Entry
@Component
struct MipushPage {
  aboutToAppear(): void {
    const params: object | undefined = router.getParams() as object | undefined;
    // [W23 协作解堵] 原 ?? 空值合并产生未类型化字面量（arkts-no-untyped-obj-literals 23:41）：
    // 改为显式 typeof 判定（语义等价：body 缺失 → ''）
    let body: string = '';
    if (params !== null && params !== undefined) {
      const rec: Record<string, Object> = params as Record<string, Object>;
      const raw: Object = rec['body'];
      if (typeof raw === 'string') {
        body = raw as string;
      }
    }
    // = w.g(this, mobile_campus_launch_main, bundle{umeng_push}) + finish()
    const payload: PushBodyParams = new PushBodyParams();
    payload.umeng_push = body;
    router.replaceUrl({
      url: 'pages/Index',
      params: payload
    });
  }

  build() {
    // 源码无布局（UmengNotifyClickActivity 透明透传 Activity）
    Column()
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Transparent)
  }
}
