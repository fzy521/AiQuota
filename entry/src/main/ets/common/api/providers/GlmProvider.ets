import { ProviderConfig } from '../../model/ProviderConfig';
import { UsageInfo, UsageWindow } from '../../model/UsageInfo';
import { httpGetJson, getObject, getNumber, getArray, getString, getValue, formatResetTime } from '../HttpUtil';

export class GlmProvider {
  static async query(config: ProviderConfig): Promise<UsageInfo> {
    const isEn = config.baseUrl.toLowerCase().includes('api.z.ai');
    const host = isEn ? 'https://api.z.ai' : 'https://open.bigmodel.cn';
    const url = `${host}/api/monitor/usage/quota/limit`;
    const headers: Record<string, string> = {
      'Authorization': config.apiKey,
      'Content-Type': 'application/json',
      'Accept-Language': 'en-US,en',
    };
    const body = await httpGetJson(url, headers) as Record<string, object | string | number | boolean | undefined>;
    if (body['success'] === false) {
      const msg = getString(body, 'msg') ?? 'GLM API error';
      throw new Error(msg);
    }

    const data = getObject(body, 'data');
    if (!data) {
      throw new Error('Missing data field');
    }

    const windows: UsageWindow[] = [];
    const limits = getArray(data, 'limits');
    if (limits) {
      for (const item of limits) {
        const type = (getString(item, 'type') ?? '').toLowerCase();
        if (type !== 'tokens_limit' && type !== 'credit_limit') {
          continue;
        }
        const percentage = getNumber(item, 'percentage') ?? 0; // 已用百分比
        const remainingPercent = Math.max(0, Math.min(100, 100 - percentage));
        const unit = getNumber(item, 'unit');
        const label = unit === 3 ? '5小时' : (unit === 6 ? '每周' : '额度');
        windows.push({
          label,
          remaining: remainingPercent,
          limit: 100,
          remainingPercent,
          resetTime: formatResetTime(getValue(item, 'nextResetTime')),
        });
      }
    }

    return { providerId: config.id, windows, updatedAt: Date.now() };
  }
}
