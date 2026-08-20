import { ProviderConfig } from '../../model/ProviderConfig';
import { UsageInfo, UsageWindow } from '../../model/UsageInfo';
import { httpGetJson, getObject, getNumber, getArray, getValue, formatResetTime } from '../HttpUtil';

export class KimiProvider {
  static async query(config: ProviderConfig): Promise<UsageInfo> {
    const url = 'https://api.kimi.com/coding/v1/usages';
    const headers: Record<string, string> = {
      'Authorization': `Bearer ${config.apiKey}`,
      'Accept': 'application/json',
    };
    const body = await httpGetJson(url, headers);
    const windows: UsageWindow[] = [];

    const limits = getArray(body, 'limits');
    if (limits) {
      for (const item of limits) {
        const detail = getObject(item, 'detail');
        if (detail) {
          const limit = getNumber(detail, 'limit') ?? 1;
          const remaining = getNumber(detail, 'remaining') ?? 0;
          windows.push({
            label: '5小时',
            remaining,
            limit,
            remainingPercent: limit > 0 ? Math.max(0, Math.min(100, remaining / limit * 100)) : 0,
            resetTime: formatResetTime(getValue(detail, 'resetTime')),
          });
        }
      }
    }

    const usage = getObject(body, 'usage');
    if (usage) {
      const limit = getNumber(usage, 'limit') ?? 1;
      const remaining = getNumber(usage, 'remaining') ?? 0;
      windows.push({
        label: '每周',
        remaining,
        limit,
        remainingPercent: limit > 0 ? Math.max(0, Math.min(100, remaining / limit * 100)) : 0,
        resetTime: formatResetTime(getValue(usage, 'resetTime')),
      });
    }

    return { providerId: config.id, windows, updatedAt: Date.now() };
  }
}
