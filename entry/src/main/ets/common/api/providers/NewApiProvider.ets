import { ProviderConfig } from '../../model/ProviderConfig';
import { UsageInfo } from '../../model/UsageInfo';
import { httpGetJson, getObject, getNumber } from '../HttpUtil';

export class NewApiProvider {
  static async query(config: ProviderConfig): Promise<UsageInfo> {
    const base = config.baseUrl.replace(/\/$/, '');
    const url = `${base}/api/user/self`;
    const headers: Record<string, string> = {
      'Authorization': `Bearer ${config.accessToken}`,
      'New-Api-User': config.userId,
    };
    const body = await httpGetJson(url, headers);
    const data = getObject(body, 'data');
    if (!data) {
      throw new Error('Missing data field');
    }
    const quota = getNumber(data, 'quota') ?? 0;
    const remaining = quota / 500000;
    return { providerId: config.id, windows: [], balance: remaining, balanceUnit: 'USD', updatedAt: Date.now() };
  }
}
