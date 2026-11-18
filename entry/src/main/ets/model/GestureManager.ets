/**
 * 手势密码本地存储 — 1:1 复刻 GestureManager（report/mobile_campus/module/d/b.java）：
 *   Hawk 键 "allGesturePwdDatas" ← JSON 数组 [{userId, gesturePwds:[...]}]（Gson 序列化）。
 *   HAP 等价存储 = PreferencesUtil（源码 Hawk.d(app).build() 同语义持久化）。
 *   b(userId) 按 userId 线性查找；c(userId, list) 命中同 userId 则先 remove 再 add（源码顺序）。
 */
import { PreferencesUtil } from '../data/PreferencesUtil';

/** GesturePwdBean（module/my/entity/GesturePwdBean.java 两字段 1:1） */
export class GesturePwdBean {
  userId: string = '';
  gesturePwds: number[] = [];
}

const KEY_ALL_GESTURE: string = 'allGesturePwdDatas';

export class GestureManager {
  /** 源码 a()：读全部（解析失败 → 空数组等价 catch 返回 null 的空遍历语义） */
  static async all(): Promise<GesturePwdBean[]> {
    const raw: string = await PreferencesUtil.getString(KEY_ALL_GESTURE, '[]');
    if (raw === '' || raw === '[]') {
      return [];
    }
    try {
      const arr: Object[] = JSON.parse(raw) as Object[];
      const out: GesturePwdBean[] = [];
      for (const one of arr) {
        const rec = one as Record<string, Object>;
        const bean = new GesturePwdBean();
        bean.userId = typeof rec['userId'] === 'string' ? rec['userId'] as string : '';
        const pwdRaw: Object = rec['gesturePwds'];
        if (Array.isArray(pwdRaw)) {
          for (const p of pwdRaw as Object[]) {
            if (typeof p === 'number') {
              bean.gesturePwds.push(p as number);
            }
          }
        }
        out.push(bean);
      }
      return out;
    } catch (error) {
      return [];
    }
  }

  /** 源码 b(userId)：按 userId 查找，未命中 → null */
  static async find(userId: string): Promise<GesturePwdBean | null> {
    const all: GesturePwdBean[] = await GestureManager.all();
    if (all.length <= 0) {
      return null;
    }
    for (const bean of all) {
      if (userId === bean.userId) {
        return bean;
      }
    }
    return null;
  }

  /** 源码 c(userId, list)：命中同 userId 先 remove 再 add，整体回写 */
  static async save(userId: string, list: number[]): Promise<void> {
    const all: GesturePwdBean[] = await GestureManager.all();
    const bean = new GesturePwdBean();
    bean.userId = userId;
    bean.gesturePwds = list;
    if (all.length <= 0) {
      const arr: GesturePwdBean[] = [bean];
      await PreferencesUtil.putString(KEY_ALL_GESTURE, JSON.stringify(arr));
      return;
    }
    let hitIndex: number = -1;
    for (let i = 0; i < all.length; i++) {
      if (all[i].userId === userId) {
        hitIndex = i;
      }
    }
    if (hitIndex !== -1) {
      all.splice(hitIndex, 1);
    }
    all.push(bean);
    await PreferencesUtil.putString(KEY_ALL_GESTURE, JSON.stringify(all));
  }
}
