import { ProviderConfig } from '../../model/ProviderConfig';
import { UsageInfo } from '../../model/UsageInfo';
import { httpGetJson, getArray, getNumber, getString } from '../HttpUtil';

export class DeepSeekProvider {
  static async query(config: ProviderConfig): Promise<UsageInfo> {
    const url = 'https://api.deepseek.com/user/balance';
    const headers: Record<string, string> = {
      'Authorization': `Bearer ${config.apiKey}`,
      'Accept': 'application/json',
    };
    const body = await httpGetJson(url, headers);
    const infos = getArray(body, 'balance_infos') ?? [];
    const first = infos[0];
    const balance = first ? (getNumber(first, 'total_balance') ?? 0) : 0;
    const unit = first ? (getString(first, 'currency') ?? 'CNY') : 'CNY';
    return { providerId: config.id, windows: [], balance, balanceUnit: unit, updatedAt: Date.now() };
  }
}
