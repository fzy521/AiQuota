import http from '@ohos.net.http';

export async function httpGetJson(url: string, headers: Record<string, string>): Promise<object> {
  const req = http.createHttp();
  try {
    const resp = await req.request(url, {
      method: http.RequestMethod.GET,
      header: headers,
      readTimeout: 15000,
      connectTimeout: 15000,
    });
    if (resp.responseCode < 200 || resp.responseCode >= 300) {
      const body = typeof resp.result === 'string' ? resp.result : JSON.stringify(resp.result);
      throw new Error(`HTTP ${resp.responseCode}: ${body}`);
    }
    const text = typeof resp.result === 'string' ? resp.result : JSON.stringify(resp.result);
    return JSON.parse(text) as object;
  } finally {
    req.destroy();
  }
}

export function getValue(obj: object | undefined, key: string): object | string | number | undefined {
  if (!obj) return undefined;
  const v = (obj as Record<string, object | string | number | boolean | undefined>)[key];
  if (typeof v === 'boolean') return undefined;
  return v;
}

export function getString(obj: object | undefined, key: string): string | undefined {
  const v = getValue(obj, key);
  return typeof v === 'string' ? v : undefined;
}

export function getNumber(obj: object | undefined, key: string): number | undefined {
  const v = getValue(obj, key);
  if (typeof v === 'number') return v;
  if (typeof v === 'string') {
    const n = parseFloat(v);
    return isNaN(n) ? undefined : n;
  }
  return undefined;
}

export function getArray(obj: object | undefined, key: string): object[] | undefined {
  if (!obj) return undefined;
  const v = (obj as Record<string, object | string | number | boolean | undefined>)[key];
  return Array.isArray(v) ? (v as object[]) : undefined;
}

export function getObject(obj: object | undefined, key: string): object | undefined {
  const v = getValue(obj, key);
  return typeof v === 'object' && v !== null ? v : undefined;
}

export function formatResetTime(value: object | string | number | undefined | null): string {
  if (value === undefined || value === null) return '';
  if (typeof value === 'string') return value;
  if (typeof value === 'number') {
    let ms = value;
    if (ms < 1000000000000) {
      ms = ms * 1000;
    }
    try {
      return new Date(ms).toISOString();
    } catch (e) {
      return '';
    }
  }
  return '';
}
