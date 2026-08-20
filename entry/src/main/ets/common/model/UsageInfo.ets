export interface UsageWindow {
  label: string;
  remaining: number;
  limit: number;
  remainingPercent: number;
  resetTime: string;
}

export interface UsageInfo {
  providerId: string;
  providerName?: string;
  windows: UsageWindow[];
  balance?: number;
  balanceUnit?: string;
  updatedAt: number;
  error?: string;
}
