import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { UsageInfo } from '../model/UsageInfo';

const STORE_NAME = 'aiquota';
const KEY_USAGE = 'usage_cache';
const KEY_FORM_IDS = 'form_ids';

export class UsageCache {
  static get(context: common.Context): UsageInfo[] {
    const pref = preferences.getPreferences(context, STORE_NAME);
    const raw = pref.getSync(KEY_USAGE, '[]') as string;
    try {
      return JSON.parse(raw) as UsageInfo[];
    } catch (e) {
      return [];
    }
  }

  static set(context: common.Context, usage: UsageInfo[]): void {
    const pref = preferences.getPreferences(context, STORE_NAME);
    pref.putSync(KEY_USAGE, JSON.stringify(usage));
    pref.flush();
  }

  static getFormIds(context: common.Context): string[] {
    const pref = preferences.getPreferences(context, STORE_NAME);
    const raw = pref.getSync(KEY_FORM_IDS, '[]') as string;
    try {
      return JSON.parse(raw) as string[];
    } catch (e) {
      return [];
    }
  }

  static addFormId(context: common.Context, formId: string): void {
    const pref = preferences.getPreferences(context, STORE_NAME);
    const ids = UsageCache.getFormIds(context);
    if (ids.indexOf(formId) < 0) {
      ids.push(formId);
      pref.putSync(KEY_FORM_IDS, JSON.stringify(ids));
      pref.flush();
    }
  }

  static removeFormId(context: common.Context, formId: string): void {
    const pref = preferences.getPreferences(context, STORE_NAME);
    const ids = UsageCache.getFormIds(context).filter(id => id !== formId);
    pref.putSync(KEY_FORM_IDS, JSON.stringify(ids));
    pref.flush();
  }
}
