import { ProviderConfig } from '../../model/ProviderConfig';
import { UsageInfo, UsageWindow } from '../../model/UsageInfo';
import { httpGetJson, getObject, getNumber, getArray, getString, getValue, formatResetTime } from '../HttpUtil';

export class MiniMaxProvider {
  static async query(config: ProviderConfig): Promise<UsageInfo> {
    const url = 'https://api.minimaxi.com/v1/api/openplatform/coding_plan/remains';
    const headers: Record<string, string> = {
      'Authorization': `Bearer ${config.apiKey}`,
      'Content-Type': 'application/json',
    };
    const body = await httpGetJson(url, headers);
    const baseResp = getObject(body, 'base_resp');
    const statusCode = getNumber(baseResp, 'status_code') ?? -1;
    if (statusCode !== 0) {
      const msg = getString(baseResp, 'status_msg') ?? `MiniMax error ${statusCode}`;
      throw new Error(msg);
    }

    const windows: UsageWindow[] = [];
    const modelRemains = getArray(body, 'model_remains') ?? [];
    const general = modelRemains.find(item => getString(item, 'model_name') === 'general');
    if (!general) {
      throw new Error('No general model remains');
    }

    const fivePct = getNumber(general, 'current_interval_remaining_percent');
    if (fivePct !== undefined) {
      windows.push({
        label: '5小时',
        remaining: fivePct,
        limit: 100,
        remainingPercent: Math.max(0, Math.min(100, fivePct)),
        resetTime: formatResetTime(getValue(general, 'end_time')),
      });
    }

    const weeklyStatus = getNumber(general, 'current_weekly_status');
    if (weeklyStatus === 1) {
      const weeklyPct = getNumber(general, 'current_weekly_remaining_percent');
      if (weeklyPct !== undefined) {
        windows.push({
          label: '每周',
          remaining: weeklyPct,
          limit: 100,
          remainingPercent: Math.max(0, Math.min(100, weeklyPct)),
          resetTime: formatResetTime(getValue(general, 'weekly_end_time')),
        });
      }
    }

    return { providerId: config.id, windows, updatedAt: Date.now() };
  }
}
