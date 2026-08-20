import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { ProviderConfig } from '../model/ProviderConfig';

const STORE_NAME = 'aiquota';
const KEY_PROVIDERS = 'providers';

export class ProviderStore {
  static async get(context: common.Context): Promise<ProviderConfig[]> {
    const pref = preferences.getPreferences(context, STORE_NAME);
    const raw = pref.getSync(KEY_PROVIDERS, '[]') as string;
    try {
      return JSON.parse(raw) as ProviderConfig[];
    } catch (e) {
      return [];
    }
  }

  static set(context: common.Context, providers: ProviderConfig[]): void {
    const pref = preferences.getPreferences(context, STORE_NAME);
    pref.putSync(KEY_PROVIDERS, JSON.stringify(providers));
    pref.flush();
  }
}
