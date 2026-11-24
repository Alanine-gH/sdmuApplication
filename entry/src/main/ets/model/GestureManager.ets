/**
 * 手势密码本地存储 — 1:1 复刻 GestureManager（report/mobile_campus/module/d/b.java）：
 *   Hawk 键 "allGesturePwdDatas" ← JSON 数组 [{userId, gesturePwds:[...]}]（Gson 序列化）。
 *   HAP 等价存储 = PreferencesUtil（源码 Hawk.d(app).build() 同语义持久化）。
 *   b(userId) 按 userId 线性查找；c(userId, list) 命中同 userId 则先 remove 再 add（源码顺序）。
 */
import { SecureAssetHelper } from '../common/SecureAssetHelper';
import { LoginSession } from '../network/LoginSession';

/** GesturePwdBean（module/my/entity/GesturePwdBean.java 两字段 1:1） */
export class GesturePwdBean {
  userId: string = '';
  gesturePwds: number[] = [];
}

const KEY_ALL_GESTURE: string = 'allGesturePwdDatas';
const ALIAS_ALL_GESTURE: string = 'sdmu_gesture_pwd_datas';

export class GestureManager {
  /** 解析当前会话用于手势存储的稳定用户标识（userId 为空时回落手机号或默认本地标识） */
  static resolveUserId(): string {
    if (LoginSession.userId !== '') {
      return LoginSession.userId;
    }
    if (LoginSession.sessionPhone !== '') {
      return LoginSession.sessionPhone;
    }
    return 'local_default';
  }
  /** 源码 a()：读全部（优先硬件 TEE，回退 PreferencesUtil；解析失败 → 空数组） */
  static async all(): Promise<GesturePwdBean[]> {
    const raw: string = await SecureAssetHelper.getSecret(ALIAS_ALL_GESTURE, KEY_ALL_GESTURE);
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
      await SecureAssetHelper.putSecret(ALIAS_ALL_GESTURE, JSON.stringify(arr), KEY_ALL_GESTURE);
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
    await SecureAssetHelper.putSecret(ALIAS_ALL_GESTURE, JSON.stringify(all), KEY_ALL_GESTURE);
  }

  /** 移除指定用户的手势密码 */
  static async remove(userId: string): Promise<void> {
    const all: GesturePwdBean[] = await GestureManager.all();
    const rest: GesturePwdBean[] = all.filter((b: GesturePwdBean) => b.userId !== userId);
    if (rest.length === 0) {
      await SecureAssetHelper.removeSecret(ALIAS_ALL_GESTURE, KEY_ALL_GESTURE);
      return;
    }
    await SecureAssetHelper.putSecret(ALIAS_ALL_GESTURE, JSON.stringify(rest), KEY_ALL_GESTURE);
  }
}
